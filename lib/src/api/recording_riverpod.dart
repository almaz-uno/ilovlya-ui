import 'package:ilovlya/src/api/api_riverpod.dart';
import 'package:ilovlya/src/api/media_list_riverpod.dart';
import 'package:ilovlya/src/model/recording_info.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'recording_riverpod.g.dart';

// @riverpod
// class RecordingsNotifier extends _$RecordingsNotifier {
//   @override
//   dynamic build() {
//     // TODO: implement build
//     throw UnimplementedError();
//   }
// }

@riverpod
Future<RecordingInfo> updateRecording(
  UpdateRecordingRef ref,
  String recordingId,
) async {
  final recording = await ref.watch(getRecordingProvider(recordingId).future);

  ref.read(mediaListNotifierProvider.notifier).updateRecording(recording);

  return recording;
}
