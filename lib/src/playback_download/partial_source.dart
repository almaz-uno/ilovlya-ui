import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:path/path.dart' as p;

import '../utils/logger_provider.dart';
import 'fetcher.dart';
import 'local_endpoint.dart';
import 'partial_file.dart';

/// Where a [PartialSource] stands.
enum SourceState { idle, running, complete, passThrough, gone }

/// A download served to the player while it arrives: a [PartialFile] filled by a [Fetcher], read through the
/// [LocalMediaEndpoint].
///
/// Every read is classified against what is stored. Stored bytes are served at once. Bytes the connection is about to
/// reach — within 2 s at its measured rate, and in any case within 2 MiB — are waited for. Anything else moves the
/// connection there. When writing fails, the source turns into a pass-through and every read is piped from the server.
class PartialSource implements EndpointSource {
  /// A read this close ahead of the transfer waits instead of moving it.
  static const minWindow = 2 << 20;
  static const windowTime = Duration(seconds: 2);

  final PartialFile file;
  final Uri url;
  final String? authorization;
  final HttpClient _client;
  late final Fetcher fetcher;

  /// Called whenever [state] changes, and on progress at most once per [Fetcher] chunk.
  void Function()? onChange;

  SourceState _state = SourceState.idle;
  String? _goneReason;
  bool _writeFailed = false;
  Future<void>? _run;
  int _readers = 0;
  int? _steeredTo;
  StreamSubscription<void>? _lengthWatch;
  Completer<int>? _length;

  PartialSource({required this.file, required this.url, this.authorization, HttpClient? client, Duration Function(int failures, bool readerWaiting)? backoff, this.onChange})
      : _client = client ?? HttpClient() {
    fetcher = Fetcher(file: file, url: url, authorization: authorization, client: _client, backoff: backoff);
    if (file.isComplete) _state = SourceState.complete;
  }

  SourceState get state => _state;

  String? get goneReason => _goneReason;

  /// Whether the source passes through because writing failed, as opposed to the media having been cleaned.
  bool get writeFailed => _writeFailed;

  bool get isRunning => _run != null;

  @override
  bool get isGone => _state == SourceState.gone;

  @override
  String get contentType => contentTypeFor(file.finalPath);

  /// Starts the transfer at [from], unless it is running, finished or impossible.
  void resume(int from) {
    if (_run != null || _state == SourceState.complete || _state == SourceState.gone || _state == SourceState.passThrough) return;
    _setState(SourceState.running);
    _run = fetcher.run(from).then(_finished, onError: (Object e) {
      AppLoggers.download.e('Playback download of ${file.downloadId} stopped by an error', error: e);
      return _finished(FetchOutcome.failed);
    });
  }

  /// Stops the transfer, keeping what was stored for a later [resume].
  Future<void> pause() async {
    fetcher.stop();
    await _run;
  }

  /// Ends the source: the transfer stops, the file is discarded, readers get [SourceGone].
  Future<void> discard(String reason) async {
    fetcher.stop();
    await _run;
    await file.discard();
    _gone(reason);
  }

  /// Stops storing: the partial file is removed and every read from now on is piped from the server.
  Future<void> passThrough(String reason) async {
    fetcher.stop();
    await _run;
    await file.discard();
    AppLoggers.download.w('Playback download of ${file.downloadId} passes through from now on: $reason');
    _setState(SourceState.passThrough);
  }

  /// Stops the transfer, waits for it to settle, and releases the connection. What was stored stays on disk.
  Future<void> dispose() async {
    fetcher.stop();
    await _run;
    await _lengthWatch?.cancel();
    fetcher.close();
  }

  @override
  Future<int> length() {
    final known = file.length;
    if (known != null) return Future.value(known);
    if (isGone) return Future.error(SourceGone(_goneReason!));
    final c = _length ??= Completer<int>();
    _lengthWatch ??= file.changes.listen((_) => _deliverLength());
    resume(0);
    return c.future;
  }

  /// Completes a pending [length] once the fetcher has learnt it. Called on every write and every change of state,
  /// because a write that fails — the reason for a pass-through — fires no change, while the length is already known.
  void _deliverLength() {
    final c = _length;
    final l = file.length;
    if (c != null && l != null && !c.isCompleted) c.complete(l);
  }

