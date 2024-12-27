import 'dart:ui';
import 'package:flutter/material.dart';

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
          child: const Text("Continue"),
           onPressed: () {
            _commitCallback();
          },
        ),
        TextButton(
          child: const Text("Cancel"),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ],
      ));
  }
}
