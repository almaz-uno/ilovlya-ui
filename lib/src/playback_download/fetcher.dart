import 'dart:async';
import 'dart:io';
import 'dart:math';

import '../utils/logger_provider.dart';
import 'partial_file.dart';

/// How a [Fetcher.run] ended.
enum FetchOutcome {
  /// Every byte of the file is stored.
  complete,

  /// [Fetcher.stop] was called.
  stopped,

  /// Too many consecutive failures with no reader waiting; what was stored is kept.
  failed,

  /// The server's file is no longer the one the partial file was started from.
  fileChanged,

  /// The server's answer carries no length, so a partial file cannot be kept.
  noLength,

  /// Writing the partial file failed — no space, the directory gone.
  writeFailed,
}

/// The one connection to the server that fills a [PartialFile].
///
/// One request is in flight at a time, and each asks for one gap only, `Range: bytes=a-(b-1)`, so it ends where the next
/// stored interval begins instead of running into it. When a gap is done, the next comes from
/// [RangeSet.nextGap] at the position reached — forward to the end, then the gaps left behind. [retarget] aborts the
/// request and continues from another offset; bytes already received are written, bytes not yet received are simply
/// not fetched, so a seek costs a reconnect and not a second transfer.
class Fetcher {
  /// Failures in a row after which a fetcher no player is attached to gives up.
  static const maxFailuresUnattended = 8;

  /// Weight of the newest one-second window in [rate].
  static const rateAlpha = 0.3;

  final PartialFile file;
  final Uri url;
  final String? bearerToken;
  final HttpClient _client;
  final Duration Function(int failures, bool readerWaiting) _backoff;

  /// Set while the endpoint has a read waiting on bytes that are not stored. Retrying then happens every second,
  /// because libmpv gives up about 36 s after its bytes stop and every second of backoff is taken from that window.
  bool readerWaiting = false;

  /// Whether a player is reading from this download. Without one, [maxFailuresUnattended] failures end the run.
  bool playerAttached = true;

  int _position = 0;
  double _rate = 0;
  int _windowBytes = 0;
  final Stopwatch _window = Stopwatch();
  HttpClientRequest? _request;
  int? _retargetTo;
  bool _stopped = false;
  bool _running = false;
  int _requests = 0;

  Fetcher({required this.file, required this.url, this.bearerToken, HttpClient? client, Duration Function(int failures, bool readerWaiting)? backoff})
      : _client = client ?? HttpClient(),
        _backoff = backoff ?? defaultBackoff;

  /// 1 s while a reader waits; otherwise 1 s doubling to 30 s.
  static Duration defaultBackoff(int failures, bool readerWaiting) {
    if (readerWaiting) return const Duration(seconds: 1);
    return Duration(seconds: min(30, 1 << min(failures - 1, 5)));
  }

  /// The next byte the current request will deliver; the frontier of the transfer.
  int get position => _position;

  /// Measured throughput in bytes per second, a moving average over one-second windows.
  double get rate => _rate;

  bool get running => _running;

  /// Requests made so far; what a test or a log line counts.
  int get requests => _requests;

  /// Fetches until the file is complete, or the run ends otherwise, starting from [from].
  Future<FetchOutcome> run(int from) async {
    if (_running) throw StateError('Fetcher is already running');
    _running = true;
    _stopped = false;
    _position = from;
    var failures = 0;
    try {
      while (!_stopped) {
        final target = _retargetTo;
        if (target != null) {
          _position = target;
          _retargetTo = null;
        }
        final length = file.length;
        int start;
        int? end;
        if (length == null) {
          start = _position;
        } else {
          final gap = file.ranges.nextGap(_position, length);
          if (gap == null) return FetchOutcome.complete;
          (start, end) = gap;
        }

        final result = await _fetch(start, end);
        switch (result) {
          case _Attempt.done:
            failures = 0;
          case _Attempt.interrupted:
            break;
          case _Attempt.failed:
            failures++;
            if (!playerAttached && failures >= maxFailuresUnattended) return FetchOutcome.failed;
            await _sleepUnlessInterrupted(_backoff(failures, readerWaiting));
          case _Attempt.fileChanged:
            return FetchOutcome.fileChanged;
          case _Attempt.noLength:
            return FetchOutcome.noLength;
          case _Attempt.writeFailed:
            return FetchOutcome.writeFailed;
        }
      }
      return FetchOutcome.stopped;
    } finally {
      _running = false;
      _request = null;
    }
  }

  /// Continues from [offset] — the place the player now reads — aborting the request in flight.
  void retarget(int offset) {
    _retargetTo = offset;
    _request?.abort();
    _wakeUp();
  }

  /// Ends the run as soon as the request in flight is aborted.
  void stop() {
    _stopped = true;
    _request?.abort();
    _wakeUp();
  }

  void close() => _client.close(force: true);

  Completer<void>? _wake;

