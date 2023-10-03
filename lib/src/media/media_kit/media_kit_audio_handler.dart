import 'package:ilovlya/src/model/download.dart';
import 'package:ilovlya/src/model/recording_info.dart';
import 'package:media_kit/media_kit.dart';
import 'package:universal_platform/universal_platform.dart';
import 'package:audio_service/audio_service.dart';

// if (!UniversalPlatform.isDesktop)

class MKPlayerHandler extends BaseAudioHandler with SeekHandler {
  static late final MKPlayerHandler _handler;

  static void init() async {
    if (UniversalPlatform.isDesktop) {
      _handler = MKPlayerHandler();
      return;
    }

    _handler = await AudioService.init<MKPlayerHandler>(
      builder: () => MKPlayerHandler(),
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'uno.almaz.ilovlya.channel.audio',
        androidNotificationChannelName: 'MKVideo playback',
        androidNotificationOngoing: true,
      ),
    );
  }

  void playRecording(RecordingInfo recording, Download download) {
    _player = Player(
        configuration: const PlayerConfiguration(
      bufferSize: 512 * 1024 * 1024,
      //title: widget.recording.title,
      // osc: true,
    ));

    player.open(Media(download.url));

    player.stream.playing.listen((event) {
      _handler.updatePlaybackState();
    });
    player.stream.position.listen((event) {
      _handler.updatePlaybackState();
    });
    player.stream.duration.listen((event) {
      mediaItem.add(MediaItem(
        id: download.url,
        title: recording.title,
        artist: recording.uploader,
        album: recording.extractor,
        artUri: Uri.parse(recording.thumbnailUrl),
        duration: player.state.duration,
      ));
      _handler.updatePlaybackState();
    });
    player.stream.buffer.listen((event) {
      _handler.updatePlaybackState();
    });
  }

  void updatePlaybackState() {
    _handler.playbackState.add(PlaybackState(
      processingState: mediaItem.value == null
          ? AudioProcessingState.idle
          : AudioProcessingState.ready,
      controls: [
        MediaControl.rewind,
        if (_player.state.playing) MediaControl.pause else MediaControl.play,
        MediaControl.fastForward,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.playPause,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      },
      playing: _player.state.playing,
      updatePosition: _player.state.position,
      bufferedPosition: _player.state.buffer,
      speed: _player.state.rate,
      queueIndex: null,
    ));
  }

  static void dispose() {
    _handler._player.dispose();

    _handler.mediaItem.add(null);
    //_handler.playbackState.add(_handler.playbackState.value.copyWith());
  }

  static MKPlayerHandler get handler => _handler;

  static Player get player => _handler._player;

  late Player _player;

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> stop() async {
    super.stop();
    _player.stop();
  }
}

// class MKPlayerHandler extends BaseAudioHandler with SeekHandler {

// }
