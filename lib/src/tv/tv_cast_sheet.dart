import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ilovlya/src/localization/app_localizations.dart';
import 'package:ilovlya/src/model/download.dart';
import 'package:ilovlya/src/model/recording_info.dart';

import 'tv_api.dart';
import 'tv_models.dart';

/// The remote control: what the television is doing, and the buttons that
/// change it. State is polled, because the effect of a command arrives from the
/// receiver rather than from the answer to the request.
class TvCastSheet extends ConsumerStatefulWidget {
  const TvCastSheet({super.key, required this.sessionId, required this.recording, required this.download});

  final String sessionId;
  final RecordingInfo recording;
  final Download download;

  static Future<void> show(BuildContext context, {required String sessionId, required RecordingInfo recording, required Download download}) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => TvCastSheet(sessionId: sessionId, recording: recording, download: download),
    );
  }

  @override
  ConsumerState<TvCastSheet> createState() => _TvCastSheetState();
}

class _TvCastSheetState extends ConsumerState<TvCastSheet> {
  static const _step = Duration(seconds: 30);

  bool _started = false;
  String? _failure;

  @override
  void initState() {
    super.initState();
    // Opening the sheet is the gesture that starts the cast; the position comes
    // from the recording, so the television continues where the phone stopped.
    WidgetsBinding.instance.addPostFrameCallback((_) => _startIfIdle());
  }

  Future<void> _startIfIdle() async {
    if (_started) {
      return;
    }
    _started = true;

    final session = await ref.read(tvSessionStateProvider(widget.sessionId).future);
    if (session.downloadId == widget.download.id && session.phase != TvPhase.paired) {
      return;
    }

    await _run(TvCommand.play(widget.download.id, position: widget.recording.position));
  }

  Future<void> _run(TvCommand cmd) async {
    try {
      await ref.read(tvSessionStateProvider(widget.sessionId).notifier).command(cmd);
      if (mounted) {
        setState(() => _failure = null);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _failure = AppLocalizations.of(context)!.tvCommandFailed);
      }
    }
  }

  Future<void> _seekBy(Duration delta, TvSession session) async {
    final target = session.position + delta.inSeconds;
    await _run(TvCommand.seek(target < 0 ? 0 : target));
  }

  Future<void> _disconnect() async {
    try {
      await ref.read(tvSessionStateProvider(widget.sessionId).notifier).end();
      ref.invalidate(tvSessionsProvider);
    } finally {
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  String _status(AppLocalizations l10n, TvSession session) {
    if (!session.connected) {
      return l10n.tvStatusDisconnected;
    }
    switch (session.phase) {
      case TvPhase.playing:
        return l10n.tvStatusPlaying;
      case TvPhase.paused:
        return l10n.tvStatusPaused;
      case TvPhase.loading:
        return l10n.tvStatusLoading;
      default:
        return l10n.tvStatusReady;
    }
  }

  String _time(int seconds) {
    final d = Duration(seconds: seconds);
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final secs = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return d.inHours > 0 ? "${d.inHours}:$minutes:$secs" : "$minutes:$secs";
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final sessionValue = ref.watch(tvSessionStateProvider(widget.sessionId));

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: sessionValue.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => Padding(
            padding: const EdgeInsets.all(24),
            child: Text(l10n.tvSessionLost, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
          data: (session) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(Icons.cast_connected),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.recording.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleMedium),
                        Text(_status(l10n, session), style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ),
                  IconButton(icon: const Icon(Icons.link_off), tooltip: l10n.tvDisconnect, onPressed: _disconnect),
                ],
              ),
              const SizedBox(height: 8),
              if (session.error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    session.error!.code == TvErrorCode.unsupportedMedia ? l10n.tvErrorUnsupportedMedia : l10n.tvErrorPlayback,
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                ),
              if (_failure != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(_failure!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [Text(_time(session.position)), Text(_time(session.duration > 0 ? session.duration : widget.recording.duration))],
              ),
              LinearProgressIndicator(value: session.duration > 0 ? (session.position / session.duration).clamp(0.0, 1.0) : null),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    iconSize: 32,
                    icon: const Icon(Icons.replay_30),
                    tooltip: l10n.tvRewind,
                    onPressed: session.isLive ? () => _seekBy(-_step, session) : null,
                  ),
                  IconButton.filled(
                    iconSize: 40,
                    icon: Icon(session.isPlaying ? Icons.pause : Icons.play_arrow),
                    tooltip: session.isPlaying ? l10n.tvPause : l10n.tvPlay,
                    onPressed: session.isLive ? () => _run(TvCommand(type: session.isPlaying ? TvCommandType.pause : TvCommandType.resume)) : null,
                  ),
                  IconButton(
                    iconSize: 32,
                    icon: const Icon(Icons.forward_30),
                    tooltip: l10n.tvForward,
                    onPressed: session.isLive ? () => _seekBy(_step, session) : null,
                  ),
                  IconButton(
                    iconSize: 32,
                    icon: const Icon(Icons.stop),
                    tooltip: l10n.tvStop,
                    onPressed: session.isLive ? () => _run(TvCommand(type: TvCommandType.stop)) : null,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
