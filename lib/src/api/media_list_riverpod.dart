import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:fuzzywuzzy/fuzzywuzzy.dart';
import 'package:path/path.dart' as p;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:universal_platform/universal_platform.dart';

import '../model/recording_info.dart';
import '../settings/settings_provider.dart';
import '../utils/logger_provider.dart';
import 'api_riverpod.dart';
import 'directories_riverpod.dart';
import 'local_json.dart';

part 'media_list_riverpod.g.dart';

@riverpod
class MediaListNotifier extends _$MediaListNotifier {
  static const limit = 100000;

  @override
  Future<List<RecordingInfo>> build() async {
    if (UniversalPlatform.isWeb) {
      return _filter(_fromWeb());
    }
    return _filter(_fromDisk());
  }

  Future<List<RecordingInfo>> allFromDisk() async {
    final stopwatch = Stopwatch()..start();
    try {
      final sp = await ref.watch(storePlacesProvider.future);
      final recordingsDir = sp.recordings();
      final mediaDir = sp.media();

      final resultList = <RecordingInfo>[];

      final list = recordingsDir.existsSync() ? recordingsDir.listSync() : <FileSystemEntity>[];

      final mediaEntities = mediaDir.existsSync() ? mediaDir.listSync() : <FileSystemEntity>[];

      for (final entity in list) {
        if (entity is! File) continue;

        try {
          final recording = RecordingInfo.fromJson(jsonDecode(entity.readAsStringSync()));
          if (recording.id.isEmpty) throw const FormatException('Recording has no ID');

          for (final df in recording.files) {
            for (final me in mediaEntities) {
              if (me is! File) continue;
              recording.hasLocalFile = recording.hasLocalFile || p.basename(me.path) == df;
              if (recording.hasLocalFile) break;
            }
          }
          resultList.add(recording);
        } catch (e, s) {
          AppLoggers.media.w('Skipping unreadable recording ${entity.path}', error: e, stackTrace: s);
        }
      }
      return resultList;
    } catch (e, s) {
      AppLoggers.media.e('Failed to load recordings from disk', error: e, stackTrace: s);
      rethrow;
    } finally {
      AppLoggers.media.d('Load all recordings from disk: elapsed=${stopwatch.elapsed}');
    }
  }

  Future<List<RecordingInfo>> _fromDisk() async {
    final stopwatch = Stopwatch()..start();
    try {
      final sortByFuture = ref.watch(settingsProvider.selectAsync((final s) => s.sortBy));
      final showHiddenFuture = ref.watch(settingsProvider.selectAsync((final s) => s.showHidden));
      final showSeenFuture = ref.watch(settingsProvider.selectAsync((final s) => s.showSeen));
      final withServerFileFuture = ref.watch(settingsProvider.selectAsync((final s) => s.withServerFile));
      final withLocalFileFuture = ref.watch(settingsProvider.selectAsync((final s) => s.withLocalFile));

      final sortBy = await sortByFuture;
      final showHidden = await showHiddenFuture;
      final showSeen = await showSeenFuture;
      final withServerFile = await withServerFileFuture;
      final withLocalFile = await withLocalFileFuture;
      if (!ref.mounted) return const [];

      final resultList = <RecordingInfo>[];

      for (final recording in await allFromDisk()) {
        if (recording.seenAt != null && !showSeen) {
          continue;
        }
        if (recording.hiddenAt != null && !showHidden) {
          continue;
        }

        if (withServerFile && !recording.hasFile) {
          continue;
        }

        if (withLocalFile && !recording.hasLocalFile) {
          continue;
        }
        resultList.add(recording);
      }

      resultList.sort((a, b) {
        final n = DateTime.fromMillisecondsSinceEpoch(0);
        if (sortBy == "updated_at") {
          return (b.updatedAt ?? n).compareTo(a.updatedAt ?? n);
        }
        return (b.createdAt ?? n).compareTo(a.createdAt ?? n);
      });

      return resultList;
    } catch (e, s) {
      AppLoggers.media.e('Failed to load recordings from disk', error: e, stackTrace: s);
      rethrow;
    } finally {
      AppLoggers.media.d('Load recordings from disk: elapsed=${stopwatch.elapsed}');
    }
  }

  Future<List<RecordingInfo>> _filter(Future<List<RecordingInfo>> list) async {
    final phrase = ref.watch(searchPhraseProvider).trim();

    if (phrase == '') {
      return list;
    }

    return extractAllSorted<RecordingInfo>(
      query: phrase,
      choices: await list,
      getter: (r) => "${r.title} ${r.uploader} ${r.extractor} ${r.webpageUrl}",
      cutoff: 50,
    ).map((e) => e.choice).toList();
  }

  Future<List<RecordingInfo>> _fromWeb() async {
    final stopwatch = Stopwatch()..start();
    try {
      final settingsFuture = ref.watch(settingsProvider.future);
      final settings = await settingsFuture;
      if (!ref.mounted) return const [];
      final showHidden = settings.showHidden;
      final showSeen = settings.showSeen;

      final recordings = await ref.refresh(listRecordingsProvider(0, limit, sortBy: settings.sortBy).future);

      return recordings.where((RecordingInfo recording) {
        if (recording.seenAt != null && !showSeen) {
          return false;
        }
        if (recording.hiddenAt != null && !showHidden) {
          return false;
        }

        return true;
      }).toList();
    } catch (e, s) {
      AppLoggers.media.e('Failed to load recordings from server', error: e, stackTrace: s);
      rethrow;
    } finally {
      AppLoggers.media.d('Load recordings from server: elapsed=${stopwatch.elapsed}');
    }
  }

  Future<List<RecordingInfo>> _pullFromServer() async {
    final stopwatch = Stopwatch()..start();
    try {
      final sp = await ref.watch(storePlacesProvider.future);
      if (!ref.mounted) return const [];
      final recordings = await ref.refresh(listRecordingsProvider(0, limit).future);
      if (!ref.mounted) return const [];
      if (recordings.any((r) => r.id.isEmpty)) throw const FormatException('Server recording has no ID');

      final recordingsDir = sp.recordings();

      for (var recording in recordings) {
        await writeLocalJson(File(p.join(recordingsDir.path, recording.id)), recording.toJson(), flush: false);
      }

      if (!ref.mounted) return const [];
      return await _filter(_fromDisk());
    } catch (e, s) {
      AppLoggers.media.e('Failed to pull recordings from server', error: e, stackTrace: s);
      rethrow;
    } finally {
      AppLoggers.media.d('Pull recordings from server: elapsed=${stopwatch.elapsed}');
    }
  }

  Future<void> refreshFromServer() async {
    if (!UniversalPlatform.isWeb) {
      try {
        final newList = await _pullFromServer();
        if (!ref.mounted) return;
        state = AsyncValue.data(newList);
      } catch (_) {
        // _pullFromServer logged the failure. Keep local data and do not let a
        // periodic or fire-and-forget refresh escape as an unhandled error.
      }
    }
  }
}

@riverpod
class SearchPhraseNotifier extends _$SearchPhraseNotifier {
  @override
  String build() {
    return '';
  }

  void setPhrase(String value) {
    state = value;
  }
}
