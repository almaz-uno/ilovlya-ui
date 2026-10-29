import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:ilovlya/src/playback_download/fetcher.dart';
import 'package:ilovlya/src/playback_download/local_endpoint.dart';
import 'package:ilovlya/src/playback_download/partial_file.dart';
import 'package:ilovlya/src/playback_download/partial_source.dart';
import 'package:path/path.dart' as p;

import 'upstream.dart';

/// What the player does: one request, `Range: bytes=<from>-` unless told otherwise, reading at most [take] bytes.
class Read {
  final int status;
  final HttpHeaders headers;
  final Uint8List body;
  final Object? error;
  final Duration firstByte;

  Read(this.status, this.headers, this.body, this.error, this.firstByte);
}

Future<Read> fetch(HttpClient client, Uri url, {String? range, int? take, String method = 'GET'}) async {
  final clock = Stopwatch()..start();
  final req = await client.openUrl(method, url);
  if (range != null) req.headers.set(HttpHeaders.rangeHeader, range);
  final res = await req.close();
  final body = BytesBuilder(copy: false);
  Duration? first;
  Object? error;
  final done = Completer<void>();
  late StreamSubscription<List<int>> sub;
  sub = res.listen((chunk) {
    first ??= clock.elapsed;
    body.add(chunk);
    if (take != null && body.length >= take) {
      sub.cancel();
      if (!done.isCompleted) done.complete();
    }
  }, onError: (Object e) {
    error = e;
    if (!done.isCompleted) done.complete();
  }, onDone: () {
    if (!done.isCompleted) done.complete();
  }, cancelOnError: true);
  await done.future;
  final bytes = body.takeBytes();
  return Read(res.statusCode, res.headers, take != null && bytes.length > take ? Uint8List.sublistView(bytes, 0, take) : bytes, error, first ?? clock.elapsed);
}

/// A response the player opened and stopped reading without closing it: libmpv's first request, from byte 0, while it
/// reads the index at the end. The endpoint goes on waiting for its bytes.
Future<(Socket, StreamSubscription<Uint8List>)> stall(Uri url, {required int after}) async {
  final socket = await Socket.connect(url.host, url.port);
  socket.write('GET ${url.path} HTTP/1.1\r\nHost: ${url.host}:${url.port}\r\nRange: bytes=0-\r\n\r\n');
  var got = 0;
  late StreamSubscription<Uint8List> sub;
  final enough = Completer<void>();
  sub = socket.listen((bytes) {
    got += bytes.length;
    if (got >= after && !enough.isCompleted) {
      sub.pause();
      enough.complete();
    }
  }, onError: (_) {}, cancelOnError: true);
  await enough.future;
  return (socket, sub);
}

