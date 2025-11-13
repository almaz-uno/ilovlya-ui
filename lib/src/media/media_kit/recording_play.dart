import 'dart:async';
import 'dart:io';

import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:background_downloader/background_downloader.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:path/path.dart' as p;
import 'package:universal_platform/universal_platform.dart';

import '../../api/api_riverpod.dart';
import '../../api/local_download_task_riverpod.dart';
import '../../api/media_list_riverpod.dart';
import '../../api/recording_riverpod.dart';
import '../../api/thumbnail_riverpod.dart';
import '../../localization/app_localizations.dart';
import '../../model/download.dart';
import '../../model/local_download.dart';
import '../../model/recording_info.dart';
import '../../settings/settings_provider.dart';
import '../../theme/media_player_theme.dart';
import '../../utils/logger_provider.dart';
import '../../utils/task_status_localization.dart';
import '../format.dart';
import '../intents.dart';
import '../media_details.dart';
import '../media_list.dart';
import 'audio_handler.dart';

String _formatDuration(Duration duration) {
  var positive = true;
  if (duration.isNegative) {
    positive = false;
    duration = -duration;
  }
  return (positive ? "" : "⏴⏴ ") + formatDuration(duration) + (positive ? " ⏵⏵" : "");
}

class RecordingViewMediaKitHandler extends ConsumerStatefulWidget {
  final RecordingInfo recording;
  final Download download;
  final bool inFull;

  const RecordingViewMediaKitHandler({
    super.key,
    required this.recording,
    required this.download,
    this.inFull = false,
  });

  @override
  ConsumerState<RecordingViewMediaKitHandler> createState() => _RecordingViewMediaKitHandlerState();
}

const _positionSendPeriod = Duration(seconds: 1);

