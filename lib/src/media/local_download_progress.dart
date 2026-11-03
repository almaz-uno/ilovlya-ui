import 'package:background_downloader/background_downloader.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../localization/app_localizations.dart';
import '../model/local_download.dart';
import '../playback_download/playback_downloads.dart';
import '../utils/task_status_localization.dart';
import 'format.dart';

/// The figures of a local download on a line of their own: `63% · ≈ 11.86 MB/s · ETA 00:11`. A part that is not known
/// is left out with its separator; the line is empty when none is. A negative progress, speed or time remaining is
/// background_downloader's code for a state, not a figure, and is left out too. A download whose server does not answer shows that
/// instead of the speed and the time remaining, which say nothing then (#213).
String localDownloadFigures(AppLocalizations l10n, LocalDownloadTask task, {Duration? notAnsweringFor}) {
  final progress = task.progress;
  final speed = task.networkSpeed;
  final eta = task.timeRemaining;
  return [
    if (progress != null && progress >= 0) '${(progress * 100).round()}%',
    if (notAnsweringFor != null)
      l10n.playbackDownloadNoAnswer(formatDuration(notAnsweringFor))
    else ...[
      if (speed != null && speed >= 0) l10n.localDownloadSpeed(speed.toStringAsFixed(2)),
      if (eta != null && !eta.isNegative) l10n.localDownloadEta(formatDuration(eta)),
    ],
  ].join(' · ');
}

/// A local download as the player and the recording's screen show it: its status, its file, its figures and a bar.
class LocalDownloadProgress extends StatelessWidget {
  const LocalDownloadProgress({super.key, required this.task, this.notAnsweringFor});

  final LocalDownloadTask task;

  /// How long the server of a playback download waiting to retry has not answered; `null` otherwise.
  final Duration? notAnsweringFor;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final style = Theme.of(context).textTheme.bodySmall;
    final status = task.status == null ? '' : TaskStatusLocalization.getLocalizedStatusWithFallback(task.status!, l10n);
    final figures = localDownloadFigures(l10n, task, notAnsweringFor: notAnsweringFor);
    final progress = task.progress;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(l10n.localDownloadHeader(status), style: style),
        Text(task.filename, style: style),
        if (figures.isNotEmpty) Text(figures, style: style),
        const SizedBox(height: 4),
        // Running without a value only while the progress is not known yet. A negative one is background_downloader's
        // code for a state (failed, canceled, not found, waiting to retry, paused), which has replaced the last value:
        // the bar stands, empty, as it did before, rather than run as if the download went on.
        LinearProgressIndicator(value: progress == null ? null : (progress < 0 ? 0.0 : progress), minHeight: 2),
      ],
    );
  }
}

/// A local download under the player. A playback download waiting to retry also tells how long its server has not
/// answered.
class PlayerDownloadProgress extends ConsumerWidget {
  const PlayerDownloadProgress({super.key, required this.task, required this.downloadId, required this.playbackDownload});

  final LocalDownloadTask task;
  final String downloadId;

  /// Whether the player reads [downloadId] while it arrives, from a playback download.
  final bool playbackDownload;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final failing = playbackDownload && task.status == TaskStatus.waitingToRetry ? ref.read(playbackDownloadsProvider.notifier).notAnsweringFor(downloadId) : null;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: LocalDownloadProgress(task: task, notAnsweringFor: failing),
    );
  }
}
