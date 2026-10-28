import 'dart:ui';
import 'package:flutter/material.dart';
import 'localization/app_localizations.dart';
import 'keyboard_shortcuts.dart';

class BlurryDialog extends StatelessWidget {
  final String title;
  final String content;
  final VoidCallback _commitCallback;

  const BlurryDialog(this.title, this.content, this._commitCallback,
      {super.key});

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
      child: DialogShortcuts(
        child: AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: <Widget>[
            TextButton(
              autofocus: isDesktopKeyboardPlatform,
              onPressed: _commitCallback,
              child: Text(AppLocalizations.of(context)!.continueButton),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(AppLocalizations.of(context)!.cancel),
            ),
          ],
        ),
      ),
    );
  }
}

void confirmDialog(BuildContext context, String title, String message,
    void Function() commitCallback) async {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return BlurryDialog(title, message, commitCallback);
    },
  );
}
