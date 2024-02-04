import 'dart:async';

import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:duration/duration.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:universal_platform/universal_platform.dart';

import '../../api/api_riverpod.dart';
import '../../model/download.dart';
import '../../model/recording_info.dart';
import '../../settings/settings_provider.dart';
import '../format.dart';
import 'media_kit_audio_handler.dart';

String _formatDuration(Duration duration) {
  var positive = true;
  if (duration.isNegative) {
    positive = false;
    duration = -duration;
  }
  return (positive ? "⏵⏵ " : "⏴⏴ ") + prettyDuration(duration, abbreviated: true);
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
  String get url => widget.download.url;
  Player get _player => MKPlayerHandler.player;
  late final _controller = VideoController(_player, configuration: VideoControllerConfiguration(enableHardwareAcceleration: !UniversalPlatform.isLinux));
  StreamSubscription? _positionSendSubs;
  Duration _rewinding = Duration.zero;
  Timer? _rewindTimer = null;

  @override
  void initState() {
    super.initState();
    _init();
  }

  void _init() async {
    MKPlayerHandler.handler.playRecording(widget.recording, widget.download);

    if (UniversalPlatform.isDesktop || UniversalPlatform.isWeb) {
      await _player.setVolume(ref.read(settingsNotifierProvider).requireValue.volume);
    }

    _player.stream.duration.listen((event) {
      _seek(Duration(seconds: widget.recording.position));
      _player.play();
      setState(() {});
    });

    _player.stream.buffering.listen((event) {
      setState(() {});
    });

    _player.stream.buffer.listen((event) {
      setState(() {});
    });

    _player.stream.playing.listen((event) {
      setState(() {});
    });

    _player.stream.videoParams.listen((event) {
      setState(() {});
    });

    _player.stream.volume.listen((double volume) {
      setState(() {});
      ref.read(settingsNotifierProvider.notifier).updateVolume(volume);
    });

    _player.stream.completed.listen((event) {
      _sendPosition(
        widget.recording.id,
        _player.state.position,
        event,
      );
      setState(() {});
    });

    _player.stream.position.listen((Duration position) {
      setState(() {});
    });

    _positionSendSubs = Stream.periodic(_positionSendPeriod).listen((event) {
      if (_player.state.playing && !_player.state.buffering && _player.state.position != Duration.zero) {
        _sendPosition(
          widget.recording.id,
          _player.state.position,
          _player.state.position == _player.state.duration,
        );
      }
    });
  }

  @override
  void dispose() {
    MKPlayerHandler.dispose();
    _positionSendSubs?.cancel();
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

  void _sendPosition(String recordingId, Duration position, bool finished) {
    ref.read(putPositionProvider(recordingId, position, finished));
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
// final titleSmall = Theme.of(context).textTheme.titleSmall;
    final techInfoStyle = GoogleFonts.ptMono();
    return Scaffold(
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
                          alignment: Alignment.bottomCenter,
                          children: <Widget>[
                            Video(
                              controller: _controller,
                              pauseUponEnteringBackgroundMode: false,
                              resumeUponEnteringForegroundMode: true,
                            ),
                            // _ControlsOverlay(player: player),
                            // VideoProgressIndicator(
                            //   _controller,
                            //   allowScrubbing: true,
                            //   colors: VideoProgressColors(
                            //     playedColor: Theme.of(context).colorScheme.primary,
                            //     backgroundColor:
                            //         const Color.fromARGB(127, 158, 158, 158),
                            //   ),
                            // ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                      child: _buildControls(context),
                    ),
                    Container(
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.all(8),
                      child: Text("Created at: ${formatDateLong(widget.recording.createdAt)} (${since(widget.recording.createdAt, false)} ago)"),
                    ),
                    Visibility(
                      visible: settings.value?.debugMode ?? false,
                      child: Container(
                        alignment: Alignment.topLeft,
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("With audio handler!", style: techInfoStyle),
                            if (widget.recording.seenAt != null) Text("seen at: ${widget.recording.seenAt} (${DateTime.now().difference(widget.recording.seenAt!)} ago)", style: techInfoStyle),
                            Text("created at: ${widget.download.createdAt}", style: techInfoStyle),
                            Text("updated at: ${widget.download.updatedAt}", style: techInfoStyle),
                            Text("duration: ${formatDuration(_player.state.duration)}", style: techInfoStyle),
                            Text("position: ${formatDuration(_player.state.position)}", style: techInfoStyle),
                            Text("buffered: ${formatDuration(_player.state.buffer)}", style: techInfoStyle),
                            Text("buffering: ${_player.state.buffering ? '>>' : '__'}", style: techInfoStyle),
                            Text("volume: ${_player.state.volume}", style: techInfoStyle),
                            Text("size: ${_player.state.width}x${_player.state.height}", style: techInfoStyle),

                            Text("video params: ${_player.state.videoParams}", style: techInfoStyle),
                            Text("audio params: ${_player.state.audioParams}", style: techInfoStyle),
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
    );
  }

  Widget _buildControls(BuildContext context) {
    // var c = Theme.of(context).colorScheme.primary;
    return Column(
      children: [
        ProgressBar(
          progressBarColor: Theme.of(context).colorScheme.primary,
          timeLabelLocation: TimeLabelLocation.sides,
          progress: _player.state.position,
          total: _player.state.duration,
          timeLabelType: TimeLabelType.remainingTime,
          buffered: _player.state.buffer,
          onSeek: (duration) {
            _seek(duration);
          },
        ),
        Stack(children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                onLongPress: () {
                  _rewind(-const Duration(minutes: 5));
                },
                onPressed: () {
                  _rewind(-const Duration(minutes: 1));
                },
                child: const Icon(Icons.fast_rewind),
              ),

              //label: const Icon(Icons.chevron_left)),
              TextButton(
                onLongPress: () {
                  _rewind(-const Duration(seconds: 30));
                },
                onPressed: () {
                  _rewind(-const Duration(seconds: 15));
                },
                child: const Icon(Icons.fast_rewind),
              ),
              if (_player.state.playing)
                TextButton(
                  onPressed: () {
                    _player.pause();
                  },
                  child: const Icon(
                    Icons.pause,
                  ),
                ),
              if (!_player.state.playing)
                TextButton(
                  onPressed: () {
                    _player.play();
                  },
                  child: const Icon(
                    Icons.play_arrow,
                  ),
                ),
              TextButton(
                onLongPress: () {
                  _rewind(const Duration(seconds: 30));
                },
                onPressed: () {
                  _rewind(const Duration(seconds: 15));
                },
                child: const Icon(
                  Icons.fast_forward,
                ),
              ),
              TextButton(
                onLongPress: () {
                  _rewind(const Duration(minutes: 5));
                },
                onPressed: () {
                  _rewind(const Duration(minutes: 1));
                },
                child: const Icon(
                  Icons.fast_forward,
                ),
              ),
            ],
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 1000),
            // transitionBuilder: (Widget child, Animation<double> animation) {
            //   return ScaleTransition(scale: animation, child: child);
            // },
            child: Text(_rewinding != Duration.zero ? _formatDuration(_rewinding) : "", key: ValueKey(_rewinding)),
          ),
        ]),
      ],
    );
  }
}

class PlayPauseIntent extends Intent {
  const PlayPauseIntent();
}

class BackIntent extends Intent {
  const BackIntent();
}

class ChangePositionIntent extends Intent {
  const ChangePositionIntent(
    this.duration,
  );
  final Duration duration;
}

class ChangeVolumeIntent extends Intent {
  const ChangeVolumeIntent(
    this.change,
  );
  final int change;
}
