import 'dart:ui';

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
  String _sortBy = "created_at";
  // final _listScrollController = ScrollController();

  Future<List<RecordingInfo>> _load(int offset, int limit) async {
    try {
      setState(() {
        _isLoading = true;
      });
      return await listRecordings(offset, limit, sortBy: _sortBy);
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
    final primary = Theme.of(context).colorScheme.primary;
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
          PopupMenuButton(
              tooltip: 'More options',
              icon: const Icon(Icons.more_vert),
              onSelected: (String choice) {
                switch (choice) {
                  case "seen":
                    _showSeen = !_showSeen;
                  case "hidden":
                    _showHidden = !_showHidden;
                  case "sort_by_created_at":
                    _sortBy = "created_at";
                    _pullRefresh();
                  case "sort_by_updated_at":
                    _sortBy = "updated_at";
                    _pullRefresh();
                }
                setState(() {});
              },
              itemBuilder: (BuildContext context) {
                var menuItems = <PopupMenuItem<String>>[];
                menuItems.add(
                  PopupMenuItem<String>(
                    value: "seen",
                    child: Row(
                      children: [
                        Icon(_showSeen ? Icons.check : null, color: primary),
                        Text("show seen", style: TextStyle(color: primary)),
                      ],
                    ),
                  ),
                );
                menuItems.add(
                  PopupMenuItem<String>(
                    value: "hidden",
                    child: Row(
                      children: [
                        Icon(_showHidden ? Icons.check : null, color: primary),
                        Text("show hidden", style: TextStyle(color: primary)),
                      ],
                    ),
                  ),
                );
                menuItems.add(
                  PopupMenuItem<String>(
                    value: "sort_by_created_at",
                    child: Row(
                      children: [
                        Icon(_sortBy == "created_at" ? Icons.check : null, color: primary),
                        Text("sort by created", style: TextStyle(color: primary)),
                      ],
                    ),
                  ),
                );
                menuItems.add(
                  PopupMenuItem<String>(
                    value: "sort_by_updated_at",
                    child: Row(
                      children: [
                        Icon(_sortBy == "updated_at" ? Icons.check : null, color: primary),
                        Text("sort by updated", style: TextStyle(color: primary)),
                      ],
                    ),
                  ),
                );
                return menuItems;
              }),
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
          return _buildList(context, snapshot.data!);
        } else if (snapshot.hasError) {
          return Text('${snapshot.error}');
        }

        return const Padding(
          padding: EdgeInsets.all(8.0),
          child: Text('Recordings list acquiring in progress...'),
        );
      },
    );
  }

  Widget _buildList(BuildContext context, List<RecordingInfo> recordings) {
    List<RecordingInfo> filtered = [];

    for (var item in recordings) {
      if (item.seenAt != null && !_showSeen) {
        continue;
      }
      if (item.hiddenAt != null && !_showHidden) {
        continue;
      }

      filtered.add(item);
    }

    return Scrollbar(
      // controller: _listScrollController,
      thumbVisibility: true,
      interactive: true,
      child: ListView.builder(
        //physics: const AlwaysScrollableScrollPhysics(),
        scrollDirection: Axis.vertical,
        shrinkWrap: true,
        itemCount: filtered.length,
        itemBuilder: (BuildContext context, int index) {
          var item = filtered[index];
          var dur = Duration(seconds: item.duration);
          var opacity = item.seenAt == null ? 1.0 : 0.5;
          if (item.hiddenAt != null) {
            opacity = 0.25;
          }
          // final TextStyle? textStyle = item.hiddenAt != null ? const TextStyle(decoration: TextDecoration.lineThrough) : null;
          var viewedSrt = item.position == 0 ? "" : " (${formatDuration(Duration(seconds: item.position))})";
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
                    "${item.title} ∙ ${formatDuration(dur)}$viewedSrt",
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
      ),
    );
  }
}
