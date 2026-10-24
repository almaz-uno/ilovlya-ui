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
import 'local_json.dart';

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

  Future<RecordingInfo> _pullFromServer() async {
    final stopwatch = Stopwatch()..start();
    try {
      final sp = await ref.watch(storePlacesProvider.future);
      final recording = await ref.refresh(getRecordingProvider(recordingId).future);
      if (recording.id != recordingId) throw const FormatException('Server returned a different recording ID');

      final recordingFile = File(p.join(sp.recordings().path, recordingId));
      await writeLocalJson(recordingFile, recording.toJson());

      return recording;
    } catch (e, s) {
      AppLoggers.media.e('Failed to pull recording from server', error: e, stackTrace: s);
      rethrow;
    } finally {
      AppLoggers.media.d('Pull recording $recordingId from server: elapsed=${stopwatch.elapsed}');
    }
  }

  Future<void> refreshFromServer() async {
    if (!UniversalPlatform.isWeb) {
      try {
        final newRecording = await _pullFromServer();
        state = AsyncValue.data(newRecording);
      } catch (_) {
        // The pull already logged the error. The local recording stays usable.
        return;
      }
    }
    // Still need to invalidate the list for synchronization
    ref.invalidate(mediaListNotifierProvider);
  }

  Future<void> putPosition(Duration? position, bool finished) async {
    if (UniversalPlatform.isWeb) return;

    final stopwatch = Stopwatch()..start();

    try {
      final sp = await ref.watch(storePlacesProvider.future);

      final recordingFile = File(p.join(sp.recordings().path, recordingId));

      await updateLocalJson(recordingFile, (json) {
        final recording = RecordingInfo.fromJson(json);
        if (position != null) recording.position = position.inSeconds;
        recording.seenAt = finished ? (recording.seenAt ?? DateTime.now()) : null;
        recording.updatedAt = DateTime.now();
        return recording.toJson();
      });
    } catch (e, s) {
      AppLoggers.media.e('Failed to put position for recording', error: e, stackTrace: s);
    } finally {
      AppLoggers.media.d('Put position for recording $recordingId: elapsed=${stopwatch.elapsed}');
    }
  }
}
