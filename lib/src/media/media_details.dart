import 'dart:async';
import 'dart:convert';
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
import '../settings/settings_view.dart';
import 'download_details.dart';
import 'format.dart';
import 'intents.dart';
import 'media_kit/audio_handler.dart';
import 'media_kit/recording_play.dart';
import 'media_list.dart';

const _cleanServerMediaIcon = Icon(Icons.clear);
const _cleanDownloadedMediaIcon = Icon(Icons.cleaning_services);
const _downloadFormatIcon = Icon(Icons.start);
const _copyURLIcon = Icon(Icons.copy);
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

  static const _updatePullPeriod = Duration(seconds: 3);

  @override
  void initState() {
    super.initState();

    _pullRefresh();

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
                final r = recording.requireValue;
                if (r.seenAt == null) {
                  await ref.read(setSeenProvider(r.id).future);
                  _pullRefresh();
                } else {
                  await ref.read(unsetSeenProvider(r.id).future);
                  _pullRefresh();
                }
              }
              return null;
            },
          ),
          ToggleHiddenIntent: CallbackAction<ToggleHiddenIntent>(
            onInvoke: (ToggleHiddenIntent intent) async {
              if (recording.hasValue) {
                final r = recording.requireValue;
                if (r.hiddenAt == null) {
                  await ref.read(setHiddenProvider(r.id).future);
                  _pullRefresh();
                } else {
                  await ref.read(unsetHiddenProvider(r.id).future);
                  _pullRefresh();
                }
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
                      _pullRefresh();
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
        InkWell(
          onTap: () async {
            await launchUrlString(recording.webpageUrl);
          },
          onLongPress: () async {},
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "${recording.id}: ${recording.title}",
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  // Text("Record id: ${recording.id}"),
                  Text("${recording.uploader} • ${recording.extractor}"),
                  Text("Created at: ${formatDateLong(recording.createdAt)} (${since(recording.createdAt, false)} ago)"),
                  Text("Updated at: ${formatDateLong(recording.updatedAt)} (${since(recording.updatedAt, false)} ago)"),
                  Row(
                    children: [
                      Text(
                        recording.webpageUrl,
                        style: const TextStyle(
                          overflow: TextOverflow.fade,
                          decoration: TextDecoration.underline,
                          color: Colors.blue,
                        ),
                      ),
                      IconButton(
                        icon: _copyURLIcon,
                        tooltip: 'Copy video URL to the clipboard',
                        onPressed: () {
                          copyToClipboard(context, recording.webpageUrl);
                        },
                      ),
                    ],
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
        ),
        Center(child: downloads.hasValue ? _localDownloadsTable(context, recording, downloads.requireValue) : const SizedBox.shrink()),
        Center(child: downloads.hasValue ? _downloadsTable(context, recording, downloads.requireValue) : const Text("Downloads info is loading...")),
        Center(child: recording.formats == null || recording.formats!.isEmpty ? const Text("No formats for the record") : _formatsTable(context, recording)),
      ],
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

  Widget _downloadsTable(BuildContext context, RecordingInfo recording, List<Download> downloads) {
    const splitter = LineSplitter();

    var rows = List<DataRow>.generate(downloads.length, (i) {
      final d = downloads[i];
      final ll = splitter.convert(d.progress);
      final pr = ll.isEmpty ? '' : ll[ll.length - 1];
      final hr = fileSizeHumanReadable(d.size);
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
              child: Text(d.formatId),
            ),
          ),
        ),
        DataCell(Row(
          children: [
            _buildActions(context, recording, d),
            _buildLocalActions(context, recording, d),
          ],
        )),
        DataCell(Opacity(opacity: opacity, child: Text(d.resolution))),
        DataCell(Opacity(opacity: opacity, child: Text(d.fps != null ? "${d.fps}" : ""))),
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
        DataCell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (BuildContext context) => DownloadDetailsView(downloadId: d.id)),
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
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Files for this recording",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  DataTable(
                    columnSpacing: 12,
                    columns: const [
                      DataColumn(label: Expanded(child: Text("format", style: headerStyle))),
                      DataColumn(label: Expanded(child: Text("", style: headerStyle))),
                      DataColumn(label: Expanded(child: Text("resolution", style: headerStyle))),
                      DataColumn(label: Expanded(child: Text("fps", style: headerStyle))),
                      DataColumn(label: Expanded(child: Text("", style: headerStyle))),
                      DataColumn(label: Expanded(child: Text("size", style: headerStyle))),
                      DataColumn(label: Expanded(child: Text("", style: headerStyle))),
                    ],
                    rows: rows,
                  ),
                ],
              ),
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
                _startPreparation(context, "${f.id}+ba");
              },
              tooltip: "Download this format and the best audio on the server (prepare for viewing)",
              icon: _downloadFormatIcon,
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
          DataCell(
            f.url != ""
                ? IconButton(
                    onPressed: () {
                      copyToClipboard(context, f.url);
                    },
                    tooltip: "Copy URL this fragment into clipboard",
                    icon: _copyURLIcon,
                  )
                : const SizedBox.shrink(),
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
            "Common available formats:",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          TextButton.icon(
            onPressed: () {
              _startPreparation(context, "ba");
            },
            icon: const Icon(Icons.audiotrack_rounded),
            label: const Text("Best audio (ba)"),
          ),
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
                DataColumn(label: Expanded(child: Text("URL", style: headerStyle))),
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
          icon: _downloadFormatIcon,
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
              onLongPress: () {
                Process.start("/usr/bin/flatpak-spawn", <String>[_mpvPlayer, "--start=${recording.position}", d.url]);
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
                      Process.start("/usr/bin/flatpak-spawn", <String>[_mpvPlayer, "--start=${recording.position}", d.fullPathMedia ?? d.url]);
                    case "mpv-play-horizontal-flip":
                      Process.start("/usr/bin/flatpak-spawn", <String>[_mpvPlayer, "--vf=hflip", "--start=${recording.position}", d.fullPathMedia ?? d.url]);
                    case "default":
                      launchUrlString(d.url);
                    case "server-delete":
                      confirmDialog(context, "Are you sure?", "Delete server media file?", () {
                        ref.read(deleteDownloadContentProvider(d.id));
                        _pullRefresh();
                      });
                    case "local-delete":
                      confirmDialog(context, "Are you sure?", "Delete local downloaded media file?", () {
                        ref.read(downloadsNotifierProvider(recording.id).notifier).clean(d.id);
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
                          _copyURLIcon,
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
        onLongPress: () {
          Process.start("/usr/bin/flatpak-spawn", <String>[_mpvPlayer, "--start=${recording.position}", d.fullPathMedia!]);
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

    final r = recording.requireValue;

    if (r.seenAt == null) {
      return IconButton(
        icon: const Icon(Icons.check_box_outline_blank_rounded),
        tooltip: 'Mark this recording as seen',
        onPressed: () async {
          await ref.read(setSeenProvider(r.id).future);
          _pullRefresh();
        },
      );
    } else {
      return IconButton(
        icon: const Icon(Icons.check_box_outlined),
        tooltip: 'Mark this recording as unseen',
        onPressed: () async {
          await ref.read(unsetSeenProvider(r.id).future);
          _pullRefresh();
        },
      );
    }
  }

  Widget _addHiddenButton(AsyncValue<RecordingInfo> recording) {
    if (!recording.hasValue) {
      return const Icon(null);
    }

    final r = recording.requireValue;

    if (r.hiddenAt == null) {
      return IconButton(
        icon: const Icon(Icons.visibility_outlined),
        tooltip: 'Hide this recording (archive it)',
        onPressed: () async {
          await ref.read(setHiddenProvider(r.id).future);
          _pullRefresh();
        },
      );
    } else {
      return IconButton(
        icon: const Icon(Icons.visibility_off_outlined),
        tooltip: 'Show this recording (unarchive it)',
        onPressed: () async {
          await ref.read(unsetHiddenProvider(r.id).future);
          _pullRefresh();
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
