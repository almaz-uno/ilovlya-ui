import 'dart:async';
import 'dart:io';

import 'package:animated_search_bar/animated_search_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ilovlya/src/api/local_download_task_riverpod.dart';
import 'package:ilovlya/src/api/thumbnail_riverpod.dart';
import 'package:universal_platform/universal_platform.dart';

import '../api/api_riverpod.dart';
import '../api/exceptions.dart';
import '../api/media_list_riverpod.dart';
import '../model/recording_info.dart';
import '../settings/settings_provider.dart';
import '../settings/settings_view.dart';
import 'format.dart';
import 'media_add.dart';
import 'media_details.dart';

Widget createThumb(WidgetRef ref, String url) {
  late Widget thumbWidget;
  if (UniversalPlatform.isWeb) {
    thumbWidget = Image.network(
      url,
      isAntiAlias: true,
      filterQuality: FilterQuality.high,
    );
  } else {
    final thumbProvider = ref.watch(thumbnailDataNotifierProvider(url));
    if (!thumbProvider.hasValue) {
      thumbWidget = const CircularProgressIndicator();
    } else {
      thumbWidget = Image.file(
        thumbProvider.requireValue,
      );
    }
  }

  return thumbWidget;
}

class MediaListViewRiverpod extends ConsumerStatefulWidget {
  const MediaListViewRiverpod({super.key});

  @override
  ConsumerState<MediaListViewRiverpod> createState() => _MediaListViewRiverpodState();
}

class _MediaListViewRiverpodState extends ConsumerState<MediaListViewRiverpod> {
  StreamSubscription? _updatePullSubs;
  final ScrollController _scrollController = ScrollController();
  String searchPhrase = "";

  static const _updatePullPeriod = Duration(seconds: 30);

  @override
  void initState() {
    super.initState();

    ref.read(mediaListNotifierProvider.notifier).refreshFromServer();

    _updatePullSubs = Stream.periodic(_updatePullPeriod).listen((event) {
      ref.read(mediaListNotifierProvider.notifier).refreshFromServer();
      ref.invalidate(getTenantProvider);
    });
  }

  @override
  void deactivate() {
    _updatePullSubs?.cancel();
    super.deactivate();
  }

