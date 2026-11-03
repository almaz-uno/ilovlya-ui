import 'package:flutter/material.dart';

import '../localization/app_localizations.dart';
import '../model/local_download.dart';
import '../utils/task_status_localization.dart';
import 'format.dart';

/// The figures of a local download on a line of their own: `63% · ≈ 11.86 MB/s · ETA 00:11`. A part that is not known
/// is left out with its separator; the line is empty when none is. A download whose server does not answer shows that
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
        LinearProgressIndicator(value: progress != null && progress >= 0 ? progress : null, minHeight: 2),
      ],
    );
  }
}
