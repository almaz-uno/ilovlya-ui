import 'dart:async';
import 'dart:io';

import 'package:animated_search_bar/animated_search_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:universal_platform/universal_platform.dart';

import '../api/api_riverpod.dart';
import '../api/exceptions.dart';
import '../api/local_download_task_riverpod.dart';
import '../api/media_list_riverpod.dart';
import '../api/recording_mutation_riverpod.dart';
import '../api/thumbnail_riverpod.dart';
import '../localization/app_localizations.dart';
import '../keyboard_shortcuts.dart';
import '../model/recording_info.dart';
import '../settings/settings_provider.dart';
import '../settings/settings_view.dart';
import '../utils/logger_provider.dart';
import 'format.dart';
import 'intents.dart';
import 'media_add.dart';
import 'media_details.dart';
import 'media_kit/audio_handler.dart';

String mediaListErrorMessage(AppLocalizations l10n, Object? error) {
  if (error is HttpStatusError && error.statusCode == HttpStatus.unauthorized) {
    return l10n.unauthorizedCheckTokenAndServer;
  }
  return '${l10n.recordingsLoadFailed}: $error';
}

Widget createThumb(WidgetRef ref, String url, {int? cacheWidth}) {
  late Widget thumbWidget;
  if (UniversalPlatform.isWeb) {
    thumbWidget = Image.network(
      url,
      isAntiAlias: true,
      filterQuality: FilterQuality.high,
      fit: BoxFit.fitWidth,
      cacheWidth: cacheWidth,
    );
  } else {
    final thumbProvider = ref.watch(thumbnailDataNotifierProvider(url));
    if (!thumbProvider.hasValue) {
      // Shimmer-like placeholder instead of CircularProgressIndicator
      thumbWidget = const _ThumbnailPlaceholder();
    } else {
      thumbWidget = Image.memory(
        thumbProvider.requireValue,
        fit: BoxFit.fitWidth,
        cacheWidth: cacheWidth,
      );
    }
  }

  return thumbWidget;
}

/// Shimmer-like placeholder for loading thumbnails - more performant than CircularProgressIndicator
class _ThumbnailPlaceholder extends StatelessWidget {
  const _ThumbnailPlaceholder();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      height: 180,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [
                  Colors.grey.shade800,
                  Colors.grey.shade700,
                  Colors.grey.shade800
                ]
              : [
                  Colors.grey.shade300,
                  Colors.grey.shade200,
                  Colors.grey.shade300
                ],
          stops: const [0.0, 0.5, 1.0],
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        Icons.image_outlined,
        size: 48,
        color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
      ),
    );
  }
}

class MediaListViewRiverpod extends ConsumerStatefulWidget {
  const MediaListViewRiverpod({super.key});

  @override
  ConsumerState<MediaListViewRiverpod> createState() =>
      _MediaListViewRiverpodState();
}

class _MediaListViewRiverpodState extends ConsumerState<MediaListViewRiverpod> {
  StreamSubscription? _updatePullSubs;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  int _selectedIndex = 0;
  final Map<int, GlobalKey> _rowKeys = {};

  static const _updatePullPeriod = Duration(seconds: 30);

  @override
  void initState() {
    super.initState();

    _refreshList();

    _updatePullSubs = Stream.periodic(_updatePullPeriod).listen((event) {
      if (MKPlayerHandler.player.state.playing) {
        AppLoggers.ui.d('Skip pull list while playing');
        return;
      }
      _refreshList();
      ref.invalidate(getTenantProvider);
    });
  }

  /// Refreshes the list from the server; the returned future never completes with an error.
  /// The error is already logged by [MediaListNotifier], so it is only noted here to keep it
  /// from escaping as an unhandled exception. The next periodic pull retries.
  Future<void> _refreshList() async {
    try {
      await ref.read(mediaListNotifierProvider.notifier).refreshFromServer();
    } catch (e) {
      AppLoggers.ui.w('Media list refresh failed: $e');
    }
  }

  @override
  void deactivate() {
    _updatePullSubs?.cancel();
    super.deactivate();
  }

