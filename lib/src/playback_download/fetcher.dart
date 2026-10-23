import 'dart:async';
import 'dart:collection';
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

  /// How long a request may stay silent — no connection, no answer, or no byte of the body — before it counts as
  /// failed. A connection that dies without a FIN or an RST, as one does across an iOS suspension or a network switch,
  /// would otherwise keep the transfer waiting for ever, with no failure for the retries and the endpoint's give-up to
  /// act on. The failure is dated from the moment the request fell silent, so the endpoint still gives a read up 45 s
  /// after its bytes stopped (`PartialSource.defaultGiveUpAfter`), within libmpv's 60 s on the endpoint
  /// (`MKPlayerHandler.loopbackNetworkTimeout`), whatever this value. 15 s: a server that answers at all answers within
  /// a round trip and sends without pausing, while a mobile link may stall for some seconds at a handover; three
  /// silent tries fit into the 45 s.
  static const defaultSilenceTimeout = Duration(seconds: 15);

  /// A transfer that has received no byte for this long is not flowing: no time remaining can be estimated for it.
  static const defaultFlowingWithin = Duration(seconds: 2);

  /// How long bytes must flow, with no pause of [flowingWithin], before a server that was not answering counts as back.
  /// A server that sends a portion on every new request and then falls silent — what a stalled proxy or a dying
  /// upstream does — answers each retry at once; the portion arrives within a second or two at the link's speed, so 5 s
  /// keeps such a transfer marked as not answering, while a server that is really back is shown so within 5 s.
  static const defaultRecoveredAfter = Duration(seconds: 5);

  /// The fewest bytes per [silenceTimeout] for a running transfer to count as answered: 64 KiB per 15 s, about
  /// 35 kbit/s. That is below the leanest audio-only format a recording comes in (about 48 kbit/s), so a transfer under
  /// it cannot keep any playback going; a slow mobile link stays well above it. It catches a server that drips a byte
  /// now and then and so never trips [silenceTimeout]. It is not the recording's bitrate on purpose: a link slower than
  /// the recording is slow, not silent, and the speed shown says so.
  static const defaultMinProgress = 64 << 10;

  final PartialFile file;
  final Uri url;
  /// The `Authorization` header value the rest of the client sends (`getAuthHeader`), or `null` for none. The content
  /// endpoint is public today and ignores it; sending it keeps the transfer working if that ever changes.
  final String? authorization;
  final HttpClient _client;
  final Duration Function(int failures, bool readerWaiting) _backoff;
  final Duration silenceTimeout;
  final Duration flowingWithin;
  final Duration recoveredAfter;
  final int minProgress;

  /// Set while the endpoint has a read waiting on bytes that are not stored. Retrying then happens every second,
  /// because libmpv gives up about 36 s after its bytes stop and every second of backoff is taken from that window.
  bool readerWaiting = false;

  /// Whether a player is reading from this download. Without one, [maxFailuresUnattended] failures end the run.
  bool playerAttached = true;

  /// Set while no stored byte has reached a reader. A file found changed on the server is then started over, the new
  /// file taken from the answer that revealed the change, instead of ending the run with [FetchOutcome.fileChanged].
  bool restartOnChange = false;

  /// Called for every answer the transfer goes on with: the stored bytes are the server's file, or were started over.
  void Function()? onAnswer;

  int _position = 0;
  DateTime? _failingSince;
  DateTime? _silentSince;
  DateTime? _troubleSince;
  DateTime? _flowingSince;
  DateTime? _runSince;
  /// Bytes received, in slices of at most [_slice], over the last [silenceTimeout].
  final Queue<(DateTime, int)> _arrivals = Queue();
  static const _slice = Duration(milliseconds: 100);
  double _rate = 0;
  int _windowBytes = 0;
  final Stopwatch _window = Stopwatch();
  final Stopwatch _sinceChunk = Stopwatch();
  HttpClientRequest? _request;
  Completer<void>? _leaveBody;
  int? _retargetTo;
  bool _stopped = false;
  bool _running = false;
  int _requests = 0;

  Fetcher(
      {required this.file,
      required this.url,
      this.authorization,
      HttpClient? client,
      Duration Function(int failures, bool readerWaiting)? backoff,
      this.silenceTimeout = defaultSilenceTimeout,
      this.flowingWithin = defaultFlowingWithin,
      this.recoveredAfter = defaultRecoveredAfter,
      this.minProgress = defaultMinProgress})
      : _client = client ?? (HttpClient()..connectionTimeout = silenceTimeout),
        _backoff = backoff ?? defaultBackoff;

  /// 1 s while a reader waits; otherwise 1 s doubling to 30 s.
  static Duration defaultBackoff(int failures, bool readerWaiting) {
    if (readerWaiting) return const Duration(seconds: 1);
    return Duration(seconds: min(30, 1 << min(failures - 1, 5)));
  }

  /// The next byte the current request will deliver; the frontier of the transfer.
  int get position => _position;

  /// Measured throughput in bytes per second, a moving average over one-second windows. Every whole second without a
  /// byte counts as a window with none, so the rate decays while the transfer stalls instead of keeping its last value.
  double get rate {
    final idle = _sinceChunk.elapsedMicroseconds ~/ 1000000;
    return idle == 0 ? _rate : _rate * pow(1 - rateAlpha, idle);
  }

  /// Whether a byte has arrived within [flowingWithin].
  bool get flowing => _sinceChunk.isRunning && _sinceChunk.elapsed < flowingWithin;

  bool get running => _running;

  /// Requests made so far; what a test or a log line counts.
  int get requests => _requests;

  /// How long every request has failed, from the first failure of the current streak; `null` while the server answers.
  Duration? get failingFor {
    final since = _failingSince;
    return since == null ? null : DateTime.now().difference(since);
  }

  /// How long the server has not been answering this transfer, for the user to see; `null` while it answers.
  ///
  /// Broader than [failingFor], which an answer of any size clears. It runs from the first failure or silence of a
  /// streak — or from the start of a [silenceTimeout] that brought fewer than [minProgress] bytes — and it goes on
  /// through answers that bring a portion and fall silent again, until bytes have flowed for [recoveredAfter].
  Duration? get notAnsweringFor {
    final now = DateTime.now();
    _assess(now);
    final since = _troubleSince;
    return since == null ? null : now.difference(since);
  }

  void _assess(DateTime now) {
    if (_failingSince != null) {
      _troubleSince ??= _failingSince;
      return;
    }
    final window = now.subtract(silenceTimeout);
    final runSince = _runSince;
    if (_running && runSince != null && !runSince.isAfter(window) && _bytesSince(window) < minProgress) {
      _troubleSince ??= window;
      return;
    }
    final flowingSince = _flowingSince;
    if (_troubleSince != null && flowing && flowingSince != null && now.difference(flowingSince) >= recoveredAfter) {
      _troubleSince = null;
    }
  }

  int _bytesSince(DateTime t) {
    _forgetBefore(t);
    return _arrivals.fold(0, (sum, a) => sum + a.$2);
  }

  void _forgetBefore(DateTime t) {
    while (_arrivals.isNotEmpty && _arrivals.first.$1.isBefore(t)) {
      _arrivals.removeFirst();
    }
  }

  /// Cuts a backoff short: a reader has come, and the server may be back.
  void wake() => _wakeUp();

  /// Fetches until the file is complete, or the run ends otherwise, starting from [from].
  Future<FetchOutcome> run(int from) async {
    if (_running) throw StateError('Fetcher is already running');
    _running = true;
    _stopped = false;
    _position = from;
    _runSince = DateTime.now();
    _troubleSince = null;
    _flowingSince = null;
    _arrivals.clear();
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
          case _Attempt.restarted:
            failures = 0;
          case _Attempt.interrupted:
            break;
          case _Attempt.failed:
            failures++;
            _failingSince ??= _silentSince ?? DateTime.now();
            _troubleSince ??= _failingSince;
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
    _leave();
    _wakeUp();
  }

  /// Ends the run as soon as the request in flight is aborted.
  void stop() {
    _stopped = true;
    _request?.abort();
    _leave();
    _wakeUp();
  }

  void close() => _client.close(force: true);

  Completer<void>? _wake;

  /// Ends the body being read at once, rather than at its next chunk, which a silent server does not send.
  void _leave() {
    final leave = _leaveBody;
    if (leave != null && !leave.isCompleted) leave.complete();
  }

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
    _silentSince = null;
    _request = null;
    final HttpClientRequest request;
    final HttpClientResponse response;
    try {
      request = _request = await _client.getUrl(url);
      _requests++;
      request.headers.set(HttpHeaders.rangeHeader, end == null ? 'bytes=$start-' : 'bytes=$start-${end - 1}');
      final lastModified = file.lastModified;
      if (lastModified != null) request.headers.set(HttpHeaders.ifRangeHeader, lastModified);
      if (authorization != null) request.headers.set(HttpHeaders.authorizationHeader, authorization!);
      response = await request.close().timeout(silenceTimeout);
    } on Object catch (e) {
      if (_interrupted) return _Attempt.interrupted;
      if (e is TimeoutException || (e is SocketException && e.message.contains('timed out'))) _silent();
      AppLoggers.download.w('Playback download request for [$start, ${end ?? ''}) failed', error: e);
      return _Attempt.failed;
    }

    // A body that is not taken is abandoned, not drained: it can be the whole file.
    final lastModified = response.headers.value(HttpHeaders.lastModifiedHeader);
    int offset;
    switch (response.statusCode) {
      case HttpStatus.partialContent:
        final range = _ContentRange.parse(response.headers.value(HttpHeaders.contentRangeHeader));
        if (range == null || range.start != start) {
          AppLoggers.download.w('Playback download got an unusable Content-Range: ${response.headers.value(HttpHeaders.contentRangeHeader)}');
          await _abandon(response);
          return _Attempt.failed;
        }
        if (range.total == null) {
          await _abandon(response);
          return _Attempt.noLength;
        }
        if (file.length == null) {
          file.setLength(range.total!, lastModified);
        } else if (file.length != range.total) {
          await _abandon(response);
          if (!restartOnChange) return _Attempt.fileChanged;
          await file.restart(range.total!, lastModified);
          _answered();
          return _Attempt.restarted;
        }
        offset = start;
      case HttpStatus.ok:
        // The whole file instead of the range: `If-Range` no longer matched, so the file changed — or, on the very
        // first request, the server ignored the range, and the body is simply the file from byte 0.
        if (response.contentLength < 0) {
          await _abandon(response);
          return _Attempt.noLength;
        }
        if (file.length == null) {
          file.setLength(response.contentLength, lastModified);
        } else if (restartOnChange) {
          // Nothing stored was served yet, so the new file simply replaces it, starting with this very body.
          await file.restart(response.contentLength, lastModified);
        } else {
          await _abandon(response);
          return _Attempt.fileChanged;
        }
        offset = 0;
      default:
        AppLoggers.download.w('Playback download got ${response.statusCode} for [$start, ${end ?? ''})');
        await _drain(response);
        return _Attempt.failed;
    }

    _answered();
    _position = offset;
    try {
      // The timer stops while the loop writes a chunk, which pauses the subscription: a slow disk is not a silent server.
      final leave = _leaveBody = Completer<void>();
      await for (final chunk in _until(response.timeout(silenceTimeout), leave.future)) {
        // Leaving the loop cancels the subscription, which closes the connection; `abort` alone does not stop a body
        // that is already arriving.
        if (_interrupted) break;
        try {
          await file.write(offset, chunk);
        } on FileSystemException catch (e) {
          return _cannotWrite(file.dataPath, e);
        }
        offset += chunk.length;
        _position = offset;
        _measure(chunk.length);
        // The record is written anew beside the data, so it fails where the open data file does not: a directory
        // that became read-only, space that ran out between the two. Either way nothing more can be kept.
        if (file.checkpointDue) {
          try {
            await file.checkpoint();
          } on FileSystemException catch (e) {
            return _cannotWrite(file.statePath, e);
          }
        }
      }
    } on Object catch (e) {
      if (_interrupted) return _Attempt.interrupted;
      if (e is TimeoutException) _silent();
      AppLoggers.download.w('Playback download broke off at $offset', error: e);
      return _Attempt.failed;
    }
    if (_interrupted) return _Attempt.interrupted;
    // A closed range ends exactly at the gap's end; anything shorter is a connection cut short.
    if (end != null && offset < end) return _Attempt.failed;
    return _Attempt.done;
  }

  bool get _interrupted => _stopped || _retargetTo != null;

  /// The request in flight said nothing for [silenceTimeout]: it is dropped, and a failure it starts is dated from the
  /// moment it fell silent.
  void _silent() {
    _request?.abort();
    _silentSince = DateTime.now().subtract(silenceTimeout);
  }

  _Attempt _cannotWrite(String path, FileSystemException e) {
    AppLoggers.download.e('Playback download cannot write $path', error: e);
    _request?.abort();
    return _Attempt.writeFailed;
  }

  /// The server answered with something the transfer goes on with.
  void _answered() {
    _failingSince = null;
    onAnswer?.call();
  }

  void _measure(int bytes) {
    final now = DateTime.now();
    if (!flowing) _flowingSince = now;
    final last = _arrivals.isEmpty ? null : _arrivals.last;
    if (last != null && now.difference(last.$1) < _slice) {
      _arrivals.removeLast();
      _arrivals.addLast((last.$1, last.$2 + bytes));
    } else {
      _arrivals.addLast((now, bytes));
      _forgetBefore(now.subtract(silenceTimeout));
    }
    if (_sinceChunk.elapsedMicroseconds >= 1000000) {
      // The first byte after a pause: the rate keeps what the pause took from it, and a new window starts here.
      _rate = rate;
      _windowBytes = 0;
      _window.reset();
    }
    _sinceChunk
      ..reset()
      ..start();
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

  /// Closes the connection without reading the body: cancelling the subscription is what stops one that is arriving.
  Future<void> _abandon(HttpClientResponse response) async {
    _request?.abort();
    try {
      await response.listen(null).cancel();
    } on Object {
      // Nothing to keep from an answer that is being thrown away.
    }
  }
}

enum _Attempt { done, restarted, interrupted, failed, fileChanged, noLength, writeFailed }

/// [source] until [end] completes; then the stream ends, and its subscription to [source] is cancelled.
Stream<T> _until<T>(Stream<T> source, Future<void> end) {
  StreamSubscription<T>? sub;
  final out = StreamController<T>(sync: true);
  out
    ..onListen = () {
      sub = source.listen(out.add, onError: out.addError, onDone: out.close);
      end.then((_) {
        sub?.cancel();
        out.close();
      });
    }
    ..onPause = (() => sub?.pause())
    ..onResume = (() => sub?.resume())
    ..onCancel = (() => sub?.cancel());
  return out.stream;
}

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
