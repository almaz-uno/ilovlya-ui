import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ilovlya/src/api/api.dart';
import 'package:ilovlya/src/api/media.dart';
import 'package:ilovlya/src/media/media_add_view.dart';
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

  final _controllerTitle = TextEditingController();

  @override
  void initState() {
    super.initState();
    setState(() {
      _futureRecording = _load(widget.id);
      _loadDownloads(widget.id);
    });
  }

  Future<RecordingInfo> _load(String id) async {
    try {
      setState(() {
        _isLoading = true;
      });
      return await getRecording(id);
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

  Future<void> _pullRefresh() async {
    setState(() {
      _futureRecording = _load(widget.id);
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
            onPressed: () async {
              var recording = await _futureRecording!;
              Clipboard.setData(ClipboardData(text: recording.webpageUrl)).then((value) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  backgroundColor: Theme.of(context).colorScheme.background,
                  content: Text('${recording.webpageUrl} copied to clipboard'),
                ));
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.check),
            tooltip: 'Mark as viewed',
            onPressed: () async {
              var r = await _futureRecording!;
              if (kDebugMode) {
                print("Mark as viewed at ${r.id}");
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.visibility_off),
            tooltip: 'Hide this record (move to archive)',
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh record (reread from the server)',
            onPressed: _pullRefresh,
          ),
        ],
      ),
      body: Stack(
        children: [
          Visibility(
            visible: _isLoading,
            child: Center(
                child: CircularProgressIndicator(
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            )),
          ),
          RefreshIndicator(
            onRefresh: _pullRefresh,
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: (_futureRecording == null) ? const Center(child: Text('loading...')) : _buildRecordings(),
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
            child: Image.network(
              server() + recording.thumbnailUrl,
              fit: BoxFit.fill,
              scale: 0.5,
            ),
          ),
        ),
        Text("${printDuration(Duration(seconds: recording.position))} / ${printDuration(Duration(seconds: recording.duration))}"),
        (_downloads == null) ? const Text("Downloads info is loading...") : _downloadsTable(context),
        recording.formats == null || recording.formats!.isEmpty ? const Text("No formats for the record") : _formatsTable(context, recording),
      ],
    );
  }

  Widget _downloadsTable(BuildContext context) {
    var downloads = _downloads!;

    var rows = List<DataRow>.generate(downloads.length, (i) {
      var d = downloads[i];
      return DataRow(cells: [
        DataCell(Text(d.formatId)),
        DataCell(Text(d.ext)),
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
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Files for this recordings",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              DataTable(
                columns: const [
                  DataColumn(label: Expanded(child: Text("id", style: headerStyle))),
                  DataColumn(label: Expanded(child: Text("ext", style: headerStyle))),
                ],
                rows: rows,
              ),
            ],
          );
  }

  Widget _formatsTable(BuildContext context, RecordingInfo recording) {
    List<DataRow> rows = [];

    for (int i = 0; i < recording.formats!.length; i++) {
      var f = recording.formats![i];
      rows.add(DataRow(
        cells: <DataCell>[
          DataCell(Text(f.id)),
          DataCell(Text(f.ext)),
          DataCell(Text(f.resolution)),
          DataCell(Visibility(visible: f.fps != 0, child: Text("${f.fps}"))),
          DataCell(Visibility(visible: f.hasAudio, child: const Icon(Icons.audiotrack_rounded))),
          DataCell(Visibility(visible: f.hasVideo, child: const Icon(Icons.videocam_rounded))),
          DataCell(
            onLongPress: () {
              _startDownload(context, "${f.id}+ba");
            },
            IconButton(
              icon: const Icon(Icons.download),
              onPressed: () {
                _startDownload(context, f.id);
              },
            ),
          ),
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
                DataColumn(label: Expanded(child: Text("id", style: headerStyle))),
                DataColumn(label: Expanded(child: Text("ext", style: headerStyle))),
                DataColumn(label: Expanded(child: Text("resolution", style: headerStyle))),
                DataColumn(label: Expanded(child: Text("fps", style: headerStyle))),
                DataColumn(label: Expanded(child: Text("", style: headerStyle))),
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

  Future<void> _startDownload(BuildContext context, String format) async {
    newDownload(widget.id, format).then((d) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: Theme.of(context).colorScheme.background,
        content: Text('Downloading for ${d.formatId} is starting'),
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
}
