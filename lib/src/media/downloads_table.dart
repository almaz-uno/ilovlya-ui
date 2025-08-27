import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../localization/app_localizations.dart';
import '../model/download.dart';
import '../model/recording_info.dart';
import 'download_details.dart';
import 'format.dart';

class DownloadsTable extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
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
              message: AppLocalizations.of(context)!.tapToPlayInEmbeddingPlayer(d.filename),
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
        ? Text(
            AppLocalizations.of(context)!.noDownloadsForRecording,
            style: const TextStyle(fontStyle: FontStyle.italic),
          )
        : Padding(
            padding: const EdgeInsets.all(8.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!.filesForThisRecording,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  DataTable(
                    columnSpacing: 12,
                    columns: [
                      DataColumn(label: Expanded(child: Text(AppLocalizations.of(context)!.formatHeader, style: headerStyle))),
                      const DataColumn(label: Expanded(child: Text("", style: headerStyle))),
                      DataColumn(label: Expanded(child: Text(AppLocalizations.of(context)!.resolutionHeader, style: headerStyle))),
                      DataColumn(label: Expanded(child: Text(AppLocalizations.of(context)!.fpsHeader, style: headerStyle))),
                      const DataColumn(label: Expanded(child: Text("", style: headerStyle))),
                      DataColumn(label: Expanded(child: Text(AppLocalizations.of(context)!.sizeHeader, style: headerStyle))),
                      const DataColumn(label: Expanded(child: Text("", style: headerStyle))),
                    ],
                    rows: rows,
                  ),
                ],
              ),
            ),
          );
  }
}
