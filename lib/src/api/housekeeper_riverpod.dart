import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:universal_platform/universal_platform.dart';

import '../model/recording_info.dart';
import '../playback_download/partial_file.dart';
import '../playback_download/playback_downloads.dart';
import '../utils/logger_provider.dart';
import 'directories_riverpod.dart';
import 'local_download_task_riverpod.dart';
import 'media_list_riverpod.dart';
import 'recording_riverpod.dart';

part 'housekeeper_riverpod.g.dart';

// Drives the housekeeping of local downloaded media files.
@riverpod
class LocalMediaHousekeeper extends _$LocalMediaHousekeeper {
  @override
  Future<(int number, int size)> build() {
    if (UniversalPlatform.isWeb) {
      return Future.value((0, 0));
    }
    return _evaluate();
  }

  Future<(int number, int size)> _evaluate([StorePlaces? places]) async {
    var number = 0, size = 0;
    final StorePlaces sp;
    if (places != null) {
      sp = places;
    } else {
      sp = await ref.watch(storePlacesProvider.future);
    }

    for (final entity in sp.media().listSync(recursive: true)) {
      AppLoggers.media.t('Processing media file: ${entity.path}');
      if (entity is! File) continue;
      number++;
      size += entity.lengthSync();
    }

    return Future.value((number, size));
  }

  Future<(int, int)> cleanAll() async {
    final container = ref.container;
    final placesFuture = container.read(storePlacesProvider.future);
    final playback = container.read(playbackDownloadsProvider.notifier);
    final tasks = container.read(localDTProvider.notifier);
    final (number, size) = state.requireValue;
    final sp = await placesFuture;
    // Partial files go with everything else; a download a player still reads continues as a plain stream.
    await playback.stopAll();
    sp.media().deleteSync(recursive: true);
    sp.media().createSync(recursive: true);
    tasks.forgetEnded();
    final newState = await _evaluate(sp);
    if (ref.mounted) state = AsyncValue.data(newState);
    return Future.value((number, size));
  }

  /// Deletes the downloaded media of seen or hidden recordings and returns how many files and bytes went.
  ///
  /// A file whose recording cannot be loaded is kept. The counters are re-evaluated even when the cleanup fails.
  Future<(int, int)> cleanStale() async {
    final container = ref.container;
    final placesFuture = container.read(storePlacesProvider.future);
    final playback = container.read(playbackDownloadsProvider.notifier);
    try {
      return await _cleanStale(container, placesFuture, playback);
    } finally {
      try {
        final sp = await placesFuture;
        final newState = await _evaluate(sp);
        if (ref.mounted) state = AsyncValue.data(newState);
      } on Object catch (err, st) {
        AppLoggers.media.w('Cannot re-evaluate the downloaded media', error: err, stackTrace: st);
      }
    }
  }

  Future<(int, int)> _cleanStale(ProviderContainer container, Future<StorePlaces> placesFuture, PlaybackDownloads playback) async {
    final sp = await placesFuture;

    int number = 0, size = 0;
    for (final e in sp.media().listSync()) {
      if (e is! File) continue;
      final stale = await _isStale(container, p.basename(e.path));
      if (!stale) continue;
      number++;
      size += e.lengthSync();
      e.deleteSync();
    }
    // Partial files follow the same rule: the partial file of a seen or hidden recording goes.
    final partial = Directory(p.join(sp.media().path, PartialFile.partialDirName));
    if (partial.existsSync()) {
      for (final e in partial.listSync()) {
        if (e is! File || e.path.endsWith('.state.json') || e.path.endsWith('.tmp')) continue;
        final bn = p.basename(e.path);
        final stale = await _isStale(container, bn);
        if (!stale) continue;
        number++;
        size += e.lengthSync();
        await playback.discardFile(bn);
        PartialFile.deleteFor(sp.media().path, bn);
      }
    }
    return (number, size);
  }

  /// Whether the media file [name] (`<recording id>-...`) belongs to a seen or hidden recording.
  /// A name without an id and a recording that cannot be loaded count as not stale.
  Future<bool> _isStale(ProviderContainer container, String name) async {
    final pos = name.indexOf('-');
    if (pos < 0) return false;
    final RecordingInfo ri;
    try {
      ri = await container.read(recordingProvider(name.substring(0, pos)).future);
    } on Object catch (err) {
      AppLoggers.media.w('Cannot tell whether the media file $name is stale', error: err);
      return false;
    }
    return ri.seenAt != null || ri.hiddenAt != null;
  }
}

// Drives local data housekeeping
// Returns number of local recordings
@riverpod
class LocalDataNotifier extends _$LocalDataNotifier {
  @override
  Future<int> build() {
    if (UniversalPlatform.isWeb) {
      return Future.value(0);
    }
    return _evaluate();
  }

  Future<int> _evaluate() async {
    final sp = await ref.watch(storePlacesProvider.future);
    int number = 0;

    for (final entity in sp.recordings().listSync(recursive: false)) {
      if (entity is! File) continue;
      number++;
    }

    return number;
  }

  Future<int> cleanMetadata() async {
    final container = ref.container;
    final placesFuture = container.read(storePlacesProvider.future);
    final mediaList = container.read(mediaListProvider.notifier);
    final number = state.requireValue;
    final sp = await placesFuture;
    sp.data().deleteSync(recursive: true);
    sp.recordings().createSync(recursive: true);
    sp.thumbnails().createSync(recursive: true);
    sp.downloads().createSync(recursive: true);
    container.invalidate(localDataProvider);
    // Not awaited: a failed pull must not fail the cleanup that has already been done.
    mediaList.refreshFromServer().catchError((Object e) {
      AppLoggers.media.w('Media list refresh after metadata cleanup failed: $e');
    });
    return Future.value(number);
  }
}
