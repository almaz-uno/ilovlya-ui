import 'dart:convert';
import 'package:flutter/material.dart';
import '../model/download.dart';
import '../model/recording_info.dart';
import 'download_details.dart';
import 'format.dart';

class DownloadsTable extends StatelessWidget {
  final RecordingInfo recording;
  final List<Download> downloads;
  final void Function(BuildContext, RecordingInfo, Download) recordView;
  final void Function(BuildContext, String) startPreparation;
  final Widget Function(BuildContext, RecordingInfo, Download) buildActions;
  final Widget Function(BuildContext, RecordingInfo, Download) buildLocalActions;

  const DownloadsTable({
    super.key,
    required this.recording,
    required this.downloads,
    required this.recordView,
    required this.startPreparation,
    required this.buildActions,
    required this.buildLocalActions,
  });

  @override
  Widget build(BuildContext context) {
    const splitter = LineSplitter();

    var rows = List<DataRow>.generate(downloads.length, (i) {
      final d = downloads[i];
      final ll = splitter.convert(d.progress);
      final pr = ll.isEmpty ? '' : ll[ll.length - 1];
      final hr = fileSizeHumanReadable(d.size);
      var opacity = 0.25;
      switch (d.status) {
        case "stale":
          opacity = 0.5;
        case "new":
        case "in_progress":
          opacity = 0.75;
        case "ready":
          opacity = 1.0;
      }

      return DataRow(cells: [
        DataCell(
          onTap: () {
            if (d.status == "ready") {
              recordView(context, recording, d);
            } else if (d.status == "stale") {
              startPreparation(context, d.formatId);
            }
          },
          Opacity(
            opacity: opacity,
            child: Tooltip(
              message: "${d.filename} tap to play in embedding player",
              child: Text(d.formatId),
            ),
          ),
        ),
        DataCell(Row(
          children: [
            buildActions(context, recording, d),
            buildLocalActions(context, recording, d),
          ],
        )),
        DataCell(Opacity(opacity: opacity, child: Text(d.resolution))),
        DataCell(Opacity(opacity: opacity, child: Text(d.fps != null ? "${d.fps}" : ""))),
        DataCell(Opacity(
          opacity: opacity,
          child: Row(
            children: [
              Visibility(visible: d.hasAudio, child: const Icon(Icons.audiotrack_rounded)),
              Visibility(visible: d.hasVideo, child: const Icon(Icons.videocam_rounded)),
            ],
          ),
        )),
        DataCell(Opacity(opacity: opacity, child: Text(d.size == 0 ? '' : hr))),
        DataCell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (BuildContext context) => DownloadDetailsView(downloadId: d.id)),
            );
          },
          Opacity(opacity: opacity, child: Text(pr)),
        ),
      ]);
    });

    const headerStyle = TextStyle(
      fontStyle: FontStyle.italic,
      fontWeight: FontWeight.bold,
    );

    return downloads.isEmpty
        ? const Text(
            "No downloads for recording",
            style: TextStyle(fontStyle: FontStyle.italic),
          )
        : Padding(
            padding: const EdgeInsets.all(8.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Files for this recording",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  DataTable(
                    columnSpacing: 12,
                    columns: const [
                      DataColumn(label: Expanded(child: Text("format", style: headerStyle))),
                      DataColumn(label: Expanded(child: Text("", style: headerStyle))),
                      DataColumn(label: Expanded(child: Text("resolution", style: headerStyle))),
                      DataColumn(label: Expanded(child: Text("fps", style: headerStyle))),
                      DataColumn(label: Expanded(child: Text("", style: headerStyle))),
                      DataColumn(label: Expanded(child: Text("size", style: headerStyle))),
                      DataColumn(label: Expanded(child: Text("", style: headerStyle))),
                    ],
                    rows: rows,
                  ),
                ],
              ),
            ),
          );
  }
}
