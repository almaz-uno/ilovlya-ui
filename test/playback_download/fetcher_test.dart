import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:ilovlya/src/playback_download/fetcher.dart';
import 'package:ilovlya/src/playback_download/partial_file.dart';
import 'package:path/path.dart' as p;

import 'upstream.dart';

void main() {
  late Directory media;
  late Upstream up;
  late Uint8List src;
  final fetchers = <Fetcher>[];

  setUp(() async {
    media = Directory.systemTemp.createTempSync('fetcher_test');
    src = randomBytes(4 << 20);
    up = await Upstream.start(src);
  });
  tearDown(() async {
    for (final f in fetchers) {
      f.stop();
      f.close();
    }
    fetchers.clear();
    await up.close();
    media.deleteSync(recursive: true);
  });

  PartialFile open([String id = 'd1']) => PartialFile.open(mediaDir: media.path, downloadId: id, filename: '$id.mp4', url: up.url.toString());

  Fetcher fetcher(PartialFile f,
      {String? token,
      Duration backoff = Duration.zero,
      Duration silence = Fetcher.defaultSilenceTimeout,
      Duration flowing = Fetcher.defaultFlowingWithin,
      Duration recovered = Fetcher.defaultRecoveredAfter,
      int minProgress = Fetcher.defaultMinProgress}) {
    final fx = Fetcher(
        file: f,
        url: up.url,
        authorization: token,
        backoff: (_, __) => backoff,
        silenceTimeout: silence,
        flowingWithin: flowing,
        recoveredAfter: recovered,
        minProgress: minProgress);
    fetchers.add(fx);
    return fx;
  }

  Future<Uint8List> finish(PartialFile f) async => File(await f.complete()).readAsBytesSync();

  /// Runs until [f] holds at least [bytes], then stops the run and closes the file, as leaving the player would.
  Future<void> interruptAfter(PartialFile f, int bytes) async {
    up.rate = 2 << 20;
    final fx = fetcher(f);
    final run = fx.run(0);
    while (f.ranges.stored < bytes) {
      await Future.delayed(const Duration(milliseconds: 5));
    }
    fx.stop();
    expect(await run, FetchOutcome.stopped);
    await f.close();
    up.rate = null;
  }

  test('a fresh download from byte 0 is one request and exactly the file', () async {
    final f = open();
    expect(await fetcher(f, token: 't0k').run(0), FetchOutcome.complete);
    expect(await finish(f), src);
    expect(up.log.length, 1);
    expect(up.log.single.range, 'bytes=0-');
    expect(up.log.single.authorization, 't0k', reason: 'the header value as getAuthHeader sends it');
    expect(up.bytesServed, src.length);
  });

  test('a download started at a saved position goes to the end, then fills what it skipped', () async {
    final f = open();
    final from = src.length ~/ 2 + 12345;
    expect(await fetcher(f).run(from), FetchOutcome.complete);
    expect(await finish(f), src);
    expect(up.log.map((r) => r.range), ['bytes=$from-', 'bytes=0-${from - 1}']);
    expect(up.log[1].ifRange, up.lastModified, reason: 'every request after the first guards against a changed file');
    expect(up.bytesServed, src.length);
  });

  test('a retarget mid-transfer fetches no byte twice beyond what was in flight', () async {
    up.rate = 2 << 20;
    final f = open();
    final fx = fetcher(f);
    final run = fx.run(0);
    while (fx.position < 512 * 1024) {
      await Future.delayed(const Duration(milliseconds: 10));
    }
    fx.retarget(3 << 20);
    expect(await run, FetchOutcome.complete);
    expect(await finish(f), src);
    expect(up.log.first.range, 'bytes=0-');
    expect(up.log[1].range, 'bytes=${3 << 20}-${src.length - 1}');
    expect(up.log.length, 3, reason: 'then the gap left behind: ${up.log}');
    expect(up.bytesServed - src.length, lessThan(256 * 1024), reason: 'served ${up.bytesServed} for ${src.length}');
    expect(fx.rate, greaterThan(0));
  });

  test('a resumed download asks only for what is missing, guarded by If-Range', () async {
    await interruptAfter(open(), 1 << 20);
    final had = open().ranges.stored;
    expect(had, greaterThanOrEqualTo(1 << 20));
    final requestsBefore = up.log.length;

    final again = open();
    expect(await fetcher(again).run(0), FetchOutcome.complete);
    expect(await finish(again), src);
    expect(up.log.skip(requestsBefore).every((r) => r.ifRange == up.lastModified && r.status == 206), isTrue, reason: '${up.log}');
    // The aborted response can still account for an in-flight chunk after the
    // client stopped. Count only the resume requests, not that old response.
    final resumedBytes = up.log.skip(requestsBefore).fold<int>(0, (bytes, request) => bytes + request.bytes);
    expect(resumedBytes, src.length - had);
  });

  test('a file replaced on the server is detected on resume, and its body is not drained', () async {
    await interruptAfter(open(), 1 << 20);
    up.replace(randomBytes(src.length, 2), 'Wed, 23 Sep 2026 10:00:00 GMT');
    up.rate = 1 << 20;
    expect(await fetcher(open()).run(0), FetchOutcome.fileChanged);
    expect(up.log.last.status, 200, reason: 'If-Range no longer matched, so the server sent the whole file');
    expect(up.log.last.bytes, lessThan(256 * 1024), reason: 'the whole new file is not read only to be thrown away');
  });

  test('a file replaced on the server before anything was served is started over from the answer that showed it', () async {
    await interruptAfter(open(), 1 << 20);
    final replaced = randomBytes(src.length + 4096, 2);
    up.replace(replaced, 'Wed, 23 Sep 2026 10:00:00 GMT');
    final requestsBefore = up.log.length;
    final f = open();
    var answers = 0;
    final fx = fetcher(f)
      ..restartOnChange = true
      ..onAnswer = () => answers++;
    expect(await fx.run(0), FetchOutcome.complete);
    expect(await finish(f), replaced);
    expect(f.lastModified, 'Wed, 23 Sep 2026 10:00:00 GMT');
    expect(up.log.last.status, 200);
    // Exclude bytes the interrupted response accounts for after it was aborted.
    final replacementBytes = up.log.skip(requestsBefore).fold<int>(0, (bytes, request) => bytes + request.bytes);
    expect(replacementBytes, replaced.length, reason: 'the 200 body is the new file, taken as it is');
    expect(answers, greaterThan(0));
  });

  test('failingFor runs from the first failure of a streak and clears with an answer', () async {
    up.failNext.addAll([503, 503]);
    final fx = fetcher(open(), backoff: const Duration(milliseconds: 100));
    final run = fx.run(0);
    await Future.delayed(const Duration(milliseconds: 150));
    expect(fx.failingFor, isNotNull);
    expect(await run, FetchOutcome.complete);
    expect(fx.failingFor, isNull);
  });

  test('a connection cut short is resumed at the byte it reached', () async {
    up.cutNextAfter = 300000;
    final f = open();
    expect(await fetcher(f).run(0), FetchOutcome.complete);
    expect(await finish(f), src);
    expect(up.log.length, 2);
    expect(up.bytesServed - src.length, lessThan(64 * 1024), reason: 'what was in flight at the cut, at most');
  });

  test('a request the server never answers fails after the silence, and the next one completes the file', () async {
    const silence = Duration(milliseconds: 300);
    up.silent = true;
    final f = open();
    final clock = Stopwatch()..start();
    final run = fetcher(f, silence: silence).run(0);
    while (up.log.isEmpty) {
      await Future.delayed(const Duration(milliseconds: 5));
    }
    up.silent = false;
    expect(await run, FetchOutcome.complete);
    expect(clock.elapsed, greaterThanOrEqualTo(silence));
    expect(await finish(f), src);
    expect(up.log.length, 2, reason: '${up.log}');
    expect(up.log.first.silenced, isTrue);
  });

  test('a body that falls silent is resumed at the byte it reached', () async {
    up.silentNextAfter = 300000;
    final f = open();
    expect(await fetcher(f, silence: const Duration(milliseconds: 300)).run(0), FetchOutcome.complete);
    expect(await finish(f), src);
    expect(up.log.length, 2, reason: '${up.log}');
    expect(up.log.first.silenced, isTrue);
    expect(up.log[1].range, 'bytes=${up.log.first.bytes}-${src.length - 1}');
    expect(up.bytesServed, src.length, reason: 'every byte sent before the silence was kept');
  });

  test('a silent failure counts from the moment the request fell silent', () async {
    // So that the endpoint gives a read up the same time after its bytes stopped, however long the silence timeout.
    const silence = Duration(milliseconds: 400);
    up.silent = true;
    final fx = fetcher(open(), silence: silence, backoff: const Duration(hours: 1));
    final run = fx.run(0);
    while (fx.failingFor == null) {
      await Future.delayed(const Duration(milliseconds: 5));
    }
    expect(fx.failingFor, greaterThanOrEqualTo(silence));
    fx.stop();
    expect(await run, FetchOutcome.stopped);
  });

  test('while no byte arrives the rate decays and the transfer is not flowing', () async {
    up.rate = 1 << 20;
    up.silentNextAfter = 2 << 20;
    final fx = fetcher(open(), silence: const Duration(seconds: 30));
    final run = fx.run(0);
    while (!(up.log.isNotEmpty && up.log.first.silenced)) {
      await Future.delayed(const Duration(milliseconds: 10));
    }
    final measured = fx.rate;
    expect(measured, greaterThan(0));
    expect(fx.flowing, isTrue);
    await Future.delayed(const Duration(milliseconds: 2300));
    expect(fx.flowing, isFalse);
    expect(fx.rate, lessThanOrEqualTo(measured * 0.49 + 1), reason: 'two empty one-second windows: (1 - 0.3)²');
    fx.stop();
    expect(await run, FetchOutcome.stopped);
  });

  test('a server that answers every retry with a portion and falls silent stays not answering until bytes flow again', () async {
    // What a stalled proxy does: each retry gets its portion at once, which clears failingFor, and then nothing.
    up.silentEveryAfter = 64 << 10;
    final fx = fetcher(open(),
        silence: const Duration(milliseconds: 300), flowing: const Duration(milliseconds: 100), recovered: const Duration(seconds: 1));
    final run = fx.run(0);
    while (fx.notAnsweringFor == null) {
      await Future.delayed(const Duration(milliseconds: 5));
    }
    expect(fx.notAnsweringFor, greaterThanOrEqualTo(const Duration(milliseconds: 300)), reason: 'dated from when the bytes stopped');
    final since = DateTime.now().subtract(fx.notAnsweringFor!);
    var answered = false;
    final clock = Stopwatch()..start();
    while (clock.elapsed < const Duration(seconds: 2)) {
      final d = fx.notAnsweringFor;
      expect(d, isNotNull, reason: 'a portion does not end it');
      expect(DateTime.now().subtract(d!).difference(since).inMilliseconds.abs(), lessThan(50), reason: 'nor restarts it');
      answered |= fx.failingFor == null;
      await Future.delayed(const Duration(milliseconds: 10));
    }
    expect(answered, isTrue, reason: 'the retries were answered: failingFor alone would have cleared');
    expect(up.log.length, greaterThanOrEqualTo(4), reason: '${up.log}');

    // The server is back: the held request times out, the next one flows, and after a second of it the server answers.
    up.silentEveryAfter = null;
    up.rate = 1 << 20;
    while (fx.notAnsweringFor != null) {
      await Future.delayed(const Duration(milliseconds: 10));
    }
    expect(fx.flowing, isTrue);
    fx.stop();
    expect(await run, FetchOutcome.stopped);
  });

  test('a slow but steady transfer is not taken for a server that does not answer', () async {
    up.rate = 64 << 10; // a 16 KiB chunk every 250 ms
    final fx = fetcher(open(), silence: const Duration(seconds: 1), minProgress: 16 << 10);
    final run = fx.run(0);
    final clock = Stopwatch()..start();
    while (clock.elapsed < const Duration(seconds: 3)) {
      expect(fx.notAnsweringFor, isNull, reason: 'at ${clock.elapsed}');
      await Future.delayed(const Duration(milliseconds: 20));
    }
    expect(fx.failingFor, isNull);
    fx.stop();
    expect(await run, FetchOutcome.stopped);
  });

  test('a transfer that brings less than the least progress counts as not answering, though no request fails', () async {
    up.rate = 32 << 10;
    final fx = fetcher(open(), silence: const Duration(seconds: 1), minProgress: 64 << 10);
    final run = fx.run(0);
    final clock = Stopwatch()..start();
    while (fx.notAnsweringFor == null && clock.elapsed < const Duration(seconds: 3)) {
      await Future.delayed(const Duration(milliseconds: 20));
    }
    expect(fx.notAnsweringFor, isNotNull);
    expect(clock.elapsed, greaterThanOrEqualTo(const Duration(seconds: 1)), reason: 'a whole window is judged');
    expect(fx.failingFor, isNull);
    fx.stop();
    expect(await run, FetchOutcome.stopped);
  });

  test('a retarget waits for a request about to close its gap, then moves', () async {
    up.rate = 1 << 20;
    final f = open();
    final fx = fetcher(f);
    final from = src.length - (512 << 10);
    final run = fx.run(from);
    while (fx.position < from + (64 << 10)) {
      await Future.delayed(const Duration(milliseconds: 5));
    }
    fx.retarget(1 << 20);
    expect(await run, FetchOutcome.complete);
    expect(await finish(f), src);
    expect(up.log.first.bytes, 512 << 10, reason: 'the closing request is not cut: ${up.log}');
    expect(up.log[1].range, 'bytes=${1 << 20}-${from - 1}', reason: 'then where the reader asked');
    expect(up.bytesServed, src.length);
  });

  test('an m4a whose moov follows mdat has its end fetched right after its first bytes', () async {
    src = m4aWithTrailingMoov(mdat: 4 << 20, moov: 240962);
    up.data = src;
    up.rate = 4 << 20;
    final moovAt = src.length - 240962;
    final f = open();
    expect(await fetcher(f).run(0), FetchOutcome.complete);
    expect(await finish(f), src);
    expect(up.log.length, 3, reason: '${up.log}');
    expect(up.log[0].range, 'bytes=0-');
    expect(up.log[1].range, 'bytes=$moovAt-${src.length - 1}');
    expect(up.log[1].bytes, 240962);
    expect(up.log[2].range, endsWith('-${moovAt - 1}'));
    expect(up.bytesServed - src.length, lessThan(256 << 10), reason: 'served ${up.bytesServed} for ${src.length}');
  });

  test('a retarget while the index at the end is fetched waits for it, whatever its size', () async {
    const moov = 3 << 20; // more than a closing gap
    src = m4aWithTrailingMoov(mdat: 4 << 20, moov: moov);
    up.data = src;
    up.rate = 2 << 20;
    final moovAt = src.length - moov;
    final f = open();
    final fx = fetcher(f);
    final run = fx.run(0);
    while (fx.position <= moovAt + (64 << 10)) {
      await Future.delayed(const Duration(milliseconds: 5));
    }
    fx.retarget(1 << 20);
    expect(await run, FetchOutcome.complete);
    expect(await finish(f), src);
    expect(up.log[1].range, 'bytes=$moovAt-${src.length - 1}');
    expect(up.log[1].bytes, moov, reason: '${up.log}');
    expect(up.log[2].range, startsWith('bytes=${1 << 20}-'));
  });

  test('a closing request that has fallen silent is not waited for', () async {
    final f = open();
    final fx = fetcher(f);
    final from = src.length - (512 << 10);
    up.silentNextAfter = 64 << 10;
    final run = fx.run(from);
    while (up.log.isEmpty || !up.log.first.silenced) {
      await Future.delayed(const Duration(milliseconds: 5));
    }
    await Future.delayed(Fetcher.closingTime);
    final clock = Stopwatch()..start();
    fx.retarget(1 << 20);
    while (up.log.length < 2) {
      await Future.delayed(const Duration(milliseconds: 5));
    }
    expect(clock.elapsed, lessThan(const Duration(seconds: 1)), reason: 'not the silence timeout: ${up.log}');
    expect(up.log[1].range, startsWith('bytes=${1 << 20}-'));
    fx.stop();
    await run;
  });

  test('requests the transfer aborts itself are no sign of a server that does not answer', () async {
    src = randomBytes(16 << 20);
    up.data = src;
    up.rate = 32 << 10; // half the least progress per second
    up.latency = const Duration(milliseconds: 50);
    final fx = fetcher(open(), silence: const Duration(seconds: 1), minProgress: 64 << 10);
    final run = fx.run(1 << 20);
    final clock = Stopwatch()..start();
    var far = false;
    while (clock.elapsed < const Duration(seconds: 3)) {
      fx.retarget((far = !far) ? 8 << 20 : 1 << 20);
      for (var i = 0; i < 15; i++) {
        expect(fx.notAnsweringFor, isNull, reason: 'at ${clock.elapsed}');
        await Future.delayed(const Duration(milliseconds: 20));
      }
    }
    expect(up.log.length, greaterThan(5), reason: 'every retarget is a new request: ${up.log}');
    fx.stop();
    expect(await run, FetchOutcome.stopped);
  });

  test('failures are retried while a player is attached', () async {
    up.failNext.addAll([503, 502, 503]);
    final f = open();
    expect(await fetcher(f).run(0), FetchOutcome.complete);
    expect(up.log.map((r) => r.status), [503, 502, 503, 206]);
  });

  test('eight failures in a row end a run no player is attached to', () async {
    up.down = true;
    final fx = fetcher(open())..playerAttached = false;
    expect(await fx.run(0), FetchOutcome.failed);
    expect(up.log.length, Fetcher.maxFailuresUnattended);
  });

  test('an answer without a length cannot be kept', () async {
    up.noLength = true;
    expect(await fetcher(open()).run(0), FetchOutcome.noLength);
  });

  test('a record that cannot be written ends the run as a write failure, not as a network one', () async {
    // The open data file keeps taking bytes; only the record, written anew at each checkpoint, needs the directory.
    // Enough data for a checkpoint by size, arriving slowly enough to take the directory away before it.
    up.replace(randomBytes(PartialFile.checkpointBytes + (1 << 20), 3), 'Thu, 24 Sep 2026 10:00:00 GMT');
    up.rate = 16 << 20;
    final f = open();
    final run = fetcher(f).run(0);
    while (f.ranges.stored == 0) {
      await Future.delayed(const Duration(milliseconds: 5));
    }
    final dir = p.dirname(f.statePath);
    await Process.run('chmod', ['a-w', dir]);
    try {
      expect(await run, FetchOutcome.writeFailed);
      expect(up.log.length, 1, reason: 'not retried: ${up.log}');
    } finally {
      await Process.run('chmod', ['u+w', dir]);
    }
  });

  test('stop ends a run that is waiting out a backoff', () async {
    up.down = true;
    final fx = fetcher(open(), backoff: const Duration(hours: 1));
    final run = fx.run(0);
    await Future.delayed(const Duration(milliseconds: 100));
    fx.stop();
    expect(await run, FetchOutcome.stopped);
  });

  test('backoff is one second while a reader waits, otherwise doubles to thirty', () {
    expect(Fetcher.defaultBackoff(5, true), const Duration(seconds: 1));
    expect([for (var n = 1; n <= 8; n++) Fetcher.defaultBackoff(n, false).inSeconds], [1, 2, 4, 8, 16, 30, 30, 30]);
  });
}
