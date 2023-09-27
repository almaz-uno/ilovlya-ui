import 'dart:async';

import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ilovlya/src/api/api.dart';
import 'package:ilovlya/src/api/media.dart';
import 'package:ilovlya/src/media/format.dart';
import 'package:ilovlya/src/model/download.dart';
import 'package:ilovlya/src/model/recording_info.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

class RecordingViewMediaKit extends StatelessWidget {
  final RecordingInfo recording;
  final Download download;

  const RecordingViewMediaKit({
    super.key,
    required this.recording,
    required this.download,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(recording.title)),
      body: _RecordingVideo(recording: recording, download: download),
    );
  }
}

class _RecordingVideo extends StatefulWidget {
  const _RecordingVideo({
    required this.recording,
    required this.download,
  });

  final Download download;
  final RecordingInfo recording;

  @override
  State<_RecordingVideo> createState() => _RecordingVideoState();
}

const _positionSendPeriod = Duration(seconds: 1);

class _RecordingVideoState extends State<_RecordingVideo> {
  String get url => serverURL(widget.download.url);

  // late VideoPlayerController _controller;

  late final player = Player();
  late final controller = VideoController(player);

  StreamSubscription? _positionSendSubs;

  @override
  void initState() {
    super.initState();
    _init();
  }

  _init() async {
    await player.open(Media(url), play: false);

    player.stream.duration.listen((event) {
      player.seek(Duration(seconds: widget.recording.position));
      player.play();
      setState(() {});
    });

    player.stream.buffering.listen((event) {
      setState(() {});
    });

    player.stream.buffer.listen((event) {
      setState(() {});
    });

    // await player.seek(Duration(seconds: widget.recording.position));

    player.stream.playing.listen((event) {
      setState(() {});
    });

    player.stream.videoParams.listen((event) {
      setState(() {});
    });

    player.stream.completed.listen((event) {
      _sendPosition(
        widget.recording.id,
        player.state.position,
        event,
      );
      setState(() {});
    });

    player.stream.position.listen((Duration position) {
      // if (player.state.position != Duration.zero &&
      //     player.state.position == player.state.duration) {
      //   _sendPosition(
      //     widget.recording.id,
      //     player.state.position,
      //     player.state.position == player.state.duration,
      //   );
      // }
      setState(() {});
    });

    _positionSendSubs = Stream.periodic(_positionSendPeriod).listen((event) {
      if (player.state.playing && player.state.position != Duration.zero) {
        _sendPosition(
          widget.recording.id,
          player.state.position,
          player.state.position == player.state.duration,
        );
      }
    });
  }

  @override
  void dispose() {
    player.dispose();
    _positionSendSubs?.cancel();
    super.dispose();
  }

