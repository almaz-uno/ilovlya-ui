import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:universal_platform/universal_platform.dart';
import '../model/download.dart';
import '../model/recording_info.dart';
import 'api_riverpod.dart';
import 'directories_riverpod.dart';

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
      debugPrintStack(stackTrace: s, label: e.toString());
      rethrow;
    } finally {
      debugPrint("load downloads for $recordingId from disk in ${stopwatch.elapsed}");
    }
  }

  Future<List<Download>> _fromWeb() async {
    final stopwatch = Stopwatch()..start();
    try {
      return await ref.refresh(listDownloadsProvider(recordingId).future);
    } catch (e, s) {
      debugPrintStack(stackTrace: s, label: e.toString());
      rethrow;
    } finally {
      debugPrint("load downloads for $recordingId from server in ${stopwatch.elapsed}");
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
      }
      recordingFile.writeAsStringSync(jsonEncode(recording.toJson()));

      return downloads;
    } catch (e, s) {
      debugPrintStack(stackTrace: s, label: e.toString());
      rethrow;
    } finally {
      debugPrint("pull downloads for $recordingId from server in ${stopwatch.elapsed}");
    }
  }

  Future<void> refreshFromServer() async {
    if (!UniversalPlatform.isWeb) await _pullFromServer();
    ref.invalidateSelf();
  }
}
