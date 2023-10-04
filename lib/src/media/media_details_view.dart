import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ilovlya/src/api/api.dart';
import 'package:ilovlya/src/api/media.dart';
import 'package:ilovlya/src/media/download_details.dart';
import 'package:ilovlya/src/media/media_kit/recording_play_view_media_kit.dart';
import 'package:ilovlya/src/media/media_kit/recording_play_view_media_kit_handler.dart';
import 'package:ilovlya/src/media/recording_play_view.dart';
import 'package:ilovlya/src/media/format.dart';
import 'package:ilovlya/src/model/download.dart';
import 'package:ilovlya/src/model/recording_info.dart';
import 'package:url_launcher/url_launcher_string.dart';

class MediaDetailsView extends StatefulWidget {
  const MediaDetailsView({
    super.key,
    this.id = "",
    this.play = false,
  });
  final String id;
  final bool play;

  static String routeName(String id, {bool play = false}) {
    String routeName = "/$pathRecordings/$id";
    if (play) {
      routeName += "?play";
    }
    return routeName;
  }

  @override
  State<MediaDetailsView> createState() => _MediaDetailsViewState();
}

class _MediaDetailsViewState extends State<MediaDetailsView> {
  Future<RecordingInfo>? _futureRecording;
  List<Download>? _downloads;
  String? title;
  bool _isLoading = false;
  bool _shouldPlay = false;
  StreamSubscription? _downloadsPullSubs;

  static const _downloadsPullPeriod = Duration(seconds: 3);

  @override
  void initState() {
    super.initState();
    _shouldPlay = widget.play;
    setState(() {
      _futureRecording = _load(widget.id, false);
    });

    _loadDownloads(widget.id);

    _downloadsPullSubs = Stream.periodic(_downloadsPullPeriod).listen((event) {
      _loadDownloads(widget.id);
      _pullRefresh();
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

      var r = await getRecording(id, updateFormats: updateFormats);
      r.thumbnailUrl = server() + r.thumbnailUrl;
      return r;
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  (Download? ready, Download? stale) _findAppropriateDownloads() {
    if (_downloads == null) {
      return (null, null);
    }
    Download? ready;
    Download? stale;
    for (var d in _downloads!) {
      if (d.updatedAt == null) {
        continue;
      }
      if ((ready == null || d.updatedAt!.isAfter(ready.updatedAt!)) &&
          d.status == "ready") {
        ready = d;
      }
      if ((stale == null || d.updatedAt!.isAfter(stale.updatedAt!)) &&
          d.status == "stale") {
        stale = d;
      }
    }

    return (ready, stale);
  }

  _loadDownloads(String recordingID) async {
    _downloads = await listDownloads(recordingID);

    for (var d in _downloads!) {
      d.url = serverURL(d.url);
    }
    var (ready, _) = _findAppropriateDownloads();
    if (mounted && ready != null && _shouldPlay && _futureRecording != null) {
      _recordView(context, await _futureRecording!, ready);
      _shouldPlay = false;
    }
    setState(() {});
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
                builder: (BuildContext context,
                    AsyncSnapshot<RecordingInfo> snapshot) {
                  return Text(snapshot.data?.title ?? "Recording...");
                }),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy),
            tooltip: 'Copy video URL to the clipboard',
            onPressed: () {
              _futureRecording!.then((recording) =>
                  copyToClipboard(context, recording.webpageUrl));
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
          Visibility(
              visible: _isLoading, child: const LinearProgressIndicator()),
          RefreshIndicator(
            onRefresh: _pullRefresh,
            child: Scrollbar(
              thumbVisibility: true,
              interactive: true,
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: (_futureRecording == null)
                    ? const Center(child: Text('loading...'))
                    : _buildRecordings(),
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
            child: InkWell(
              onTap: () {
                var (ready, stale) = _findAppropriateDownloads();
                if (ready != null) {
                  _recordView(context, recording, ready);
                } else if (stale != null) {
                  _startPreparation(context, stale.formatId);
                }
              },
              child: Column(
                children: [
                  Image.network(
                    recording.thumbnailUrl,
                    height: MediaQuery.of(context).size.height * 0.5,
                    // fit: BoxFit.fill,
                    // scale: 0.5,
                  ),
                  LinearProgressIndicator(
                    backgroundColor: const Color.fromARGB(127, 158, 158, 158),
                    value: recording.duration == 0
                        ? null
                        : recording.position / recording.duration,
                  ),
                ],
              ),
            ),
          ),
        ),
        Text(
            "${formatDuration(Duration(seconds: recording.position))} / ${formatDuration(Duration(seconds: recording.duration))}"),
        (_downloads == null)
            ? const Text("Downloads info is loading...")
            : _downloadsTable(context, recording),
        recording.formats == null || recording.formats!.isEmpty
            ? const Text("No formats for the record")
            : _formatsTable(context, recording),
      ],
    );
  }