  void _sendPosition(String recordingId, Duration position, bool finished) {
    putPosition(recordingId, position, finished);
  }

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.space): PlayPauseIntent(),
        SingleActivator(LogicalKeyboardKey.arrowLeft,
            control: true,
            shift: true): ChangePositionIntent(Duration(seconds: -300)),
        SingleActivator(LogicalKeyboardKey.arrowLeft,
            control: true,
            shift: false): ChangePositionIntent(Duration(seconds: -60)),
        SingleActivator(LogicalKeyboardKey.arrowLeft,
            control: false,
            shift: true): ChangePositionIntent(Duration(seconds: -30)),
        SingleActivator(LogicalKeyboardKey.arrowLeft,
            control: false,
            shift: false): ChangePositionIntent(Duration(seconds: -5)),
        SingleActivator(LogicalKeyboardKey.arrowRight,
            control: true,
            shift: true): ChangePositionIntent(Duration(seconds: 300)),
        SingleActivator(LogicalKeyboardKey.arrowRight,
            control: true,
            shift: false): ChangePositionIntent(Duration(seconds: 60)),
        SingleActivator(LogicalKeyboardKey.arrowRight,
            control: false,
            shift: true): ChangePositionIntent(Duration(seconds: 30)),
        SingleActivator(LogicalKeyboardKey.arrowRight,
            control: false,
            shift: false): ChangePositionIntent(Duration(seconds: 5)),
        SingleActivator(LogicalKeyboardKey.arrowDown,
            control: false, shift: false): ChangeVolumeIntent(-5),
        SingleActivator(LogicalKeyboardKey.arrowUp,
            control: false, shift: false): ChangeVolumeIntent(5),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          PlayPauseIntent: CallbackAction<PlayPauseIntent>(
              onInvoke: (PlayPauseIntent intent) {
            player.playOrPause();
            return null;
          }),
          ChangePositionIntent: CallbackAction<ChangePositionIntent>(
              onInvoke: (ChangePositionIntent intent) {
            player.seek(player.state.position + intent.duration);
            return null;
          }),
          ChangeVolumeIntent: CallbackAction<ChangeVolumeIntent>(
              onInvoke: (ChangeVolumeIntent intent) {
            var nv = (player.state.volume).toInt() + intent.change;
            if (nv < 0) {
              nv = 0;
            }
            if (nv > 100) {
              nv = 100;
            }

            player.setVolume(nv.toDouble());
            return null;
          }),
        },
        child: Focus(
          autofocus: true,
          child: SingleChildScrollView(
            child: Column(
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                  child: Row(
                    children: [
                      // const BackButton(),
                      Expanded(
                          child: Text(
                              "${widget.recording.title} • ${formatDuration(player.state.duration)}")),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width,
                    height: MediaQuery.of(context).size.width * 9.0 / 16.0,
                    child: Stack(
                      alignment: Alignment.bottomCenter,
                      children: <Widget>[
                        Video(
                          controller: controller,
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
                Container(
                  alignment: Alignment.topLeft,
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget.recording.seenAt != null)
                        Text(
                            "seen at: ${widget.recording.seenAt} (${DateTime.now().difference(widget.recording.seenAt!)} ago)"),
                      Text("created at: ${widget.download.createdAt}"),
                      Text("updated at: ${widget.download.updatedAt}"),
                      Text(
                          "duration: ${formatDuration(player.state.duration)}"),
                      Text(
                          "position: ${formatDuration(player.state.position)}"),
                      Text("buffered: ${formatDuration(player.state.buffer)}"),
                      Text(
                          "buffering: ${player.state.buffering ? 'XX' : '>>'}"),
                      Text("volume: ${player.state.volume}"),
                      Text(
                          "size: ${player.state.width}x${player.state.height}"),

                      Text("video params: ${player.state.videoParams}"),
                      Text("audio params: ${player.state.audioParams}"),
                      // Text("${_controller.value}"),
                    ],
                  ),
                ),
              ],
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
          progress: player.state.position,
          total: player.state.duration,
          timeLabelType: TimeLabelType.remainingTime,
          buffered: player.state.buffer,
          onSeek: (duration) {
            player.seek(duration);
          },
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(
              onLongPress: () {
                player.seek(player.state.position - const Duration(minutes: 5));
              },
              onPressed: () {
                player.seek(player.state.position - const Duration(minutes: 1));
              },
              child: const Icon(Icons.fast_rewind),
            ),

            //label: const Icon(Icons.chevron_left)),
            TextButton(
              onLongPress: () {
                player
                    .seek(player.state.position - const Duration(seconds: 30));
              },
              onPressed: () {
                player
                    .seek(player.state.position - const Duration(seconds: 15));
              },
              child: const Icon(Icons.fast_rewind),
            ),
            if (player.state.playing)
              TextButton(
                onPressed: () {
                  player.pause();
                },
                child: const Icon(
                  Icons.pause,
                ),
              ),
            if (!player.state.playing)
              TextButton(
                onPressed: () {
                  player.play();
                },
                child: const Icon(
                  Icons.play_arrow,
                ),
              ),
            TextButton(
              onLongPress: () {
                player
                    .seek(player.state.position + const Duration(seconds: 30));
              },
              onPressed: () {
                player
                    .seek(player.state.position + const Duration(seconds: 15));
              },
              child: const Icon(
                Icons.fast_forward,
              ),
            ),
            TextButton(
              onLongPress: () {
                player.seek(player.state.position + const Duration(minutes: 5));
              },
              onPressed: () {
                player.seek(player.state.position + const Duration(minutes: 1));
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
                  _player.seek(
                      _player.state.position - const Duration(seconds: 5));
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
                  _player.seek(
                      _player.state.position + const Duration(seconds: 5));
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
