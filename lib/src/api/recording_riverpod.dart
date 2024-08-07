import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:ilovlya/src/api/media_list_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:universal_platform/universal_platform.dart';

import '../model/recording_info.dart';
import 'api_riverpod.dart';
import 'directories_riverpod.dart';

part 'recording_riverpod.g.dart';

@riverpod
class RecordingNotifier extends _$RecordingNotifier {
  @override
  Future<RecordingInfo> build(String recordingId) async {
    if (UniversalPlatform.isWeb) {
      return _fromWeb();
    }
    return _fromDisk();
  }

  Future<RecordingInfo> _fromDisk() async {
    final stopwatch = Stopwatch()..start();
    try {
      final sp = await ref.watch(storePlacesProvider.future);

      final recordingFile = File(p.join(sp.recordings().path, recordingId));

      final recording = RecordingInfo.fromJson(jsonDecode(recordingFile.readAsStringSync()));
      for (final df in recording.files) {
        if (File(p.join(sp.media().path, df)).existsSync()) {
          recording.hasLocalFile = true;
          break;
        }
      }
      return recording;
    } catch (e, s) {
      debugPrintStack(stackTrace: s, label: e.toString());
      rethrow;
    } finally {
      debugPrint("load recording $recordingId from disk in ${stopwatch.elapsed}");
    }
  }

  Future<RecordingInfo> _fromWeb() async {
    final stopwatch = Stopwatch()..start();
    try {
      return await ref.refresh(getRecordingProvider(recordingId).future);
    } catch (e, s) {
      debugPrintStack(stackTrace: s, label: e.toString());
      rethrow;
    } finally {
      debugPrint("load recording $recordingId from server in ${stopwatch.elapsed}");
    }
  }

  Future<void> _pullFromServer() async {
    final stopwatch = Stopwatch()..start();
    try {
      final sp = await ref.watch(storePlacesProvider.future);
      final recording = await ref.refresh(getRecordingProvider(recordingId).future);

      final recordingFile = File(p.join(sp.recordings().path, recordingId));
      recordingFile.writeAsStringSync(jsonEncode(recording.toJson()));
    } catch (e, s) {
      debugPrintStack(stackTrace: s, label: e.toString());
      rethrow;
    } finally {
      debugPrint("pull recording $recordingId from server in ${stopwatch.elapsed}");
    }
  }

  Future<void> refreshFromServer() async {
    if (!UniversalPlatform.isWeb) await _pullFromServer();
    ref.invalidateSelf();
    ref.invalidate(mediaListNotifierProvider);
  }

  Future<RecordingInfo> putPosition(Duration? position, bool finished) async {
    final stopwatch = Stopwatch()..start();

    try {
      final sp = await ref.watch(storePlacesProvider.future);

      final recordingFile = File(p.join(sp.recordings().path, recordingId));

      final recording = RecordingInfo.fromJson(jsonDecode(recordingFile.readAsStringSync()));
      for (final df in recording.files) {
        if (File(p.join(sp.media().path, df)).existsSync()) {
          recording.hasLocalFile = true;
          break;
        }
      }
      if (position != null) {
        recording.position = position.inSeconds;
      }
      if (finished) {
        recording.seenAt = recording.seenAt ?? DateTime.now();
      } else {
        recording.seenAt = null;
      }
      recording.updatedAt = DateTime.now();

      //save back
      recordingFile.writeAsStringSync(jsonEncode(recording.toJson()));

      return recording;
    } catch (e, s) {
      debugPrintStack(stackTrace: s, label: e.toString());
      rethrow;
    } finally {
      debugPrint("load recording $recordingId from disk in ${stopwatch.elapsed}");
    }
  }
}