  void _scrollDown() {
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(seconds: 2),
      curve: Curves.fastOutSlowIn,
    );
  }

  void _scrollUp() {
    _scrollController.animateTo(
      _scrollController.position.minScrollExtent,
      duration: const Duration(seconds: 2),
      curve: Curves.fastOutSlowIn,
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaList = ref.watch(mediaListNotifierProvider);
    final settings = ref.watch(settingsNotifierProvider);
    final primary = Theme.of(context).colorScheme.primary;
    final tenant = ref.watch(getTenantProvider);
    String usageInfo = "";
    if (tenant.hasValue) {
      final t = tenant.requireValue;
      usageInfo = "quote: ${t.quotaStr()} usage: ${t.usageStr()} (${t.files}) free: ${t.freeStr()} ";
    }

    return Scaffold(
      appBar: AppBar(
        title: AnimatedSearchBar(
          label: "Search...",
          labelAlignment: Alignment.centerRight,
          onChanged: (String value){
            ref.read(searchPhraseNotifierProvider.notifier).setPhrase(value);
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add an arbitrary media',
            onPressed: () {
              Navigator.restorablePushNamed(context, MediaAddView.routeName(false));
            },
          ),
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
              onPressed: () {
                ref.read(mediaListNotifierProvider.notifier).refreshFromServer();
              }),
          PopupMenuButton(
              tooltip: 'More options',
              icon: const Icon(Icons.more_vert),
              onSelected: (String choice) {
                switch (choice) {
                  case "seen":
                    ref.read(settingsNotifierProvider.notifier).toggleShowSeen();
                  case "hidden":
                    ref.read(settingsNotifierProvider.notifier).toggleShowHidden();
                  case "sort_by_created_at":
                    ref.read(settingsNotifierProvider.notifier).updateSortBy("created_at");
                  case "sort_by_updated_at":
                    ref.read(settingsNotifierProvider.notifier).updateSortBy("updated_at");
                  case "with_server_file":
                    ref.read(settingsNotifierProvider.notifier).toggleWithServerFile();
                  case "with_local_file":
                    ref.read(settingsNotifierProvider.notifier).toggleWithLocalFile();
                }
                //setState(() {});
              },
              itemBuilder: (BuildContext context) {
                var menuItems = <PopupMenuItem<String>>[];
                menuItems.add(
                  PopupMenuItem<String>(
                    value: "seen",
                    child: Row(
                      children: [
                        Icon(settings.requireValue.showSeen ? Icons.check : null, color: primary),
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
                        Icon(settings.requireValue.showHidden ? Icons.check : null, color: primary),
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
                        Icon(settings.requireValue.sortBy == "created_at" ? Icons.check : null, color: primary),
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
                        Icon(settings.requireValue.sortBy == "updated_at" ? Icons.check : null, color: primary),
                        Text("sort by updated", style: TextStyle(color: primary)),
                      ],
                    ),
                  ),
                );
                menuItems.add(
                  PopupMenuItem<String>(
                    value: "with_server_file",
                    child: Row(
                      children: [
                        Icon(settings.requireValue.withServerFile ? Icons.flag_circle_outlined : null, color: primary),
                        Text("show only with server file", style: TextStyle(color: primary)),
                      ],
                    ),
                  ),
                );
                menuItems.add(
                  PopupMenuItem<String>(
                    value: "with_local_file",
                    child: Row(
                      children: [
                        Icon(settings.requireValue.withLocalFile ? Icons.download_done : null, color: primary),
                        Text("show only with local file", style: TextStyle(color: primary)),
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
      floatingActionButton: Wrap(
        spacing: 8.0,
        children: [
          FloatingActionButton.small(
            heroTag: "up",
            onPressed: _scrollUp,
            child: const Icon(Icons.arrow_upward),
          ),
          FloatingActionButton.small(
            heroTag: "down",
            onPressed: _scrollDown,
            child: const Icon(Icons.arrow_downward),
          ),
        ],
      ),
      bottomNavigationBar: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(usageInfo),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(mediaListNotifierProvider.notifier).refreshFromServer(),
        child: Stack(
          children: [
            Visibility(visible: mediaList.isLoading, child: const LinearProgressIndicator()),
            _buildRecordingsList(context, mediaList),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordingsList(BuildContext context, AsyncValue<List<RecordingInfo>> mediaList) {
    final setting = ref.watch(settingsNotifierProvider);

    if (mediaList.hasError) {
      if (mediaList.error is HttpStatusError && (mediaList.error as HttpStatusError).statusCode == HttpStatus.unauthorized) {
        return ErrorWidget("Unauthorized: please check and specify token and server URL in settings");
      }
      return ErrorWidget("${mediaList.error}: please check and specify token and server URL in settings");
    }

    if (!mediaList.hasValue) {
      return const Center(child: Text('Loading in progress...'));
    }

    if (mediaList.requireValue.isEmpty) {
      return const Center(child: Text("No recordings. Check you filter settings or API token value."));
    }

    return ListView.builder(
      controller: _scrollController,
      scrollDirection: Axis.vertical,
      shrinkWrap: true,
      itemCount: mediaList.requireValue.length,
      itemBuilder: (BuildContext context, int index) {
        var item = mediaList.requireValue[index];
        var dur = Duration(seconds: item.duration);
        var opacity = item.seenAt == null ? 1.0 : 0.5;
        if (item.hiddenAt != null) {
          opacity = 0.25;
        }
        // final TextStyle? textStyle = item.hiddenAt != null ? const TextStyle(decoration: TextDecoration.lineThrough) : null;
        var viewedSrt = item.position == 0 ? "" : " (${formatDuration(Duration(seconds: item.position))})";

        List<Widget> right = [];

        final tt = ref.watch(localDTNotifierProvider);
        for (final did in item.downloads) {
          if (!tt.containsKey(did) || tt[did]?.status?.isFinalState == true) continue;
          right.add(Padding(
            padding: const EdgeInsets.all(8.0),
            child: CircularProgressIndicator(value: tt[did]?.progress),
          ));
        }

        right += [
          if (item.hiddenAt != null) const Icon(Icons.visibility_off_outlined),
          if (item.hasLocalFile) const Icon(Icons.download_done),
          if (item.hasFile) const Icon(Icons.flag_circle_outlined),
        ];

        final dt = setting.requireValue.sortBy == "updated_at" ? item.updatedAt : item.createdAt;

        return Opacity(
          opacity: opacity,
          child: Column(
            children: [
              ListTile(
                leading: SizedBox(
                  width: 100, // alignment
                  child: Center(
                    child: createThumb(ref, item.thumbnailUrl),
                  ),
                ),
                title: Text(
                  "${item.title} ∙ ${formatDuration(dur)}$viewedSrt",
                  // style: textStyle,
                ),
                subtitle: Text("${item.uploader} ∙ ${item.extractor} • ${formatDate(dt)} (${since(dt, true)})"),
                trailing: right.isEmpty ? null : Wrap(children: right),
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
  }
}