  void _wakeUp() {
    final wake = _wake;
    if (wake != null && !wake.isCompleted) wake.complete();
  }

  Future<void> _sleepUnlessInterrupted(Duration d) async {
    final wake = _wake = Completer<void>();
    await Future.any([Future.delayed(d), wake.future]);
    _wake = null;
  }

  Future<_Attempt> _fetch(int start, int? end) async {
    final HttpClientRequest request;
    final HttpClientResponse response;
    try {
      request = _request = await _client.getUrl(url);
      _requests++;
      request.headers.set(HttpHeaders.rangeHeader, end == null ? 'bytes=$start-' : 'bytes=$start-${end - 1}');
      final lastModified = file.lastModified;
      if (lastModified != null) request.headers.set(HttpHeaders.ifRangeHeader, lastModified);
      if (bearerToken != null) request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $bearerToken');
      response = await request.close();
    } on Object catch (e) {
      if (_interrupted) return _Attempt.interrupted;
      AppLoggers.download.w('Playback download request for [$start, ${end ?? ''}) failed', error: e);
      return _Attempt.failed;
    }

    int offset;
    switch (response.statusCode) {
      case HttpStatus.partialContent:
        final range = _ContentRange.parse(response.headers.value(HttpHeaders.contentRangeHeader));
        if (range == null || range.start != start) {
          AppLoggers.download.w('Playback download got an unusable Content-Range: ${response.headers.value(HttpHeaders.contentRangeHeader)}');
          await _drain(response);
          return _Attempt.failed;
        }
        if (range.total == null) {
          await _drain(response);
          return _Attempt.noLength;
        }
        if (file.length == null) {
          file.setLength(range.total!, response.headers.value(HttpHeaders.lastModifiedHeader));
        } else if (file.length != range.total) {
          await _drain(response);
          return _Attempt.fileChanged;
        }
        offset = start;
      case HttpStatus.ok:
        // The whole file instead of the range: `If-Range` no longer matched, so the file changed — or, on the very
        // first request, the server ignored the range, and the body is simply the file from byte 0.
        if (file.length != null) {
          await _drain(response);
          return _Attempt.fileChanged;
        }
        if (response.contentLength < 0) {
          await _drain(response);
          return _Attempt.noLength;
        }
        file.setLength(response.contentLength, response.headers.value(HttpHeaders.lastModifiedHeader));
        offset = 0;
      default:
        AppLoggers.download.w('Playback download got ${response.statusCode} for [$start, ${end ?? ''})');
        await _drain(response);
        return _Attempt.failed;
    }

    _position = offset;
    try {
      await for (final chunk in response) {
        // Leaving the loop cancels the subscription, which closes the connection; `abort` alone does not stop a body
        // that is already arriving.
        if (_interrupted) break;
        try {
          await file.write(offset, chunk);
        } on FileSystemException catch (e) {
          AppLoggers.download.e('Playback download cannot write ${file.dataPath}', error: e);
          _request?.abort();
          return _Attempt.writeFailed;
        }
        offset += chunk.length;
        _position = offset;
        _measure(chunk.length);
        if (file.checkpointDue) await file.checkpoint();
      }
    } on Object catch (e) {
      if (_interrupted) return _Attempt.interrupted;
      AppLoggers.download.w('Playback download broke off at $offset', error: e);
      return _Attempt.failed;
    }
    if (_interrupted) return _Attempt.interrupted;
    // A closed range ends exactly at the gap's end; anything shorter is a connection cut short.
    if (end != null && offset < end) return _Attempt.failed;
    return _Attempt.done;
  }

  bool get _interrupted => _stopped || _retargetTo != null;

  void _measure(int bytes) {
    if (!_window.isRunning) _window.start();
    _windowBytes += bytes;
    final elapsed = _window.elapsedMicroseconds;
    if (elapsed >= 1000000) {
      final instant = _windowBytes * 1e6 / elapsed;
      _rate = _rate == 0 ? instant : rateAlpha * instant + (1 - rateAlpha) * _rate;
      _windowBytes = 0;
      _window.reset();
    }
  }

  Future<void> _drain(HttpClientResponse response) async {
    try {
      await response.drain<void>();
    } on Object {
      // Nothing to keep from an answer that is being thrown away.
    }
  }
}

enum _Attempt { done, interrupted, failed, fileChanged, noLength, writeFailed }

class _ContentRange {
  final int start;
  final int end;
  final int? total;

  _ContentRange(this.start, this.end, this.total);

  static final _re = RegExp(r'^bytes (\d+)-(\d+)/(\d+|\*)$');

  static _ContentRange? parse(String? value) {
    final m = value == null ? null : _re.firstMatch(value.trim());
    if (m == null) return null;
    return _ContentRange(int.parse(m[1]!), int.parse(m[2]!), m[3] == '*' ? null : int.parse(m[3]!));
  }
}
