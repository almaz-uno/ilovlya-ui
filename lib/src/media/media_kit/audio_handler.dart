import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:media_kit/media_kit.dart';
import 'package:universal_platform/universal_platform.dart';

import '../../model/download.dart';
import '../../model/recording_info.dart';

class MKPlayerHandler extends BaseAudioHandler with SeekHandler {
  static late final MKPlayerHandler _handler;

  static MKPlayerHandler get handler => _handler;

  static Player get player => _handler._player;

  final _player = Player(
      configuration: const PlayerConfiguration(
    bufferSize: 128 * 1024 * 1024,
    logLevel: MPVLogLevel.info,
    osc: false,
  ));

  bool _wasPlayingBeforeInterruption = false;

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

    // Setup audio session interruption handling for iOS
    await _handler._setupAudioSessionHandling();
  }

  Future<void> _setupAudioSessionHandling() async {
    final session = await AudioSession.instance;

    // Listen to audio interruptions (phone calls, alarms, etc.)
    session.interruptionEventStream.listen((event) {
      debugPrint('Audio interruption event: ${event.type}, begin: ${event.begin}');

      if (event.begin) {
        // Interruption began (phone call, alarm, etc.)
        if (_player.state.playing) {
          _wasPlayingBeforeInterruption = true;
          _player.pause();
          debugPrint('Paused playback due to interruption');
        }
      } else {
        // Interruption ended - resume playback if it was playing before
        if (_wasPlayingBeforeInterruption) {
          // Add small delay to ensure audio session is ready
          Future.delayed(const Duration(milliseconds: 500), () {
            if (_wasPlayingBeforeInterruption) {
              _player.play();
              debugPrint('Resumed playback after interruption');
            }
            _wasPlayingBeforeInterruption = false;
          });
        }
      }
    });

    // Listen to becoming noisy events (headphones unplugged)
    session.becomingNoisyEventStream.listen((_) {
      debugPrint('Becoming noisy - pausing playback');
      if (_player.state.playing) {
        _player.pause();
      }
    });
  }

  void playRecording(RecordingInfo recording, Download download, Uri thumbnailUrl) {
    var url = download.fullPathMedia ?? download.url;

    player.open(Media(url));

    player.stream.playing.listen((event) {
      _handler.updatePlaybackState();
    });
    player.stream.position.listen((event) {
      _handler.updatePlaybackState();
    });

    player.stream.duration.listen((event) {
      mediaItem.add(MediaItem(
        id: url,
        title: recording.title,
        artist: recording.uploader,
        album: recording.extractor,
        artUri: thumbnailUrl,
        duration: player.state.duration,
      ));
      _handler.updatePlaybackState();
    });
    player.stream.buffer.listen((event) {
      _handler.updatePlaybackState();
    });
  }

  void updatePlaybackState() {
    // If mediaItem is null, set state to idle (removes lock screen notification)
    final bool hasMedia = mediaItem.value != null;

    _handler.playbackState.add(PlaybackState(
      processingState: hasMedia
          ? AudioProcessingState.ready
          : AudioProcessingState.idle,
      controls: hasMedia ? [
        MediaControl.rewind,
        if (_player.state.playing) MediaControl.pause else MediaControl.play,
        MediaControl.fastForward,
      ] : [],
      systemActions: hasMedia ? const {
        MediaAction.seek,
        MediaAction.playPause,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      } : {},
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

  /// Clear media session (removes lock screen notification)
  static void clearMediaSession() {
    _handler.mediaItem.add(null);
    _handler.updatePlaybackState();
  }

  @override
  Future<void> play() async {
    _player.playOrPause();
    super.play();
  }

  @override
  Future<void> pause() async {
    _player.playOrPause();
    super.pause();
  }

  @override
  Future<void> seek(Duration position) async {
    _player.seek(position);
    super.seek(position);
  }

  @override
  Future<void> stop() async {
    // final session = await AudioSession.instance;
    // await session.setActive(false);
    _player.stop();

    // Clear the media item to remove lock screen notification
    _handler.mediaItem.add(null);
    _handler.updatePlaybackState();

    super.stop();
  }
}
