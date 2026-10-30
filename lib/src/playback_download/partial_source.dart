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
/// connection there. When writing fails, the source turns into a pass-through: what is stored is still served, and
/// the rest is piped from the server.
///
/// A partial file resumed from an earlier session serves nothing until the server's first answer confirms that it is
/// still the server's file; a file that changed meanwhile is started over, and the player never sees the old bytes.
class PartialSource implements EndpointSource {
  /// A read this close ahead of the transfer waits instead of moving it.
  static const minWindow = 2 << 20;
  static const windowTime = Duration(seconds: 2);

  /// How long a read waits for a server that does not answer before it is given up — shorter than the player's own
  /// network timeout for this source, so that the player learns of the interruption from the endpoint.
  static const defaultGiveUpAfter = Duration(seconds: 45);

  /// How long a reader that arrives after that is given for the server to answer the try it prompts.
  static const retryGrace = Duration(seconds: 1);

  final PartialFile file;
  final Uri url;
  final String? authorization;
  final Duration giveUpAfter;
  final Duration silenceTimeout;
  final HttpClient _client;
  late final Fetcher fetcher;

  /// Called whenever [state] changes, and on progress at most once per [Fetcher] chunk.
  void Function()? onChange;

  SourceState _state = SourceState.idle;
  String? _goneReason;
  /// Why the source is being discarded, from the moment [discard] is called: what stops the transfer then is not a
  /// pause, and nothing starts it again.
  String? _discarding;
  bool _writeFailed = false;
  Future<void>? _run;
  int _readers = 0;
  int? _steeredTo;
  StreamSubscription<void>? _lengthWatch;
  /// The pending [length] calls, each with the number of tries the fetcher had made when it came.
  final List<(Completer<int>, int)> _lengthWaiters = [];
  bool _lengthPolling = false;
  bool _confirmed;

  PartialSource(
      {required this.file,
      required this.url,
      this.authorization,
      this.giveUpAfter = defaultGiveUpAfter,
      HttpClient? client,
      Duration Function(int failures, bool readerWaiting)? backoff,
      this.silenceTimeout = Fetcher.defaultSilenceTimeout,
      Duration flowingWithin = Fetcher.defaultFlowingWithin,
      Duration recoveredAfter = Fetcher.defaultRecoveredAfter,
      this.onChange})
      : _client = client ?? (HttpClient()..connectionTimeout = silenceTimeout),
        _confirmed = file.ranges.isEmpty || file.isComplete {
    fetcher = Fetcher(file: file, url: url, authorization: authorization, client: _client, backoff: backoff, silenceTimeout: silenceTimeout, flowingWithin: flowingWithin, recoveredAfter: recoveredAfter)
      ..restartOnChange = !_confirmed
      ..onAnswer = _onAnswer;
    if (file.isComplete) _state = SourceState.complete;
  }

  SourceState get state => _state;

  String? get goneReason => _goneReason;

  /// Whether the source passes through because writing failed, as opposed to the media having been cleaned.
  bool get writeFailed => _writeFailed;

  bool get isRunning => _run != null;

  /// Whether reads beyond what is stored are given up, the server having failed for [giveUpAfter]. Asking prompts a
  /// try, so that a server that has come back is noticed without waiting out the backoff.
  bool get serverAway {
    final failing = fetcher.failingFor;
    if (failing == null) return false;
    fetcher.wake();
    return failing >= giveUpAfter;
  }

  @override
  bool get isGone => _state == SourceState.gone;

  @override
  String get contentType => contentTypeFor(file.finalPath);

