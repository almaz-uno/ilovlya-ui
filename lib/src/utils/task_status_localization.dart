import 'package:background_downloader/background_downloader.dart';
import '../localization/app_localizations.dart';

/// Localizes TaskStatus enum values to user-friendly strings
class TaskStatusLocalization {
  /// Returns localized string for a TaskStatus
  static String getLocalizedStatus(TaskStatus status, AppLocalizations l10n) {
    switch (status) {
      case TaskStatus.enqueued:
        return l10n.taskStatusEnqueued;
      case TaskStatus.running:
        return l10n.taskStatusRunning;
      case TaskStatus.complete:
        return l10n.taskStatusComplete;
      case TaskStatus.notFound:
        return l10n.taskStatusNotFound;
      case TaskStatus.failed:
        return l10n.taskStatusFailed;
      case TaskStatus.canceled:
        return l10n.taskStatusCanceled;
      case TaskStatus.waitingToRetry:
        return l10n.taskStatusWaitingToRetry;
      case TaskStatus.paused:
        return l10n.taskStatusPaused;
    }
  }

  /// Returns localized string with fallback to original enum name
  static String getLocalizedStatusWithFallback(TaskStatus status, AppLocalizations l10n) {
    try {
      return getLocalizedStatus(status, l10n);
    } catch (e) {
      // Fallback to enum name without prefix if localization is missing
      final enumString = status.toString();
      const prefix = "TaskStatus.";
      return enumString.startsWith(prefix)
          ? enumString.replaceFirst(prefix, "")
          : enumString;
    }
  }
}
