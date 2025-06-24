import 'dart:async';
import 'dart:io';

import 'package:background_downloader/background_downloader.dart';
import 'package:duration/duration.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:universal_platform/universal_platform.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../alert_dialog.dart';
import '../api/api.dart';
import '../api/api_riverpod.dart';
import '../api/downloads_riverpod.dart';
import '../api/local_download_task_riverpod.dart';
import '../api/directories_riverpod.dart';
import '../api/recording_riverpod.dart';
import '../model/download.dart';
import '../model/local_download.dart';
import '../model/recording_info.dart';
import '../settings/settings_provider.dart';
import '../settings/settings_view.dart';
import 'downloads_table.dart';
import 'format.dart';
import 'formats_table.dart';
import 'intents.dart';
import 'media_kit/audio_handler.dart';
import 'media_kit/recording_play.dart';
import 'media_list.dart';
import 'mpv.dart';

const _cleanServerMediaIcon = Icon(Icons.clear);
const _cleanDownloadedMediaIcon = Icon(Icons.cleaning_services);
const _copyCURLIcon = Icon(Icons.terminal);
const _hFlipIcon = Icon(Icons.flip_sharp);
const _playMpvIcon = Icon(Icons.play_circle);
// const _ffPlayer = "/app/bin/ffplay";
//const _ffmpeg = "/app/bin/ffmpeg";
const _mpvPlayer = "/app/bin/mpv";

class MediaDetailsView extends ConsumerStatefulWidget {
  const MediaDetailsView({
    super.key,
    this.id = "",
  });
  final String id;

  static String routeName(String id) {
    return "/$pathRecordings/$id";
  }

  @override
  ConsumerState<MediaDetailsView> createState() => _MediaDetailsViewState();
}

class _MediaDetailsViewState extends ConsumerState<MediaDetailsView> {
  String? title;
  StreamSubscription? _updatePullSubs;
  late String _mpvSocketPath;
  bool settingSeen = false;
  bool settingHidden = false;

  static const _updatePullPeriod = Duration(seconds: 3);

