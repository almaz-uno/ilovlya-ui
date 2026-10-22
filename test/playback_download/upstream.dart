import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

/// A stand-in for the server's content endpoint, answering the way `http.ServeContent` does: one `Range` per request
/// with `206` and `Content-Range`, `Content-Length`, `Last-Modified`, and `If-Range` against `Last-Modified` — the
/// whole file with `200` when it no longer matches.
///
/// Built on a raw [ServerSocket] rather than [HttpServer], because the tests need to misbehave mid-body — cut a
/// connection, fall silent — in ways the HTTP server does not allow once a body has started. One request per
/// connection, `Connection: close`.
class Upstream {
  final ServerSocket _server;
  final Set<Socket> _open = {};
  Uint8List data;
  String lastModified;

  /// Bytes per second for bodies; `null` for as fast as the socket takes them.
  int? rate;

  /// Answers the next requests with this status and an empty body, one per entry.
  final List<int> failNext = [];

  /// Fails every request with `503` while set.
  bool down = false;

  /// Destroys the next response's connection after this many body bytes, once.
  int? cutNextAfter;

  /// While set, the server says nothing and closes nothing: a new request gets no status line, and a body in progress
  /// stops after the chunk it is sending — a connection that died without a FIN or an RST, as one does across an iOS
  /// suspension. A connection held so is released when the client goes, or by [dropConnections] or [close].
  bool silent = false;

  /// Stops sending the next response's body after this many bytes, once, as [silent] does.
  int? silentNextAfter;

  /// Answers `200` with the whole file and no `Content-Length`; the body ends when the connection closes.
  bool noLength = false;

  final List<UpstreamRequest> log = [];
  int bytesServed = 0;
  Completer<void> _release = Completer<void>();

  Upstream._(this._server, this.data, this.lastModified) {
    _server.listen(_handle);
  }

  static Future<Upstream> start(Uint8List data, {String lastModified = 'Tue, 22 Sep 2026 18:11:30 GMT'}) async {
    final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    return Upstream._(server, data, lastModified);
  }

  Uri get url => Uri.parse('http://127.0.0.1:${_server.port}/api/recordings/downloads/d1/content/f.mp4');

  /// Replaces the file, as the server preparing the download anew would.
  void replace(Uint8List newData, String newLastModified) {
    data = newData;
    lastModified = newLastModified;
  }

  /// Resets every open connection, as a server that goes away does; the listening socket stays.
  void dropConnections() {
    _releaseSilent();
    for (final s in _open.toList()) {
      s.destroy();
    }
  }

  Future<void> close() async {
    _releaseSilent();
    await _server.close();
    for (final s in _open.toList()) {
      s.destroy();
    }
  }

  void _releaseSilent() {
    _release.complete();
    _release = Completer<void>();
  }

  Future<void> _handle(Socket socket) async {
    _open.add(socket);
    final head = BytesBuilder();
    late StreamSubscription<Uint8List> sub;
    final headers = Completer<String>();
    final gone = Completer<void>();
    void clientGone() {
      if (!headers.isCompleted) headers.complete('');
      if (!gone.isCompleted) gone.complete();
    }

    sub = socket.listen((bytes) {
      if (headers.isCompleted) return;
      head.add(bytes);
      final text = latin1.decode(head.toBytes());
      if (text.contains('\r\n\r\n')) headers.complete(text);
    }, onError: (_) => clientGone(), onDone: clientGone);
    try {
      final text = await headers.future;
      if (text.isEmpty) return;
      await _respond(socket, _parse(text), gone.future);
    } on Object {
      // The client went away — an abort or a retarget. That is what several tests provoke.
    } finally {
      await sub.cancel();
      socket.destroy();
      _open.remove(socket);
    }
  }

  Map<String, String> _parse(String text) {
    final lines = text.split('\r\n');
    return {
      for (final line in lines.skip(1))
        if (line.contains(':')) line.substring(0, line.indexOf(':')).trim().toLowerCase(): line.substring(line.indexOf(':') + 1).trim()
    };
  }