void main() {
  late Directory media;
  late Upstream up;
  late Uint8List src;
  late LocalMediaEndpoint endpoint;
  late HttpClient player;
  final sources = <PartialSource>[];

  setUp(() async {
    media = Directory.systemTemp.createTempSync('local_endpoint_test');
    src = randomBytes(4 << 20);
    up = await Upstream.start(src);
    endpoint = await LocalMediaEndpoint.start();
    player = HttpClient();
  });
  tearDown(() async {
    for (final s in sources) {
      await s.dispose();
    }
    sources.clear();
    player.close(force: true);
    await endpoint.close();
    await up.close();
    await Process.run('chmod', ['-R', 'u+w', media.path]);
    media.deleteSync(recursive: true);
  });

  (PartialSource, Uri) serve(
      {String id = 'd1', Duration giveUpAfter = PartialSource.defaultGiveUpAfter, Duration backoff = Duration.zero, Duration silence = Fetcher.defaultSilenceTimeout}) {
    final file = PartialFile.open(mediaDir: media.path, downloadId: id, filename: '$id.mp4', url: up.url.toString());
    final source = PartialSource(file: file, url: up.url, giveUpAfter: giveUpAfter, backoff: (_, _) => backoff, silenceTimeout: silence);
    sources.add(source);
    return (source, endpoint.register(id, '$id.mp4', source));
  }

  /// Waits for the transfer to end and its outcome to be settled: the run is over before the file is completed and
  /// the state follows.
  Future<void> settle(PartialSource s, {Duration within = const Duration(seconds: 10)}) async {
    final clock = Stopwatch()..start();
    while (s.isRunning || s.state == SourceState.running) {
      if (clock.elapsed > within) fail('not settled within $within: running ${s.isRunning}, ${s.state}');
      await Future.delayed(const Duration(milliseconds: 10));
    }
  }

  test('serves an open-ended range as libmpv asks for it, and the file is the server\'s', () async {
    final (source, url) = serve();
    final r = await fetch(player, url, range: 'bytes=0-');
    expect(r.status, 206);
    expect(r.headers.value(HttpHeaders.contentRangeHeader), 'bytes 0-${src.length - 1}/${src.length}');
    expect(r.headers.contentType?.mimeType, 'video/mp4');
    expect(r.body, src);
    await settle(source);
    expect(source.state, SourceState.complete);
    expect(File(p.join(media.path, 'd1.mp4')).readAsBytesSync(), src);
    expect(up.bytesServed, src.length);
  });

  test('answers 200 without a Range header and 416 past the end; HEAD has no body', () async {
    final (_, url) = serve();
    final whole = await fetch(player, url);
    expect(whole.status, 200);
    expect(whole.headers.contentLength, src.length);
    expect(whole.body, src);
    expect((await fetch(player, url, range: 'bytes=${src.length}-')).status, 416);
    final head = await fetch(player, url, range: 'bytes=10-19', method: 'HEAD');
    expect(head.status, 206);
    expect(head.headers.contentLength, 10);
    expect(head.body, isEmpty);
  });

  test('a read near the end comes first, without waiting for the whole file', () async {
    up.rate = 2 << 20;
    final (source, url) = serve();
    final tailFrom = src.length - 65536;
    final tail = await fetch(player, url, range: 'bytes=$tailFrom-');
    expect(tail.body, src.sublist(tailFrom));
    expect(up.log[1].range, startsWith('bytes=$tailFrom-'), reason: 'moved where the player reads: ${up.log}');
    expect(up.log.first.bytes, lessThan(tailFrom), reason: 'the first request was cut, not let run to the tail: ${up.log}');
    expect(tail.firstByte, lessThan(const Duration(seconds: 5)), reason: 'a safety net; the whole file takes 2 s');
    final rest = await fetch(player, url, range: 'bytes=0-');
    expect(rest.body, src);
    await settle(source);
    expect(up.bytesServed - src.length, lessThan(256 * 1024), reason: '${up.log}');
  });

  test('a seek beyond what has arrived moves the transfer instead of waiting for it', () async {
    up.rate = 1 << 20;
    final (source, url) = serve();
    await fetch(player, url, range: 'bytes=0-', take: 200000);
    final seekTo = 3 << 20;
    final after = await fetch(player, url, range: 'bytes=$seekTo-', take: 100000);
    expect(after.body, src.sublist(seekTo, seekTo + 100000));
    expect(up.log.map((r) => r.range), contains(startsWith('bytes=$seekTo-')));
    final below = up.log.where((r) => int.parse(RegExp(r'bytes=(\d+)-').firstMatch(r.range!)![1]!) < seekTo).fold(0, (n, r) => n + r.bytes);
    expect(below, lessThan(seekTo), reason: 'moved there, not fetched its way there: ${up.log}');
    expect(after.firstByte, lessThan(const Duration(seconds: 5)), reason: 'a safety net; fetching the way there takes ~2.8 s');
    source.fetcher.stop();
  });

  test('a seek just ahead of the transfer waits for it instead of moving it', () async {
    up.rate = 1 << 20;
    final (source, url) = serve();
    await fetch(player, url, range: 'bytes=0-', take: 100000);
    final requests = up.log.length;
    final ahead = source.fetcher.position + 256 * 1024;
    final r = await fetch(player, url, range: 'bytes=$ahead-', take: 50000);
    expect(r.body, src.sublist(ahead, ahead + 50000));
    expect(up.log.length, requests, reason: 'no new request to the server: ${up.log}');
    source.fetcher.stop();
  });

  // ilovlya-ui#176: two readers far apart — the first response waiting at the front, the index read at the end — moved
  // the transfer back and forth, each request storing what one round trip brought, some hundreds of requests for the
  // index. Without the look at the first bytes (a file not seen as an MP4) the closing gap alone must keep it short.
  for (final recognised in [true, false]) {
    test('an index at the end read while the first response waits at the front takes a few requests (${recognised ? 'm4a' : 'unrecognised'})',
        () async {
      const moov = 240962;
      src = m4aWithTrailingMoov(mdat: 8 << 20, moov: moov);
      if (!recognised) src.setRange(4, 8, 'xxxx'.codeUnits);
      up.data = src;
      up.rate = 2 << 20; // a mobile link
      up.latency = const Duration(milliseconds: 150);
      final (source, url) = serve();
      final moovAt = src.length - moov;

      final (front, frontSub) = await stall(url, after: 64 << 10);
      final clock = Stopwatch()..start();
      final tail = await fetch(player, url, range: 'bytes=$moovAt-');
      final took = clock.elapsed;
      expect(tail.body, src.sublist(moovAt));
      expect(up.log.length, lessThanOrEqualTo(4), reason: 'requests until the index was read: ${up.log}');
      expect(took, lessThan(const Duration(seconds: 4)), reason: 'the index is a fraction of a second at this rate');
      expect(source.fetcher.notAnsweringFor, isNull);

      await frontSub.cancel();
      front.destroy();
      source.fetcher.stop();
    });
  }

  test('refuses what was not registered with it', () async {
    final (_, url) = serve();
    final base = url.replace(pathSegments: url.pathSegments.sublist(0, 1));
    expect((await fetch(player, url.replace(pathSegments: ['wrong-token', ...url.pathSegments.skip(1)]))).status, 404);
    expect((await fetch(player, base.replace(pathSegments: [url.pathSegments.first, 'unknown', 'x.mp4']))).status, 404);
    expect((await fetch(player, base.replace(pathSegments: [url.pathSegments.first, 'http://example.com/']))).status, 404);
    expect((await fetch(player, url, method: 'POST')).status, 404);
  });

  test('a source unregistered mid-response resets it, and answers 404 afterwards', () async {
    up.rate = 1 << 20;
    final (_, url) = serve();
    final reading = fetch(player, url, range: 'bytes=0-');
    await Future.delayed(const Duration(milliseconds: 300));
    endpoint.unregister('d1');
    final r = await reading;
    expect(r.error, isNotNull, reason: 'a reset, not a clean end of file: got ${r.body.length} bytes');
    expect(r.body.length, lessThan(src.length));
    expect((await fetch(player, url, range: 'bytes=0-')).status, 404);
  });

  test('when the file cannot be written, the bytes come from the server and nothing is left behind', () async {
    final (source, url) = serve();
    await Process.run('chmod', ['a-w', p.join(media.path, PartialFile.partialDirName)]);
    final r = await fetch(player, url, range: 'bytes=0-');
    expect(r.error, isNull);
    expect(r.body, src);
    expect(source.state, SourceState.passThrough);
    expect(Directory(p.join(media.path, PartialFile.partialDirName)).listSync(), isEmpty);
  });

  test('when the record stops being writable mid-download, the rest comes from the server', () async {
    final big = randomBytes(PartialFile.checkpointBytes + (1 << 20), 3);
    up.replace(big, 'Thu, 24 Sep 2026 10:00:00 GMT');
    up.rate = 16 << 20;
    final (source, url) = serve();
    final reading = fetch(player, url, range: 'bytes=0-');
    while (source.file.ranges.stored == 0) {
      await Future.delayed(const Duration(milliseconds: 5));
    }
    await Process.run('chmod', ['a-w', p.join(media.path, PartialFile.partialDirName)]);
    final r = await reading;
    expect(r.error, isNull);
    expect(r.body, big);
    expect(source.state, SourceState.passThrough);
    expect(source.writeFailed, isTrue);
    // At most the whole first answer, which the server may have pushed into the socket before the abort, and the 1 MiB
    // that was not stored; fetching the stored bytes again would add 8 MiB.
    expect(up.bytesServed, lessThanOrEqualTo(big.length + (1 << 20)), reason: 'what was stored is read from the file, not fetched again');
  });

  test('a partial file whose server file changed meanwhile is started over, and serves none of the old bytes', () async {
    up.rate = 4 << 20;
    up.silentNextAfter = 2 << 20; // the first transfer never finishes the file, however slow the test runs
    final (first, url) = serve();
    await fetch(player, url, range: 'bytes=0-', take: 1 << 20);
    await first.dispose(); // the application went away, keeping what was stored
    final replaced = randomBytes(src.length + 4096, 2);
    up.replace(replaced, 'Wed, 23 Sep 2026 10:00:00 GMT');
    up.rate = null;

    final (second, again) = serve();
    expect(second.confirmed, isFalse);
    final r = await fetch(player, again, range: 'bytes=0-');
    expect(r.status, 206);
    expect(r.headers.value(HttpHeaders.contentRangeHeader), 'bytes 0-${replaced.length - 1}/${replaced.length}');
    expect(r.body, replaced);
    await settle(second);
    expect(second.state, SourceState.complete);
    expect(File(p.join(media.path, 'd1.mp4')).readAsBytesSync(), replaced);
  });

  test('a read waiting for a server that stays away gives up, and so does every read while it lasts', () async {
    up.rate = 1 << 20;
    final (source, url) = serve(giveUpAfter: const Duration(milliseconds: 400), backoff: const Duration(milliseconds: 50));
    await fetch(player, url, range: 'bytes=0-', take: 100000);
    up.down = true;
    up.dropConnections();
    final clock = Stopwatch()..start();
    final waiting = await fetch(player, url, range: 'bytes=${3 << 20}-');
    expect(waiting.error, isNotNull, reason: 'reset, so that the player learns of it');
    expect(clock.elapsed, greaterThanOrEqualTo(const Duration(milliseconds: 300)));
    final failing = source.fetcher.failingFor!;
    clock.reset();
    final next = await fetch(player, url, range: 'bytes=${3 << 20}-');
    expect(next.error, isNotNull);
    // The try the read prompts fails too, and the failure goes on from where it was: no second full wait.
    // The fetcher's clock is not the stopwatch: they may part by microseconds.
    expect(source.fetcher.failingFor, greaterThanOrEqualTo(failing + clock.elapsed - const Duration(milliseconds: 10)));
    expect(clock.elapsed, lessThan(const Duration(seconds: 5)), reason: 'a safety net');

    up.down = false;
    up.rate = null;
    final back = await fetch(player, url, range: 'bytes=${3 << 20}-');
    expect(back.error, isNull);
    expect(back.body, Uint8List.sublistView(src, 3 << 20));
    expect(source.isGone, isFalse);
  });

  test('a fresh playback whose server falls silent after the first bytes recovers by itself and plays to the end', () async {
    // #144: open the player on a file ready on the server; the first answer stops after a few KiB without closing. The
    // player reads from 0, within the window, so nothing moves the transfer: only the silence timeout ends the request.
    up.silentNextAfter = 4096;
    final (source, url) = serve(silence: const Duration(milliseconds: 300));
    final clock = Stopwatch()..start();
    final read = await fetch(player, url, range: 'bytes=0-');
    expect(read.error, isNull);
    expect(read.body, src, reason: 'the whole file, through one response, with no reopening');
    expect(clock.elapsed, lessThan(const Duration(seconds: 15)), reason: 'a safety net');
    expect(up.log.first.silenced, isTrue);
    expect(up.log[1].range, startsWith('bytes=${up.log.first.bytes}-'), reason: 'resumed at the byte it reached: ${up.log}');
    await settle(source);
    expect(source.state, SourceState.complete);
  });

  test('a seek while the server is silent moves the transfer at once, not after the silence timeout', () async {
    // `abort` does not end a body that sends nothing; on develop the retarget waited for a chunk that never came.
    up.silentNextAfter = 4096;
    final (_, url) = serve(silence: const Duration(seconds: 30));
    final first = fetch(player, url, range: 'bytes=0-', take: 8192);
    while (up.log.isEmpty || !up.log.first.silenced) {
      await Future.delayed(const Duration(milliseconds: 10));
    }
    final clock = Stopwatch()..start();
    final far = await fetch(HttpClient(), url, range: 'bytes=${3 << 20}-', take: 65536);
    expect(far.body, Uint8List.sublistView(src, 3 << 20, (3 << 20) + 65536));
    expect(clock.elapsed, lessThan(const Duration(seconds: 3)));
    expect(up.log[1].range, 'bytes=${3 << 20}-${src.length - 1}');
    first.ignore();
  });

  test('a read waiting for a server that falls silent gives up as for one that refuses, and is served once it speaks', () async {
    // The connection neither answers nor closes, as across an iOS suspension: without a timeout nothing ever fails,
    // and the read waits for ever (#144).
    up.rate = 1 << 20;
    final (source, url) = serve(giveUpAfter: const Duration(milliseconds: 600), backoff: const Duration(milliseconds: 50), silence: const Duration(milliseconds: 200));
    await fetch(player, url, range: 'bytes=0-', take: 100000);
    up.silent = true;
    final clock = Stopwatch()..start();
    final waiting = await fetch(player, url, range: 'bytes=${3 << 20}-');
    expect(waiting.error, isNotNull, reason: 'reset, so that the player learns of it');
    // Given up for the server's silence, whichever reads steered the transfer meanwhile (the first one may still wait).
    expect(source.serverAway, isTrue, reason: '${up.log}');
    expect(up.log.where((r) => r.silenced), isNotEmpty);
    expect(clock.elapsed, lessThan(const Duration(seconds: 5)), reason: 'a safety net; given up about 600 ms after the bytes stopped');

    up.silent = false;
    up.rate = null;
    final back = await fetch(player, url, range: 'bytes=${3 << 20}-');
    expect(back.error, isNull);
    expect(back.body, Uint8List.sublistView(src, 3 << 20));
    expect(source.isGone, isFalse);
  });

  test('a silent server is given up though two waiting reads steer the transfer by turns', () async {
    // libmpv's first response stalls at the front while it reads elsewhere; both reads wait, and each steers the transfer
    // back to itself every 250 ms. On develop every request was cut short of the silence timeout by the other read's
    // retarget, a cut request was no failure, and the reads never gave up: ~8 requests a second for ever.
    up.rate = 1 << 20;
    final (source, url) = serve(giveUpAfter: const Duration(milliseconds: 600), backoff: const Duration(milliseconds: 50), silence: const Duration(seconds: 1));
    final (front, paused) = await stall(url, after: 65536);
    try {
      up.silent = true;
      final far = await fetch(player, url, range: 'bytes=${3 << 20}-').timeout(const Duration(seconds: 10));
      expect(far.error, isNotNull, reason: 'reset, so that the player learns of it');
      expect(source.serverAway, isTrue);
      // The request for the read at 3 MiB was let wait for its answer until the silence timeout, not cut by the other.
      final asked = up.log.where((r) => r.range!.startsWith('bytes=${3 << 20}-')).toList();
      expect(asked, isNotEmpty, reason: '${up.log}');
      expect(asked.first.silenced, isTrue, reason: '${up.log}');
      expect(up.log.length, lessThanOrEqualTo(4), reason: 'no request a 250 ms: ${up.log}');
    } finally {
      await paused.cancel();
      front.destroy();
    }
  });

  test('two reads that steer the transfer by turns are both served by a server slow to answer', () async {
    // Each read steers the transfer back to itself every 250 ms. A request cut before its answer brings nothing, and
    // over a link whose answers take longer than that no request was ever answered: on develop the two reads cut each
    // other's requests for ever, and counting the silence across them gave up on a server that answers.
    up.rate = 2 << 20;
    up.latency = const Duration(milliseconds: 400);
    final (source, url) = serve(giveUpAfter: const Duration(milliseconds: 600), backoff: const Duration(milliseconds: 50), silence: const Duration(seconds: 1));
    final front = fetch(player, url, range: 'bytes=0-', take: 256 << 10);
    final far = fetch(player, url, range: 'bytes=${3 << 20}-', take: 256 << 10);
    final (a, b) = await (front, far).wait.timeout(const Duration(seconds: 10));
    expect(a.error, isNull);
    expect(a.body, Uint8List.sublistView(src, 0, 256 << 10));
    expect(b.error, isNull);
    expect(b.body, Uint8List.sublistView(src, 3 << 20, (3 << 20) + (256 << 10)));
    expect(source.serverAway, isFalse);
    expect(up.log.where((r) => r.status == null), hasLength(lessThanOrEqualTo(1)), reason: 'no request cut before its answer but one at most: ${up.log}');
    expect(up.log.length, lessThanOrEqualTo(6), reason: '${up.log}');
  });

  test('a server that cannot be connected to is given up though two waiting reads steer the transfer by turns', () async {
    // The connect itself hangs, as to a host that drops the packets: no request exists to abort, and a retarget used to
    // leave the connect running until the client's own timeout, then take its end for its own cut — no failure, and
    // the other read asked again, for ever.
    var hang = Duration.zero;
    final client = HttpClient()
      ..connectionFactory = (uri, proxyHost, proxyPort) async {
        await Future<void>.delayed(hang);
        return Socket.startConnect(uri.host, uri.port);
      };
    up.rate = 64 << 10; // the transfer does not reach either read by itself
    final file = PartialFile.open(mediaDir: media.path, downloadId: 'd1', filename: 'd1.mp4', url: up.url.toString());
    final source = PartialSource(
        file: file, url: up.url, client: client, giveUpAfter: const Duration(milliseconds: 600), backoff: (_, _) => const Duration(milliseconds: 50), silenceTimeout: const Duration(seconds: 1));
    sources.add(source);
    final url = endpoint.register('d1', 'd1.mp4', source);
    await fetch(player, url, range: 'bytes=0-', take: 16384);
    hang = const Duration(seconds: 3); // every connect from now on, none of them failing by itself
    final reads = await (fetch(player, url, range: 'bytes=${1 << 20}-'), fetch(player, url, range: 'bytes=${3 << 20}-')).wait.timeout(const Duration(seconds: 10));
    expect(reads.$1.error, isNotNull, reason: 'reset, so that the player learns of it');
    expect(reads.$2.error, isNotNull, reason: 'reset, so that the player learns of it');
    expect(source.serverAway, isTrue);
  });

  test('a server silent from the start is given up before the length is known, and the URL is served once it speaks', () async {
    // No answer yet, so no length: the endpoint waited for it with no bound, and the player's first request hung for as
    // long as the server said nothing (#195).
    up.silent = true;
    const giveUpAfter = Duration(seconds: 1);
    final (source, url) = serve(giveUpAfter: giveUpAfter, backoff: const Duration(milliseconds: 50), silence: const Duration(milliseconds: 300));
    final clock = Stopwatch()..start();
    final first = await fetch(player, url, range: 'bytes=0-').timeout(const Duration(seconds: 10));
    expect(first.status, HttpStatus.serviceUnavailable, reason: 'unavailable, not missing: ${first.status}');
    expect(source.serverAway, isTrue);
    expect(source.isGone, isFalse);
    // The bound of #195: within the give-up time and the grace a read is given, not after the fetcher's own timeouts.
    expect(clock.elapsed, lessThan(giveUpAfter + PartialSource.retryGrace), reason: '${up.log}');

    up.silent = false;
    up.dropConnections();
    final back = await fetch(player, url, range: 'bytes=0-').timeout(const Duration(seconds: 10));
    expect(back.status, HttpStatus.partialContent);
    expect(back.body, src);
  });

  test('a server that comes back slow to answer is waited for, though it was given up before', () async {
    // The failure goes on until an answer: the second wait for the length found it older than the give-up time at once.
    // It is judged by a try made after it came, which the server answers, in 1.5 s.
    up.silent = true;
    final (source, _) = serve(giveUpAfter: const Duration(milliseconds: 600), backoff: const Duration(milliseconds: 50), silence: const Duration(seconds: 2));
    await expectLater(source.length().timeout(const Duration(seconds: 10)), throwsA(isA<UpstreamUnavailable>()));
    expect(source.fetcher.failingFor, greaterThanOrEqualTo(const Duration(milliseconds: 600)));

    up.silent = false;
    up.latency = const Duration(milliseconds: 1500);
    up.dropConnections();
    expect(await source.length().timeout(const Duration(seconds: 10)), src.length);
  });

  test('a wait for the length ends when the transfer stops before it is known, and leaves nothing running', () async {
    // Paused for another download, or disposed, before the server failed even once: the wait looked for a length or a
    // failure that would never come, every 250 ms, for ever, and kept the source counted as read.
    for (final stop in ['pause', 'dispose']) {
      up.silent = true;
      final (source, url) = serve(id: 'd-$stop', silence: const Duration(seconds: 30));
      final waiting = expectLater(source.length().timeout(const Duration(seconds: 2)), throwsA(isA<TransferStopped>()), reason: stop);
      final player = fetch(HttpClient(), url, range: 'bytes=0-');
      await Future<void>.delayed(const Duration(milliseconds: 300));
      expect(source.fetcher.readerWaiting, isTrue);
      await (stop == 'pause' ? source.pause() : source.dispose());
      await waiting;
      expect((await player.timeout(const Duration(seconds: 2))).status, HttpStatus.serviceUnavailable, reason: stop);
      await Future<void>.delayed(const Duration(milliseconds: 300));
      expect(source.fetcher.readerWaiting, isFalse, reason: 'no wait left behind after $stop');
      up.silent = false;
      up.dropConnections();
    }
  });

  test('a resumed download whose server is away answers unavailable, not the length it kept', () async {
    // The length stored with the partial file is not handed to the player until the server confirms the file.
    up.rate = 4 << 20;
    up.silentNextAfter = 2 << 20; // the first transfer never finishes the file
    final (first, url) = serve();
    await fetch(player, url, range: 'bytes=0-', take: 1 << 20);
    await first.dispose();

    up.silent = true;
    final (second, again) = serve(giveUpAfter: const Duration(milliseconds: 600), backoff: const Duration(milliseconds: 50), silence: const Duration(milliseconds: 300));
    expect(second.confirmed, isFalse);
    expect(second.file.length, src.length, reason: 'the length kept from the first transfer');
    final r = await fetch(player, again, range: 'bytes=0-').timeout(const Duration(seconds: 10));
    expect(r.status, HttpStatus.serviceUnavailable);
    expect(r.headers.contentLength, 0);
    expect(r.headers.value(HttpHeaders.contentRangeHeader), isNull);
  });

  test('a file replaced on the server during playback ends the playback rather than splicing two files', () async {
    up.rate = 1 << 20;
    final (source, url) = serve();
    await fetch(player, url, range: 'bytes=0-', take: 200000);
    up.replace(randomBytes(src.length, 2), 'Wed, 23 Sep 2026 10:00:00 GMT');
    final r = await fetch(player, url, range: 'bytes=${3 << 20}-');
    expect(r.error ?? (r.status == 404 ? 'refused' : null), isNotNull, reason: 'status ${r.status}, ${r.body.length} bytes');
    await settle(source);
    expect(source.state, SourceState.gone);
    expect((await fetch(player, url, range: 'bytes=0-')).status, 404);
  });

  test('a suspended endpoint refuses connections, and serves the same URL on the same port once resumed', () async {
    up.rate = 1 << 20;
    final (_, url) = serve();
    final port = endpoint.port;
    final open = fetch(player, url, range: 'bytes=0-');
    await Future<void>.delayed(const Duration(milliseconds: 300));
    await endpoint.suspend();
    expect(endpoint.isListening, isFalse);
    final cut = await open;
    expect(cut.error ?? (cut.body.length < src.length ? 'short' : null), isNotNull, reason: 'the open response is reset');
    await expectLater(fetch(player, url, range: 'bytes=0-'), throwsA(isA<SocketException>()));

    up.rate = null;
    await endpoint.resume();
    expect(endpoint.isListening, isTrue);
    expect(endpoint.port, port);
    final back = await fetch(player, url, range: 'bytes=${cut.body.length}-');
    expect(back.error, isNull);
    expect(back.status, 206);
    expect(back.body, Uint8List.sublistView(src, cut.body.length));
    expect((await fetch(player, url.replace(pathSegments: ['wrong', ...url.pathSegments.skip(1)]))).status, 404, reason: 'the token is kept, and still required');
  });

  test('the port is bound again at once after the endpoint closed the connections itself', () async {
    final (_, url) = serve();
    for (var i = 0; i < 3; i++) {
      // The endpoint closes each response first, which leaves its side of the connection in TIME_WAIT.
      expect((await fetch(player, url, range: 'bytes=0-1023')).status, 206);
    }
    await endpoint.suspend();
    await endpoint.resume(wait: Duration.zero); // bound at the first try, or this throws
    expect((await fetch(player, url, range: 'bytes=0-1023')).body, Uint8List.sublistView(src, 0, 1024));
  });

  test('resuming on a port another socket holds gives up after the wait', () async {
    serve();
    await endpoint.suspend();
    final squatter = await ServerSocket.bind(InternetAddress.loopbackIPv4, endpoint.port);
    try {
      final clock = Stopwatch()..start();
      await expectLater(endpoint.resume(wait: const Duration(milliseconds: 600)), throwsA(isA<SocketException>()));
      expect(clock.elapsed, greaterThanOrEqualTo(const Duration(milliseconds: 600)));
      expect(endpoint.isListening, isFalse);
    } finally {
      await squatter.close();
    }
  });
}
