import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/exceptions.dart';
import '../api/media_list_riverpod.dart';
import '../settings/settings_provider.dart';
import '../settings/settings_view.dart';
import 'format.dart';
import 'media_add_view.dart';
import 'media_details_view.dart';

class MediaListViewRiverpod extends ConsumerStatefulWidget {
  const MediaListViewRiverpod({super.key});

  @override
  ConsumerState<MediaListViewRiverpod> createState() => _MediaListViewRiverpodState();
}

class _MediaListViewRiverpodState extends ConsumerState<MediaListViewRiverpod> {
  StreamSubscription? _updatePullSubs;

  static const _updatePullPeriod = Duration(minutes: 5);

  @override
  void initState() {
    super.initState();

    _updatePullSubs = Stream.periodic(_updatePullPeriod).listen((event) {
      ref.invalidate(mediaListNotifierProvider);
    });
  }

  @override
  void deactivate() {
    _updatePullSubs?.cancel();
    super.deactivate();
  }

  @override
  Widget build(BuildContext context) {
    final mediaList = ref.watch(mediaListNotifierProvider);
    final settings = ref.watch(settingsNotifierProvider);
    final primary = Theme.of(context).colorScheme.primary;

    if (mediaList.hasError) {
      if (mediaList.error is HttpStatusError && (mediaList.error as HttpStatusError).statusCode == HttpStatus.unauthorized) {
        Future.microtask(() {
          Navigator.restorablePushNamed(context, SettingsView.routeName);
          showDialog(
              context: context,
              barrierDismissible: true,
              builder: (BuildContext context) => const AlertDialog(
                    title: Text("Unauthorized"),
                    content: Text('Fill token and check server URL settings'),
                  ));
        });
      }
      return ErrorWidget(mediaList.error!);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('List of recordings'),
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
            onPressed: () => ref.invalidate(mediaListNotifierProvider),
          ),
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
        onRefresh: () {
          ref.invalidate(mediaListNotifierProvider);
          return Future.value(null);
        },
        child: Stack(
          children: [
            Visibility(visible: mediaList.isLoading, child: const LinearProgressIndicator()),
            mediaList.hasValue ? _buildRecordingsList(context) : const Center(child: Text('Loading in progress...')),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordingsList(BuildContext context) {
    final mediaList = ref.watch(mediaListNotifierProvider);
    final setting = ref.watch(settingsNotifierProvider);

    return ListView.builder(
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

        Widget? trailing;

        if (item.hiddenAt != null) {
          trailing = const Icon(Icons.visibility_off_outlined);
        }
        if (item.hasFile) {
          trailing = const Icon(Icons.flag_circle_outlined);
        }

        final dt = setting.requireValue.sortBy == "updated_at" ? item.updatedAt : item.createdAt;

        return Opacity(
          opacity: opacity,
          child: Column(
            children: [
              ListTile(
                leading: SizedBox(
                  width: 100, // alignment
                  child: Center(
                    child: Image.network(
                      item.thumbnailUrl,
                      isAntiAlias: true,
                      filterQuality: FilterQuality.high,
                    ),
                  ),
                ),
                title: Text(
                  "${item.title} ∙ ${formatDuration(dur)}$viewedSrt",
                  // style: textStyle,
                ),
                subtitle: Text("${item.uploader} ∙ ${item.extractor} • ${formatDate(dt)} (${since(dt, true)})"),
                trailing: trailing,
                onTap: () {
                  Navigator.restorablePushNamed(context, MediaDetailsView.routeName(item.id), arguments: item.id);
                },
                onLongPress: () {
                  Navigator.restorablePushNamed(context, MediaDetailsView.routeName(item.id, play: true), arguments: item.id);
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
