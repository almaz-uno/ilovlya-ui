import 'dart:ui';
import 'package:flutter/material.dart';
import 'localization/app_localizations.dart';

class BlurryDialog extends StatelessWidget {

  final String title;
  final String content;
  final VoidCallback _commitCallback;

  const BlurryDialog(this.title, this.content, this._commitCallback, {super.key});

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
      child:  AlertDialog(
      title: Text(title),
      content: Text(content),
      actions: <Widget>[
        TextButton(
          child: Text(AppLocalizations.of(context)!.continueButton),
           onPressed: () {
            _commitCallback();
          },
        ),
        TextButton(
          child: Text(AppLocalizations.of(context)!.cancel),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ],
      ));
  }
}

void confirmDialog(BuildContext context, String title, String message, void Function() commitCallback) async {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return BlurryDialog(title, message, commitCallback);
    },
  );
}
