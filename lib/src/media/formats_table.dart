import 'package:flutter/material.dart';

import '../model/recording_info.dart';
import 'media_details.dart';

const downloadFormatIcon = Icon(Icons.start);
const copyURLIcon = Icon(Icons.copy);

class FormatsTable extends StatelessWidget {
  final RecordingInfo recording;
  final void Function(BuildContext, String) startPreparation;

  const FormatsTable({
    super.key,
    required this.recording,
    required this.startPreparation,
  });

  @override
  Widget build(BuildContext context) {
    List<DataRow> rows = [];

    for (int i = 0; i < recording.formats!.length; i++) {
      var f = recording.formats![i];
      rows.add(DataRow(
        cells: <DataCell>[
          DataCell(
            IconButton(
              onPressed: () {
                startPreparation(context, "${f.id}+ba");
              },
              tooltip: "Download this format and the best audio on the server (prepare for viewing)",
              icon: downloadFormatIcon,
            ),
          ),
          DataCell(
            onTap: () {
              startPreparation(context, f.id);
            },
            Tooltip(
              message: "Download exact this format (prepare this format for viewing)",
              child: Text(f.id),
            ),
          ),
          DataCell(
            f.url != ""
                ? IconButton(
                    onPressed: () {
                      copyToClipboard(context, f.url);
                    },
                    tooltip: "Copy URL this fragment into clipboard",
                    icon: copyURLIcon,
                  )
                : const SizedBox.shrink(),
          ),
          DataCell(Text(f.ext)),
          DataCell(Text(f.resolution)),
          DataCell(Visibility(visible: f.fps != 0, child: Text("${f.fps}"))),
          DataCell(Visibility(visible: f.hasAudio, child: const Icon(Icons.audiotrack_rounded))),
          DataCell(Visibility(visible: f.hasVideo, child: const Icon(Icons.videocam_rounded))),
        ],
      ));
    }

    const headerStyle = TextStyle(
      fontStyle: FontStyle.italic,
      fontWeight: FontWeight.bold,
    );

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Common available formats:",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          TextButton.icon(
            onPressed: () {
              startPreparation(context, "ba");
            },
            icon: const Icon(Icons.audiotrack_rounded),
            label: const Text("Best audio (ba)"),
          ),
          const Text(
            "Available formats:",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columnSpacing: 12,
              columns: const <DataColumn>[
                DataColumn(label: Expanded(child: Text("", style: headerStyle))),
                DataColumn(label: Expanded(child: Text("id", style: headerStyle))),
                DataColumn(label: Expanded(child: Text("URL", style: headerStyle))),
                DataColumn(label: Expanded(child: Text("ext", style: headerStyle))),
                DataColumn(label: Expanded(child: Text("resolution", style: headerStyle))),
                DataColumn(label: Expanded(child: Text("fps", style: headerStyle))),
                DataColumn(label: Expanded(child: Text("", style: headerStyle))),
                DataColumn(label: Expanded(child: Text("", style: headerStyle))),
              ],
              rows: rows,
            ),
          ),
        ],
      ),
    );
  }
}
