import 'dart:io';
import 'dart:typed_data';

import 'package:background_downloader/background_downloader.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ilovlya/src/api/directories_riverpod.dart';
import 'package:ilovlya/src/api/local_download_task_riverpod.dart';
import 'package:ilovlya/src/model/download.dart';
import 'package:ilovlya/src/model/local_download.dart';
import 'package:ilovlya/src/model/settings.dart';
import 'package:ilovlya/src/playback_download/partial_file.dart';
import 'package:ilovlya/src/playback_download/partial_source.dart';
import 'package:ilovlya/src/playback_download/playback_downloads.dart';
import 'package:ilovlya/src/settings/settings_provider.dart';
import 'package:path/path.dart' as p;

import '../helpers/provider_container.dart';
import 'local_endpoint_test.dart' show fetch;
import 'upstream.dart';

/// The real notifier listens to `background_downloader`, which needs a platform; these tests only need the map.
class _LocalDT extends LocalDTNotifier {
  @override
  Map<String, LocalDownloadTask> build() => {};
}

class _Settings extends SettingsNotifier {
  @override
  Future<Settings> build() async => Settings(token: 'tok');
}

void main() {
  late Directory root;
  late Upstream up;
  late Uint8List src;
  late ProviderContainer c;
  late HttpClient player;

  setUp(() async {
    root = Directory.systemTemp.createTempSync('playback_downloads_test');
    src = randomBytes(2 << 20);
    up = await Upstream.start(src);
    player = HttpClient();
    c = createTestProviderContainer(overrides: [
      storePlacesProvider.overrideWith((ref) async => StorePlaces(dataDir: p.join(root.path, 'data'), mediaDir: p.join(root.path, 'media'))),
      settingsProvider.overrideWith(() => _Settings()),
      localDTProvider.overrideWith(() => _LocalDT()),
    ]);
    Directory(p.join(root.path, 'media')).createSync(recursive: true);
  });
  tearDown(() async {
    c.dispose();
    player.close(force: true);
    await up.close();
    await Future.delayed(const Duration(milliseconds: 50));
    root.deleteSync(recursive: true);
  });

  Download download(String id) => Download(
        id: id,
        recordingId: 'r-$id',
        title: 'Title $id',
        filename: '$id.mp4',
        url: up.url.replace(pathSegments: ['api', 'recordings', 'downloads', id, 'content', '$id.mp4']).toString(),
      );

  PlaybackDownloads downloads() => c.read(playbackDownloadsProvider.notifier);
  LocalDownloadTask? task(String id) => c.read(localDTProvider)[id];
  String media(String name) => p.join(root.path, 'media', name);

  Future<void> until(bool Function() condition) async {
    for (var i = 0; i < 500 && !condition(); i++) {
      await Future.delayed(const Duration(milliseconds: 10));
    }
    expect(condition(), isTrue);
  }

  test('a played download ends as the final file, announced like any other download', () async {
    final d = download('d1');
    final url = await downloads().open(d);
    expect(url.host, '127.0.0.1');
    expect(task('d1')?.status, isNotNull);
    expect(downloads().shownSource('d1'), d.url, reason: 'while it arrives, the server is shown, not the endpoint');

    final r = await fetch(player, url, range: 'bytes=0-');
    expect(r.body, src);
    await until(() => c.read(playbackDownloadsProvider)['d1'] == SourceState.complete);
    expect(File(media('d1.mp4')).readAsBytesSync(), src);
    expect(downloads().shownSource('d1'), media('d1.mp4'), reason: 'once all of it has arrived, the local file is shown');
    expect(task('d1')?.status, TaskStatus.complete);
    expect(task('d1')?.progress, 1.0);
    expect(up.log.every((r) => r.authorization == 'tok'), isTrue, reason: 'the bare token, as getAuthHeader sends it');

    downloads().detach('d1');
    await until(() => !downloads().owns('d1'));
    expect(task('d1')?.status, TaskStatus.complete, reason: 'a finished download stays visible as finished');
  });

  test('opening another download pauses the first, which keeps its record for later', () async {
    up.rate = 512 * 1024;
    final first = await downloads().open(download('d1'));
    await fetch(player, first, range: 'bytes=0-', take: 100000);
    await downloads().open(download('d2'));

    expect(c.read(playbackDownloadsProvider)['d1'], SourceState.idle);
    expect(downloads().isActive('d1'), isFalse);
    expect(downloads().isActive('d2'), isTrue);
    expect(task('d1')?.status, TaskStatus.paused);
    final state = File(p.join(root.path, 'media', PartialFile.partialDirName, 'd1.mp4.state.json'));
    expect(state.existsSync(), isTrue, reason: 'the pause checkpointed what was stored');

    await downloads().discard('d2');
  });

  test('an answer without a length means streaming from the server instead', () async {
    up.noLength = true;
    final d = download('d1');
    final url = await downloads().open(d);
    expect(url.toString(), d.url);
    expect(downloads().owns('d1'), isFalse);
    expect(task('d1'), isNull);
  });

  test('cleaning the media turns an attached download into a pass-through and ends the others', () async {
    up.rate = 512 * 1024;
    final unattended = await downloads().open(download('d2'));
    await fetch(player, unattended, range: 'bytes=0-', take: 50000);
    downloads().detach('d2');
    final attached = await downloads().open(download('d1')); // pauses d2
    await fetch(player, attached, range: 'bytes=0-', take: 50000);

    await downloads().stopAll();
    expect(c.read(playbackDownloadsProvider)['d1'], SourceState.passThrough);
    expect(downloads().owns('d2'), isFalse);
    expect(task('d2'), isNull);
    expect(Directory(p.join(root.path, 'media', PartialFile.partialDirName)).listSync(), isEmpty);

    up.rate = null;
    final r = await fetch(player, attached, range: 'bytes=1000-');
    expect(r.body, src.sublist(1000), reason: 'the playback goes on as a plain stream');
  });

  test('discard deletes the partial file and forgets the download', () async {
    up.rate = 512 * 1024;
    final url = await downloads().open(download('d1'));
    await fetch(player, url, range: 'bytes=0-', take: 50000);
    await downloads().discard('d1');
    expect(downloads().owns('d1'), isFalse);
    expect(task('d1'), isNull);
    expect(File(p.join(root.path, 'media', PartialFile.partialDirName, 'd1.mp4')).existsSync(), isFalse);
    expect((await fetch(player, url, range: 'bytes=0-')).status, 404);
  });

  test('a download whose server fails waits to retry, with no speed and no time remaining, and runs again once it answers', () async {
    up.rate = 512 * 1024;
    downloads().recoveredAfter = const Duration(milliseconds: 300);
    final url = await downloads().open(download('d1'));
    await fetch(player, url, range: 'bytes=0-', take: 50000);
    await until(() => task('d1')?.status == TaskStatus.running && task('d1')?.networkSpeed != null);

    up.down = true;
    up.dropConnections();
    await until(() => task('d1')?.status == TaskStatus.waitingToRetry);
    expect(task('d1')!.networkSpeed, isNull, reason: 'the last speed says nothing about a server that does not answer');
    expect(task('d1')!.timeRemaining, isNull);
    expect(downloads().notAnsweringFor('d1'), isNotNull, reason: 'what the progress line shows instead');

    up.down = false;
    await until(() => task('d1')?.status == TaskStatus.running);
    expect(downloads().notAnsweringFor('d1'), isNull);
    await downloads().discard('d1');
  });

  test('a server that answers every retry with a portion and falls silent keeps the download waiting to retry', () async {
    // The case found in the simulator: every retry got its portion at once, so the line stayed "running" at 0–2 %.
    downloads()
      ..silenceTimeout = const Duration(milliseconds: 300)
      ..flowingWithin = const Duration(milliseconds: 100)
      ..recoveredAfter = const Duration(seconds: 1);
    up.silentEveryAfter = 64 << 10;
    final url = await downloads().open(download('d1'));
    await fetch(player, url, range: 'bytes=0-', take: 50000);
    await until(() => task('d1')?.status == TaskStatus.waitingToRetry);
    final since = DateTime.now().subtract(downloads().notAnsweringFor('d1')!);
    final clock = Stopwatch()..start();
    while (clock.elapsed < const Duration(seconds: 2)) {
      await Future.delayed(const Duration(milliseconds: 50));
      expect(task('d1')!.status, TaskStatus.waitingToRetry, reason: 'at ${clock.elapsed}, after ${up.log.length} requests');
      expect(task('d1')!.networkSpeed, isNull);
      expect(DateTime.now().subtract(downloads().notAnsweringFor('d1')!).difference(since).inMilliseconds.abs(), lessThan(100),
          reason: 'the time shown runs from the start, not from the last portion');
    }
    expect(up.log.length, greaterThanOrEqualTo(3), reason: 'two retries, each answered with its portion');
    expect(task('d1')!.progress, greaterThan(0));
    await downloads().discard('d1');
  });

  test('opening a download whose server is away from the start hands the player a URL that answers unavailable', () async {
    // #195: the length is not known, and the server has been away for longer than the give-up time. The wait for the
    // length fails rather than waits, and the endpoint tells the player at once instead of keeping its request.
    downloads()
      ..silenceTimeout = const Duration(milliseconds: 300)
      ..giveUpAfter = const Duration(milliseconds: 600);
    up.silent = true;
    final url = await downloads().open(download('d1')).timeout(PlaybackDownloads.lengthWait);
    final clock = Stopwatch()..start();
    final r = await fetch(player, url, range: 'bytes=0-').timeout(const Duration(seconds: 5));
    expect(r.status, HttpStatus.serviceUnavailable);
    // At once: after the one try the request prompts, which fails within the 300 ms silence timeout.
    expect(clock.elapsed, lessThan(const Duration(seconds: 1)), reason: 'not after the give-up time again');
    up.silent = false;
    await downloads().discard('d1');
  });

  test('a download discarded while its length is awaited is streamed from the server, not served by the endpoint', () async {
    // A discard during open()'s wait — the download removed, or its file cleaned — ended the wait as a stop, and open()
    // handed the player the endpoint's URL, which the discard had just unregistered: 404 instead of the stream.
    downloads().silenceTimeout = const Duration(seconds: 30);
    up.silent = true;
    final d = download('d1');
    final opening = downloads().open(d);
    await Future<void>.delayed(const Duration(milliseconds: 300));
    await downloads().discardFile(d.filename);
    expect(await opening.timeout(const Duration(seconds: 2)), Uri.parse(d.url));
    up.silent = false;
  });

  test('a download whose media is cleaned before the server first answers is streamed from the server', () async {
    // #200: the pass-through has no length to serve from, so every request to the endpoint was answered 503; open()
    // handed the player the endpoint's URL all the same.
    downloads().silenceTimeout = const Duration(seconds: 30);
    up.silent = true;
    final d = download('d1');
    final opening = downloads().open(d);
    await Future<void>.delayed(const Duration(milliseconds: 300));
    await downloads().stopAll();
    expect(await opening.timeout(const Duration(seconds: 2)), Uri.parse(d.url));
    up.silent = false;
  });

  group('time spent suspended is not silence', () {
    // On iOS a paused player in the background lets the process be suspended (spec 004, "On iOS"): no byte arrives, and
    // wall-clock time goes on. Here the process runs on, so the suspension is played by a server that falls silent at the
    // same moment, which is what the transfer sees of it.
    void short() => downloads()
      ..silenceTimeout = const Duration(milliseconds: 300)
      ..flowingWithin = const Duration(milliseconds: 100)
      ..recoveredAfter = const Duration(seconds: 1);

    Future<void> suspendFor(Duration d) async {
      downloads().playerPlaying = false;
      downloads().inFront = false;
      up.silent = true;
      await Future.delayed(d);
    }

    test('back in front, a transfer that was flowing is not shown as not answering', () async {
      short();
      up.rate = 256 * 1024;
      final url = await downloads().open(download('d1'));
      await fetch(player, url, range: 'bytes=0-', take: 50000);
      await until(() => task('d1')?.status == TaskStatus.running && task('d1')?.networkSpeed != null);

      await suspendFor(const Duration(milliseconds: 1500));
      up.silent = false;
      downloads().inFront = true;
      expect(downloads().notAnsweringFor('d1'), isNull, reason: 'the server did nothing wrong; the application was away');
      final clock = Stopwatch()..start();
      while (clock.elapsed < const Duration(seconds: 1)) {
        expect(task('d1')!.status, isNot(TaskStatus.waitingToRetry), reason: 'at ${clock.elapsed} after the return');
        await Future.delayed(const Duration(milliseconds: 50));
      }
      await until(() => c.read(playbackDownloadsProvider)['d1'] == SourceState.complete);
      expect(File(media('d1.mp4')).readAsBytesSync(), src);
    });

    test('a failure streak from before the suspension does not count the suspension', () async {
      short();
      up.rate = 256 * 1024;
      final url = await downloads().open(download('d1'));
      await fetch(player, url, range: 'bytes=0-', take: 50000);
      up.down = true;
      up.dropConnections();
      await until(() => downloads().notAnsweringFor('d1') != null);
      final before = downloads().notAnsweringFor('d1')!;

      await suspendFor(const Duration(milliseconds: 1500));
      downloads().inFront = true;
      final after = downloads().notAnsweringFor('d1')!;
      expect(after - before, lessThan(const Duration(milliseconds: 300)), reason: 'only the time in front counts: $before, then $after');
      up
        ..silent = false
        ..down = false;
      await downloads().discard('d1');
    });

    test('a server that is in fact silent after the return is still reported after the silence timeout', () async {
      short();
      // Well above the 64 KiB per 300 ms the window asks for, so that only the silence after the return can trip it.
      up.rate = 512 * 1024;
      final url = await downloads().open(download('d1'));
      await fetch(player, url, range: 'bytes=0-', take: 50000);
      await until(() => task('d1')?.status == TaskStatus.running && task('d1')?.networkSpeed != null);

      await suspendFor(const Duration(milliseconds: 1500));
      downloads().inFront = true; // up stays silent
      expect(downloads().notAnsweringFor('d1'), isNull);
      final clock = Stopwatch()..start();
      await until(() => downloads().notAnsweringFor('d1') != null);
      // The window still holds what came just before the suspension; it runs out 300 ms less the time 64 KiB took at
      // 512 KiB/s, about 175 ms after the return. Before the fix the report came at once, carrying the suspension.
      expect(clock.elapsed, greaterThanOrEqualTo(const Duration(milliseconds: 100)), reason: 'not at once');
      // Counted from the return, less the 300 ms window, however late this looks: the suspension took 1.5 s.
      final notAnswering = downloads().notAnsweringFor('d1')!;
      expect(notAnswering, lessThanOrEqualTo(clock.elapsed + const Duration(milliseconds: 300)), reason: 'counted from the return, not from the suspension');
      expect(clock.elapsed, lessThan(const Duration(seconds: 5)), reason: 'a safety net');
      up.silent = false;
      await downloads().discard('d1');
    });
  });

  test('in the background the endpoint listens only while the player plays, and keeps its URL across', () async {
    up.rate = 512 * 1024;
    final url = await downloads().open(download('d1'));
    final first = await fetch(player, url, range: 'bytes=0-', take: 50000);

    downloads().playerPlaying = true;
    downloads().inFront = false;
    await downloads().listeningSettled;
    expect((await fetch(player, url, range: 'bytes=0-', take: 1000)).status, 206, reason: 'playing keeps the process running');

    downloads().playerPlaying = false;
    await downloads().listeningSettled;
    await expectLater(fetch(player, url, range: 'bytes=0-'), throwsA(isA<SocketException>()), reason: 'about to be suspended');
    expect(downloads().owns('d1'), isTrue, reason: 'the download is frozen, not ended');

    downloads().inFront = true;
    await downloads().listeningSettled;
    up.rate = null;
    final back = await fetch(player, url, range: 'bytes=${first.body.length}-');
    expect(back.body, src.sublist(first.body.length));
    expect(await downloads().open(download('d1')), url, reason: 'the same port and token');
    await downloads().discard('d1');
  });

  test('if the port cannot be bound again, the next open serves the download from a new endpoint', () async {
    up.rate = 512 * 1024;
    final url = await downloads().open(download('d1'));
    await fetch(player, url, range: 'bytes=0-', take: 50000);
    downloads().inFront = false;
    await downloads().listeningSettled;
    final squatter = await ServerSocket.bind(InternetAddress.loopbackIPv4, url.port);
    try {
      downloads().inFront = true;
      await downloads().listeningSettled;
    } finally {
      await squatter.close();
    }
    expect(downloads().owns('d1'), isTrue);

    up.rate = null;
    final again = await downloads().open(download('d1'));
    expect(again, isNot(url));
    expect((await fetch(player, again, range: 'bytes=0-')).body, src);
    await downloads().discard('d1');
  });
}
