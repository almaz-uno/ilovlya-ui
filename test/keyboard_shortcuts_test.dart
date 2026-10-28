import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ilovlya/src/keyboard_shortcuts.dart';
import 'package:ilovlya/src/media/intents.dart';
import 'package:ilovlya/src/localization/app_localizations.dart';

void main() {
  testWidgets('list navigation keys work outside text fields and help opens',
      (tester) async {
    var moves = 0;
    final controller = TextEditingController();
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: ScreenShortcuts(
          shortcuts: const {
            SingleActivator(LogicalKeyboardKey.keyJ): SelectNextIntent(),
          },
          actions: {
            SelectNextIntent: CallbackAction<SelectNextIntent>(onInvoke: (_) {
              moves++;
              return null;
            }),
          },
          help: const [ShortcutHelpEntry('j / ↓', 'Select next recording')],
          child: Column(
            children: [
              TextField(controller: controller),
              TextButton(onPressed: () {}, child: const Text('List')),
            ],
          ),
        ),
      ),
    ));

    await tester.tap(find.byType(TextField));
    await tester.sendKeyEvent(LogicalKeyboardKey.keyJ, character: 'j');
    await tester.pump();
    expect(moves, 0);

    final listFocus = FocusNode(debugLabel: 'recordings list');
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: ScreenShortcuts(
          shortcuts: const {
            SingleActivator(LogicalKeyboardKey.keyJ): SelectNextIntent(),
          },
          actions: {
            SelectNextIntent: CallbackAction<SelectNextIntent>(onInvoke: (_) {
              moves++;
              return null;
            }),
          },
          help: const [ShortcutHelpEntry('j / ↓', 'Select next recording')],
          child: Focus(
              focusNode: listFocus, autofocus: true, child: const Text('List')),
        ),
      ),
    ));
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.keyJ, character: 'j');
    await tester.pump();
    expect(moves, 1);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.slash, character: '?');
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.pumpAndSettle();
    expect(find.text('Keyboard shortcuts'), findsOneWidget);
    expect(find.text('Select next recording'), findsOneWidget);
    listFocus.dispose();
    controller.dispose();
  });

  testWidgets('dialog Enter confirms and Escape cancels', (tester) async {
    var confirmations = 0;
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(builder: (context) {
        return Scaffold(
          body: TextButton(
            onPressed: () => showDialog<void>(
              context: context,
              builder: (context) => DialogShortcuts(
                child: AlertDialog(
                  actions: [
                    TextButton(
                      autofocus: true,
                      onPressed: () {
                        confirmations++;
                        Navigator.of(context).pop();
                      },
                      child: const Text('Confirm'),
                    ),
                  ],
                ),
              ),
            ),
            child: const Text('Open'),
          ),
        );
      }),
    ));

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(confirmations, 1);

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(confirmations, 1);
    expect(find.text('Confirm'), findsNothing);
  });
}
