import 'package:idb_shim/idb.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../model/recording_info.dart';
import '../settings/settings_provider.dart';
import 'api_riverpod.dart';
import 'persistent_riverpod.dart';

part 'media_list_riverpod.g.dart';

const _storeName = "recordings";

@riverpod
class MediaListNotifier extends _$MediaListNotifier {
  static const limit = 1000;

  @override
  Future<List<RecordingInfo>> build() async {
    return _loadList();
  }

  Future<void> _save(List<RecordingInfo> recordings) async {
    final db = await ref.watch(dbProvider(_storeName).future);

    final txn = db.transaction(_storeName, idbModeReadWrite);
    final store = txn.objectStore(_storeName);
    for (var recording in recordings) {
      store.put(recording, recording.id);
    }
    await txn.completed;
  }

  Future<List<RecordingInfo>> _loadList() async {
    final settings = await ref.watch(settingsNotifierProvider.future);
    final showHidden = settings.showHidden;
    final showSeen = settings.showSeen;

    final recordings = await ref.read(listRecordingsProvider(0, limit, sortBy: settings.sortBy).future);

    // _save(recordings);

    return recordings.where((RecordingInfo recording) {
      if (recording.seenAt != null && !showSeen) {
        return false;
      }
      if (recording.hiddenAt != null && !showHidden) {
        return false;
      }

      return true;
    }).toList();
  }

  void updateRecording(RecordingInfo recording) {
    if (!state.hasValue) {
      return;
    }

    final list = state.requireValue;

    for (var i = 0; i < list.length; i++) {
      if (list[i].id == recording.id) {
        list[i] = recording;
        state = AsyncData(list);
        // _save(recordings);
      }
    }
  }
}
