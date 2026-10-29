import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:ilovlya/src/api/api_riverpod.dart';
import 'package:ilovlya/src/api/directories_riverpod.dart';
import 'package:ilovlya/src/api/downloads_riverpod.dart';
import 'package:ilovlya/src/api/media_list_riverpod.dart';
import 'package:ilovlya/src/model/download.dart';
import 'package:ilovlya/src/model/recording_info.dart';
import 'package:ilovlya/src/model/settings.dart';
import 'package:ilovlya/src/playback_download/playback_downloads.dart';
import 'package:ilovlya/src/settings/settings_provider.dart';
import 'package:path/path.dart' as p;

import 'helpers/provider_container.dart';

class _Settings extends SettingsNotifier {
  @override
  Future<Settings> build() async => Settings();
}

class _PlaybackDownloads extends PlaybackDownloads {
  @override
  Future<void> discard(String downloadId) async {}
}

void main() {
  late Directory root;
  late StorePlaces places;

  setUp(() {
    root = Directory.systemTemp.createTempSync('provider_review_test');
    places = StorePlaces(dataDir: p.join(root.path, 'data'), mediaDir: p.join(root.path, 'media'));
    places.media().createSync(recursive: true);
  });

  tearDown(() => root.deleteSync(recursive: true));

  ProviderContainer container({List<Override> overrides = const []}) =>
      createTestProviderContainer(overrides: [storePlacesProvider.overrideWith((ref) async => places), settingsProvider.overrideWith(_Settings.new), ...overrides]);

  RecordingInfo recording(String id, {String title = 'Recording'}) => RecordingInfo(id: id, title: title, files: ['$id.mp4']);

  Download download(String id) => Download(id: id, recordingId: 'r1', title: 'Download $id', filename: '$id.mp4', url: 'https://example.test/$id.mp4', status: 'ready');

  test('cleanup fetches downloads when the local recording metadata is missing', () async {
    final recordingFile = File(p.join(places.recordings().path, 'r1'))..writeAsStringSync(jsonEncode((recording('r1')..downloads = ['local']).toJson()));
    final local = download('local');
    final localDownloadFile = File(p.join(places.downloads().path, local.id))..writeAsStringSync(jsonEncode(local.toJson()));
    final localMediaFile = File(p.join(places.media().path, local.filename))..writeAsBytesSync([1]);
    final remote = download('remote');
    final c = container(
      overrides: [
        playbackDownloadsProvider.overrideWith(_PlaybackDownloads.new),
        listDownloadsProvider('r1').overrideWith((ref) async => [remote]),
      ],
    );
    addTearDown(c.dispose);
    final subscription = c.listen(downloadsProvider('r1'), (_, _) {});
    await c.read(downloadsProvider('r1').future);
    recordingFile.deleteSync();

    await c.read(downloadsProvider('r1').notifier).cleanAll();

    expect(localDownloadFile.existsSync(), isTrue);
    expect(localMediaFile.existsSync(), isFalse);
    expect(c.read(downloadsProvider('r1')).requireValue.map((d) => d.id), ['remote']);
    subscription.close();
  });

  test('server refresh retains recordings that exist only in the local library', () async {
    final localOnly = recording('r2', title: 'Offline recording');
    File(p.join(places.recordings().path, localOnly.id)).writeAsStringSync(jsonEncode(localOnly.toJson()));
    final remote = recording('r1', title: 'Server recording');
    final c = container(
      overrides: [
        listRecordingsProvider(0, MediaListNotifier.limit).overrideWith((ref) async => [remote]),
      ],
    );
    addTearDown(c.dispose);
    final subscription = c.listen(mediaListProvider, (_, _) {});
    expect((await c.read(mediaListProvider.future)).map((r) => r.id), ['r2']);

    await c.read(mediaListProvider.notifier).refreshFromServer();

    final ids = c.read(mediaListProvider).requireValue.map((r) => r.id).toSet();
    expect(ids, {'r1', 'r2'});
    subscription.close();
  });
}
