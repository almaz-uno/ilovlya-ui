import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:async/async.dart';
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
import '../../playback_download/partial_source.dart';
import '../../playback_download/playback_downloads.dart';
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

  /// Where to read from instead of the download itself: the local endpoint of a playback download. `null` plays the
  /// local file or the server's URL, as before, and keeps the switch to a local file an explicit download completes.
  final Uri? source;

  const RecordingViewMediaKitHandler({
    super.key,
    required this.recording,
    required this.download,
    this.inFull = false,
    this.source,
  });

  @override
  ConsumerState<RecordingViewMediaKitHandler> createState() => _RecordingViewMediaKitHandlerState();
}

const _positionSendPeriod = Duration(seconds: 1);

/// Positions written per recording, by any player: a position kept for a server that is away gives way to a newer one.
final _positionWrites = <String, int>{};

class _RecordingViewMediaKitHandlerState extends ConsumerState<RecordingViewMediaKitHandler> {
  // String get url => widget.download.url;
  Player get _player => MKPlayerHandler.player;
  // Shared, app-lifetime controller (see MKPlayerHandler.videoController):
  // avoids per-open video-output creation/teardown that froze the return.
  VideoController get _controller => MKPlayerHandler.videoController;
  StreamSubscription? _positionSendSubs;
  StreamSubscription? _uiUpdateSubs;
  Duration _rewinding = Duration.zero;
  Timer? _rewindTimer;
  bool _hasAttemptedSwitch = false; // Flag to prevent multiple switch attempts
  bool _isFirstDurationEvent = true; // Flag to auto-play only on first duration event
  bool _interrupted = false; // The stream ended before the recording did; reopening at the position
  int _reopenAttempts = 0;
  Timer? _reopenRetry;

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
      source: widget.source,
    );

    if (UniversalPlatform.isDesktop || UniversalPlatform.isWeb) {
      await _player.setVolume(ref.read(settingsNotifierProvider).requireValue.volume);
    }

    _player.stream.duration.listen((event) {
      if (!mounted) return;
      if (_interrupted && event > Duration.zero) {
        // The reopened source has loaded; play continues from the position the seek below restores.
        _interrupted = false;
        _reopenRetry?.cancel();
      }
      _seek(Duration(seconds: widget.recording.position));
      // Auto-play only on first duration event (initial load)
      if (_isFirstDurationEvent) {
        _player.play();
        _isFirstDurationEvent = false;
      }
      _player.setRate(ref.read(settingsNotifierProvider.select((s) => s.value?.playerSpeed)) ?? 1.0);
    });

    // Combine multiple UI-updating streams into one to avoid excessive setState calls
    _uiUpdateSubs = StreamGroup.merge([
      _player.stream.buffering,
      _player.stream.buffer,
      _player.stream.playing,
      _player.stream.videoParams,
      _player.stream.position,
    ]).listen((event) {
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
      // `false` arrives on every open and seek, while the position may still be zero; it says nothing the periodic
      // tick does not, and sending it wrote a zero to the server at every start.
      if (!event) return;
      if (_reachedEnd()) {
        _sendPosition(widget.recording.id, _player.state.position, true);
        if (widget.source != null) unawaited(ref.read(playbackDownloadsProvider.notifier).ended(widget.download.id));
      } else {
        _onInterrupted();
      }
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

  /// Whether the player's end of file is the end of the recording: within max(2 s, 1 %) of the duration. libmpv reports
  /// the end of the file also when the server went away and the buffer ran out, at the position where the bytes did.
  /// Without a duration the end of the file keeps its old meaning.
  bool _reachedEnd() {
    final duration = _player.state.duration;
    if (duration <= Duration.zero) return true;
    final tolerance = Duration(milliseconds: max(2000, duration.inMilliseconds ~/ 100));
    return duration - _player.state.position <= tolerance;
  }

  /// The stream ended before the recording did. The position is kept as an ordinary one, not as finished, and the same
  /// source is opened again, paused at that position: a completed player would otherwise start from zero on play.
  void _onInterrupted() {
    final position = _player.state.position;
    AppLoggers.player.w('Playback of ${widget.recording.id} ended at ${position.inSeconds}s of ${_player.state.duration.inSeconds}s: an interruption, not the end');
    _keepPosition(position);
    widget.recording.position = position.inSeconds;
    if (!_interrupted) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.playbackInterrupted(formatDuration(position)))));
    }
    _interrupted = true;
    _reopenAttempts = 0;
    _reopen();
  }

  /// Sends the position of an interruption until the server takes it: the server is often what went away, and with
  /// the playback stopped no periodic position follows to correct it. The retries run on the container, past this
  /// screen, and give way to any newer position written for the recording.
  void _keepPosition(Duration position) {
    final id = widget.recording.id;
    final container = ProviderScope.containerOf(context, listen: false);
    final generation = _positionWrites[id] = (_positionWrites[id] ?? 0) + 1;
    container.read(recordingNotifierProvider(id).notifier).putPosition(position, false);
    unawaited(() async {
      for (var attempt = 1; attempt <= 120 && _positionWrites[id] == generation; attempt++) {
        final provider = putPositionProvider(id, position, false);
        final keepAlive = container.listen(provider, (_, __) {}); // an auto-dispose provider read once may not finish
        try {
          await container.read(provider.future);
          return;
        } on Object catch (e) {
          if (attempt == 1) AppLoggers.player.w('The server did not take the position ${position.inSeconds}s of $id; trying again every 5 s', error: e);
        } finally {
          keepAlive.close();
        }
        await Future<void>.delayed(const Duration(seconds: 5));
      }
    }());
  }

  /// Opens the source again, paused; the duration listener seeks to the kept position once it loads. A source that
  /// does not load — the server still away — is tried again every 5 s for two minutes while the screen is open. A
  /// playback download is opened through its owner again, which starts it over if its file changed on the server.
  Future<void> _reopen() async {
    if (!mounted || !_interrupted) return;
    _reopenAttempts++;
    try {
      final url = widget.source == null
          ? widget.download.fullPathMedia ?? widget.download.url
          : (await ref.read(playbackDownloadsProvider.notifier).open(widget.download)).toString();
      if (!mounted || !_interrupted) return;
      await MKPlayerHandler.openMedia(url, play: false);
    } catch (e, s) {
      AppLoggers.player.w('Reopening ${widget.recording.id} failed (attempt $_reopenAttempts)', error: e, stackTrace: s);
    }
    _reopenRetry?.cancel();
    _reopenRetry = Timer(const Duration(seconds: 5), () {
      if (mounted && _interrupted && _player.state.duration <= Duration.zero && _reopenAttempts < 24) _reopen();
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
  void deactivate() {
    // Stop UI-updating streams immediately.
    _positionSendSubs?.cancel();
    _uiUpdateSubs?.cancel();
    _reopenRetry?.cancel();
    _interrupted = false;
    // A playback download outlives the player: it continues unattended.
    if (widget.source != null) ref.read(playbackDownloadsProvider.notifier).detach(widget.download.id);
    // Defer the native player teardown until after the pop transition. The
    // native stop() (releasing the HW video decoder) otherwise blocks the
    // platform thread during the reverse slide, causing a visible jerk.
    Future.delayed(const Duration(milliseconds: 400), () {
      MKPlayerHandler.player.stop();
      MKPlayerHandler.clearMediaSession(); // Clear lock screen notification
    });
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
    _positionWrites[recordingId] = (_positionWrites[recordingId] ?? 0) + 1;
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
    if (widget.source != null) {
      // Told once: writing the file failed, and the playback goes on as a plain stream.
      ref.listen(playbackDownloadsProvider.select((s) => s[widget.download.id]), (previous, next) {
        if (next == SourceState.passThrough && previous != SourceState.passThrough && ref.read(playbackDownloadsProvider.notifier).savingFailed(widget.download.id)) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.playbackDownloadNotSaved)));
        }
      });
    }
    // final rewindTextStyle = Theme.of(context).textTheme.titleSmall;
    final techInfoStyle = GoogleFonts.ptMono();
    return PopScope(
      onPopInvokedWithResult: (bool didPop, Object? result) {
        final updateThumbnails = ref.read(settingsNotifierProvider.select((value) => value.requireValue.updateThumbnails));
        // Capture the container now: `ref` becomes invalid once this widget is
        // disposed by the pop, but the container outlives it.
        final container = ProviderScope.containerOf(context, listen: false);
        final recId = widget.recording.id;
        final thumbUrl = widget.recording.thumbnailUrl;
        // Defer the teardown (thumbnail screenshot + provider invalidations)
        // past the pop transition. Run synchronously here it rebuilds/refetches
        // the details and the whole media list underneath, blocking the button's
        // programmatic pop animation (a swipe hides it — it is finger-driven).
        Future.delayed(const Duration(milliseconds: 350), () {
          if (!UniversalPlatform.isWeb && updateThumbnails) {
            MKPlayerHandler.player.screenshot(format: "image/png").then((imgData) {
              container.read(thumbnailDataNotifierProvider(thumbUrl).notifier).updateThumbnailImg(imgData);
            });
          }
          container.invalidate(recordingNotifierProvider(recId));
          container.invalidate(mediaListNotifierProvider);
        });
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
                          // Only a playback that reads the server's URL switches; a playback download is the file already.
                          if (widget.source == null && task != null && task.status == TaskStatus.complete && !_hasAttemptedSwitch) {
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
                      if (settings.value?.debugMode ?? false)
                        Container(
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
