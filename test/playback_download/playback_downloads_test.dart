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
    c = ProviderContainer(overrides: [
      storePlacesProvider.overrideWith((ref) async => StorePlaces(dataDir: p.join(root.path, 'data'), mediaDir: p.join(root.path, 'media'))),
      settingsNotifierProvider.overrideWith(() => _Settings()),
      localDTNotifierProvider.overrideWith(() => _LocalDT()),
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
  LocalDownloadTask? task(String id) => c.read(localDTNotifierProvider)[id];
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

    final r = await fetch(player, url, range: 'bytes=0-');
    expect(r.body, src);
    await until(() => c.read(playbackDownloadsProvider)['d1'] == SourceState.complete);
    expect(File(media('d1.mp4')).readAsBytesSync(), src);
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
}
