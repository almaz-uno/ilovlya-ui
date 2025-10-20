import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:background_downloader/background_downloader.dart';
import 'package:ilovlya/src/utils/task_status_localization.dart';
import 'package:ilovlya/src/localization/app_localizations.dart';

void main() {
  group('TaskStatusLocalization tests', () {
    testWidgets('should return localized status for English', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: Builder(
            builder: (context) {
              final l10n = AppLocalizations.of(context)!;

              // Test different task statuses
              expect(TaskStatusLocalization.getLocalizedStatus(TaskStatus.enqueued, l10n), 'enqueued');
              expect(TaskStatusLocalization.getLocalizedStatus(TaskStatus.running, l10n), 'running');
              expect(TaskStatusLocalization.getLocalizedStatus(TaskStatus.complete, l10n), 'complete');
              expect(TaskStatusLocalization.getLocalizedStatus(TaskStatus.failed, l10n), 'failed');
              expect(TaskStatusLocalization.getLocalizedStatus(TaskStatus.canceled, l10n), 'canceled');
              expect(TaskStatusLocalization.getLocalizedStatus(TaskStatus.notFound, l10n), 'not found');
              expect(TaskStatusLocalization.getLocalizedStatus(TaskStatus.waitingToRetry, l10n), 'waiting to retry');
              expect(TaskStatusLocalization.getLocalizedStatus(TaskStatus.paused, l10n), 'paused');

              return Container();
            },
          ),
        ),
      );
    });

    testWidgets('should return localized status for Russian', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('ru'),
          home: Builder(
            builder: (context) {
              final l10n = AppLocalizations.of(context)!;

              // Test different task statuses in Russian
              expect(TaskStatusLocalization.getLocalizedStatus(TaskStatus.enqueued, l10n), 'в очереди');
              expect(TaskStatusLocalization.getLocalizedStatus(TaskStatus.running, l10n), 'выполняется');
              expect(TaskStatusLocalization.getLocalizedStatus(TaskStatus.complete, l10n), 'завершена');
              expect(TaskStatusLocalization.getLocalizedStatus(TaskStatus.failed, l10n), 'завершилась с ошибкой');
              expect(TaskStatusLocalization.getLocalizedStatus(TaskStatus.canceled, l10n), 'отменена');
              expect(TaskStatusLocalization.getLocalizedStatus(TaskStatus.notFound, l10n), 'не найдена');
              expect(TaskStatusLocalization.getLocalizedStatus(TaskStatus.waitingToRetry, l10n), 'ожидает повтора');
              expect(TaskStatusLocalization.getLocalizedStatus(TaskStatus.paused, l10n), 'приостановлена');

              return Container();
            },
          ),
        ),
      );
    });

    testWidgets('should provide fallback for getLocalizedStatusWithFallback', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: Builder(
            builder: (context) {
              final l10n = AppLocalizations.of(context)!;

              // Test fallback behavior
              String result = TaskStatusLocalization.getLocalizedStatusWithFallback(TaskStatus.running, l10n);
              expect(result, 'running'); // Should return localized string, or fallback to cleaned enum name

              return Container();
            },
          ),
        ),
      );
    });
  });
}
