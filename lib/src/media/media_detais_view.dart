import 'package:flutter/material.dart';
import 'package:ilovlya/src/api/api.dart';
import 'package:ilovlya/src/api/media.dart';
import 'package:ilovlya/src/media/media_add_view.dart';
import 'package:ilovlya/src/media/misc.dart';
import 'package:ilovlya/src/model/recording_info.dart';

class MediaDetailsView extends StatefulWidget {
  const MediaDetailsView({
    super.key,
    this.id = "",
  });
  final String id;

  static String routeName(String id) {
    return "/$pathRecordings/$id";
  }

  @override
  State<MediaDetailsView> createState() => _MediaDetailsViewState();
}

class _MediaDetailsViewState extends State<MediaDetailsView> {
  Future<RecordingInfo>? _futureRecording;
  String? title;

  final _controllerTitle = TextEditingController();

  @override
  void initState() {
    super.initState();
    setState(() {
      _futureRecording = getRecording(widget.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.id == "") {
      Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false);
    }
    return Scaffold(
      appBar: AppBar(
        title: (_futureRecording == null)
            ? const Text('Recording info...')
            : FutureBuilder<RecordingInfo>(
                future: _futureRecording,
                builder: (BuildContext context, AsyncSnapshot<RecordingInfo> snapshot) {
                  _controllerTitle.text = snapshot.data?.title ?? "Recording...";
                  return Theme(
                    data: ThemeData(
                      textSelectionTheme: const TextSelectionThemeData(
                        selectionColor: Colors.amber,
                        cursorColor: Colors.amber,
                      ),
                    ),
                    child: TextField(
                      controller: _controllerTitle,
                      decoration: const InputDecoration(),
                      style: TextStyle(color: Theme.of(context).primaryTextTheme.titleSmall!.color),
                    ),
                  );
                }),
      ),
      body: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: (_futureRecording == null) ? const Text('loading...') : buildRecordings(),
      ),
    );
  }

  FutureBuilder<RecordingInfo> buildRecordings() {
    return FutureBuilder<RecordingInfo>(
        future: _futureRecording,
        builder: (BuildContext context, AsyncSnapshot<RecordingInfo> snapshot) {
          if (snapshot.hasData) {
            title = snapshot.data!.title;
            return buildForm(context, snapshot.data!);
          } else if (snapshot.hasError) {
            return ErrorWidget(snapshot.error!);
          }

          return const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text('Media info acquiring in progress...'),
          );
        });
  }

  Widget buildForm(BuildContext context, RecordingInfo recording) {
    return Column(
      children: [
        Center(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Image.network(
              recording.thumbnailDataUrl == null ? noImage : recording.thumbnailDataUrl!,
              fit: BoxFit.fill,
              scale: 0.5,
            ),
          ),
        ),
        Text("${recording.title} • ${printDuration(Duration(seconds: recording.position))} / ${printDuration(Duration(seconds: recording.duration))}"),
        recording.formats == null || recording.formats!.isEmpty ? const Text("No formats for the record") : formatsTable(context, recording),
      ],
    );
  }

  Widget formatsTable(BuildContext context, RecordingInfo recording) {
    List<TableRow> rows = [];

    for (int i = 0; i < recording.formats!.length; i++) {
      var item = recording.formats![i];
      rows.add(TableRow(
        children: [
          Container(
            margin: const EdgeInsets.all(8.0),
            child: Text(item.id, textScaleFactor: 2),
          ),
          Container(
            margin: const EdgeInsets.all(8.0),
            child: Text(item.ext, textScaleFactor: 2),
          ),
          Container(
            margin: const EdgeInsets.all(8.0),
            child: Text(item.resolution, textScaleFactor: 2),
          ),
          Container(
            margin: const EdgeInsets.all(4.0),
            child: item.hasAudio ? const Icon(Icons.audio_file_outlined) : const SizedBox.shrink(),
          ),
          Container(
            margin: const EdgeInsets.all(4.0),
            child: item.hasVideo ? const Icon(Icons.video_file_outlined) : const SizedBox.shrink(),
          ),
          Container(
            margin: const EdgeInsets.all(4.0),
            child: IconButton(
              icon: const Icon(Icons.download),
              tooltip: "Download format and best audio if already not presented",
              onPressed: () {
                print("pressed on ${recording.id}+${item.id}");
              },
            ),
          ),
          Container(
            margin: const EdgeInsets.all(4.0),
            child: IconButton(
              icon: const Icon(Icons.download_outlined),
              tooltip: "Don't force download best audio",
              onPressed: () {
                print("pressed on ${recording.id}+${item.id} / wo ba");
              },
            ),
          ),
          Container(
            margin: const EdgeInsets.all(4.0),
            child: IconButton(
              icon: const Icon(Icons.info_outline_rounded),
              tooltip: "Show additional download info in the separate dialog window",
              onPressed: () {
                print("pressed on ${recording.id}+${item.id}");
              },
            ),
          ),
        ],
      ));
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Table(
        // border: TableBorder.symmetric(inside: const BorderSide()),
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        columnWidths: const {
          0: IntrinsicColumnWidth(),
          1: IntrinsicColumnWidth(),
          2: IntrinsicColumnWidth(),
          3: IntrinsicColumnWidth(),
          4: IntrinsicColumnWidth(),
          5: IntrinsicColumnWidth(),
          6: IntrinsicColumnWidth(),
          7: IntrinsicColumnWidth(),
        },
        children: rows,
      ),
    );
  }
}
