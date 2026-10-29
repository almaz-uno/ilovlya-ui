import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:fuzzywuzzy/fuzzywuzzy.dart';
import 'package:path/path.dart' as p;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:universal_platform/universal_platform.dart';

import '../model/recording_info.dart';
import '../model/settings.dart';
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
      return _readAllFromDisk(sp);
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
      final settingsFuture = ref.watch(
        settingsProvider.selectAsync((s) => (sortBy: s.sortBy, showHidden: s.showHidden, showSeen: s.showSeen, withServerFile: s.withServerFile, withLocalFile: s.withLocalFile)),
      );
      final placesFuture = ref.watch(storePlacesProvider.future);
      final selected = await settingsFuture;
      final sp = await placesFuture;
      if (!ref.mounted) return const [];
      final settings = Settings(sortBy: selected.sortBy, showHidden: selected.showHidden, showSeen: selected.showSeen, withServerFile: selected.withServerFile, withLocalFile: selected.withLocalFile);
      return _readAndFilterFromDisk(sp, settings);
    } catch (e, s) {
      AppLoggers.media.e('Failed to load recordings from disk', error: e, stackTrace: s);
      rethrow;
    } finally {
      AppLoggers.media.d('Load recordings from disk: elapsed=${stopwatch.elapsed}');
    }
  }

  List<RecordingInfo> _readAllFromDisk(StorePlaces sp) {
    final recordingsDir = sp.recordings();
    final mediaDir = sp.media();
    final recordings = <RecordingInfo>[];
    final list = recordingsDir.existsSync() ? recordingsDir.listSync() : <FileSystemEntity>[];
    final mediaNames = mediaDir.existsSync() ? mediaDir.listSync().whereType<File>().map((file) => p.basename(file.path)).toSet() : <String>{};

    for (final entity in list) {
      if (entity is! File) continue;
      try {
        final recording = RecordingInfo.fromJson(jsonDecode(entity.readAsStringSync()));
        if (recording.id.isEmpty) throw const FormatException('Recording has no ID');
        recording.hasLocalFile = recording.hasLocalFile || recording.files.any(mediaNames.contains);
        recordings.add(recording);
      } catch (e, s) {
        AppLoggers.media.w('Skipping unreadable recording ${entity.path}', error: e, stackTrace: s);
      }
    }
    return recordings;
  }

  List<RecordingInfo> _readAndFilterFromDisk(StorePlaces sp, Settings settings) {
    final result = _readAllFromDisk(sp).where((recording) {
      if (recording.seenAt != null && !settings.showSeen) return false;
      if (recording.hiddenAt != null && !settings.showHidden) return false;
      if (settings.withServerFile && !recording.hasFile) return false;
      if (settings.withLocalFile && !recording.hasLocalFile) return false;
      return true;
    }).toList();
    result.sort((a, b) {
      final n = DateTime.fromMillisecondsSinceEpoch(0);
      if (settings.sortBy == 'updated_at') return (b.updatedAt ?? n).compareTo(a.updatedAt ?? n);
      return (b.createdAt ?? n).compareTo(a.createdAt ?? n);
    });
    return result;
  }

  Future<List<RecordingInfo>> _filter(Future<List<RecordingInfo>> list) async {
    return _filterWithPhrase(ref.watch(searchPhraseProvider).trim(), list);
  }

  Future<List<RecordingInfo>> _filterWithPhrase(String phrase, Future<List<RecordingInfo>> list) async {

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
      final container = ref.container;
      final placesFuture = container.read(storePlacesProvider.future);
      final sp = await placesFuture;
      final recordings = await container.refresh(listRecordingsProvider(0, limit).future);
      if (recordings.any((r) => r.id.isEmpty)) throw const FormatException('Server recording has no ID');

      final recordingsDir = sp.recordings();

      for (var recording in recordings) {
        await writeLocalJson(File(p.join(recordingsDir.path, recording.id)), recording.toJson(), flush: false);
      }

      final settings = await container.read(settingsProvider.future);
      final phrase = container.read(searchPhraseProvider).trim();
      return await _filterWithPhrase(phrase, Future.value(_readAndFilterFromDisk(sp, settings)));
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