  @override
  Future<int> available(int offset, bool Function() isCancelled) async {
    _readers++;
    fetcher.readerWaiting = true;
    try {
      while (true) {
        if (isGone) throw SourceGone(_goneReason!);
        if (_state == SourceState.passThrough) throw const PassThroughRequested();
        final end = file.ranges.end(offset);
        if (end > offset) return end - offset;
        if (isCancelled()) return 0;
        _steer(offset);
        await file.changes.first.timeout(const Duration(milliseconds: 250), onTimeout: () {});
      }
    } finally {
      _readers--;
      fetcher.readerWaiting = _readers > 0;
    }
  }

  @override
  Future<List<int>> read(int offset, int count) => file.read(offset, count);

  @override
  Stream<List<int>> upstream(int start, int end) async* {
    final req = await _client.getUrl(url);
    req.headers.set(HttpHeaders.rangeHeader, 'bytes=$start-${end - 1}');
    if (authorization != null) req.headers.set(HttpHeaders.authorizationHeader, authorization!);
    final res = await req.close();
    if (res.statusCode != HttpStatus.partialContent) {
      await res.drain<void>();
      throw HttpException('Pass-through for [$start, $end) got ${res.statusCode}', uri: url);
    }
    yield* res;
  }

  void _steer(int offset) {
    if (_run == null) {
      _steeredTo = offset;
      resume(offset);
      return;
    }
    final ahead = offset - fetcher.position;
    final window = max(minWindow, (fetcher.rate * windowTime.inMicroseconds / 1e6).round());
    if (ahead >= 0 && ahead <= window) {
      _steeredTo = null;
      return;
    }
    if (_steeredTo == offset) return; // already moving there; the position catches up once the new request starts
    _steeredTo = offset;
    fetcher.retarget(offset);
  }

  Future<void> _finished(FetchOutcome outcome) async {
    try {
      await _settle(outcome);
    } on Object catch (e) {
      // The file may be gone underneath — the media cleaned while the transfer stopped. Nothing to settle then.
      AppLoggers.download.w('Playback download of ${file.downloadId} could not settle after $outcome', error: e);
      _run = null;
    }
  }

  Future<void> _settle(FetchOutcome outcome) async {
    _run = null;
    AppLoggers.download.i('Playback download of ${file.downloadId} ended: $outcome after ${fetcher.requests} requests, ${file.ranges.stored} of ${file.length} bytes');
    switch (outcome) {
      case FetchOutcome.complete:
        await file.complete();
        _setState(SourceState.complete);
      case FetchOutcome.stopped:
      case FetchOutcome.failed:
        await file.checkpoint();
        if (_state == SourceState.running) _setState(SourceState.idle);
      case FetchOutcome.fileChanged:
        await file.discard();
        _gone('the file changed on the server');
      case FetchOutcome.noLength:
        await file.discard();
        _gone('the server sent no length');
      case FetchOutcome.writeFailed:
        _writeFailed = true;
        _setState(SourceState.passThrough);
        // A directory that refused the record refuses the deletion too; what is left there goes with the next clean.
        try {
          await file.discard();
        } on FileSystemException catch (e) {
          AppLoggers.download.w('Playback download of ${file.downloadId} could not remove its partial file', error: e);
        }
    }
  }

  void _gone(String reason) {
    _goneReason = reason;
    final c = _length;
    if (c != null && !c.isCompleted) c.completeError(SourceGone(reason));
    _setState(SourceState.gone);
  }

  void _setState(SourceState s) {
    _state = s;
    _deliverLength();
    onChange?.call();
  }
}

/// A content type from the file's extension. libmpv probes the content anyway; this is for the media session and for
/// anything that does look at the header.
String contentTypeFor(String path) => switch (p.extension(path).toLowerCase()) {
      '.mp4' || '.m4v' => 'video/mp4',
      '.webm' => 'video/webm',
      '.mkv' => 'video/x-matroska',
      '.m4a' => 'audio/mp4',
      '.mp3' => 'audio/mpeg',
      '.opus' || '.ogg' => 'audio/ogg',
      _ => 'application/octet-stream',
    };
