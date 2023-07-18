import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ilovlya/src/api/api.dart';
import 'package:ilovlya/src/api/media.dart';
import 'package:ilovlya/src/media/download_details.dart';
import 'package:ilovlya/src/media/recording_play_view.dart';
import 'package:ilovlya/src/media/format.dart';
import 'package:ilovlya/src/model/download.dart';
import 'package:ilovlya/src/model/recording_info.dart';
import 'package:url_launcher/url_launcher_string.dart';

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
  List<Download>? _downloads;
  String? title;
  bool _isLoading = false;
  bool _isLoadingDownloads = false;
  StreamSubscription? _downloadsPullSubs;

  final _controllerTitle = TextEditingController();

  static const _downloadsPullPeriod = Duration(seconds: 3);

  @override
  void initState() {
    super.initState();
    setState(() {
      _futureRecording = _load(widget.id, false);
    });
    _loadDownloads(widget.id);
    _downloadsPullSubs = Stream.periodic(_downloadsPullPeriod).listen((event) {
      setState(() {
        _loadDownloads(widget.id);
        _pullRefresh();
      });
    });
  }

  @override
  void deactivate() {
    _downloadsPullSubs?.cancel();
    super.deactivate();
  }

  Future<RecordingInfo> _load(String id, bool updateFormats) async {
    try {
      setState(() {
        _isLoading = true;
      });
      return await getRecording(id, updateFormats: updateFormats);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  _loadDownloads(String recordingID) async {
    try {
      setState(() {
        _isLoadingDownloads = true;
      });
      _downloads = await listDownloads(recordingID);
    } finally {
      setState(() {
        _isLoadingDownloads = false;
      });
    }
  }

  Future<void> _pullRefresh({bool updateFormats = false}) async {
    setState(() {
      _futureRecording = _load(widget.id, updateFormats);
    });
  }

  @override
  Widget build(BuildContext context) {
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
        actions: [
          IconButton(
            icon: const Icon(Icons.copy),
            tooltip: 'Copy video URL to the clipboard',
            onPressed: () {
              _futureRecording!.then((recording) => copyToClipboard(context, recording.webpageUrl));
            },
          ),
          _addSeenButton(),
          _addHiddenButton(),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh record (reread from the server)',
            onPressed: () {
              _pullRefresh(updateFormats: true);
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          Visibility(visible: _isLoading, child: const LinearProgressIndicator()),
          RefreshIndicator(
            onRefresh: _pullRefresh,
            child: Scrollbar(
              thumbVisibility: true,
              interactive: true,
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: (_futureRecording == null) ? const Center(child: Text('loading...')) : _buildRecordings(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  FutureBuilder<RecordingInfo> _buildRecordings() {
    return FutureBuilder<RecordingInfo>(
        future: _futureRecording,
        builder: (BuildContext context, AsyncSnapshot<RecordingInfo> snapshot) {
          if (snapshot.hasData) {
            title = snapshot.data!.title;
            return _buildForm(context, snapshot.data!);
          } else if (snapshot.hasError) {
            return ErrorWidget(snapshot.error!);
          }

          return const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text('Media info acquiring in progress...'),
          );
        });
  }

  Widget _buildForm(BuildContext context, RecordingInfo recording) {
    return Column(
      children: [
        InkWell(
          onTap: () async {
            await launchUrlString(recording.webpageUrl);
          },
          onLongPress: () async {},
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    recording.extractor,
                    textScaleFactor: 1.5,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    recording.uploader,
                    textScaleFactor: 1.5,
                  ),
                  Text(
                    recording.title,
                  ),
                  Text(
                    recording.webpageUrl,
                    style: const TextStyle(
                      overflow: TextOverflow.fade,
                      decoration: TextDecoration.underline,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Center(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                Image.network(
                  server() + recording.thumbnailUrl,
                  fit: BoxFit.fill,
                  scale: 0.5,
                ),
                LinearProgressIndicator(
                  backgroundColor: const Color.fromARGB(127, 158, 158, 158),
                  value: recording.duration == 0 ? null : recording.position / recording.duration,
                ),
              ],
            ),
          ),
        ),
        Text("${formatDuration(Duration(seconds: recording.position))} / ${formatDuration(Duration(seconds: recording.duration))}"),
        (_downloads == null) ? const Text("Downloads info is loading...") : _downloadsTable(context),
        recording.formats == null || recording.formats!.isEmpty ? const Text("No formats for the record") : _formatsTable(context, recording),
      ],
    );
  }

  Widget _downloadsTable(BuildContext context) {
    var downloads = _downloads!;
    const splitter = LineSplitter();

    var rows = List<DataRow>.generate(downloads.length, (i) {
      var d = downloads[i];
      var ll = splitter.convert(d.progress);
      var pr = ll.isEmpty ? '' : ll[ll.length - 1];
      var hr = fileSizeHumanReadable(d.size);
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
              _recordView(context, d);
            } else if (d.status == "stale") {
              _startPreparation(context, d.formatId);
            }
          },
          Opacity(
            opacity: opacity,
            child: Tooltip(
              message: "${d.filename} tap to play in embedding player",
              child: Text(d.filename.replaceFirst(d.recordingId, "⏵⏵⏵")),
            ),
          ),
        ),
        DataCell(Opacity(opacity: opacity, child: Text(d.resolution))),
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
        DataCell(_buildActions(context, d)),
        DataCell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (BuildContext context) => DownloadDetailsView(download: d)),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Files for this recordings",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Scrollbar(
                  thumbVisibility: true,
                  interactive: true,
                  scrollbarOrientation: ScrollbarOrientation.bottom,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columnSpacing: 12,
                      columns: const [
                        DataColumn(label: Expanded(child: Text("file", style: headerStyle))),
                        DataColumn(label: Expanded(child: Text("resolution", style: headerStyle))),
                        DataColumn(label: Expanded(child: Text("", style: headerStyle))),
                        DataColumn(label: Expanded(child: Text("size", style: headerStyle))),
                        DataColumn(label: Expanded(child: Text("", style: headerStyle))),
                        DataColumn(label: Expanded(child: Text("", style: headerStyle))),
                      ],
                      rows: rows,
                    ),
                  ),
                ),
              ],
            ),
          );
  }

  Widget _formatsTable(BuildContext context, RecordingInfo recording) {
    List<DataRow> rows = [];

    for (int i = 0; i < recording.formats!.length; i++) {
      var f = recording.formats![i];
      rows.add(DataRow(
        cells: <DataCell>[
          DataCell(
            IconButton(
              onPressed: () {
                _startPreparation(context, "${f.id}+ba*");
                // _startPreparation(context, f.id);
              },
              tooltip: "Download this format and the best audio on the server (prepare for viewing)",
              icon: const Icon(Icons.file_download_outlined),
            ),
          ),
          DataCell(
            onTap: () {
              _startPreparation(context, f.id);
            },
            Tooltip(
              message: "Download exact this format (prepare this format for viewing)",
              child: Text(f.id),
            ),
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

  Future<void> _startPreparation(BuildContext context, String format) async {
    newDownload(widget.id, format).then((d) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: Theme.of(context).colorScheme.background,
        content: Text('Preparation for ${d.formatId} is starting'),
      ));
    }).catchError((err) {
      showDialog(
          context: context,
          barrierDismissible: true,
          builder: (BuildContext context) => Dialog(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(err.toString()),
                ),
              ));
    });
  }

  void _recordView(BuildContext context, Download d) {
    _futureRecording!.then((r) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (BuildContext context) => RecordingView(recording: r, download: d)),
      );
    });
  }

  Widget _buildActions(BuildContext context, Download d) {
    switch (d.status) {
      case "stale":
        return IconButton(
          onPressed: () {
            _startPreparation(context, d.formatId);
          },
          tooltip: "Download this format again on the server (prepare for viewing)",
          icon: const Icon(Icons.file_download_outlined),
        );
      case "new":
      case "in_progress":
        return const Center(child: Icon(Icons.downloading));
      case "ready":
        return Row(
          children: [
            IconButton(
              onPressed: () {
                copyToClipboard(context, d.url);
              },
              tooltip: "Copy file link to clipboard",
              icon: const Icon(Icons.copy_rounded),
            ),
            // IconButton(
            //   onPressed: () {
            //     _recordView(context, d);
            //   },
            //   tooltip: "Play in embedded player",
            //   icon: const Icon(Icons.play_arrow),
            // ),
            IconButton(
              onPressed: () {
                launchUrlString(d.url);
              },
              tooltip: "Open in default application",
              icon: const Icon(Icons.open_in_browser),
            ),
          ],
        );
      default:
        return ErrorWidget("Unexpected download status ${d.status}");
    }
  }

  Widget _addSeenButton() {
    return FutureBuilder<RecordingInfo>(
      future: _futureRecording,
      builder: (BuildContext context, AsyncSnapshot<RecordingInfo> snapshot) {
        if (snapshot.hasData && snapshot.data!.seenAt == null) {
          return IconButton(
            icon: const Icon(Icons.check_box_outline_blank_rounded),
            tooltip: 'Mark this recording as seen',
            onPressed: () async {
              await setSeen(snapshot.data!.id);
              _pullRefresh();
            },
          );
        } else if (snapshot.hasData && snapshot.data!.seenAt != null) {
          return IconButton(
            icon: const Icon(Icons.check_box_outlined),
            tooltip: 'Mark this recording as unseen',
            onPressed: () async {
              await unsetSeen(snapshot.data!.id);
              _pullRefresh();
            },
          );
        } else {
          return const SizedBox();
        }
      },
    );
  }

  Widget _addHiddenButton() {
    return FutureBuilder<RecordingInfo>(
      future: _futureRecording,
      builder: (BuildContext context, AsyncSnapshot<RecordingInfo> snapshot) {
        if (snapshot.hasData && snapshot.data!.hiddenAt == null) {
          return IconButton(
            icon: const Icon(Icons.visibility_outlined),
            tooltip: 'Hide this recording (archive it)',
            onPressed: () async {
              await setHidden(snapshot.data!.id);
              _pullRefresh();
            },
          );
        } else if (snapshot.hasData && snapshot.data!.hiddenAt != null) {
          return IconButton(
            icon: const Icon(Icons.visibility_off_outlined),
            tooltip: 'Show this recording (unarchive it)',
            onPressed: () async {
              await unsetHidden(snapshot.data!.id);
              _pullRefresh();
            },
          );
        } else {
          return const SizedBox();
        }
      },
    );
  }
}

void copyToClipboard(BuildContext context, String textData) {
  Clipboard.setData(ClipboardData(text: textData)).then((value) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      backgroundColor: Theme.of(context).colorScheme.background,
      content: Text('$textData copied to clipboard'),
    ));
  });
}
