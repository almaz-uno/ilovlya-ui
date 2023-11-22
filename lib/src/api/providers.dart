import 'package:ilovlya/src/api/media.dart';
import 'package:ilovlya/src/settings/settings_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../model/recording_info.dart';

part 'providers.g.dart';

@riverpod
class MediaListNotifier extends _$MediaListNotifier {
  static const limit = 1000;

  @override
  Future<List<RecordingInfo>> build() async {
    return _loadList();
  }

  Future<void> _save() async {
    // TODO: add this functionality
  }

  Future<List<RecordingInfo>> _loadList() async {
    final settings = await ref.watch(settingsNotifierProvider.future);
    final showHidden = settings.showHidden;
    final showSeen = settings.showSeen;
    return (await listRecordings(0, limit, sortBy: settings.sortBy))
        .where((RecordingInfo recording) {
      if (recording.seenAt != null && !showSeen) {
        return false;
      }
      if (recording.hiddenAt != null && !showHidden) {
        return false;
      }

      return true;
    }).toList();
  }

  Future<void> refresh() async {
    state = AsyncData(await _loadList());
  }
}
