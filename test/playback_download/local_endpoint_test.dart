import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
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

  (PartialSource, Uri) serve({String id = 'd1'}) {
    final file = PartialFile.open(mediaDir: media.path, downloadId: id, filename: '$id.mp4', url: up.url.toString());
    final source = PartialSource(file: file, url: up.url, backoff: (_, __) => Duration.zero);
    sources.add(source);
    return (source, endpoint.register(id, '$id.mp4', source));
  }

  Future<void> settle(PartialSource s) async {
    while (s.isRunning) {
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
    expect(tail.firstByte, lessThan(const Duration(seconds: 1)), reason: 'the whole file would take 2 s');
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
    expect(after.firstByte, lessThan(const Duration(milliseconds: 800)), reason: 'waiting would take ~2.8 s at 1 MiB/s');
    expect(up.log.map((r) => r.range), contains(startsWith('bytes=$seekTo-')));
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
}
