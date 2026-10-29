// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'playback_downloads.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The owner of the playback downloads: one [PartialSource] per download, served by one [LocalMediaEndpoint].
///
/// At most one playback download is active. Opening another pauses the previous one, whose partial file stays where it
/// is and is resumed the next time that download is played. A download outlives the player: [detach] lets it continue
/// unattended until it completes, fails eight times in a row, or another one starts.
///
/// The state is the [SourceState] of every download it owns; the progress itself is published into
/// [localDTProvider], beside the `background_downloader` tasks, which is where the player's progress line and
/// the explicit download's guard already look.
///
/// On iOS the endpoint listens only while it may be needed: with the application in front, or with the player playing,
/// which keeps the process running in the background. Otherwise the process is about to be suspended, and its sockets
/// reclaimed; the endpoint stops listening and listens again on the same port on return, so that the player's URL stays
/// valid (spec 004, "On iOS").

@ProviderFor(PlaybackDownloads)
final playbackDownloadsProvider = PlaybackDownloadsProvider._();

/// The owner of the playback downloads: one [PartialSource] per download, served by one [LocalMediaEndpoint].
///
/// At most one playback download is active. Opening another pauses the previous one, whose partial file stays where it
/// is and is resumed the next time that download is played. A download outlives the player: [detach] lets it continue
/// unattended until it completes, fails eight times in a row, or another one starts.
///
/// The state is the [SourceState] of every download it owns; the progress itself is published into
/// [localDTProvider], beside the `background_downloader` tasks, which is where the player's progress line and
/// the explicit download's guard already look.
///
/// On iOS the endpoint listens only while it may be needed: with the application in front, or with the player playing,
/// which keeps the process running in the background. Otherwise the process is about to be suspended, and its sockets
/// reclaimed; the endpoint stops listening and listens again on the same port on return, so that the player's URL stays
/// valid (spec 004, "On iOS").
final class PlaybackDownloadsProvider
    extends $NotifierProvider<PlaybackDownloads, Map<String, SourceState>> {
  /// The owner of the playback downloads: one [PartialSource] per download, served by one [LocalMediaEndpoint].
  ///
  /// At most one playback download is active. Opening another pauses the previous one, whose partial file stays where it
  /// is and is resumed the next time that download is played. A download outlives the player: [detach] lets it continue
  /// unattended until it completes, fails eight times in a row, or another one starts.
  ///
  /// The state is the [SourceState] of every download it owns; the progress itself is published into
  /// [localDTProvider], beside the `background_downloader` tasks, which is where the player's progress line and
  /// the explicit download's guard already look.
  ///
  /// On iOS the endpoint listens only while it may be needed: with the application in front, or with the player playing,
  /// which keeps the process running in the background. Otherwise the process is about to be suspended, and its sockets
  /// reclaimed; the endpoint stops listening and listens again on the same port on return, so that the player's URL stays
  /// valid (spec 004, "On iOS").
  PlaybackDownloadsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'playbackDownloadsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$playbackDownloadsHash();

  @$internal
  @override
  PlaybackDownloads create() => PlaybackDownloads();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Map<String, SourceState> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Map<String, SourceState>>(value),
    );
  }
}

String _$playbackDownloadsHash() => r'62997831a6069e1ee6297bea8577368092ee06e7';

/// The owner of the playback downloads: one [PartialSource] per download, served by one [LocalMediaEndpoint].
///
/// At most one playback download is active. Opening another pauses the previous one, whose partial file stays where it
/// is and is resumed the next time that download is played. A download outlives the player: [detach] lets it continue
/// unattended until it completes, fails eight times in a row, or another one starts.
///
/// The state is the [SourceState] of every download it owns; the progress itself is published into
/// [localDTProvider], beside the `background_downloader` tasks, which is where the player's progress line and
/// the explicit download's guard already look.
///
/// On iOS the endpoint listens only while it may be needed: with the application in front, or with the player playing,
/// which keeps the process running in the background. Otherwise the process is about to be suspended, and its sockets
/// reclaimed; the endpoint stops listening and listens again on the same port on return, so that the player's URL stays
/// valid (spec 004, "On iOS").

abstract class _$PlaybackDownloads extends $Notifier<Map<String, SourceState>> {
  Map<String, SourceState> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<Map<String, SourceState>, Map<String, SourceState>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<Map<String, SourceState>, Map<String, SourceState>>,
              Map<String, SourceState>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
