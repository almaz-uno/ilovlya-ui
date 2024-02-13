import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:universal_platform/universal_platform.dart';

import '../model/recording_info.dart';
import '../settings/settings_provider.dart';
import 'api_riverpod.dart';
import 'directories_riverpod.dart';

part 'media_list_riverpod.g.dart';

@riverpod
class MediaListNotifier extends _$MediaListNotifier {
  static const limit = 1000;

  @override
  Future<List<RecordingInfo>> build() async {
    if (UniversalPlatform.isWeb) {
      return _fromWeb();
    }
    return _fromDisk();
  }

  Future<List<RecordingInfo>> _fromDisk() async {
    final stopwatch = Stopwatch()..start();
    try {
      final sp = await ref.watch(storePlacesProvider.future);
      final sortBy = await ref.watch(settingsNotifierProvider.selectAsync((final s) => s.sortBy));
      final showHidden = await ref.watch(settingsNotifierProvider.selectAsync((final s) => s.showHidden));
      final showSeen = await ref.watch(settingsNotifierProvider.selectAsync((final s) => s.showSeen));

      final withServerFile = await ref.watch(settingsNotifierProvider.selectAsync((final s) => s.withServerFile));
      final withLocalFile = await ref.watch(settingsNotifierProvider.selectAsync((final s) => s.withLocalFile));

      final resultList = <RecordingInfo>[];

      final recordingsDir = sp.recordings();

      final list = recordingsDir.listSync();
      for (final entity in list) {
        if (entity is! File) continue;

        final recording = RecordingInfo.fromJson(jsonDecode(entity.readAsStringSync()));

        for (final df in recording.files) {
          if (File(p.join(sp.media().path, df)).existsSync()) {
            recording.hasLocalFile = true;
            break;
          }
        }

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
      debugPrintStack(stackTrace: s, label: e.toString());
      rethrow;
    } finally {
      debugPrint("load recordings from disk in ${stopwatch.elapsed}");
    }
  }

  Future<List<RecordingInfo>> _fromWeb() async {
    final stopwatch = Stopwatch()..start();
    try {
      final settings = await ref.watch(settingsNotifierProvider.future);
      final showHidden = settings.showHidden;
      final showSeen = settings.showSeen;

      final recordings = await ref.read(listRecordingsProvider(0, limit, sortBy: settings.sortBy).future);

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
      debugPrintStack(stackTrace: s, label: e.toString());
      rethrow;
    } finally {
      debugPrint("load recordings from server in ${stopwatch.elapsed}");
    }
  }

  Future<void> _pullFromServer() async {
    final stopwatch = Stopwatch()..start();
    try {
      final sp = await ref.watch(storePlacesProvider.future);
      final recordings = await ref.read(listRecordingsProvider(0, limit).future);

      final recordingsDir = sp.recordings();

      for (var recording in recordings) {
        final r = jsonEncode(recording.toJson());
        File(p.join(recordingsDir.path, recording.id)).writeAsStringSync(r);
      }
    } catch (e, s) {
      debugPrintStack(stackTrace: s, label: e.toString());
      rethrow;
    } finally {
      debugPrint("pull recordings from server in ${stopwatch.elapsed}");
    }
  }

  Future<void> refreshFromServer() async {
    if (!UniversalPlatform.isWeb) await _pullFromServer();
    ref.invalidateSelf();
  }
}