class _RecordingViewMediaKitHandlerState extends ConsumerState<RecordingViewMediaKitHandler> {
  // String get url => widget.download.url;
  Player get _player => MKPlayerHandler.player;
  late final _controller = VideoController(_player, configuration: VideoControllerConfiguration(enableHardwareAcceleration: !UniversalPlatform.isLinux));
  StreamSubscription? _positionSendSubs;
  Duration _rewinding = Duration.zero;
  Timer? _rewindTimer;
  bool _hasAttemptedSwitch = false; // Flag to prevent multiple switch attempts

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _init();
    });
  }

  void _init() async {
    final thumbnailUrl = UniversalPlatform.isWeb ? Uri.parse(widget.recording.thumbnailUrl) : (await ref.read(thumbnailDataNotifierProvider(widget.recording.thumbnailUrl).notifier).getThumbnailUri());

    final settings = ref.read(settingsNotifierProvider).requireValue;
    final useCaching = settings.downloadWhilePlaying;
    final mediaDirectory = settings.mediaStorageDirectory;

    MKPlayerHandler.handler.playRecording(
      widget.recording,
      widget.download,
      thumbnailUrl,
      useCaching: useCaching,
      mediaDirectory: mediaDirectory,
    );

    if (UniversalPlatform.isDesktop || UniversalPlatform.isWeb) {
      await _player.setVolume(ref.read(settingsNotifierProvider).requireValue.volume);
    }

    _player.stream.duration.listen((event) {
      if (!mounted) return;
      _seek(Duration(seconds: widget.recording.position));
      _player.play();
      _player.setRate(ref.read(settingsNotifierProvider.select((s) => s.value?.playerSpeed)) ?? 1.0);
    });

    _player.stream.buffering.listen((event) {
      if (!mounted) return;
      setState(() {});
    });

    _player.stream.buffer.listen((event) {
      if (!mounted) return;
      setState(() {});
    });

    _player.stream.playing.listen((event) {
      if (!mounted) return;
      setState(() {});
    });

    _player.stream.videoParams.listen((event) {
      if (!mounted) return;
      setState(() {});
    });

    _player.stream.volume.listen((double volume) {
      if (!mounted) return;
      setState(() {});
      ref.read(settingsNotifierProvider.notifier).updateVolume(volume);
    });

    _player.stream.completed.listen((event) {
      if (!mounted) return;
      _sendPosition(
        widget.recording.id,
        _player.state.position,
        event,
      );
      setState(() {});
    });

    _player.stream.position.listen((Duration position) {
      if (!mounted) return;
      setState(() {});
    });

    _positionSendSubs = Stream.periodic(_positionSendPeriod).listen((event) {
      if (!mounted) return;
      if (_player.state.playing && !_player.state.buffering && _player.state.position != Duration.zero) {
        _sendPosition(
          widget.recording.id,
          _player.state.position,
          _player.state.position == _player.state.duration,
        );
      }
      setState(() {});
    });
  }

  /// Switch playback from remote to local file
  Future<void> _switchToLocalFile(LocalDownloadTask task) async {
    if (!mounted) return;

    final settings = ref.read(settingsNotifierProvider).requireValue;
    final localFilePath = p.join(settings.mediaStorageDirectory, task.filename);
    final localFile = File(localFilePath);

    // 1. Verify file exists
    if (!localFile.existsSync()) {
      AppLoggers.player.e('Cannot switch to local file: file not found at $localFilePath');
      final l10n = AppLocalizations.of(context)!;
      _showErrorSnackBar(l10n.localFileNotFound(task.filename));
      return;
    }

    // 2. Check if already playing from local file
    if (_player.state.playlist.medias.isEmpty) {
      AppLoggers.player.w('Playlist is empty, cannot check current source');
      return;
    }

    final currentSource = _player.state.playlist.medias[0].uri;
    final localFileUri = 'file://$localFilePath';
    AppLoggers.player.d("Current source: $currentSource, Local file URI: $localFileUri");

    if (currentSource == localFileUri) {
      AppLoggers.player.i('Already playing from local file: ${task.filename}');
      return;
    }

    // 3. Save current playback state
    final currentPosition = _player.state.position;
    final isPlaying = _player.state.playing;

    AppLoggers.player.i('Switching to local file: ${task.filename} at position ${currentPosition.inSeconds}s');

    try {
      // 4. Save position to recording (will be restored automatically on open)
      _sendPosition(
        widget.recording.id,
        currentPosition,
        false, // Not finished
      );

      widget.recording.position = currentPosition.inSeconds;

      // 4. Open local file
      await _player.open(
        Media('file://$localFilePath'),
        play: false, // Don't play yet
      );

      // 5. Restore playback state
      if (isPlaying) {
        await _player.play();
      }

      // 6. Show success notification
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        _showSuccessSnackBar(l10n.nowPlayingFromLocalFile(task.filename));
      }

      AppLoggers.player.i('Successfully switched to local file: ${task.filename}');
    } catch (e, s) {
      AppLoggers.player.e(
        'Failed to switch to local file',
        error: e,
        stackTrace: s,
      );

      // Revert to remote source on error
      try {
        final thumbnailUrl =
            UniversalPlatform.isWeb ? Uri.parse(widget.recording.thumbnailUrl) : (await ref.read(thumbnailDataNotifierProvider(widget.recording.thumbnailUrl).notifier).getThumbnailUri());

        // Save position to recording before reverting
        _sendPosition(
          widget.recording.id,
          currentPosition,
          false,
        );

        MKPlayerHandler.handler.playRecording(
          widget.recording,
          widget.download,
          thumbnailUrl,
          useCaching: true,
          mediaDirectory: settings.mediaStorageDirectory,
        );

        if (isPlaying) {
          await _player.play();
        }

        if (mounted) {
          final l10n = AppLocalizations.of(context)!;
          _showErrorSnackBar(l10n.failedToSwitchToLocalFile(e.toString()));
        }
      } catch (revertError) {
        AppLoggers.player.e('Failed to revert to remote source', error: revertError);
      }
    }
  }

  /// Show success SnackBar
  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Show error SnackBar
  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  @override
  void deactivate() async {
    MKPlayerHandler.player.stop();
    MKPlayerHandler.clearMediaSession(); // Clear lock screen notification
    _positionSendSubs?.cancel();
    super.deactivate();
  }

  @override
  void activate() {
    super.activate();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _rewind(Duration interval) {
    _seek(_player.state.position + interval);

    if (_rewindTimer != null) {
      _rewinding += interval;
      _rewindTimer?.cancel();
    } else {
      _rewinding = interval;
    }

    _rewindTimer = Timer(const Duration(seconds: 3), () {
      setState(() {
        _rewinding = Duration.zero;
      });
    });
  }

  void _seek(Duration position) {
    if (position.isNegative) {
      position = Duration.zero;
    }
    if (position > _player.state.duration) {
      position = _player.state.duration;
    }
    _player.seek(position);
  }

  void _sendPosition(String recordingId, Duration position, bool autoFinished) {
    if (ref.watch(settingsNotifierProvider.select((s) => s.value?.autoViewed)) == false) autoFinished = false;
    ref.read(recordingNotifierProvider(recordingId).notifier).putPosition(position, autoFinished);
    ref.read(putPositionProvider(recordingId, position, autoFinished));
  }

  @override
  Widget build(BuildContext context) {
    double aspectRatio = 9.0 / 16.0;
    if (_player.state.width != null && _player.state.height != null && _player.state.width != 0 && _player.state.height != 0) {
      aspectRatio = _player.state.height!.toDouble() / _player.state.width!.toDouble();
    }

    double mediaW = MediaQuery.of(context).size.width * 0.8;
    double mediaH = MediaQuery.of(context).size.height * 0.8;

    double playerW = mediaW;
    double playerH = mediaW * aspectRatio;

    if (playerH > mediaH) {
      playerH = mediaH;
      playerW = playerW * mediaH / playerH;
    }

    final settings = ref.watch(settingsNotifierProvider);
    // final rewindTextStyle = Theme.of(context).textTheme.titleSmall;
    final techInfoStyle = GoogleFonts.ptMono();
    return PopScope(
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        final updateThumbnails = ref.read(settingsNotifierProvider.select((value) => value.requireValue.updateThumbnails));
        if (!UniversalPlatform.isWeb && updateThumbnails) {
          MKPlayerHandler.player.screenshot(format: "image/png").then((imgData) {
            ref.read(thumbnailDataNotifierProvider(widget.recording.thumbnailUrl).notifier).updateThumbnailImg(imgData);
          });
        }

        ref.invalidate(recordingNotifierProvider(widget.recording.id));
        ref.invalidate(mediaListNotifierProvider);
      },
      child: Scaffold(
        // appBar: AppBar(
        //   centerTitle: true,
        //   // toolbarHeight: titleSmall?.height,
        //   scrolledUnderElevation: null,
        //   elevation: null,
        //   title: Text(
        //     "${widget.recording.title} • ${formatDuration(_player.state.duration)}",
        //     // textScaler: TextScaler.linear(0.5),
        //     style: titleSmall,
        //   ),
        //   // actions: [
        //   //   IconButton(
        //   //     onPressed: () {},
        //   //     icon: const Icon(Icons.open_in_full),
        //   //   )
        //   // ],
        // ),
        body: SafeArea(
          child: Shortcuts(
            shortcuts: const <ShortcutActivator, Intent>{
              SingleActivator(LogicalKeyboardKey.backspace): BackIntent(),
              SingleActivator(LogicalKeyboardKey.escape): BackIntent(),
              SingleActivator(LogicalKeyboardKey.space): PlayPauseIntent(),
              SingleActivator(
                LogicalKeyboardKey.arrowLeft,
                control: true,
                shift: true,
              ): ChangePositionIntent(Duration(seconds: -300)),
              SingleActivator(LogicalKeyboardKey.arrowLeft, control: false, shift: true): ChangePositionIntent(Duration(seconds: -60)),
              SingleActivator(LogicalKeyboardKey.arrowLeft, control: true, shift: false): ChangePositionIntent(Duration(seconds: -30)),
              SingleActivator(LogicalKeyboardKey.arrowLeft, control: false, shift: false): ChangePositionIntent(Duration(seconds: -10)),
              SingleActivator(LogicalKeyboardKey.arrowRight, control: true, shift: true): ChangePositionIntent(Duration(seconds: 300)),
              SingleActivator(LogicalKeyboardKey.arrowRight, control: false, shift: true): ChangePositionIntent(Duration(seconds: 60)),
              SingleActivator(LogicalKeyboardKey.arrowRight, control: true, shift: false): ChangePositionIntent(Duration(seconds: 30)),
              SingleActivator(LogicalKeyboardKey.arrowRight, control: false, shift: false): ChangePositionIntent(Duration(seconds: 10)),
              SingleActivator(LogicalKeyboardKey.arrowDown, control: false, shift: false): ChangeVolumeIntent(-5),
              SingleActivator(LogicalKeyboardKey.arrowUp, control: false, shift: false): ChangeVolumeIntent(5),
            },
            child: Actions(
              actions: <Type, Action<Intent>>{
                BackIntent: CallbackAction<BackIntent>(
                  onInvoke: (BackIntent intent) {
                    Navigator.of(context).pop(true);
                    return null;
                  },
                ),
                PlayPauseIntent: CallbackAction<PlayPauseIntent>(onInvoke: (PlayPauseIntent intent) {
                  _player.playOrPause();
                  return null;
                }),
                ChangePositionIntent: CallbackAction<ChangePositionIntent>(onInvoke: (ChangePositionIntent intent) {
                  _rewind(intent.duration);
                  return null;
                }),
                ChangeVolumeIntent: CallbackAction<ChangeVolumeIntent>(onInvoke: (ChangeVolumeIntent intent) {
                  var nv = (_player.state.volume).toInt() + intent.change;
                  if (nv < 0) {
                    nv = 0;
                  }
                  if (nv > 100) {
                    nv = 100;
                  }

                  _player.setVolume(nv.toDouble());
                  return null;
                }),
              },
              child: Focus(
                autofocus: true,
                child: SingleChildScrollView(
                  child: Column(
                    children: <Widget>[
                      Row(
                        children: [
                          const BackButton(),
                          Expanded(child: Text("${widget.recording.title} • ${formatDuration(_player.state.duration)}")),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                        child: SizedBox(
                          width: playerW,
                          height: playerH,
                          child: Stack(
                            alignment: Alignment.topCenter,
                            children: <Widget>[
                              Video(
                                controller: _controller,
                                pauseUponEnteringBackgroundMode: false,
                                resumeUponEnteringForegroundMode: true,
                                onEnterFullscreen: _onEnterFullscreen,
                              ),
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 500),
                                child: Text(
                                  _rewinding != Duration.zero ? _formatDuration(_rewinding) : "",
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white),
                                  key: ValueKey(_rewinding),
                                ),
                              ),
                              if (!widget.download.hasVideo)
                                SizedBox(
                                  width: playerW,
                                  height: playerH,
                                  child: createThumb(ref, widget.recording.thumbnailUrl),
                                ),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                        child: PlayerControls(
                          player: _player,
                          onSeek: (duration) => _seek(duration),
                          onRewind: (interval) => _rewind(interval),
                          ref: ref,
                        ),
                      ),
                      // Download progress indicator
                      Consumer(
                        builder: (context, ref, child) {
                          // Find task for current download using selector
                          final task = ref.watch(localDTNotifierProvider.select((tasks) => tasks[widget.download.id]));

                          // Check if download completed and file exists, then switch to local
                          if (task != null && task.status == TaskStatus.complete && !_hasAttemptedSwitch) {
                            final settings = ref.read(settingsNotifierProvider).requireValue;
                            final localFilePath = p.join(settings.mediaStorageDirectory, task.filename);
                            final localFile = File(localFilePath);

                            if (localFile.existsSync()) {
                              // Schedule switch after this frame to avoid calling setState during build
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (!_hasAttemptedSwitch && mounted) {
                                  _hasAttemptedSwitch = true;
                                  _switchToLocalFile(task);
                                }
                              });
                            }
                          }

                          // Show progress only if task exists, is not complete, and has progress
                          if (task != null && task.status != null) {
                            final l10n = AppLocalizations.of(context)!;

                            // Localize status
                            final localizedStatus = TaskStatusLocalization.getLocalizedStatusWithFallback(task.status!, l10n);

                            // Format estimate (speed and ETA)
                            final eta = task.timeRemaining == null ? "" : formatDuration(task.timeRemaining!);
                            final est = task.networkSpeed == null || task.networkSpeed! < 0 ? "" : " ≈ ${task.networkSpeed!.toStringAsFixed(2)} MB/s, ETA: $eta";

                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          l10n.localDownloadingStatus(localizedStatus, task.filename, est),
                                          style: Theme.of(context).textTheme.bodySmall,
                                        ),
                                      ),
                                      if (task.progress != null)
                                        Text(
                                          '${(task.progress! * 100).round()}%',
                                          style: Theme.of(context).textTheme.bodySmall,
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  LinearProgressIndicator(value: task.progress, minHeight: 2),
                                ],
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                      Container(
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.all(8),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(AppLocalizations.of(context)!
                                  .createdAtWithDate(formatDateLong(widget.recording.createdAt), since(widget.recording.createdAt, false, Localizations.localeOf(context).languageCode))),
                              if (_player.state.playlist.medias.isNotEmpty)
                                Row(
                                  children: [
                                    Text("${AppLocalizations.of(context)!.playingFrom}: ${_player.state.playlist.medias[0].uri}"),
                                    IconButton(
                                      onPressed: () {
                                        copyToClipboard(context, _player.state.playlist.medias[0].uri);
                                      },
                                      icon: const Icon(Icons.copy),
                                    )
                                  ],
                                ),
                              Text("${AppLocalizations.of(context)!.sizeLabel}: ${fileSizeHumanReadable(widget.download.size)}"),
                            ],
                          ),
                        ),
                      ),
                      Visibility(
                        visible: settings.value?.debugMode ?? false,
                        child: Container(
                          alignment: Alignment.topLeft,
                          padding: const EdgeInsets.all(8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(AppLocalizations.of(context)!.withAudioHandler, style: techInfoStyle),
                              if (widget.recording.seenAt != null)
                                Text("${AppLocalizations.of(context)!.seenAt}: ${widget.recording.seenAt} (${DateTime.now().difference(widget.recording.seenAt!)} ago)", style: techInfoStyle),
                              Text("${AppLocalizations.of(context)!.debugCreatedAt}: ${widget.download.createdAt}", style: techInfoStyle),
                              Text("${AppLocalizations.of(context)!.debugUpdatedAt}: ${widget.download.updatedAt}", style: techInfoStyle),
                              Text("${AppLocalizations.of(context)!.debugDuration}: ${formatDuration(_player.state.duration)}", style: techInfoStyle),
                              Text("${AppLocalizations.of(context)!.debugPosition}: ${formatDuration(_player.state.position)}", style: techInfoStyle),
                              Text("${AppLocalizations.of(context)!.debugBuffered}: ${formatDuration(_player.state.buffer)}", style: techInfoStyle),
                              Text("${AppLocalizations.of(context)!.debugBuffering}: ${_player.state.buffering ? '>>' : '__'}", style: techInfoStyle),
                              Text("${AppLocalizations.of(context)!.debugVolume}: ${_player.state.volume}", style: techInfoStyle),
                              Text("${AppLocalizations.of(context)!.debugAudioBitrate}: ${_player.state.audioBitrate}", style: techInfoStyle),
                              Text("${AppLocalizations.of(context)!.debugAudioDevice}: ${_player.state.audioDevice}", style: techInfoStyle),
                              Text("${AppLocalizations.of(context)!.debugSize}: ${_player.state.width}x${_player.state.height}", style: techInfoStyle),
                              Text("${AppLocalizations.of(context)!.debugVideoParams}: ${_player.state.videoParams}", style: techInfoStyle),
                              Text("${AppLocalizations.of(context)!.debugAudioParams}: ${_player.state.audioParams}", style: techInfoStyle),
                              // Text("${_controller.value}"),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _onEnterFullscreen() async {
    try {
      if (Platform.isAndroid || Platform.isIOS) {
        await Future.wait(
          [
            SystemChrome.setEnabledSystemUIMode(
              SystemUiMode.immersiveSticky,
              overlays: [],
            ),
            SystemChrome.setPreferredOrientations(
              [],
            ),
          ],
        );
      } else if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
        await const MethodChannel('com.alexmercerind/media_kit_video').invokeMethod(
          'Utils.EnterNativeFullscreen',
        );
      }
    } catch (exception, stacktrace) {
      AppLoggers.player.e('Failed to enter fullscreen', error: exception, stackTrace: stacktrace);
    }
  }
}

class PlayerControls extends StatelessWidget {
  final Player player;
  final void Function(Duration) onSeek;
  final void Function(Duration) onRewind;
  final WidgetRef ref;

  const PlayerControls({
    super.key,
    required this.player,
    required this.onSeek,
    required this.onRewind,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ProgressBar(
          progressBarColor: MediaPlayerTheme.getProgressBarColor(context),
          timeLabelLocation: TimeLabelLocation.sides,
          progress: player.state.position,
          total: player.state.duration,
          timeLabelType: TimeLabelType.remainingTime,
          buffered: player.state.buffer,
          onSeek: onSeek,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton(
              onLongPress: () {
                onRewind(-const Duration(minutes: 5));
              },
              onPressed: () {
                onRewind(-const Duration(minutes: 1));
              },
              child: const Icon(Icons.fast_rewind),
            ),
            TextButton(
              onLongPress: () {
                onRewind(-const Duration(seconds: 30));
              },
              onPressed: () {
                onRewind(-const Duration(seconds: 15));
              },
              child: const Icon(Icons.fast_rewind),
            ),
            if (player.state.playing)
              TextButton(
                onPressed: () {
                  player.playOrPause();
                },
                child: const Icon(Icons.pause),
              ),
            if (!player.state.playing)
              TextButton(
                onPressed: () {
                  player.playOrPause();
                },
                child: const Icon(Icons.play_arrow),
              ),
            TextButton(
              onLongPress: () {
                onRewind(const Duration(seconds: 30));
              },
              onPressed: () {
                onRewind(const Duration(seconds: 15));
              },
              child: const Icon(Icons.fast_forward),
            ),
            TextButton(
              onLongPress: () {
                onRewind(const Duration(minutes: 5));
              },
              onPressed: () {
                onRewind(const Duration(minutes: 1));
              },
              child: const Icon(Icons.fast_forward),
            ),
          ],
        ),
        IntrinsicWidth(
          child: DropdownButton<double>(
            icon: const Icon(Icons.speed),
            value: ref.watch(settingsNotifierProvider.select((s) => s.value?.playerSpeed)),
            onChanged: (value) {
              ref.read(settingsNotifierProvider.notifier).updatePlayerSpeed(value ?? 1.0);
              player.setRate(value ?? 1.0);
            },
            items: [
              for (final e in getSpeedRates(AppLocalizations.of(context)!).entries) DropdownMenuItem(value: e.key, child: Text(e.value)),
            ],
          ),
        )
      ],
    );
  }
}
