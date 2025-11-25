import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:universal_platform/universal_platform.dart';

import '../model/recording_info.dart';
import '../utils/logger_provider.dart';
import 'api_riverpod.dart';
import 'directories_riverpod.dart';
import 'media_list_riverpod.dart';

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
      AppLoggers.media.e('Failed to load recording from disk', error: e, stackTrace: s);
      rethrow;
    } finally {
      AppLoggers.media.d('Load recording $recordingId from disk: elapsed=${stopwatch.elapsed}');
    }
  }

  Future<RecordingInfo> _fromWeb() async {
    final stopwatch = Stopwatch()..start();
    try {
      return await ref.refresh(getRecordingProvider(recordingId).future);
    } catch (e, s) {
      AppLoggers.media.e('Failed to load recording from server', error: e, stackTrace: s);
      rethrow;
    } finally {
      AppLoggers.media.d('Load recording $recordingId from server: elapsed=${stopwatch.elapsed}');
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
      AppLoggers.media.e('Failed to pull recording from server', error: e, stackTrace: s);
      rethrow;
    } finally {
      AppLoggers.media.d('Pull recording $recordingId from server: elapsed=${stopwatch.elapsed}');
    }
  }

  Future<void> refreshFromServer() async {
    if (!UniversalPlatform.isWeb) await _pullFromServer();
    ref.invalidateSelf();
    ref.invalidate(mediaListNotifierProvider);
  }

  Future<void> putPosition(Duration? position, bool finished) async {
    if (UniversalPlatform.isWeb) return;

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
      recordingFile.writeAsString(jsonEncode(recording.toJson()));
    } catch (e, s) {
      AppLoggers.media.e('Failed to put position for recording', error: e, stackTrace: s);
      rethrow;
    } finally {
      AppLoggers.media.d('Put position for recording $recordingId: elapsed=${stopwatch.elapsed}');
    }
  }
}
