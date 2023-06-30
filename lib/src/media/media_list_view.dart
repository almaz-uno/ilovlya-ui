import 'package:ilovlya/src/api/media.dart';
import 'package:ilovlya/src/media/media_add_view.dart';
import 'package:ilovlya/src/media/media_detais_view.dart';
import 'package:ilovlya/src/media/misc.dart';
import 'package:ilovlya/src/model/recording_info.dart';
import 'package:ilovlya/src/settings/settings_view.dart';
import 'package:flutter/material.dart';

class MediaListView extends StatefulWidget {
  const MediaListView({
    super.key,
  });

  @override
  State<MediaListView> createState() => _MediaListViewState();
}

class _MediaListViewState extends State<MediaListView> {
  Future<List<RecordingInfo>>? _futureRecordingsList;
  var _isLoading = false;

  Future<List<RecordingInfo>> _load(int offset, int limit) async {
    try {
      setState(() {
        _isLoading = true;
      });
      // await Future.delayed(Duration(seconds: 2)); // testing purposes only
      return await listRecordings(0, 10);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _futureRecordingsList = _load(0, 100);
  }

  Future<void> _pullRefresh() async {
    setState(() {
      _futureRecordingsList = _load(0, 100);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('List of recordings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.content_paste_go_rounded),
            tooltip: 'Add from clipboard',
            onPressed: () {
              Navigator.restorablePushNamed(context, MediaAddView.routeName(true));
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh list',
            onPressed: _pullRefresh,
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
            onPressed: () {
              Navigator.restorablePushNamed(context, SettingsView.routeName);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: RefreshIndicator(
          onRefresh: _pullRefresh,
          child: Column(
            children: [
              Center(
                child: Visibility(
                    visible: _isLoading,
                    child: const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: LinearProgressIndicator(),
                    )),
              ),
              Center(child: (_futureRecordingsList == null) ? const Text('Loading in progress') : buildRecordingsList()),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.restorablePushNamed(context, MediaAddView.routeName(false));
        },
        tooltip: 'Add new media link',
        child: const Icon(Icons.add),
      ),
    );
  }

  FutureBuilder<List<RecordingInfo>> buildRecordingsList() {
    return FutureBuilder<List<RecordingInfo>>(
      future: _futureRecordingsList,
      builder: (BuildContext context, AsyncSnapshot<List<RecordingInfo>> snapshot) {
        if (snapshot.hasData) {
          return ListView.builder(
            scrollDirection: Axis.vertical,
            shrinkWrap: true,
            itemCount: snapshot.data!.length,
            itemBuilder: (BuildContext context, int index) {
              var item = snapshot.data![index];
              var dur = Duration(seconds: item.duration ?? 0);
              return ListTile(
                leading: SizedBox(
                  width: 100, // alignment
                  child: Image.network(
                    (item.thumbnailDataUrl == null) ? noImage : item.thumbnailDataUrl!,
                    isAntiAlias: true,
                    filterQuality: FilterQuality.high,
                  ),
                ),
                title: Text("${item.title} ∙ ${printDuration(dur)}"),
                subtitle: Text("${item.uploader} ∙ ${item.extractor}"),
                onTap: () {
                  Navigator.restorablePushNamed(context, MediaDetailsView.routeName(item.id), arguments: item.id);
                },
              );
            },
          );
        } else if (snapshot.hasError) {
          return Text('${snapshot.error}');
        }

        return const Padding(
          padding: EdgeInsets.all(8.0),
          child: Text('Media info acquiring in progress...'),
        );
      },
    );
  }
}