  Future<void> _respond(Socket socket, Map<String, String> h, Future<void> gone) async {
    final entry = UpstreamRequest(h['range'], h['if-range'], h['authorization']);
    log.add(entry);
    // Holds the connection open with nothing sent, until the client gives up on it or the test lets it go.
    Future<void> hold() async {
      entry.silenced = true;
      await Future.any([gone, _release.future]);
    }

    if (silent) return hold();
    void head(int status, Map<String, Object> fields) {
      entry.status = status;
      final b = StringBuffer('HTTP/1.1 $status ${_reason[status] ?? 'Status'}\r\n');
      fields.forEach((k, v) => b.write('$k: $v\r\n'));
      b.write('Connection: close\r\n\r\n');
      socket.add(latin1.encode(b.toString()));
    }

    if (down || failNext.isNotEmpty) {
      head(down ? 503 : failNext.removeAt(0), {'Content-Length': 0});
      await socket.flush();
      return;
    }
    final total = data.length;
    final body = data;
    var start = 0, end = total - 1;
    final m = RegExp(r'^bytes=(\d+)-(\d*)$').firstMatch(h['range'] ?? '');
    // Without lengths the answer is what a length-stripping proxy gives: the whole file, 200, ended by the close.
    final honour = !noLength && m != null && (h['if-range'] == null || h['if-range'] == lastModified);
    final fields = <String, Object>{'Accept-Ranges': 'bytes', 'Last-Modified': lastModified, 'Content-Type': 'video/mp4'};
    int status;
    if (honour) {
      start = int.parse(m[1]!);
      if (m[2]!.isNotEmpty) end = min(int.parse(m[2]!), total - 1);
      if (start >= total) {
        head(416, {'Content-Range': 'bytes */$total', 'Content-Length': 0});
        await socket.flush();
        return;
      }
      status = 206;
      fields['Content-Range'] = 'bytes $start-$end/$total';
    } else {
      status = 200;
    }
    if (!noLength) fields['Content-Length'] = end - start + 1;
    head(status, fields);

    final cut = cutNextAfter;
    cutNextAfter = null;
    final quiet = silentNextAfter;
    silentNextAfter = null;
    const chunk = 16384;
    final clock = Stopwatch()..start();
    var sent = 0;
    for (var o = start; o <= end; o += chunk) {
      if (cut != null && sent >= cut) {
        socket.destroy();
        return;
      }
      if (silent || (quiet != null && sent >= quiet)) return hold();
      final piece = Uint8List.sublistView(body, o, min(o + chunk, end + 1));
      socket.add(piece);
      await socket.flush();
      sent += piece.length;
      bytesServed += piece.length;
      entry.bytes += piece.length;
      final r = rate;
      if (r != null) {
        final due = Duration(microseconds: sent * 1000000 ~/ r);
        if (due > clock.elapsed) await Future.delayed(due - clock.elapsed);
      }
    }
    await socket.flush();
  }

  static const _reason = {200: 'OK', 206: 'Partial Content', 416: 'Range Not Satisfiable', 502: 'Bad Gateway', 503: 'Service Unavailable'};
}

class UpstreamRequest {
  final String? range;
  final String? ifRange;
  final String? authorization;
  int? status;
  int bytes = 0;

  /// Whether the server fell silent on this request, before its head or in its body.
  bool silenced = false;

  UpstreamRequest(this.range, this.ifRange, this.authorization);

  @override
  String toString() => 'UpstreamRequest($range, ifRange: $ifRange, status: $status, bytes: $bytes${silenced ? ', silenced' : ''})';
}

Uint8List randomBytes(int n, [int seed = 1]) {
  final rnd = Random(seed);
  return Uint8List.fromList(List.generate(n, (_) => rnd.nextInt(256)));
}
