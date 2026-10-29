import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:universal_platform/universal_platform.dart';
import '../model/download.dart';
import '../model/recording_info.dart';
import '../playback_download/partial_file.dart';
import '../playback_download/playback_downloads.dart';
import '../utils/logger_provider.dart';
import 'api_riverpod.dart';
import 'directories_riverpod.dart';
import 'local_download_task_riverpod.dart';
import 'recording_riverpod.dart';
import 'local_json.dart';

part 'downloads_riverpod.g.dart';

@riverpod
class DownloadsNotifier extends _$DownloadsNotifier {
  @override
  Future<List<Download>> build(String recordingId) async {
    if (UniversalPlatform.isWeb) {
      return _fromWeb();
    }
    return _fromDisk();
  }

  Future<List<Download>> _fromDisk() async {
    final stopwatch = Stopwatch()..start();
    try {
      final sp = await ref.watch(storePlacesProvider.future);

      return _readFromDisk(sp);
    } on PathNotFoundException catch (_) {
      try {
        return await _fromWeb();
      } catch (_) {
        // _fromWeb logged the failure; a missing cache must stay usable offline.
        return [];
      }
    } catch (e, s) {
      AppLoggers.download.e('Failed to load downloads from disk', error: e, stackTrace: s);
      return [];
    } finally {
      AppLoggers.download.d('Load downloads for $recordingId from disk: elapsed=${stopwatch.elapsed}');
    }
  }

  List<Download> _readFromDisk(StorePlaces sp) {
    final resultList = <Download>[];
    final recording = RecordingInfo.fromJson(jsonDecode(File(p.join(sp.recordings().path, recordingId)).readAsStringSync()));
    for (var did in recording.downloads) {
      final f = File(p.join(sp.downloads().path, did));
      try {
        final download = Download.fromJson(jsonDecode(f.readAsStringSync()));
        if (download.id.isEmpty) throw const FormatException('Download has no ID');
        final mediaFile = p.join(sp.media().path, download.filename);
        download.fullPathMedia = File(mediaFile).existsSync() ? mediaFile : null;
        resultList.add(download);
      } catch (e, s) {
        AppLoggers.download.w('Skipping unreadable download ${f.path}', error: e, stackTrace: s);
      }
    }
    resultList.sort((a, b) => a.id.compareTo(b.id));
    return resultList;
  }

  Future<List<Download>> _fromWeb() async {
    final stopwatch = Stopwatch()..start();
    try {
      return await ref.refresh(listDownloadsProvider(recordingId).future);
    } catch (e, s) {
      AppLoggers.download.e('Failed to load downloads from server', error: e, stackTrace: s);
      rethrow;
    } finally {
      AppLoggers.download.d('Load downloads for $recordingId from server: elapsed=${stopwatch.elapsed}');
    }
  }

  Future<List<Download>> _pullFromServer() async {
    final stopwatch = Stopwatch()..start();
    try {
      final container = ref.container;
      final placesFuture = container.read(storePlacesProvider.future);
      final sp = await placesFuture;
      final downloads = await container.refresh(listDownloadsProvider(recordingId).future);
      if (downloads.any((d) => d.id.isEmpty || d.filename.isEmpty)) throw const FormatException('Server download has no ID or filename');

      final recordingFile = File(p.join(sp.recordings().path, recordingId));
      final downloadsDir = sp.downloads();

      for (var d in downloads) {
        await writeLocalJson(File(p.join(downloadsDir.path, d.id)), d.toJson(), flush: false);

        // Check if local file exists
        final mediaFile = p.join(sp.media().path, d.filename);
        d.fullPathMedia = File(mediaFile).existsSync() ? mediaFile : null;
      }
      // Newly opened recordings may not have reached the local library yet.
      // Keep their downloads usable; library synchronization supplies metadata.
      if (recordingFile.existsSync()) {
        await updateLocalJson(recordingFile, (json) {
          final recording = RecordingInfo.fromJson(json)..downloads = downloads.map((d) => d.id).toList();
          return recording.toJson();
        }, flush: false);
      }

      container.invalidate(recordingProvider(recordingId));

      return downloads;
    } catch (e, s) {
      AppLoggers.download.e('Failed to pull downloads from server', error: e, stackTrace: s);
      rethrow;
    } finally {
      AppLoggers.download.d('Pull downloads for $recordingId from server: elapsed=${stopwatch.elapsed}');
    }
  }

  Future<void> cleanAll() async {
    await _clean();
  }

  Future<void> clean(String downloadId) async {
    await _clean(downloadId: downloadId);
  }

  Future<void> _clean({String downloadId = ""}) async {
    final container = ref.container;
    final placesFuture = container.read(storePlacesProvider.future);
    final playback = container.read(playbackDownloadsProvider.notifier);
    final tasks = container.read(localDTProvider.notifier);
    final downloads = state.requireValue;
    final sp = await placesFuture;
    for (final dp in downloads) {
      if (downloadId != "" && dp.id != downloadId) continue;
      // The partial file belongs to the download as much as the final one does.
      await playback.discard(dp.id);
      PartialFile.deleteFor(sp.media().path, dp.filename);
      // So does its task: a complete one would still be shown as complete. One still running is left to finish.
      if (container.read(localDTProvider)[dp.id]?.status?.isFinalState ?? false) tasks.forget(dp.id);
      if (dp.fullPathMedia == null) continue;
      final f = File(dp.fullPathMedia!);
      if (f.existsSync()) f.deleteSync();
    }
    // Re-read data from disk and update state directly
    final newDownloads = _readFromDisk(sp);
    if (ref.mounted) state = AsyncValue.data(newDownloads);
    container.invalidate(recordingProvider(recordingId));
  }

  Future<void> refreshFromServer() async {
    if (!UniversalPlatform.isWeb) {
      try {
        final newDownloads = await _pullFromServer();
        if (ref.mounted) state = AsyncValue.data(newDownloads);
      } catch (_) {
        // The pull already logged the failure; keep the downloaded files usable.
      }
    }
  }
}
