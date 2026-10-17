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

  Fetcher fetcher(PartialFile f, {String? token, Duration backoff = Duration.zero}) {
    final fx = Fetcher(file: f, url: up.url, authorization: token, backoff: (_, __) => backoff);
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
    final servedBefore = up.bytesServed;
    final requestsBefore = up.log.length;

    final again = open();
    expect(await fetcher(again).run(0), FetchOutcome.complete);
    expect(await finish(again), src);
    expect(up.log.skip(requestsBefore).every((r) => r.ifRange == up.lastModified && r.status == 206), isTrue, reason: '${up.log}');
    expect(up.bytesServed - servedBefore, src.length - had);
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
    final servedBefore = up.bytesServed;
    final f = open();
    var answers = 0;
    final fx = fetcher(f)
      ..restartOnChange = true
      ..onAnswer = () => answers++;
    expect(await fx.run(0), FetchOutcome.complete);
    expect(await finish(f), replaced);
    expect(f.lastModified, 'Wed, 23 Sep 2026 10:00:00 GMT');
    expect(up.log.last.status, 200);
    expect(up.bytesServed - servedBefore, replaced.length, reason: 'the 200 body is the new file, taken as it is');
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
