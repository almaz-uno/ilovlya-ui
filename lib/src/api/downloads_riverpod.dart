import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:universal_platform/universal_platform.dart';
import '../model/download.dart';
import '../model/recording_info.dart';
import '../utils/logger_provider.dart';
import 'api_riverpod.dart';
import 'directories_riverpod.dart';
import 'recording_riverpod.dart';

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

      final resultList = <Download>[];

      final recording = RecordingInfo.fromJson(jsonDecode(File(p.join(sp.recordings().path, recordingId)).readAsStringSync()));

      for (var did in recording.downloads) {
        final f = File(p.join(sp.downloads().path, did));

        final download = Download.fromJson(jsonDecode(f.readAsStringSync()));
        final mediaFile = p.join(sp.media().path, download.filename);
        download.fullPathMedia = File(mediaFile).existsSync() ? mediaFile : null;

        resultList.add(download);
      }

      resultList.sort((a, b) => a.id.compareTo(b.id));

      return resultList;
    } on PathNotFoundException catch (_) {
      return _fromWeb();
    } catch (e, s) {
      AppLoggers.download.e('Failed to load downloads from disk', error: e, stackTrace: s);
      rethrow;
    } finally {
      AppLoggers.download.d('Load downloads for $recordingId from disk: elapsed=${stopwatch.elapsed}');
    }
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
      final sp = await ref.watch(storePlacesProvider.future);
      final downloads = await ref.refresh(listDownloadsProvider(recordingId).future);

      final recordingFile = File(p.join(sp.recordings().path, recordingId));
      final recording = RecordingInfo.fromJson(jsonDecode(recordingFile.readAsStringSync()));
      final downloadsDir = sp.downloads();

      recording.downloads = [];

      for (var d in downloads) {
        recording.downloads.add(d.id);
        File(p.join(downloadsDir.path, d.id)).writeAsStringSync(jsonEncode(d.toJson()));

        // Check if local file exists
        final mediaFile = p.join(sp.media().path, d.filename);
        d.fullPathMedia = File(mediaFile).existsSync() ? mediaFile : null;
      }
      recordingFile.writeAsStringSync(jsonEncode(recording.toJson()));

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
    for (final dp in state.requireValue) {
      if (dp.fullPathMedia == null) continue;
      if (downloadId != "" && dp.id != downloadId) continue;
      final f = File(dp.fullPathMedia!);
      if (f.existsSync()) f.deleteSync();
    }
    // Re-read data from disk and update state directly
    final newDownloads = await _fromDisk();
    state = AsyncValue.data(newDownloads);
    ref.invalidate(recordingNotifierProvider(recordingId));
  }

  Future<void> refreshFromServer() async {
    if (!UniversalPlatform.isWeb) {
      final newDownloads = await _pullFromServer();
      // Update state directly instead of invalidateSelf()
      // This avoids full provider recreation and widget tree rebuild
      state = AsyncValue.data(newDownloads);
    }
  }
}
