import 'package:background_downloader/background_downloader.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:universal_platform/universal_platform.dart';
import '../model/local_download.dart';
import 'downloads_riverpod.dart';
import 'media_list_riverpod.dart';

part 'local_download_task_riverpod.g.dart';

@Riverpod(keepAlive: true)
class LocalDTNotifier extends _$LocalDTNotifier {
  @override
  Map<String, LocalDownloadTask> build() {
    if (!UniversalPlatform.isWeb) {
      FileDownloader().updates.listen(_gatherUpdates);
    }
    return <String, LocalDownloadTask>{};
  }

  void _gatherUpdates(TaskUpdate update) {
    final id = update.task.taskId;
    if (!state.containsKey(id)) {
      state = {
        ...state,
        id: LocalDownloadTask(
          id: id,
          displayName: update.task.displayName,
          filename: update.task.filename,
        ),
      };
    }

    state.update(id, (LocalDownloadTask ldt) {
      switch (update) {
        case TaskStatusUpdate _:
          ldt.status = update.status;
          if (update.status.isFinalState) {
            ref.invalidate(mediaListNotifierProvider);
            ref.invalidate(downloadsNotifierProvider(update.task.taskId));
          }
        case TaskProgressUpdate _:
          ldt.progress = update.progress;
          ldt.networkSpeed = update.networkSpeed;
          ldt.timeRemaining = update.timeRemaining;
      }
      return ldt;
    });

    state = <String, LocalDownloadTask>{}..addAll(state);

  }

  /// Puts the state of a download that is not a `background_downloader` task — a playback download — beside the tasks,
  /// so that the progress line in the player and the guard in `downloadFile` see it like any other.
  void publish(LocalDownloadTask task) {
    state = {...state, task.id: task};
  }

  /// Drops what [publish] put there, once the download is gone.
  void forget(String id) {
    if (!state.containsKey(id)) return;
    state = {...state}..remove(id);
  }
}
