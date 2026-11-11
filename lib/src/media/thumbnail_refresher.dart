import 'dart:async';

/// Decides when the thumbnail of the recording being played is taken again from the player.
///
/// - On pause, once the player has stayed paused for [pauseDelay]. A seek while paused starts the wait again, so pause,
///   seek, pause gives one capture.
/// - While playing, every [period].
/// - A capture is skipped while [canCapture] says no (the option is off, or there is no frame yet), and when the
///   position has moved less than [minMove] since the last capture.
/// - [captureLast], on leaving the player, takes one more, whatever the position.
///
/// Captures never overlap: one that comes due while another runs is skipped, and [captureLast] waits for it.
class ThumbnailRefresher {
  ThumbnailRefresher({
    required this.capture,
    required this.canCapture,
    this.pauseDelay = const Duration(seconds: 1),
    this.period = const Duration(seconds: 30),
    this.minMove = const Duration(seconds: 1),
  });

  /// Takes and stores the thumbnail; true if it did.
  final Future<bool> Function() capture;
  final bool Function() canCapture;
  final Duration pauseDelay;
  final Duration period;
  final Duration minMove;

  bool _playing = false;
  bool _stopped = false;
  Duration? _position;
  Duration? _captured;
  Timer? _timer;
  Future<void>? _running;

  /// The player's `playing` changed.
  void onPlaying(bool playing) {
    if (_stopped || playing == _playing) return;
    _playing = playing;
    _timer?.cancel();
    _timer = playing ? Timer.periodic(period, (_) => _due()) : Timer(pauseDelay, _due);
  }

  /// The player's position changed. While paused, that is a seek.
  void onPosition(Duration position) {
    final before = _position;
    _position = position;
    if (_stopped || _playing || before == null || before == position) return;
    _timer?.cancel();
    _timer = Timer(pauseDelay, _due);
  }

  /// No more captures but [captureLast].
  void stop() {
    _stopped = true;
    _timer?.cancel();
    _timer = null;
  }

  /// One last capture, once a capture that runs has ended.
  Future<void> captureLast() async {
    stop();
    await _running;
    if (canCapture()) await _run();
  }

  void _due() {
    if (_stopped || _running != null || !canCapture()) return;
    final position = _position;
    final captured = _captured;
    if (position != null && captured != null && (position - captured).abs() < minMove) return;
    unawaited(_run());
  }

  /// A capture that throws counts as one that did not take the thumbnail.
  Future<void> _run() async {
    final position = _position;
    final done = Completer<void>();
    _running = done.future;
    try {
      if (await capture()) _captured = position;
    } catch (_) {
      // Left to [capture] to report; the next one comes due as usual.
    } finally {
      _running = null;
      done.complete();
    }
  }
}