  Widget _downloadsTable(BuildContext context, RecordingInfo recording) {
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
              _recordView(context, recording, d);
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
        DataCell(_buildActions(context, recording, d)),
        DataCell(Opacity(opacity: opacity, child: Text(d.resolution))),
        DataCell(Opacity(
            opacity: opacity, child: Text(d.fps != null ? "${d.fps}" : ""))),
        DataCell(Opacity(
          opacity: opacity,
          child: Row(
            children: [
              Visibility(
                  visible: d.hasAudio,
                  child: const Icon(Icons.audiotrack_rounded)),
              Visibility(
                  visible: d.hasVideo,
                  child: const Icon(Icons.videocam_rounded)),
            ],
          ),
        )),
        DataCell(Opacity(opacity: opacity, child: Text(d.size == 0 ? '' : hr))),
        DataCell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (BuildContext context) =>
                      DownloadDetailsView(download: d)),
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
                        DataColumn(
                            label: Expanded(
                                child: Text("file", style: headerStyle))),
                        DataColumn(
                            label:
                                Expanded(child: Text("", style: headerStyle))),
                        DataColumn(
                            label: Expanded(
                                child: Text("resolution", style: headerStyle))),
                        DataColumn(
                            label: Expanded(
                                child: Text("fps", style: headerStyle))),
                        DataColumn(
                            label:
                                Expanded(child: Text("", style: headerStyle))),
                        DataColumn(
                            label: Expanded(
                                child: Text("size", style: headerStyle))),
                        DataColumn(
                            label:
                                Expanded(child: Text("", style: headerStyle))),
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
              tooltip:
                  "Download this format and the best audio on the server (prepare for viewing)",
              icon: const Icon(Icons.file_download_outlined),
            ),
          ),
          DataCell(
            onTap: () {
              _startPreparation(context, f.id);
            },
            Tooltip(
              message:
                  "Download exact this format (prepare this format for viewing)",
              child: Text(f.id),
            ),
          ),
          DataCell(Text(f.ext)),
          DataCell(Text(f.resolution)),
          DataCell(Visibility(visible: f.fps != 0, child: Text("${f.fps}"))),
          DataCell(Visibility(
              visible: f.hasAudio,
              child: const Icon(Icons.audiotrack_rounded))),
          DataCell(Visibility(
              visible: f.hasVideo, child: const Icon(Icons.videocam_rounded))),
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
                DataColumn(
                    label: Expanded(child: Text("", style: headerStyle))),
                DataColumn(
                    label: Expanded(child: Text("id", style: headerStyle))),
                DataColumn(
                    label: Expanded(child: Text("ext", style: headerStyle))),
                DataColumn(
                    label: Expanded(
                        child: Text("resolution", style: headerStyle))),
                DataColumn(
                    label: Expanded(child: Text("fps", style: headerStyle))),
                DataColumn(
                    label: Expanded(child: Text("", style: headerStyle))),
                DataColumn(
                    label: Expanded(child: Text("", style: headerStyle))),
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

  void _recordView(BuildContext context, RecordingInfo recording, Download d) {
    Navigator.of(context).push(
      MaterialPageRoute(
          builder: (BuildContext context) =>
              RecordingViewMediaKitHandler(recording: recording, download: d)),
    );
  }

  Widget _buildActions(
    BuildContext context,
    RecordingInfo recording,
    Download d,
  ) {
    switch (d.status) {
      case "stale":
        return IconButton(
          onPressed: () {
            _startPreparation(context, d.formatId);
          },
          tooltip:
              "Download this format again on the server (prepare for viewing)",
          icon: const Icon(Icons.file_download_outlined),
        );
      case "new":
      case "in_progress":
        return Center(
            child: CircularProgressIndicator(value: d.progressByLastLine()));
      case "ready":
        return Row(
          children: [
            IconButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (BuildContext context) =>
                          RecordingViewMediaKit(
                              recording: recording, download: d)),
                );
              },
              tooltip: "Open with MediaKit with handler",
              icon: const Icon(Icons.slideshow),
            ),
            PopupMenuButton(
                tooltip: 'Do with it...',
                icon: const Icon(Icons.more_vert),
                onSelected: (String choice) async {
                  switch (choice) {
                    case "copy":
                      copyToClipboard(context, d.url);
                    case "default":
                      launchUrlString(d.url);
                    case "standard_open":
                      _openWithStandard(context, recording, d);
                  }
                  setState(() {});
                },
                itemBuilder: (BuildContext context) {
                  var menuItems = <PopupMenuItem<String>>[];
                  menuItems.add(
                    const PopupMenuItem<String>(
                      value: "copy",
                      child: Row(
                        children: [
                          Icon(Icons.copy_rounded),
                          Text("Copy file link to clipboard"),
                        ],
                      ),
                    ),
                  );
                  menuItems.add(
                    const PopupMenuItem<String>(
                      value: "default",
                      child: Row(
                        children: [
                          Icon(Icons.open_in_browser),
                          Text("Open in default application"),
                        ],
                      ),
                    ),
                  );
                  menuItems.add(
                    const PopupMenuItem<String>(
                      value: "standard_open",
                      child: Row(
                        children: [
                          Icon(Icons.slideshow),
                          Text(
                            "Open with standard player",
                          ),
                        ],
                      ),
                    ),
                  );
                  return menuItems;
                }),
          ],
        );
      default:
        return ErrorWidget("Unexpected download status ${d.status}");
    }
  }

  void _openWithStandard(
    BuildContext context,
    RecordingInfo recording,
    Download d,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
          builder: (BuildContext context) =>
              RecordingView(recording: recording, download: d)),
    );
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

Future<void> copyToClipboard(BuildContext context, String textData) async {
  await Clipboard.setData(ClipboardData(text: textData)).then((value) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      backgroundColor: Theme.of(context).colorScheme.background,
      content: Text('$textData copied to clipboard'),
    ));
  });
}
