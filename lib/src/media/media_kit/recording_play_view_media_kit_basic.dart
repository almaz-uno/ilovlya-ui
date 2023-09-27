import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:ilovlya/src/api/api.dart';
import 'package:ilovlya/src/model/download.dart';
import 'package:ilovlya/src/model/recording_info.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class RecordingViewMediaKitBasic extends StatefulWidget {
  final RecordingInfo recording;
  final Download download;

  const RecordingViewMediaKitBasic({
    super.key,
    required this.recording,
    required this.download,
  });

  @override
  State<RecordingViewMediaKitBasic> createState() => _RecordingViewMediaKitBasicState();
}

class _RecordingViewMediaKitBasicState extends State<RecordingViewMediaKitBasic> {
  String get url => serverURL(widget.download.url);

  // Create a [Player] to control playback.
  late final player = Player();
  // Create a [VideoController] to handle video output from [Player].
  late final controller = VideoController(player);

  @override
  void initState() {
    super.initState();
    player.open(Media(url));
    player.seek(Duration(seconds: widget.recording.position));

  }

  @override
  void dispose() {
    player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.width * 9.0 / 16.0,
        // Use [Video] widget to display video output.
        child: Video(
          controller: controller,
          filterQuality: FilterQuality.high,
          pauseUponEnteringBackgroundMode: false,
        ),
      ),
    );
  }
}
