import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:media_kit/media_kit.dart';
import 'package:universal_platform/universal_platform.dart';

import '../../model/download.dart';
import '../../model/recording_info.dart';
import '../../utils/logger_provider.dart';
import 'caching_proxy_server.dart';

class MKPlayerHandler extends BaseAudioHandler with SeekHandler {
  static late final MKPlayerHandler _handler;

  static MKPlayerHandler get handler => _handler;

  static Player get player => _handler._player;

  final _player = Player(
      configuration: const PlayerConfiguration(
    bufferSize: 32 * 1024 * 1024,
    logLevel: MPVLogLevel.info,
    osc: false,
  ));

  CachingProxyServer? _cachingProxyServer;

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
      AppLoggers.player.i('Audio interruption event: type=${event.type}, begin=${event.begin}');

      if (event.begin) {
        // Interruption began (phone call, alarm, etc.)
        if (_player.state.playing) {
          _wasPlayingBeforeInterruption = true;
          _player.pause();
          AppLoggers.player.i('Paused playback due to interruption');
        }
      } else {
        // Interruption ended - resume playback if it was playing before
        if (_wasPlayingBeforeInterruption) {
          // Add small delay to ensure audio session is ready
          Future.delayed(const Duration(milliseconds: 500), () {
            if (_wasPlayingBeforeInterruption) {
              _player.play();
              AppLoggers.player.i('Resumed playback after interruption');
            }
            _wasPlayingBeforeInterruption = false;
          });
        }
      }
    });

    // Listen to becoming noisy events (headphones unplugged)
    session.becomingNoisyEventStream.listen((_) {
      AppLoggers.player.i('Becoming noisy - pausing playback');
      if (_player.state.playing) {
        _player.pause();
      }
    });
  }

  Future<void> playRecording(RecordingInfo recording, Download download, Uri thumbnailUrl, {bool useCaching = false, String? mediaDirectory}) async {
    var url = download.fullPathMedia ?? download.url;
    // at the web platform force to not use caching
    useCaching = useCaching && !UniversalPlatform.isWeb;
    // If caching is enabled and we have a network URL, use proxy server
    if (useCaching && mediaDirectory != null && download.fullPathMedia == null) {
      try {
        // Initialize proxy server if needed
        _cachingProxyServer ??= CachingProxyServer(mediaDirectory: mediaDirectory);

        // Start server if not running
        if (!_cachingProxyServer!.isRunning) {
          await _cachingProxyServer!.start();
          AppLoggers.player.i('CachingProxyServer started on port ${_cachingProxyServer!.port}');
        }

        // Use proxied URL
        url = _cachingProxyServer!.getProxiedUrl(download);
        AppLoggers.player.d('Using proxied URL for playback with caching: $url');
      } catch (e, s) {
        AppLoggers.player.e('Failed to setup caching proxy', error: e, stackTrace: s);
        // Fallback to original URL
        url = download.fullPathMedia ?? download.url;
      }
    }

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
    player.stream.rate.listen((event) {
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
    _handler._cachingProxyServer?.stop();
    _handler._player.dispose();

    _handler.mediaItem.add(null);
    //_handler.playbackState.add(_handler.playbackState.value.copyWith());
  }

  /// Clear media session (removes lock screen notification)
  static void clearMediaSession() {
    _handler.mediaItem.add(null);
    _handler.updatePlaybackState();
  }

  /// Stop caching proxy server if running
  static Future<void> stopCachingProxy() async {
    if (_handler._cachingProxyServer != null && _handler._cachingProxyServer!.isRunning) {
      await _handler._cachingProxyServer!.stop();
      AppLoggers.player.i('CachingProxyServer stopped manually');
    }
  }

  @override
  Future<void> play() async {
    _player.play();
    super.play();
  }

  @override
  Future<void> pause() async {
    _player.pause();
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