  /// Starts the transfer at [from], unless it is running, finished or impossible.
  void resume(int from) {
    if (_run != null || _discarding != null || _state == SourceState.complete || _state == SourceState.gone || _state == SourceState.passThrough) {
      return;
    }
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
    // Marked before the transfer stops: a length awaited meanwhile ends with [SourceGone], not [TransferStopped].
    _discarding ??= reason;
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

  /// Removes what a pass-through after a failed write kept for reading, once nobody reads from it.
  Future<void> releaseStored() async {
    try {
      await file.discard();
    } on FileSystemException catch (e) {
      // A directory that refused the writes may refuse the deletion too; what is left goes with the next clean.
      AppLoggers.download.w('Playback download of ${file.downloadId} could not remove its partial file', error: e);
    }
  }

  /// Stops the transfer, waits for it to settle, and releases the connection. What was stored stays on disk.
  Future<void> dispose() async {
    fetcher.stop();
    await _run;
    await _lengthWatch?.cancel();
    fetcher.close();
  }

  /// Whether the stored bytes are known to be the server's file: nothing was stored, or the server has answered.
  bool get confirmed => _confirmed;

  /// The file's length once the server has confirmed it, the transfer started if it is not running. Throws
  /// [SourceGone]; [UpstreamUnavailable] once the server has failed for [giveUpAfter] and a try made since the call
  /// failed too — an old failure alone does not give up a server that may be back; [TransferStopped] when the
  /// transfer stops before the length is known (paused for another download, disposed).
  @override
  Future<int> length() {
    final known = file.length;
    if (known != null && _confirmed) return Future.value(known);
    final gone = _goneReason ?? _discarding;
    if (gone != null) return Future.error(SourceGone(gone));
    _lengthWatch ??= file.changes.listen((_) => _deliverLength());
    final since = fetcher.attempts;
    resume(0);
    if (fetcher.failingFor != null) fetcher.wake();
    final waiter = Completer<int>();
    _lengthWaiters.add((waiter, since));
    if (!_lengthPolling) unawaited(_pollLength());
    return waiter.future;
  }

  /// Looks after the pending [length] calls, all of them at once: one listener, one timer, however many wait. Counts
  /// as one reader while any waits, so that failures are retried every second.
  Future<void> _pollLength() async {
    _lengthPolling = true;
    _readers++;
    fetcher.readerWaiting = true;
    try {
      while (true) {
        _settleLengthWaiters();
        if (_lengthWaiters.isEmpty) return;
        await _nextChange(const Duration(milliseconds: 250));
      }
    } finally {
      _readers--;
      fetcher.readerWaiting = _readers > 0;
      _lengthPolling = false;
    }
  }

  void _settleLengthWaiters() {
    if (_lengthWaiters.isEmpty) return;
    final l = file.length;
    Object? error;
    if (l != null && _confirmed) {
      for (final (w, _) in _lengthWaiters) {
        w.complete(l);
      }
      _lengthWaiters.clear();
      return;
    }
    final gone = _goneReason ?? _discarding;
    if (gone != null) {
      error = SourceGone(gone);
    } else if (!isRunning) {
      error = const TransferStopped();
    }
    if (error != null) {
      for (final (w, _) in _lengthWaiters) {
        w.completeError(error);
      }
      _lengthWaiters.clear();
      return;
    }
    final failing = fetcher.failingFor;
    if (failing == null || failing < giveUpAfter) return;
    final failed = fetcher.lastFailedAttempt;
    _lengthWaiters.removeWhere((entry) {
      final (w, since) = entry;
      if (failed <= since) return false;
      w.completeError(UpstreamUnavailable(failing));
      return true;
    });
  }

  /// Completes a pending [length] once the fetcher has learnt it, and the server has confirmed it. Called on every
  /// write, every answer and every change of state, because a write that fails — the reason for a pass-through —
  /// fires no change, while the length is already known.
  void _deliverLength() {
    final l = file.length;
    if (l == null || !_confirmed) return;
    for (final (w, _) in _lengthWaiters) {
      w.complete(l);
    }
    _lengthWaiters.clear();
  }

  void _onAnswer() {
    if (_confirmed) return;
    _confirmed = true;
    fetcher.restartOnChange = false;
    _deliverLength();
  }

  @override
  Future<int> available(int offset, bool Function() isCancelled) async {
    _readers++;
    fetcher.readerWaiting = true;
    // A new reader while the server fails — the player reconnecting, or reopening — is worth a try at once, and the
    // try is waited for before the reader is given up: the server may be back.
    if (fetcher.failingFor != null) fetcher.wake();
    final arrived = DateTime.now();
    final grace = giveUpAfter < retryGrace ? giveUpAfter : retryGrace;
    try {
      while (true) {
        final gone = _goneReason ?? _discarding;
        if (gone != null) throw SourceGone(gone);
        if (_confirmed) {
          final end = file.ranges.end(offset);
          if (end > offset) return end - offset;
        }
        final length = file.length;
        if (_state == SourceState.passThrough) throw PassThroughRequested(_confirmed && length != null ? file.ranges.gapEnd(offset, length) : null);
        final failing = fetcher.failingFor;
        if (failing != null && failing >= giveUpAfter && DateTime.now().difference(arrived) >= grace) throw UpstreamUnavailable(failing);
        if (isCancelled()) return 0;
        _steer(offset);
        await _nextChange(const Duration(milliseconds: 250));
      }
    } finally {
      _readers--;
      fetcher.readerWaiting = _readers > 0;
    }
  }

  /// Completes on the file's next change, or after [limit]. Unlike `changes.first.timeout(...)`, whose listener stays
  /// until the next change however long that takes, it leaves no listener behind: a wait on a silent server ticks every
  /// 250 ms.
  Future<void> _nextChange(Duration limit) {
    final done = Completer<void>();
    late final StreamSubscription<void> sub;
    final timer = Timer(limit, () {
      sub.cancel();
      if (!done.isCompleted) done.complete();
    });
    sub = file.changes.listen((_) {
      timer.cancel();
      sub.cancel();
      if (!done.isCompleted) done.complete();
    });
    return done.future;
  }

  @override
  Future<List<int>> read(int offset, int count) => file.read(offset, count);

  @override
  Stream<List<int>> upstream(int start, int end) async* {
    final req = await _client.getUrl(url);
    req.headers.set(HttpHeaders.rangeHeader, 'bytes=$start-${end - 1}');
    if (authorization != null) req.headers.set(HttpHeaders.authorizationHeader, authorization!);
    // Silent as the fetcher would be: the endpoint resets the player's response, and the player asks again.
    final res = await req.close().timeout(silenceTimeout, onTimeout: () {
      req.abort();
      throw TimeoutException('Pass-through for [$start, $end) got no answer', silenceTimeout);
    });
    if (res.statusCode != HttpStatus.partialContent) {
      await res.drain<void>();
      throw HttpException('Pass-through for [$start, $end) got ${res.statusCode}', uri: url);
    }
    yield* res.timeout(silenceTimeout);
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
    // A length still awaited will not come from this run.
    _settleLengthWaiters();
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
        // What is stored stays readable, so that none of it is fetched twice; [releaseStored] removes it once the
        // session ends.
        _writeFailed = true;
        _setState(SourceState.passThrough);
    }
  }

  void _gone(String reason) {
    _goneReason = reason;
    _setState(SourceState.gone);
    _settleLengthWaiters();
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
