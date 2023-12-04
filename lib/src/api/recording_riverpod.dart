import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../model/recording_info.dart';
import 'api_riverpod.dart';
import 'media_list_riverpod.dart';

part 'recording_riverpod.g.dart';

@riverpod
Future<RecordingInfo> updateRecording(
  UpdateRecordingRef ref,
  String recordingId,
) async {
  final recording = await ref.watch(getRecordingProvider(recordingId).future);
  ref.read(mediaListNotifierProvider.notifier).updateRecording(recording);
  return recording;
}
