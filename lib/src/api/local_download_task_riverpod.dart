import 'package:background_downloader/background_downloader.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:universal_platform/universal_platform.dart';
import '../model/local_download.dart';

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
        case TaskProgressUpdate _:
          ldt.progress = update.progress;
          ldt.networkSpeed = update.networkSpeed;
          ldt.timeRemaining = update.timeRemaining;
      }
      return ldt;
    });
  }


}