  @override
  void initState() {
    super.initState();

    _mpvSocketPath = "/tmp/${widget.id}";

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _pullRefresh();
    });

    _updatePullSubs = Stream.periodic(_updatePullPeriod).listen((event) {
      if (MKPlayerHandler.player.state.playing) {
        debugPrint("skip pull details while playing");
        return;
      }
      _pullRefresh();
    });
  }

  @override
  void deactivate() {
    _updatePullSubs?.cancel();
    super.deactivate();
  }

  void _toggleSeen(RecordingInfo recording) async {
    try {
      setState(() {
        settingSeen = true;
      });
      if (recording.seenAt == null) {
        await ref.read(setSeenProvider(recording.id).future);
      } else {
        await ref.read(unsetSeenProvider(recording.id).future);
      }
      await _pullRefresh();
    } finally {
      setState(() {
        settingSeen = false;
      });
    }
  }

  void _toggleHidden(RecordingInfo recording) async {
    try {
      setState(() {
        settingHidden = true;
      });
      if (recording.hiddenAt == null) {
        await ref.read(setHiddenProvider(recording.id).future);
      } else {
        await ref.read(unsetHiddenProvider(recording.id).future);
      }
      await _pullRefresh();
    } finally {
      setState(() {
        settingHidden = false;
      });
    }
  }

  void _sendPosition(String recordingId, Duration position, bool autoFinished) {
    if (ref.watch(settingsNotifierProvider.select((s) => s.value?.autoViewed)) == false) autoFinished = false;
    ref.read(putPositionProvider(recordingId, position, autoFinished));
  }

  (Download? local, Download? ready, Download? stale) _findAppropriateDownloads(List<Download> downloads) {
    Download? local;
    Download? ready;
    Download? stale;
    for (var d in downloads) {
      if (d.updatedAt == null) {
        continue;
      }
      if ((local == null || d.size > local.size) && d.fullPathMedia != null) {
        local = d;
      }
      if ((ready == null || d.updatedAt!.isAfter(ready.updatedAt!)) && d.status == "ready") {
        ready = d;
      }
      if ((stale == null || d.updatedAt!.isAfter(stale.updatedAt!)) && d.status == "stale") {
        stale = d;
      }
    }

    return (local, ready, stale);
  }

  Future<void> _pullRefresh() async {
    getMpvPlaybackPosition(_mpvSocketPath, (double? pos) {
      debugPrint("Current position: $pos");
      if (pos != null) _sendPosition(widget.id, Duration(seconds: pos.toInt()), false);
    });
    await ref.read(recordingNotifierProvider(widget.id).notifier).refreshFromServer();
    await ref.read(downloadsNotifierProvider(widget.id).notifier).refreshFromServer();
  }

  @override
  Widget build(BuildContext context) {
    final recording = ref.watch(recordingNotifierProvider(widget.id));
    // final downloads = ref.watch(listDownloadsProvider(widget.id));
    // if (downloads.hasValue && recording.hasValue) {
    //   var (ready, _) = _findAppropriateDownloads(downloads.requireValue);
    //   if (ready != null && _shouldPlay) {
    //     _recordView(context, recording.requireValue, ready);
    //     _shouldPlay = false;
    //   }
    // }
    return Shortcuts(
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.backspace): BackIntent(),
        SingleActivator(LogicalKeyboardKey.escape): BackIntent(),
        SingleActivator(LogicalKeyboardKey.keyR): RefreshIntent(),
        SingleActivator(LogicalKeyboardKey.f5): RefreshIntent(),
        SingleActivator(LogicalKeyboardKey.keyV): ToggleSeenIntent(),
        SingleActivator(LogicalKeyboardKey.keyH): ToggleHiddenIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          BackIntent: CallbackAction<BackIntent>(
            onInvoke: (BackIntent intent) {
              Navigator.of(context).pop(true);
              return null;
            },
          ),
          RefreshIntent: CallbackAction<RefreshIntent>(
            onInvoke: (RefreshIntent intent) {
              _pullRefresh();
              return null;
            },
          ),
          ToggleSeenIntent: CallbackAction<ToggleSeenIntent>(
            onInvoke: (ToggleSeenIntent intent) async {
              if (recording.hasValue) {
                _toggleSeen(recording.requireValue);
              }
              return null;
            },
          ),
          ToggleHiddenIntent: CallbackAction<ToggleHiddenIntent>(
            onInvoke: (ToggleHiddenIntent intent) async {
              if (recording.hasValue) {
                _toggleHidden(recording.requireValue);
              }
              return null;
            },
          ),
        },
        child: Focus(
          autofocus: true,
          child: Scaffold(
            appBar: AppBar(
              title: recording.hasValue ? Text(recording.requireValue.title) : const Text('Loading info...'),
              actions: [
                IconButton(
                  icon: _cleanServerMediaIcon,
                  tooltip: 'Clean all downloaded content on the server',
                  onPressed: () {
                    if (recording.hasValue) {
                      confirmDialog(context, "Are you sure?", "Delete all files on the server?", () {
                        ref.read(deleteRecordingDownloadsContentProvider(recording.requireValue.id));
                        _pullRefresh();
                        Navigator.pop(context);
                      });
                    }
                  },
                ),
                IconButton(
                  icon: _cleanDownloadedMediaIcon,
                  tooltip: 'Clean all downloaded media from the device',
                  onPressed: () {
                    confirmDialog(context, "Are you sure?", "Delete all local files on the device?", () {
                      ref.read(downloadsNotifierProvider(widget.id).notifier).cleanAll();
                      Navigator.pop(context);
                    });
                  },
                ),
                _addSeenButton(recording),
                _addHiddenButton(recording),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Refresh record (reread from the server)',
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
            body: Stack(
              children: [
                // Visibility(visible: recording.isLoading, child: const LinearProgressIndicator()),
                SingleChildScrollView(
                  child: _buildRecording(recording),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecording(AsyncValue<RecordingInfo> recording) {
    if (!recording.hasValue) {
      return const Center(child: Text('loading...'));
    }

    if (recording.hasError) {
      return ErrorWidget(recording.error!);
    }

    return _buildForm(context, recording.requireValue);
  }

  Widget _buildForm(BuildContext context, RecordingInfo recording) {
    final downloads = ref.watch(downloadsNotifierProvider(recording.id));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(context, recording),
        _buildPreview(context, recording, downloads),
        if (downloads.hasValue) ...[
          _localDownloadsTable(context, recording, downloads.requireValue),
          Center(
            child: DownloadsTable(
              recording: recording,
              downloads: downloads.requireValue,
              recordView: _recordView,
              startPreparation: _startPreparation,
              buildActions: _buildActions,
              buildLocalActions: _buildLocalActions,
            ),
          ),
        ] else
          const Text("Downloads info is loading..."),
        if (recording.formats != null && recording.formats!.isNotEmpty)
          Center(
            child: FormatsTable(
              recording: recording,
              startPreparation: _startPreparation,
            ),
          )
        else
          const Text("No formats for the record"),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, RecordingInfo recording) {
    return Center(
      child: InkWell(
        onTap: () async => await launchUrlString(recording.webpageUrl),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("${recording.id}: ${recording.title}", style: Theme.of(context).textTheme.bodyLarge),
                Text("${recording.uploader} • ${recording.extractor}"),
                Text("Created at: ${formatDateLong(recording.createdAt)} (${since(recording.createdAt, false)} ago)"),
                Text("Updated at: ${formatDateLong(recording.updatedAt)} (${since(recording.updatedAt, false)} ago)"),
                Row(
                  children: [
                    Text(recording.webpageUrl, style: const TextStyle(overflow: TextOverflow.fade, decoration: TextDecoration.underline, color: Colors.blue)),
                    IconButton(
                      icon: copyURLIcon,
                      tooltip: 'Copy video URL to the clipboard',
                      onPressed: () => copyToClipboard(context, recording.webpageUrl),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPreview(BuildContext context, RecordingInfo recording, AsyncValue<List<Download>> downloads) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: InkWell(
          onTap: () {
            var (local, ready, stale) = downloads.hasValue ? _findAppropriateDownloads(downloads.requireValue) : (null, null, null);
            if (local != null) {
              _recordView(context, recording, local);
            } else if (ready != null) {
              _recordView(context, recording, ready);
            } else if (stale != null) {
              _startPreparation(context, stale.formatId);
            }
          },
          child: Column(
            children: [
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.5,
                child: createThumb(ref, recording.thumbnailUrl),
              ),
              LinearProgressIndicator(
                backgroundColor: const Color.fromARGB(127, 158, 158, 158),
                value: recording.duration == 0 ? null : recording.position / recording.duration,
              ),
              Text("${formatDuration(Duration(seconds: recording.position))} / ${formatDuration(Duration(seconds: recording.duration))}"),
            ],
          ),
        ),
      ),
    );
  }

  Widget ldline(LocalDownloadTask dt) {
    var st = dt.status?.toString() ?? "";
    const p = "TaskStatus.";
    st = st.startsWith(p) ? st.replaceFirst(p, "") : st;
    var eta = dt.timeRemaining == null ? "" : prettyDuration(dt.timeRemaining!, abbreviated: true);
    var est = dt.networkSpeed == null || dt.networkSpeed! < 0 ? "" : " ≈ ${dt.networkSpeed?.toStringAsFixed(2) ?? ''} Mb/s, ETA: $eta";

    return Column(
      children: [
        Text("Local downloading $st: ${dt.filename} $est"),
        if (dt.status?.isFinalState != true) LinearProgressIndicator(value: dt.progress),
      ],
    );
  }

  Widget _localDownloadsTable(BuildContext context, RecordingInfo recording, List<Download> downloads) {
    final downloadTasks = ref.watch(localDTNotifierProvider.select((value) {
      return <String, LocalDownloadTask>{
        for (final d in downloads)
          if (value.containsKey(d.id)) d.id: value[d.id]!
      };
    }));

    if (downloadTasks.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [for (final dt in downloadTasks.values) ldline(dt)],
      ),
    );
  }

  Future<void> _startPreparation(BuildContext context, String format) async {
    ref.read(newDownloadProvider(widget.id, format).future).then((d) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
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
      MaterialPageRoute(builder: (BuildContext context) => RecordingViewMediaKitHandler(recording: recording, download: d)),
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
          tooltip: "Download this format again on the server (prepare for viewing)",
          icon: downloadFormatIcon,
        );
      case "new":
      case "in_progress":
        return Center(child: CircularProgressIndicator(value: d.progressByLastLine()));
      case "ready":
        return Row(
          children: [
            IconButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (BuildContext context) => RecordingViewMediaKitHandler(recording: recording, download: d)),
                );
              },
              onLongPress: () async {
                final p =
                    await Process.start("/usr/bin/flatpak-spawn", <String>[_mpvPlayer, "--title=${recording.title}", "--start=${recording.position}", "--input-ipc-server=$_mpvSocketPath", d.url]);
                await stdout.addStream(p.stdout);
                await stderr.addStream(p.stderr);
              },
              tooltip: "Open with MediaKit with handler",
              icon: const Icon(Icons.flag_circle_outlined),
            ),
            PopupMenuButton(
                tooltip: 'Do with it...',
                icon: const Icon(Icons.more_vert),
                onSelected: (String choice) async {
                  switch (choice) {
                    case "copy":
                      copyToClipboard(context, d.url);
                    case "copy-curl":
                      copyToClipboard(context, "curl '${d.url}' -o '${d.filename}'");
                    case "mpv-play":
                      final p = await Process.start("/usr/bin/flatpak-spawn",
                          <String>[_mpvPlayer, "--start=${recording.position}", "--title=${recording.title}", "--input-ipc-server=$_mpvSocketPath", d.fullPathMedia ?? d.url]);
                      await stdout.addStream(p.stdout);
                      await stderr.addStream(p.stderr);
                    case "mpv-play-horizontal-flip":
                      final p = await Process.start("/usr/bin/flatpak-spawn",
                          <String>[_mpvPlayer, "--vf=hflip", "--start=${recording.position}", "--title=${recording.title}", "--input-ipc-server=$_mpvSocketPath", d.fullPathMedia ?? d.url]);
                      await stdout.addStream(p.stdout);
                      await stderr.addStream(p.stderr);
                    case "default":
                      launchUrlString(d.url);
                    case "server-delete":
                      confirmDialog(context, "Are you sure?", "Delete server media file?", () {
                        ref.read(deleteDownloadContentProvider(d.id));
                        _pullRefresh();
                        Navigator.pop(context);
                      });
                    case "local-delete":
                      confirmDialog(context, "Are you sure?", "Delete local downloaded media file?", () {
                        ref.read(downloadsNotifierProvider(recording.id).notifier).clean(d.id);
                        Navigator.pop(context);
                      });
                    case "share-url":
                      await Share.shareUri(Uri.parse(d.url));
                    case "download":
                      if (UniversalPlatform.isWeb) {
                        return;
                      }
                      downloadFile(context, d);
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
                          copyURLIcon,
                          Expanded(child: Text("Copy file link to clipboard")),
                        ],
                      ),
                    ),
                  );
                  menuItems.add(
                    const PopupMenuItem<String>(
                      value: "copy-curl",
                      child: Row(
                        children: [
                          _copyCURLIcon,
                          Expanded(child: Text("Copy curl command to clipboard")),
                        ],
                      ),
                    ),
                  );
                  menuItems.add(
                    const PopupMenuItem<String>(
                      value: "mpv-play",
                      child: Row(
                        children: [
                          _playMpvIcon,
                          Expanded(child: Text("Play with embedded mpv player")),
                        ],
                      ),
                    ),
                  );
                  menuItems.add(
                    const PopupMenuItem<String>(
                      value: "mpv-play-horizontal-flip",
                      child: Row(
                        children: [
                          _playMpvIcon,
                          _hFlipIcon,
                          Expanded(child: Text("Play with embedded mpv player with horizontal flip")),
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
                          Expanded(child: Text("Open in default application")),
                        ],
                      ),
                    ),
                  );
                  menuItems.add(
                    const PopupMenuItem<String>(
                      value: "server-delete",
                      child: Row(
                        children: [
                          _cleanServerMediaIcon,
                          Expanded(
                            child: Text("Delete file on the server and free server usage quota"),
                          ),
                        ],
                      ),
                    ),
                  );

                  if (!UniversalPlatform.isWeb) {
                    menuItems.add(
                      const PopupMenuItem<String>(
                        value: "local-delete",
                        child: Row(
                          children: [
                            _cleanDownloadedMediaIcon,
                            Expanded(child: Text("Delete local file")),
                          ],
                        ),
                      ),
                    );
                    if (UniversalPlatform.isMobile) {
                      menuItems.add(
                        const PopupMenuItem<String>(
                          value: "share-url",
                          child: Row(
                            children: [
                              Icon(Icons.ios_share),
                              Expanded(
                                child: Text("Share the download URL in..."),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    menuItems.add(
                      const PopupMenuItem<String>(
                        value: "download",
                        child: Row(
                          children: [
                            Icon(Icons.download),
                            Expanded(child: Text("Download local file")),
                          ],
                        ),
                      ),
                    );
                  }
                  return menuItems;
                }),
          ],
        );
      default:
        return ErrorWidget("Unexpected download status ${d.status}");
    }
  }

  Widget _buildLocalActions(
    BuildContext context,
    RecordingInfo recording,
    Download d,
  ) {
    if (d.fullPathMedia != null) {
      return IconButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (BuildContext context) => RecordingViewMediaKitHandler(recording: recording, download: d)),
          );
        },
        onLongPress: () async {
          final p = await Process.start(
              "/usr/bin/flatpak-spawn", <String>[_mpvPlayer, "--title=${recording.title}", "--start=${recording.position}", "--input-ipc-server=$_mpvSocketPath", d.fullPathMedia!]);
          await stdout.addStream(p.stdout);
          await stderr.addStream(p.stderr);
        },
        tooltip: "Local file is downloaded. Click to play.",
        icon: const Icon(Icons.download_done),
      );
    }
    switch (d.status) {
      case "stale":
      case "new":
      case "in_progress":
        return const SizedBox.shrink();
      case "ready":
        if (UniversalPlatform.isWeb) {
          return const SizedBox.shrink();
        }
        return IconButton(
          onPressed: () {
            downloadFile(context, d);
          },
          icon: const Icon(Icons.download),
          tooltip: "Download media to local storage",
        );
      default:
        return ErrorWidget("Unexpected download status ${d.status}");
    }
  }

  Widget _addSeenButton(AsyncValue<RecordingInfo> recording) {
    if (!recording.hasValue) {
      return const SizedBox();
    }

    if (settingSeen) {
      return const Center(child: CircularProgressIndicator());
    }

    final r = recording.requireValue;

    if (r.seenAt == null) {
      return IconButton(
        icon: const Icon(Icons.check_box_outline_blank_rounded),
        tooltip: 'Mark this recording as seen',
        onPressed: () async {
          _toggleSeen(r);
        },
      );
    } else {
      return IconButton(
        icon: const Icon(Icons.check_box_outlined),
        tooltip: 'Mark this recording as unseen',
        onPressed: () async {
          _toggleSeen(r);
        },
      );
    }
  }

  Widget _addHiddenButton(AsyncValue<RecordingInfo> recording) {
    if (!recording.hasValue) {
      return const Icon(null);
    }

    if (settingHidden) {
      return const Center(child: CircularProgressIndicator());
    }

    final r = recording.requireValue;

    if (r.hiddenAt == null) {
      return IconButton(
        icon: const Icon(Icons.visibility_outlined),
        tooltip: 'Hide this recording (archive it)',
        onPressed: () async {
          _toggleHidden(r);
        },
      );
    } else {
      return IconButton(
        icon: const Icon(Icons.visibility_off_outlined),
        tooltip: 'Show this recording (unarchive it)',
        onPressed: () async {
          _toggleHidden(r);
        },
      );
    }
  }

  Future<void> downloadFile(BuildContext context, Download download) async {
    final sp = await (context as WidgetRef).watch(storePlacesProvider.future);

    final task = DownloadTask(
      taskId: download.id,
      url: download.url,
      directory: sp.media().path,
      baseDirectory: BaseDirectory.root,
      filename: download.filename,
      retries: 8,
      updates: Updates.statusAndProgress,
      displayName: download.title,
      metaData: download.recordingId,
    );

    FileDownloader().enqueue(task);
  }
}

Future<void> copyToClipboard(BuildContext context, String textData) async {
  await Clipboard.setData(ClipboardData(text: textData)).then((value) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('$textData copied to clipboard'),
    ));
  });
}
