import 'dart:async';

import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_in_app_pip/flutter_in_app_pip.dart';
import 'package:ilovlya/src/api/media.dart';
import 'package:ilovlya/src/media/format.dart';
import 'package:ilovlya/src/model/download.dart';
import 'package:ilovlya/src/model/recording_info.dart';
import 'package:video_player/video_player.dart';
import 'package:wakelock/wakelock.dart';

class RecordingView extends StatelessWidget {
  final RecordingInfo recording;
  final Download download;

  const RecordingView({
    super.key,
    required this.recording,
    required this.download,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(title: Text(recording.title)),
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
  late VideoPlayerController _controller;
  StreamSubscription? _positionSendSubs;

  @override
  void initState() {
    super.initState();

    _controller = VideoPlayerController.networkUrl(
      Uri.parse(widget.download.url),
      videoPlayerOptions: VideoPlayerOptions(
        mixWithOthers: false,
        allowBackgroundPlayback: true,
      ),
    );

    _controller.addListener(() {
      if (_controller.value.position != Duration.zero && _controller.value.position == _controller.value.duration) {
        _sendPosition(
          widget.recording.id,
          _controller.value.position,
          _controller.value.position == _controller.value.duration,
        );
      }
      setState(() {});
    });
    _controller.setLooping(false);

    _controller.initialize().then((_) async {
      await _controller.seekTo(Duration(seconds: widget.recording.position));
      _controller.play();
    });

    _positionSendSubs = Stream.periodic(_positionSendPeriod).listen((event) {
      if (_controller.value.isPlaying && _controller.value.position != Duration.zero) {
        _sendPosition(
          widget.recording.id,
          _controller.value.position,
          _controller.value.position == _controller.value.duration,
        );
      }
    });

    Wakelock.enable();
  }

  @override
  void dispose() {
    _controller.dispose();
    _positionSendSubs?.cancel();
    super.dispose();
    Wakelock.disable();
  }

  void _sendPosition(String recordingId, Duration position, bool finished) {
    // print("$recordingId $position $finished");
    putPosition(recordingId, position, finished);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: <Widget>[
          Container(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
            child: Row(
              children: [
                const BackButton(),
                Expanded(child: Text("${widget.recording.title} • ${formatDuration(_controller.value.duration)}")),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
            child: AspectRatio(
              aspectRatio: widget.download.hasVideo ? _controller.value.aspectRatio : 8.0,
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: <Widget>[
                  VideoPlayer(_controller),
                  _ControlsOverlay(controller: _controller),
                  VideoProgressIndicator(
                    _controller,
                    allowScrubbing: true,
                    colors: VideoProgressColors(
                      playedColor: Theme.of(context).colorScheme.primary,
                      backgroundColor: const Color.fromARGB(127, 158, 158, 158),
                    ),
                  ),
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
                Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        PictureInPicture.startPiP(pipWidget: VideoPlayer(_controller));
                      },
                      icon: const Icon(Icons.picture_in_picture),
                    ),
                    IconButton(
                      onPressed: () {
                        PictureInPicture.stopPiP();
                      },
                      icon: const Icon(Icons.exit_to_app),
                    ),
                  ],
                ),
                if (widget.recording.seenAt != null) Text("seen at: ${widget.recording.seenAt} (${DateTime.now().difference(widget.recording.seenAt!)} ago)"),
                Text("duration: ${formatDuration(_controller.value.duration)}"),
                Text("position: ${formatDuration(_controller.value.position)}"),
                Text("buffered: ${_controller.value.buffered.isNotEmpty ? formatDuration(_controller.value.buffered.last.end) : ''}"),
                Text("isBuffering: ${_controller.value.isBuffering}"),
                Text("volume: ${_controller.value.volume}"),
                Text("size: ${_controller.value.size}"),
                // Text("${_controller.value}"),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControls(BuildContext context) {
    Duration? buffered;
    for (var element in _controller.value.buffered) {
      buffered = element.end;
    }
    // var c = Theme.of(context).colorScheme.primary;
    return Column(
      children: [
        ProgressBar(
          progressBarColor: Theme.of(context).colorScheme.primary,
          progress: _controller.value.position,
          total: _controller.value.duration,
          timeLabelType: TimeLabelType.remainingTime,
          buffered: buffered,
          onSeek: (duration) {
            _controller.seekTo(duration);
          },
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(
              onLongPress: () {
                _controller.seekTo(_controller.value.position - const Duration(minutes: 5));
              },
              onPressed: () {
                _controller.seekTo(_controller.value.position - const Duration(minutes: 1));
              },
              child: const Icon(Icons.fast_rewind),
            ),

            //label: const Icon(Icons.chevron_left)),
            TextButton(
              onLongPress: () {
                _controller.seekTo(_controller.value.position - const Duration(seconds: 30));
              },
              onPressed: () {
                _controller.seekTo(_controller.value.position - const Duration(seconds: 15));
              },
              child: const Icon(Icons.fast_rewind),
            ),
            if (_controller.value.isPlaying)
              TextButton(
                onLongPress: () {
                  _controller.seekTo(_controller.value.position + const Duration(seconds: 30));
                },
                onPressed: () {
                  _controller.pause();
                },
                child: const Icon(
                  Icons.pause,
                ),
              ),
            if (!_controller.value.isPlaying)
              TextButton(
                onLongPress: () {
                  _controller.seekTo(_controller.value.position + const Duration(seconds: 30));
                },
                onPressed: () {
                  _controller.play();
                },
                child: const Icon(
                  Icons.play_arrow,
                ),
              ),
            TextButton(
              onLongPress: () {
                _controller.seekTo(_controller.value.position + const Duration(seconds: 30));
              },
              onPressed: () {
                _controller.seekTo(_controller.value.position + const Duration(seconds: 15));
              },
              child: const Icon(
                Icons.fast_forward,
              ),
            ),
            TextButton(
              onLongPress: () {
                _controller.seekTo(_controller.value.position + const Duration(minutes: 5));
              },
              onPressed: () {
                _controller.seekTo(_controller.value.position + const Duration(minutes: 1));
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
  const _ControlsOverlay({required VideoPlayerController controller}) : _controller = controller;

  static const _volumes = <double>[
    0.10,
    0.20,
    0.30,
    0.40,
    0.50,
    0.60,
    0.70,
    0.80,
    0.90,
    1.00,
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

  final VideoPlayerController _controller;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 50),
          reverseDuration: const Duration(milliseconds: 200),
          child: _controller.value.isPlaying
              ? const SizedBox.shrink()
              : Container(
                  color: Colors.black26,
                  child: const Center(
                    child: Icon(
                      Icons.play_arrow,
                      color: Colors.white,
                      size: 100.0,
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
                  _controller.seekTo(_controller.value.position - const Duration(seconds: 5));
                },
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  _controller.value.isPlaying ? _controller.pause() : _controller.play();
                },
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  _controller.seekTo(_controller.value.position + const Duration(seconds: 5));
                },
              ),
            ),
          ],
        ),
        Align(
          alignment: Alignment.topLeft,
          child: PopupMenuButton<double>(
            initialValue: _controller.value.volume,
            tooltip: 'Sound volume',
            onSelected: (double volume) {
              _controller.setVolume(volume);
            },
            itemBuilder: (BuildContext context) {
              return <PopupMenuItem<double>>[
                for (var volume in _volumes)
                  PopupMenuItem<double>(
                    value: volume,
                    child: Text('${volume * 100}%'),
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
              child: Text('${_controller.value.volume * 100}%'),
            ),
          ),
        ),
        Align(
          alignment: Alignment.topRight,
          child: PopupMenuButton<double>(
            initialValue: _controller.value.playbackSpeed,
            tooltip: 'Playback speed',
            onSelected: (double speed) {
              _controller.setPlaybackSpeed(speed);
            },
            itemBuilder: (BuildContext context) {
              return <PopupMenuItem<double>>[
                for (final double speed in _examplePlaybackRates)
                  PopupMenuItem<double>(
                    value: speed,
                    child: Text('${speed}x'),
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
              child: Text('${_controller.value.playbackSpeed}x'),
            ),
          ),
        ),
      ],
    );
  }
}
