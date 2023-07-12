import 'package:flutter/material.dart';
import 'package:ilovlya/src/model/download.dart';

class DownloadDetailsView extends StatelessWidget {
  const DownloadDetailsView({
    super.key,
    required this.download,
  });

  final Download download;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(download.filename.replaceFirst(download.recordingId, "***"))),
      body: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Text(
            softWrap: false,
            download.progress,
          ),
        ),
      ),
    );
  }
}