  void _scrollDown() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(seconds: 2),
      curve: Curves.fastOutSlowIn,
    );
  }

  void _scrollUp() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      _scrollController.position.minScrollExtent,
      duration: const Duration(seconds: 2),
      curve: Curves.fastOutSlowIn,
    );
  }

  void _moveSelection(int delta, int itemCount) {
    if (itemCount == 0) return;
    setState(() {
      _selectedIndex = (_selectedIndex + delta).clamp(0, itemCount - 1);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final rowContext = _rowKeys[_selectedIndex]?.currentContext;
      if (rowContext != null) {
        Scrollable.ensureVisible(rowContext,
            duration: const Duration(milliseconds: 150), alignment: 0.5);
      } else if (_scrollController.hasClients && itemCount > 1) {
        final estimatedOffset = _scrollController.position.maxScrollExtent *
            _selectedIndex /
            (itemCount - 1);
        _scrollController
            .animateTo(estimatedOffset,
                duration: const Duration(milliseconds: 150),
                curve: Curves.easeOut)
            .then((_) {
          final rowContext = _rowKeys[_selectedIndex]?.currentContext;
          if (mounted && rowContext != null && rowContext.mounted) {
            Scrollable.ensureVisible(rowContext,
                duration: const Duration(milliseconds: 100), alignment: 0.5);
          }
        });
      }
    });
  }

  void _selectEnd(int itemCount) {
    if (itemCount == 0) return;
    setState(() => _selectedIndex = itemCount - 1);
    _scrollDown();
  }

  void _selectHome() {
    setState(() => _selectedIndex = 0);
    _scrollUp();
  }

  void _openSelected(
      BuildContext context, AsyncValue<List<RecordingInfo>> mediaList) {
    if (!mediaList.hasValue || mediaList.requireValue.isEmpty) return;
    final index = _selectedIndex.clamp(0, mediaList.requireValue.length - 1);
    final item = mediaList.requireValue[index];
    Navigator.restorablePushNamed(context, MediaDetailsView.routeName(item.id),
        arguments: item.id);
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
      final storeStr = t.storeUsage > 0
          ? " 🏠${t.localUsageStr()}/☁️${t.storeUsageStr()} "
          : "";

      usageInfo = AppLocalizations.of(context)!.quotaUsageInfo(
        t.quotaStr(),
        t.usageStr(),
        t.files,
        t.freeStr(),
        storeStr,
      );
    }

    return ScreenShortcuts(
      shortcuts: <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.keyR): RefreshIntent(),
        SingleActivator(LogicalKeyboardKey.f5): RefreshIntent(),
        SingleActivator(LogicalKeyboardKey.home): NavigateHomeIntent(),
        SingleActivator(LogicalKeyboardKey.end): NavigateEndIntent(),
        if (isDesktopKeyboardPlatform) ...{
          SingleActivator(LogicalKeyboardKey.arrowUp): SelectPreviousIntent(),
          SingleActivator(LogicalKeyboardKey.arrowDown): SelectNextIntent(),
          SingleActivator(LogicalKeyboardKey.keyK): SelectPreviousIntent(),
          SingleActivator(LogicalKeyboardKey.keyJ): SelectNextIntent(),
          SingleActivator(LogicalKeyboardKey.enter): OpenSelectedIntent(),
          SingleActivator(LogicalKeyboardKey.numpadEnter): OpenSelectedIntent(),
          SingleActivator(LogicalKeyboardKey.equal, shift: true):
              AddMediaIntent(),
          SingleActivator(LogicalKeyboardKey.add): AddMediaIntent(),
          SingleActivator(LogicalKeyboardKey.insert): PasteMediaIntent(),
          SingleActivator(LogicalKeyboardKey.comma, control: true):
              OpenSettingsIntent(),
        },
      },
      actions: <Type, Action<Intent>>{
        RefreshIntent: CallbackAction<RefreshIntent>(
          onInvoke: (intent) {
            if (!isTextInputFocused()) _refreshList();
            return null;
          },
        ),
        NavigateHomeIntent: CallbackAction<NavigateHomeIntent>(
          onInvoke: (intent) {
            if (!isTextInputFocused()) _selectHome();
            return null;
          },
        ),
        NavigateEndIntent: CallbackAction<NavigateEndIntent>(
          onInvoke: (intent) {
            if (!isTextInputFocused()) {
              _selectEnd(mediaList.valueOrNull?.length ?? 0);
            }
            return null;
          },
        ),
        SelectPreviousIntent:
            CallbackAction<SelectPreviousIntent>(onInvoke: (_) {
          if (!isTextInputFocused()) {
            _moveSelection(-1, mediaList.valueOrNull?.length ?? 0);
          }
          return null;
        }),
        SelectNextIntent: CallbackAction<SelectNextIntent>(onInvoke: (_) {
          if (!isTextInputFocused()) {
            _moveSelection(1, mediaList.valueOrNull?.length ?? 0);
          }
          return null;
        }),
        OpenSelectedIntent: CallbackAction<OpenSelectedIntent>(onInvoke: (_) {
          if (!isTextInputFocused()) _openSelected(context, mediaList);
          return null;
        }),
        AddMediaIntent: CallbackAction<AddMediaIntent>(onInvoke: (_) {
          if (!isTextInputFocused()) {
            Navigator.restorablePushNamed(
                context, MediaAddView.routeName(false));
          }
          return null;
        }),
        PasteMediaIntent: CallbackAction<PasteMediaIntent>(onInvoke: (_) {
          if (!isTextInputFocused()) {
            Navigator.restorablePushNamed(
                context, MediaAddView.routeName(true));
          }
          return null;
        }),
        OpenSettingsIntent: CallbackAction<OpenSettingsIntent>(onInvoke: (_) {
          if (!isTextInputFocused()) {
            Navigator.restorablePushNamed(context, SettingsView.routeName);
          }
          return null;
        }),
      },
      help: [
        ShortcutHelpEntry(
            '↑ / k', AppLocalizations.of(context)!.selectPreviousRecording),
        ShortcutHelpEntry(
            '↓ / j', AppLocalizations.of(context)!.selectNextRecording),
        ShortcutHelpEntry(
            'Enter', AppLocalizations.of(context)!.openSelectedRecording),
        ShortcutHelpEntry('+', AppLocalizations.of(context)!.addArbitraryMedia),
        ShortcutHelpEntry(
            'Insert', AppLocalizations.of(context)!.addFromClipboard),
        ShortcutHelpEntry('r / F5', AppLocalizations.of(context)!.refreshList),
        ShortcutHelpEntry('Home / End', AppLocalizations.of(context)!.scrollUp),
        ShortcutHelpEntry('Ctrl+,', AppLocalizations.of(context)!.settings),
      ],
      child: Focus(
        child: SafeArea(
          top: false,
          child: Scaffold(
            appBar: AppBar(
              title: AnimatedSearchBar(
                label: AppLocalizations.of(context)!.search,
                controller: _searchController,
                labelAlignment: Alignment.centerLeft,
                searchStyle:
                    TextStyle(color: Theme.of(context).colorScheme.onSurface),
                cursorColor: Theme.of(context).colorScheme.primary,
                onChanged: (String value) {
                  ref
                      .read(searchPhraseNotifierProvider.notifier)
                      .setPhrase(value);
                },
              ),
              actions: [
                IconButton(
                    icon: const Icon(Icons.refresh),
                    tooltip: AppLocalizations.of(context)!.refreshList,
                    onPressed: _refreshList),
                PopupMenuButton(
                    tooltip: AppLocalizations.of(context)!.moreOptions,
                    icon: const Icon(Icons.more_vert),
                    onSelected: (String choice) {
                      switch (choice) {
                        case "seen":
                          ref
                              .read(settingsNotifierProvider.notifier)
                              .toggleShowSeen();
                        case "hidden":
                          ref
                              .read(settingsNotifierProvider.notifier)
                              .toggleShowHidden();
                        case "sort_by_created_at":
                          ref
                              .read(settingsNotifierProvider.notifier)
                              .updateSortBy("created_at");
                        case "sort_by_updated_at":
                          ref
                              .read(settingsNotifierProvider.notifier)
                              .updateSortBy("updated_at");
                        case "with_server_file":
                          ref
                              .read(settingsNotifierProvider.notifier)
                              .toggleWithServerFile();
                        case "with_local_file":
                          ref
                              .read(settingsNotifierProvider.notifier)
                              .toggleWithLocalFile();
                      }
                    },
                    itemBuilder: (BuildContext context) {
                      var menuItems = <PopupMenuItem<String>>[];
                      menuItems.add(PopupMenuItem<String>(
                          value: "seen",
                          child: Row(children: [
                            Icon(
                                settings.requireValue.showSeen
                                    ? Icons.check
                                    : null,
                                color: primary),
                            Flexible(
                                child: Text(
                                    AppLocalizations.of(context)!.showSeen,
                                    style: TextStyle(color: primary)))
                          ])));
                      menuItems.add(PopupMenuItem<String>(
                          value: "hidden",
                          child: Row(children: [
                            Icon(
                                settings.requireValue.showHidden
                                    ? Icons.check
                                    : null,
                                color: primary),
                            Flexible(
                                child: Text(
                                    AppLocalizations.of(context)!.showHidden,
                                    style: TextStyle(color: primary)))
                          ])));
                      menuItems.add(PopupMenuItem<String>(
                          value: "sort_by_created_at",
                          child: Row(children: [
                            Icon(
                                settings.requireValue.sortBy == "created_at"
                                    ? Icons.check
                                    : null,
                                color: primary),
                            Flexible(
                                child: Text(
                                    AppLocalizations.of(context)!.sortByCreated,
                                    style: TextStyle(color: primary)))
                          ])));
                      menuItems.add(PopupMenuItem<String>(
                          value: "sort_by_updated_at",
                          child: Row(children: [
                            Icon(
                                settings.requireValue.sortBy == "updated_at"
                                    ? Icons.check
                                    : null,
                                color: primary),
                            Flexible(
                                child: Text(
                                    AppLocalizations.of(context)!.sortByUpdated,
                                    style: TextStyle(color: primary)))
                          ])));
                      menuItems.add(PopupMenuItem<String>(
                          value: "with_server_file",
                          child: Row(children: [
                            Icon(
                                settings.requireValue.withServerFile
                                    ? Icons.flag_circle_outlined
                                    : null,
                                color: primary),
                            Flexible(
                                child: Text(
                                    AppLocalizations.of(context)!
                                        .showOnlyWithServerFile,
                                    style: TextStyle(color: primary)))
                          ])));
                      menuItems.add(PopupMenuItem<String>(
                          value: "with_local_file",
                          child: Row(children: [
                            Icon(
                                settings.requireValue.withLocalFile
                                    ? Icons.download_done
                                    : null,
                                color: primary),
                            Flexible(
                                child: Text(
                                    AppLocalizations.of(context)!
                                        .showOnlyWithLocalFile,
                                    style: TextStyle(color: primary)))
                          ])));
                      return menuItems;
                    }),
                IconButton(
                    icon: const Icon(Icons.settings),
                    tooltip: AppLocalizations.of(context)!.settings,
                    onPressed: () => Navigator.restorablePushNamed(
                        context, SettingsView.routeName)),
              ],
            ),
            floatingActionButton: Wrap(
              spacing: 8.0,
              children: [
                FloatingActionButton.small(
                    heroTag: "add_media",
                    tooltip: AppLocalizations.of(context)!.addArbitraryMedia,
                    onPressed: () => Navigator.restorablePushNamed(
                        context, MediaAddView.routeName(false)),
                    child: const Icon(Icons.add)),
                FloatingActionButton.small(
                    heroTag: "add_from_clipboard",
                    tooltip: AppLocalizations.of(context)!.addFromClipboard,
                    onPressed: () => Navigator.restorablePushNamed(
                        context, MediaAddView.routeName(true)),
                    child: const Icon(Icons.content_paste_go_rounded)),
                FloatingActionButton.small(
                    heroTag: "scroll_up",
                    tooltip: AppLocalizations.of(context)!.scrollUp,
                    onPressed: _scrollUp,
                    child: const Icon(Icons.arrow_upward)),
                FloatingActionButton.small(
                    heroTag: "scroll_down",
                    tooltip: AppLocalizations.of(context)!.scrollDown,
                    onPressed: _scrollDown,
                    child: const Icon(Icons.arrow_downward)),
              ],
            ),
            bottomNavigationBar:
                SafeArea(child: Text(usageInfo, textAlign: TextAlign.center)),
            body: RefreshIndicator(
              onRefresh: _refreshList,
              child: Stack(children: [
                if (mediaList.isLoading) const LinearProgressIndicator(),
                _buildRecordingsList(context, mediaList)
              ]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecordingsList(
      BuildContext context, AsyncValue<List<RecordingInfo>> mediaList) {
    final setting = ref.watch(settingsNotifierProvider);

    if (mediaList.hasError) {
      return ErrorWidget(mediaListErrorMessage(
          AppLocalizations.of(context)!, mediaList.error));
    }

    if (!mediaList.hasValue) {
      return Center(
          child: Text(AppLocalizations.of(context)!.loadingInProgress));
    }

    if (mediaList.requireValue.isEmpty) {
      return Center(
          child: Text(AppLocalizations.of(context)!.noRecordingsCheckFilters));
    }

    if (_selectedIndex >= mediaList.requireValue.length) {
      _selectedIndex = mediaList.requireValue.length - 1;
    }

    return ListView.builder(
      controller: _scrollController,
      scrollDirection: Axis.vertical,
      itemCount: mediaList.requireValue.length,
      itemBuilder: (BuildContext context, int index) {
        var item = mediaList.requireValue[index];
        var dur = Duration(seconds: item.duration);
        var opacity = item.seenAt == null ? 1.0 : 0.5;
        if (item.hiddenAt != null) {
          opacity = 0.25;
        }
        // final TextStyle? textStyle = item.hiddenAt != null ? const TextStyle(decoration: TextDecoration.lineThrough) : null;
        var viewedSrt = item.position == 0
            ? ""
            : " (${formatDuration(Duration(seconds: item.position))})";

        List<Widget> right = [];

        final tt = ref.watch(localDTNotifierProvider);
        for (final did in item.downloads) {
          if (!tt.containsKey(did) || tt[did]?.status?.isFinalState == true) {
            continue;
          }
          right.add(Padding(
            padding: const EdgeInsets.all(8.0),
            child: CircularProgressIndicator(value: tt[did]?.progress),
          ));
        }

        right += [
          RecordingMutationIndicator(recordingId: item.id),
          if (item.hiddenAt != null) const Icon(Icons.visibility_off_outlined),
          if (item.hasLocalFile) const Icon(Icons.download_done),
          if (item.hasFile) const Icon(Icons.flag_circle_outlined),
        ];

        final dt = setting.requireValue.sortBy == "updated_at"
            ? item.updatedAt
            : item.createdAt;

        // Use ColorFiltered or alpha in text styles instead of Opacity widget for better performance
        final textColor = Theme.of(context)
            .textTheme
            .bodyMedium
            ?.color
            ?.withValues(alpha: opacity);
        final subtitleColor = Theme.of(context)
            .textTheme
            .bodySmall
            ?.color
            ?.withValues(alpha: opacity);

        return Column(
          key: _rowKeys.putIfAbsent(index, GlobalKey.new),
          children: [
            ListTile(
              selected: index == _selectedIndex,
              leading: SizedBox(
                width: 100, // alignment
                child: Center(
                  child: opacity < 1.0
                      ? ColorFiltered(
                          colorFilter: ColorFilter.mode(
                            Colors.grey.withValues(alpha: 1.0 - opacity),
                            BlendMode.srcATop,
                          ),
                          child: createThumb(ref, item.thumbnailUrl),
                        )
                      : createThumb(ref, item.thumbnailUrl),
                ),
              ),
              title: Text(
                "${item.title} ∙ ${formatDuration(dur)}$viewedSrt",
                style: TextStyle(color: textColor),
              ),
              subtitle: Text(
                "${item.uploader} ∙ ${item.extractor} • ${formatDate(dt)} (${since(dt, true, Localizations.localeOf(context).languageCode)})",
                style: TextStyle(color: subtitleColor),
              ),
              trailing: right.isEmpty ? null : Wrap(children: right),
              onTap: () {
                setState(() => _selectedIndex = index);
                Navigator.restorablePushNamed(
                    context, MediaDetailsView.routeName(item.id),
                    arguments: item.id);
              },
            ),
            LinearProgressIndicator(
              backgroundColor: const Color.fromARGB(127, 158, 158, 158),
              value: item.duration == 0 ? null : item.position / item.duration,
            ),
          ],
        );
      },
    );
  }
}
