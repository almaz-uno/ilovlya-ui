// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'playback_downloads.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$playbackDownloadsHash() => r'0c12e88a716a7eda8afa78e7716cfca756ddd99b';

/// The owner of the playback downloads: one [PartialSource] per download, served by one [LocalMediaEndpoint].
///
/// At most one playback download is active. Opening another pauses the previous one, whose partial file stays where it
/// is and is resumed the next time that download is played. A download outlives the player: [detach] lets it continue
/// unattended until it completes, fails eight times in a row, or another one starts.
///
/// The state is the [SourceState] of every download it owns; the progress itself is published into
/// [localDTNotifierProvider], beside the `background_downloader` tasks, which is where the player's progress line and
/// the explicit download's guard already look.
///
/// Copied from [PlaybackDownloads].
@ProviderFor(PlaybackDownloads)
final playbackDownloadsProvider =
    NotifierProvider<PlaybackDownloads, Map<String, SourceState>>.internal(
  PlaybackDownloads.new,
  name: r'playbackDownloadsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$playbackDownloadsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$PlaybackDownloads = Notifier<Map<String, SourceState>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
