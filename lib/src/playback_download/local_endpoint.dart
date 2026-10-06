import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import '../utils/logger_provider.dart';

/// The source is gone — discarded, the file changed on the server, the media cleaned. Its responses are closed and new
/// requests are answered `404`.
class SourceGone implements Exception {
  final String reason;

  const SourceGone(this.reason);

  @override
  String toString() => 'SourceGone($reason)';
}

/// What the endpoint serves under one identifier.
abstract interface class EndpointSource {
  String get contentType;

  bool get isGone;

  /// The file's length, waiting for the server's first answer if it is not known yet. Throws [SourceGone].
  Future<int> length();

  /// How many bytes are readable at [offset] right now, waiting for them if there are none. [isCancelled] is consulted
  /// while waiting, so that a reader the player has abandoned stops steering the transfer. Throws [SourceGone], or
  /// [PassThroughRequested] when the bytes will not be stored and have to come from the server directly.
  Future<int> available(int offset, bool Function() isCancelled);

  Future<List<int>> read(int offset, int count);

  /// `[start, end)` piped from the server, for a source that can no longer store what it receives.
  Stream<List<int>> upstream(int start, int end);
}

/// The source can no longer store bytes; the rest of the response comes from [EndpointSource.upstream].
class PassThroughRequested implements Exception {
  const PassThroughRequested();
}

/// An HTTP endpoint on the loopback interface from which the player reads a download while it arrives.
///
/// Bound to `127.0.0.1` on a port the system chooses. Every path is `/<token>/<id>/<name>`, the token being 128 random
/// bits generated per process: any process on the device can reach a loopback port, so a request without the token
/// is answered `404`, as is one for an identifier nobody registered. The endpoint never fetches a URL it is given — it
/// serves registered sources only, and is not a relay.
///
/// `GET` and `HEAD`, one range per request, which is all libmpv asks for: `206` with `Content-Range`, `200` without a
/// `Range` header, `416` past the end. The request is parsed by [HttpServer]; for a body the socket is then taken over,
/// so that a response that cannot be completed is reset rather than left hanging — libmpv reconnects with `Range`
/// either way, and a reset is the honest answer.
class LocalMediaEndpoint {
  final HttpServer _server;
  final String _token;
  final Map<String, EndpointSource> _sources = {};
  final Map<String, Set<Socket>> _bodies = {};

  LocalMediaEndpoint._(this._server, this._token) {
    _server.autoCompress = false;
    _server.listen(_handle);
  }

  static Future<LocalMediaEndpoint> start() async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final rnd = Random.secure();
    final token = base64Url.encode(List.generate(16, (_) => rnd.nextInt(256))).replaceAll('=', '');
    AppLoggers.download.i('Local media endpoint listening on 127.0.0.1:${server.port}');
    return LocalMediaEndpoint._(server, token);
  }

  int get port => _server.port;

  /// Serves [source] under [id] and returns the URL the player opens. [name] is there only so that the player and the
  /// media session see a sensible file name and extension.
  Uri register(String id, String name, EndpointSource source) {
    _sources[id] = source;
    return Uri(scheme: 'http', host: '127.0.0.1', port: port, pathSegments: [_token, id, name]);
  }

  /// Stops serving [id]: open responses are reset, later requests answered `404`.
  void unregister(String id) {
    _sources.remove(id);
    for (final s in _bodies.remove(id) ?? const <Socket>{}) {
      s.destroy();
    }
  }

  Future<void> close() async {
    for (final id in _sources.keys.toList()) {
      unregister(id);
    }
    await _server.close(force: true);
  }

  Future<void> _handle(HttpRequest req) async {
    final res = req.response;
    final seg = req.uri.pathSegments;
    final source = (req.method == 'GET' || req.method == 'HEAD') && seg.length >= 2 && seg[0] == _token ? _sources[seg[1]] : null;
    if (source == null || source.isGone) return _status(res, HttpStatus.notFound);
    final id = seg[1];

    final int length;
    try {
      length = await source.length();
    } on Object catch (e) {
      AppLoggers.download.w('Local endpoint: no length for $id', error: e);
      return _status(res, HttpStatus.notFound);
    }

    final range = _Range.parse(req.headers.value(HttpHeaders.rangeHeader), length);
    if (range == _Range.unsatisfiable) {
      res.headers.set(HttpHeaders.contentRangeHeader, 'bytes */$length');
      return _status(res, HttpStatus.requestedRangeNotSatisfiable);
    }
    final start = range?.start ?? 0;
    final end = range?.end ?? length; // exclusive

    res.statusCode = range == null ? HttpStatus.ok : HttpStatus.partialContent;
    res.headers.contentType = ContentType.parse(source.contentType);
    res.headers.set(HttpHeaders.acceptRangesHeader, 'bytes');
    if (range != null) res.headers.set(HttpHeaders.contentRangeHeader, 'bytes $start-${end - 1}/$length');
    res.headers.persistentConnection = false;
    res.contentLength = end - start;
    if (req.method == 'HEAD' || start == end) {
      await res.close();
      return;
    }

    final Socket socket;
    try {
      socket = await res.detachSocket(writeHeaders: true);
    } on Object {
      return; // the player went away before the headers
    }
    final open = _bodies.putIfAbsent(id, () => {})..add(socket);
    var cancelled = false;
    unawaited(socket.done.then((_) {}, onError: (_) {}).whenComplete(() => cancelled = true));
    var pos = start;
    try {
      while (pos < end && !cancelled) {
        int n;
        try {
          n = await source.available(pos, () => cancelled);
        } on PassThroughRequested {
          await socket.addStream(source.upstream(pos, end));
          pos = end;
          break;
        }
        if (cancelled) break;
        final chunk = await source.read(pos, min(n, min(65536, end - pos)));
        if (chunk.isEmpty) continue;
        socket.add(chunk);
        pos += chunk.length;
        await socket.flush();
      }
      if (pos >= end) {
        await socket.flush();
        await socket.close();
      } else {
        socket.destroy();
      }
    } on Object catch (e) {
      if (!cancelled) AppLoggers.download.w('Local endpoint: response for $id reset at $pos', error: e);
      socket.destroy();
    } finally {
      open.remove(socket);
    }
  }

  Future<void> _status(HttpResponse res, int status) async {
    res.statusCode = status;
    res.contentLength = 0;
    res.headers.persistentConnection = false;
    try {
      await res.close();
    } on Object {
      // The player went away; nothing to tell it.
    }
  }
}

class _Range {
  final int start;
  final int end; // exclusive

  const _Range(this.start, this.end);

  static const unsatisfiable = _Range(-1, -1);

  /// One `bytes=` range. `null` — serve the whole file — for no header, a malformed one or several ranges, as a
  /// server is allowed to ignore what it does not understand.
  static _Range? parse(String? header, int length) {
    if (header == null) return null;
    final m = RegExp(r'^bytes=(\d*)-(\d*)$').firstMatch(header.trim());
    if (m == null || (m[1]!.isEmpty && m[2]!.isEmpty)) return null;
    if (m[1]!.isEmpty) {
      final suffix = int.parse(m[2]!);
      if (suffix == 0) return unsatisfiable;
      return _Range(max(0, length - suffix), length);
    }
    final start = int.parse(m[1]!);
    if (start >= length) return unsatisfiable;
    final last = m[2]!.isEmpty ? length - 1 : min(int.parse(m[2]!), length - 1);
    if (last < start) return null;
    return _Range(start, last + 1);
  }
}
