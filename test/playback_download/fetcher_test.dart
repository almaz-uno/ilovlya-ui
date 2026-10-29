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
        backoff: (_, _) => backoff,
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

  test('what follows mdat is let finish only when it is the index', () async {
    const tail = 3 << 20;
    src = m4aWithTrailingMoov(mdat: 4 << 20, moov: tail, tail: 'skip');
    up.data = src;
    up.rate = 2 << 20;
    final at = src.length - tail;
    final f = open();
    final fx = fetcher(f);
    final run = fx.run(0);
    while (fx.position <= at + (64 << 10)) {
      await Future.delayed(const Duration(milliseconds: 5));
    }
    fx.retarget(1 << 20);
    expect(await run, FetchOutcome.complete);
    expect(await finish(f), src);
    expect(up.log[1].range, 'bytes=$at-${src.length - 1}');
    expect(up.log[1].bytes, lessThan(tail), reason: 'a skip box is no index: ${up.log}');
    expect(up.log[2].range, startsWith('bytes=${1 << 20}-'));
  });

  test('a resume in the middle of the index keeps it pinned', () async {
    const moov = 3 << 20;
    src = m4aWithTrailingMoov(mdat: 4 << 20, moov: moov);
    up.data = src;
    up.rate = 1 << 20;
    final at = src.length - moov;
    final f = open();
    final fx = fetcher(f);
    final run = fx.run(0);
    while (fx.position <= at + (256 << 10)) {
      await Future.delayed(const Duration(milliseconds: 5));
    }
    fx.suspend();
    fx.resume(); // iOS took the socket: the request goes on from where it was, from the middle of the index
    while (up.log.length < 3 || fx.position <= at + (384 << 10)) {
      await Future.delayed(const Duration(milliseconds: 5));
    }
    fx.retarget(1 << 20);
    expect(await run, FetchOutcome.complete);
    expect(await finish(f), src);
    expect(up.log[2].range, endsWith('-${src.length - 1}'), reason: '${up.log}');
    expect(up.log[2].range, isNot('bytes=$at-${src.length - 1}'));
    expect(at + moov - int.parse(RegExp(r'bytes=(\d+)-').firstMatch(up.log[2].range!)![1]!), up.log[2].bytes,
        reason: 'the rest of the index is not cut: ${up.log}');
    expect(up.log[3].range, startsWith('bytes=${1 << 20}-'));
  });

  test('one slow answer does not make a retarget wait for many seconds of the rest', () async {
    src = randomBytes(16 << 20);
    up.data = src;
    up.rate = 1 << 20;
    up.latency = const Duration(seconds: 5); // a stall on the first answer
    final f = open();
    final fx = fetcher(f);
    final from = src.length - (8 << 20);
    final run = fx.run(from);
    while (up.log.isEmpty || up.log.first.status == null) {
      await Future.delayed(const Duration(milliseconds: 10));
    }
    up.latency = Duration.zero;
    while (fx.rate == 0 || fx.position < from + (1200 << 10)) {
      await Future.delayed(const Duration(milliseconds: 10));
    }
    // About 6.8 s of the rest are left: more than the answer time counts for.
    final clock = Stopwatch()..start();
    fx.retarget(1 << 20);
    while (up.log.length < 2) {
      await Future.delayed(const Duration(milliseconds: 5));
    }
    expect(up.log.first.bytes, lessThan(8 << 20), reason: 'cut, not let finish: ${up.log}');
    expect(clock.elapsed, lessThan(const Duration(seconds: 3)), reason: 'a safety net; the rest takes 6.8 s: ${up.log}');
    fx.stop();
    await run;
  });

  test('what follows mdat is let finish only when it is the index, though its first bytes came apart', () async {
    const tail = 3 << 20;
    src = m4aWithTrailingMoov(mdat: 4 << 20, moov: tail, tail: 'skip');
    up.data = src;
    up.rate = 2 << 20;
    final at = src.length - tail;
    final f = open();
    // An earlier run stored 4 bytes of the box header: the request for the tail begins after them.
    f.setLength(src.length, up.lastModified);
    await f.write(at, src.sublist(at, at + 4));
    final fx = fetcher(f);
    final run = fx.run(0);
    while (fx.position <= at + (64 << 10)) {
      await Future.delayed(const Duration(milliseconds: 5));
    }
    fx.retarget(1 << 20);
    expect(await run, FetchOutcome.complete);
    expect(await finish(f), src);
    expect(up.log[1].range, 'bytes=${at + 4}-${src.length - 1}', reason: '${up.log}');
    expect(up.log[1].bytes, lessThan(tail - 4), reason: 'a skip box is no index: ${up.log}');
    expect(up.log[2].range, startsWith('bytes=${1 << 20}-'));
  });

  test('one stalled answer leaves the usual answer time within a few answers', () async {
    src = randomBytes(24 << 20);
    up.data = src;
    up.rate = 1 << 20;
    up.latency = const Duration(seconds: 6); // a stall, or an iOS suspend while the answer was awaited
    final f = open();
    final fx = fetcher(f);
    final run = fx.run(0);
    while (up.log.isEmpty || up.log.first.status == null) {
      await Future.delayed(const Duration(milliseconds: 10));
    }
    up.latency = Duration.zero;
    // Two quick answers: the usual answer time is 6 s × 0.7² ≈ 2.9 s if the stall counts in full, 3 s × 0.7² ≈ 1.5 s
    // if it counts for the most one answer does.
    fx.retarget(8 << 20);
    while (up.log.length < 2 || up.log.last.status == null) {
      await Future.delayed(const Duration(milliseconds: 5));
    }
    fx.retarget(src.length - (4 << 20));
    while (up.log.length < 3 || fx.rate == 0 || src.length - fx.position > (2200 << 10)) {
      await Future.delayed(const Duration(milliseconds: 5));
    }
    expect(src.length - fx.position, greaterThan(2000 << 10), reason: 'the rest is not yet within 2 s');
    // About 2.1 s of the rest are left: more than 1.5 s, less than 2.9 s.
    final clock = Stopwatch()..start();
    fx.retarget(1 << 20);
    while (up.log.length < 4) {
      await Future.delayed(const Duration(milliseconds: 5));
    }
    expect(up.log[2].bytes, lessThan(4 << 20), reason: 'cut, not let finish: ${up.log}');
    expect(clock.elapsed, lessThan(const Duration(seconds: 5)), reason: 'a safety net: ${up.log}');
    fx.stop();
    await run;
  });

  test('a retarget that waits for a closing request moves the transfer once that request falls silent', () async {
    up.rate = 256 << 10;
    final f = open();
    final fx = fetcher(f);
    final from = src.length - (256 << 10);
    up.silentNextAfter = 64 << 10;
    final run = fx.run(from);
    while (fx.position < from + (16 << 10)) {
      await Future.delayed(const Duration(milliseconds: 5));
    }
    // Asked once, as the endpoint does, while the request still brings bytes: it waits.
    fx.retarget(1 << 20);
    final clock = Stopwatch()..start();
    while (up.log.length < 2) {
      await Future.delayed(const Duration(milliseconds: 5));
    }
    expect(up.log.first.silenced, isTrue, reason: '${up.log}');
    expect(clock.elapsed, lessThan(Fetcher.liveWithin + const Duration(seconds: 1)), reason: 'not the 15 s silence timeout');
    expect(up.log[1].range, startsWith('bytes=${1 << 20}-'));
    fx.stop();
    await run;
  });

  test('a retarget while a request waits for its answer is judged by that request, not by where the last one ended', () async {
    final f = open();
    final from = src.length - (256 << 10);
    final fx = fetcher(f);
    up.rate = 1 << 20; // the gap behind takes almost 4 s
    up.latency = const Duration(milliseconds: 400);
    final run = fx.run(from);
    // The tail is done; the gap behind, [0, from), is asked for next and not answered yet.
    while (up.log.length < 2) {
      await Future.delayed(const Duration(milliseconds: 5));
    }
    await Future.delayed(const Duration(milliseconds: 100));
    final clock = Stopwatch()..start();
    fx.retarget(2 << 20);
    while (up.log.length < 3) {
      await Future.delayed(const Duration(milliseconds: 5));
    }
    expect(clock.elapsed, lessThan(const Duration(seconds: 3)), reason: 'a safety net; the whole gap takes ~4 s: ${up.log}');
    expect(up.log[1].range, 'bytes=0-${from - 1}');
    // Let have its answer — cutting it would bring nothing sooner — and cut one answer time later.
    expect(up.log[1].status, 206, reason: '${up.log}');
    expect(up.log[1].bytes, lessThan(1 << 20), reason: 'cut, not let finish: ${up.log}');
    expect(up.log[2].range, startsWith('bytes=${2 << 20}-'));
    fx.stop();
    await run;
  });

  test('a closing request is waited for only while its rest arrives within the closing time', () async {
    up.rate = 128 << 10;
    final f = open();
    final fx = fetcher(f);
    final from = src.length - (1536 << 10);
    final run = fx.run(from);
    while (fx.rate == 0 || fx.position < from + (192 << 10)) {
      await Future.delayed(const Duration(milliseconds: 10));
    }
    // More than a second of the rest at this rate is left: the retarget does not wait for it.
    final clock = Stopwatch()..start();
    fx.retarget(1 << 20);
    while (up.log.length < 2) {
      await Future.delayed(const Duration(milliseconds: 5));
    }
    expect(up.log.first.bytes, lessThan(1536 << 10), reason: 'cut, not let finish: ${up.log}');
    expect(clock.elapsed, lessThan(const Duration(seconds: 3)), reason: 'a safety net; the rest takes ~10 s');
    fx.stop();
    await run;
  });

  test('seeks over a link with a long round trip are no sign of a server that does not answer', () async {
    src = randomBytes(16 << 20);
    up.data = src;
    up.rate = 96 << 10; // above the least progress, but a third of every cycle goes to the reconnect
    up.latency = const Duration(milliseconds: 300);
    final fx = fetcher(open(), silence: const Duration(seconds: 1), minProgress: 64 << 10);
    final run = fx.run(1 << 20);
    final clock = Stopwatch()..start();
    var far = false;
    while (clock.elapsed < const Duration(seconds: 4)) {
      fx.retarget((far = !far) ? 8 << 20 : 1 << 20);
      for (var i = 0; i < 20; i++) {
        expect(fx.notAnsweringFor, isNull, reason: 'at ${clock.elapsed}: ${up.log}');
        await Future.delayed(const Duration(milliseconds: 20));
      }
    }
    // A retarget waits for the answer of the request in flight and for one answer time of its body, so the seeks are
    // fewer requests than retargets; the transfer went both ways all the same.
    final starts = up.log.skip(1).map((r) => int.parse(RegExp(r'bytes=(\d+)-').firstMatch(r.range!)![1]!)).toList();
    expect(starts, containsAll([greaterThanOrEqualTo(8 << 20), lessThan(8 << 20)]), reason: '${up.log}');
    fx.stop();
    expect(await run, FetchOutcome.stopped);
  });

  test('a server that answers every request and sends nothing is not answering, however often the player seeks', () async {
    src = randomBytes(16 << 20);
    up.data = src;
    up.silentEveryAfter = 0; // a stalled proxy: the head, then silence
    up.latency = const Duration(milliseconds: 50);
    final fx = fetcher(open(), silence: const Duration(seconds: 1), minProgress: 64 << 10);
    final run = fx.run(1 << 20);
    final clock = Stopwatch()..start();
    var far = false;
    while (fx.notAnsweringFor == null && clock.elapsed < const Duration(seconds: 4)) {
      fx.retarget((far = !far) ? 8 << 20 : 1 << 20);
      await Future.delayed(const Duration(milliseconds: 300));
    }
    expect(fx.notAnsweringFor, isNotNull, reason: 'after ${clock.elapsed}: ${up.log}');
    expect(fx.failingFor, isNull, reason: 'no request lived long enough to fail');
    fx.stop();
    await run;
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
