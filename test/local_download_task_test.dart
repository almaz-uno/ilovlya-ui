import 'package:background_downloader/background_downloader.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ilovlya/src/api/local_download_task_riverpod.dart';
import 'package:ilovlya/src/model/local_download.dart';

/// The real notifier listens to `background_downloader`, which needs a platform; this test only needs the map.
class _LocalDT extends LocalDTNotifier {
  @override
  Map<String, LocalDownloadTask> build() => {};
}

void main() {
  test('cleaning forgets the tasks that have ended and keeps the ones still running', () {
    final c = ProviderContainer(overrides: [localDTProvider.overrideWith(() => _LocalDT())]);
    addTearDown(c.dispose);
    final tasks = c.read(localDTProvider.notifier);
    for (final (id, status) in [
      ('complete', TaskStatus.complete),
      ('failed', TaskStatus.failed),
      ('running', TaskStatus.running),
      ('paused', TaskStatus.paused),
    ]) {
      tasks.publish(LocalDownloadTask(id: id, displayName: id, filename: '$id.mp4', status: status));
    }

    tasks.forgetEnded();

    expect(c.read(localDTProvider).keys, unorderedEquals(['running', 'paused']));
  });
}
