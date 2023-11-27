import 'dart:async';

import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:universal_platform/universal_platform.dart';

import '../../api/media.dart';
import '../../model/download.dart';
import '../../model/recording_info.dart';
import '../../settings/settings_provider.dart';
import '../format.dart';
import 'media_kit_audio_handler.dart';

void _seek(Player player, Duration position) {
  if (position.isNegative) {
    position = Duration.zero;
  }
  if (position > player.state.duration) {
    position = player.state.duration;
  }
  player.seek(position);
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

  late final _controller = VideoController(_player);

  StreamSubscription? _positionSendSubs;

  @override
  void initState() {
    super.initState();
    _init();
  }

  _init() async {
    // await _player.open(Media(url), play: false);

    MKPlayerHandler.handler.playRecording(widget.recording, widget.download);

    if (UniversalPlatform.isDesktop || UniversalPlatform.isWeb) {
      await _player.setVolume(ref.read(settingsNotifierProvider).requireValue.volume);
    }

    _player.stream.duration.listen((event) {
      _seek(_player, Duration(seconds: widget.recording.position));
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
      if (_player.state.playing && _player.state.position != Duration.zero) {
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
    //_player.dispose();
    MKPlayerHandler.dispose();
    _positionSendSubs?.cancel();
    super.dispose();
  }

  void _sendPosition(String recordingId, Duration position, bool finished) {
    putPosition(recordingId, position, finished);
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
            SingleActivator(LogicalKeyboardKey.arrowLeft, control: true, shift: true): ChangePositionIntent(Duration(seconds: -300)),
            SingleActivator(LogicalKeyboardKey.arrowLeft, control: true, shift: false): ChangePositionIntent(Duration(seconds: -60)),
            SingleActivator(LogicalKeyboardKey.arrowLeft, control: false, shift: true): ChangePositionIntent(Duration(seconds: -30)),
            SingleActivator(LogicalKeyboardKey.arrowLeft, control: false, shift: false): ChangePositionIntent(Duration(seconds: -10)),
            SingleActivator(LogicalKeyboardKey.arrowRight, control: true, shift: true): ChangePositionIntent(Duration(seconds: 300)),
            SingleActivator(LogicalKeyboardKey.arrowRight, control: true, shift: false): ChangePositionIntent(Duration(seconds: 60)),
            SingleActivator(LogicalKeyboardKey.arrowRight, control: false, shift: true): ChangePositionIntent(Duration(seconds: 30)),
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
                _seek(_player, _player.state.position + intent.duration);
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
                    Container(
                      // padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                      child: Row(
                        children: [
                          const BackButton(),
                          Expanded(child: Text("${widget.recording.title} • ${formatDuration(_player.state.duration)}")),
                        ],
                      ),
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
                              filterQuality: FilterQuality.high,
                              pauseUponEnteringBackgroundMode: false,
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
                            Text("buffering: ${_player.state.buffering ? 'XX' : '>>'}", style: techInfoStyle),
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
            _seek(_player, duration);
          },
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(
              onLongPress: () {
                _seek(_player, _player.state.position - const Duration(minutes: 5));
              },
              onPressed: () {
                _seek(_player, _player.state.position - const Duration(minutes: 1));
              },
              child: const Icon(Icons.fast_rewind),
            ),

            //label: const Icon(Icons.chevron_left)),
            TextButton(
              onLongPress: () {
                _seek(_player, _player.state.position - const Duration(seconds: 30));
              },
              onPressed: () {
                _seek(_player, _player.state.position - const Duration(seconds: 15));
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
                _seek(_player, _player.state.position + const Duration(seconds: 30));
              },
              onPressed: () {
                _seek(_player, _player.state.position + const Duration(seconds: 15));
              },
              child: const Icon(
                Icons.fast_forward,
              ),
            ),
            TextButton(
              onLongPress: () {
                _seek(_player, _player.state.position + const Duration(minutes: 5));
              },
              onPressed: () {
                _seek(_player, _player.state.position + const Duration(minutes: 1));
              },
              child: const Icon(
                Icons.fast_forward,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ControlsOverlay extends StatelessWidget {
  const _ControlsOverlay({required Player player}) : _player = player;

  static const _volumes = <double>[
    10,
    20,
    30,
    40,
    50,
    60,
    70,
    80,
    90,
    100,
  ];
  static const List<double> _examplePlaybackRates = <double>[
    0.25,
    0.5,
    1.0,
    1.5,
    2.0,
    3.0,
    5.0,
    10.0,
  ];

  final Player _player;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 500),
          reverseDuration: const Duration(milliseconds: 200),
          child: _player.state.playing
              ? const SizedBox.shrink()
              : Container(
                  color: Colors.black26,
                  child: const Center(
                    child: Icon(
                      // Icons.play_arrow,
                      null,
                      color: Colors.white,
                      size: 32.0,
                      semanticLabel: 'Play',
                    ),
                  ),
                ),
        ),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () {
                  _seek(_player, _player.state.position - const Duration(seconds: 5));
                },
              ),
            ),
            Expanded(
              child: GestureDetector(
                onDoubleTap: () {
                  _player.playOrPause();
                },
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  _seek(_player, _player.state.position + const Duration(seconds: 5));
                },
              ),
            ),
          ],
        ),
        Align(
          alignment: Alignment.topLeft,
          child: PopupMenuButton<double>(
            initialValue: _player.state.volume,
            tooltip: 'Sound volume',
            onSelected: (double volume) {
              _player.setVolume(volume);
            },
            itemBuilder: (BuildContext context) {
              return <PopupMenuItem<double>>[
                for (var volume in _volumes)
                  PopupMenuItem<double>(
                    value: volume,
                    child: Text('$volume%'),
                  )
              ];
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(
                // Using less vertical padding as the text is also longer
                // horizontally, so it feels like it would need more spacing
                // horizontally (matching the aspect ratio of the video).
                vertical: 12,
                horizontal: 16,
              ),
              child: Visibility(
                visible: !_player.state.playing,
                child: Text('${(_player.state.volume).toInt()}%'),
              ),
            ),
          ),
        ),
        Align(
          alignment: Alignment.topRight,
          child: PopupMenuButton<double>(
            initialValue: _player.state.rate,
            tooltip: 'Playback rate',
            onSelected: (double rate) {
              _player.setRate(rate);
            },
            itemBuilder: (BuildContext context) {
              return <PopupMenuItem<double>>[
                for (final double rate in _examplePlaybackRates)
                  PopupMenuItem<double>(
                    value: rate,
                    child: Text('${rate}x'),
                  )
              ];
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(
                // Using less vertical padding as the text is also longer
                // horizontally, so it feels like it would need more spacing
                // horizontally (matching the aspect ratio of the video).
                vertical: 12,
                horizontal: 16,
              ),
              child: Text('${_player.state.rate}x'),
            ),
          ),
        ),
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
