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

  const DownloadsTable({
    super.key,
    required this.recording,
    required this.downloads,
    required this.recordView,
    required this.startPreparation,
    required this.buildActions,
  });

  // Cell padding mimicking DataTable's columnSpacing: 12 (~6px per side).
  static Widget _cell(Widget child) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 8.0),
        child: child,
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (downloads.isEmpty) {
      return Text(
        AppLocalizations.of(context)!.noDownloadsForRecording,
        style: const TextStyle(fontStyle: FontStyle.italic),
      );
    }

    const splitter = LineSplitter();
    const headerStyle = TextStyle(fontStyle: FontStyle.italic, fontWeight: FontWeight.bold);
    final l10n = AppLocalizations.of(context)!;

    // Header row (7 columns; some are visually blank like in the old DataTable).
    final rows = <TableRow>[
      TableRow(children: [
        _cell(Text(l10n.formatHeader, style: headerStyle)),
        _cell(const Text("", style: headerStyle)),
        _cell(Text(l10n.resolutionHeader, style: headerStyle)),
        _cell(Text(l10n.fpsHeader, style: headerStyle)),
        _cell(const Text("", style: headerStyle)),
        _cell(Text(l10n.sizeHeader, style: headerStyle)),
        _cell(const Text("", style: headerStyle)),
      ]),
    ];

    for (final d in downloads) {
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

      // Use color opacity instead of Opacity widget for better performance.
      final textColor = Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: opacity) ?? Colors.black.withValues(alpha: opacity);
      final iconColor = Theme.of(context).iconTheme.color?.withValues(alpha: opacity) ?? Colors.black.withValues(alpha: opacity);
      final textStyle = TextStyle(color: textColor);

      rows.add(TableRow(children: [
        _cell(InkWell(
          onTap: () {
            if (d.status == "ready") {
              recordView(context, recording, d);
            } else if (d.status == "stale") {
              startPreparation(context, d.formatId);
            }
          },
          child: Tooltip(
            message: l10n.tapToPlayInEmbeddingPlayer(d.filename),
            child: Text(d.formatId, style: textStyle),
          ),
        )),
        _cell(buildActions(context, recording, d)),
        _cell(Text(d.resolution, style: textStyle)),
        _cell(Text(d.fps != null ? "${d.fps}" : "", style: textStyle)),
        _cell(Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (d.hasAudio) Icon(Icons.audiotrack_rounded, color: iconColor),
            if (d.hasVideo) Icon(Icons.videocam_rounded, color: iconColor),
          ],
        )),
        _cell(Text(d.size == 0 ? '' : hr, style: textStyle)),
        _cell(InkWell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (BuildContext context) => DownloadDetailsView(downloadId: d.id)),
            );
          },
          child: Text(pr, style: textStyle),
        )),
      ]));
    }

    // RepaintBoundary: once rasterized, the table is cached as a layer and is
    // not re-rasterized on unrelated repaints (progress bar ticking, etc.).
    return RepaintBoundary(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.filesForThisRecording,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              // Raw Table instead of DataTable: no per-cell Material/InkWell
              // machinery and no heading infrastructure — much cheaper to build
              // and raster. IntrinsicColumnWidth keeps content-sized columns so
              // the horizontal scroll still works for wide content.
              Table(
                defaultColumnWidth: const IntrinsicColumnWidth(),
                defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                border: TableBorder(
                  horizontalInside: BorderSide(width: 1, color: Theme.of(context).dividerColor),
                ),
                children: rows,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
