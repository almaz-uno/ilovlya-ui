import 'package:flutter/foundation.dart';
import 'package:ilovlya/src/api/api.dart';
import 'package:ilovlya/src/api/media.dart';
import 'package:ilovlya/src/media/format.dart';
import 'package:ilovlya/src/media/media_add_view.dart';
import 'package:ilovlya/src/media/media_details_view.dart';
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
  bool _isLoading = false;
  bool _showHidden = false;
  bool _showSeen = false;

  Future<List<RecordingInfo>> _load(int offset, int limit) async {
    try {
      setState(() {
        _isLoading = true;
      });
      return await listRecordings(offset, limit);
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

  @override
  void deactivate() {
    super.deactivate();
    if (kDebugMode) {
      print("deactivate()");
    }
  }

  @override
  void activate() {
    super.activate();
    if (kDebugMode) {
      print("activate()");
    }
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
            icon: const Icon(Icons.more_vert),
            tooltip: 'More options',
            onPressed: () {
              Navigator.restorablePushNamed(context, SettingsView.routeName);
            },
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
      body: RefreshIndicator(
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
            (_futureRecordingsList == null) ? const Center(child: Text('Loading in progress')) : Expanded(child: buildRecordingsList()),
          ],
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
            physics: const AlwaysScrollableScrollPhysics(),
            scrollDirection: Axis.vertical,
            shrinkWrap: true,
            itemCount: snapshot.data!.length,
            itemBuilder: (BuildContext context, int index) {
              var item = snapshot.data![index];
              var dur = Duration(seconds: item.duration);
              var opacity = item.seenAt == null ? 1.0 : 0.5;
              if (item.hiddenAt != null) {
                opacity = 0.25;
              }
              // final TextStyle? textStyle = item.hiddenAt != null ? const TextStyle(decoration: TextDecoration.lineThrough) : null;
              final Widget? trailing = item.hiddenAt != null ? const Icon(Icons.visibility_off_outlined) : null;
              return Opacity(
                opacity: opacity,
                child: Column(
                  children: [
                    ListTile(
                      leading: SizedBox(
                        width: 100, // alignment
                        child: Stack(
                          children: [
                            Image.network(
                              server() + item.thumbnailUrl,
                              isAntiAlias: true,
                              filterQuality: FilterQuality.high,
                            ),
                          ],
                        ),
                      ),
                      title: Text(
                        "${item.title} ∙ ${formatDuration(dur)}",
                        // style: textStyle,
                      ),
                      subtitle: Text("${item.uploader} ∙ ${item.extractor}"),
                      trailing: trailing,
                      onTap: () {
                        Navigator.restorablePushNamed(context, MediaDetailsView.routeName(item.id), arguments: item.id);
                      },
                    ),
                    LinearProgressIndicator(
                      backgroundColor: const Color.fromARGB(127, 158, 158, 158),
                      value: item.duration == 0 ? null : item.position / item.duration,
                    ),
                  ],
                ),
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
