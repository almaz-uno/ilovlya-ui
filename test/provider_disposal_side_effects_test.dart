import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:background_downloader/background_downloader.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:ilovlya/src/api/api_riverpod.dart';
import 'package:ilovlya/src/api/directories_riverpod.dart';
import 'package:ilovlya/src/api/downloads_riverpod.dart';
import 'package:ilovlya/src/api/housekeeper_riverpod.dart';
import 'package:ilovlya/src/api/local_download_task_riverpod.dart';
import 'package:ilovlya/src/api/media_list_riverpod.dart';
import 'package:ilovlya/src/api/recording_riverpod.dart';
import 'package:ilovlya/src/api/thumbnail_riverpod.dart';
import 'package:ilovlya/src/model/download.dart';
import 'package:ilovlya/src/model/local_download.dart';
import 'package:ilovlya/src/model/recording_info.dart';
import 'package:ilovlya/src/model/settings.dart';
import 'package:ilovlya/src/playback_download/playback_downloads.dart';
import 'package:ilovlya/src/settings/settings_provider.dart';
import 'package:path/path.dart' as p;

import 'helpers/provider_container.dart';

class _Settings extends SettingsNotifier {
  _Settings(this.settings);
  final Settings settings;

  @override
  Future<Settings> build() async => settings;
}

class _LocalTasks extends LocalDTNotifier {
  @override
  Map<String, LocalDownloadTask> build() => {};
}

class _CountingMediaListNotifier extends MediaListNotifier {
  _CountingMediaListNotifier(this.onBuild);
  final void Function() onBuild;

  @override
  Future<List<RecordingInfo>> build() async {
    onBuild();
    return [];
  }
}

class _DelayedPlaybackDownloads extends PlaybackDownloads {
  final started = Completer<void>();
  final finishDiscard = Completer<void>();
  final discardFileStarted = Completer<String>();
  final finishDiscardFile = Completer<void>();

  @override
  Future<void> discard(String downloadId) async {
    started.complete();
    await finishDiscard.future;
  }

  @override
  Future<void> discardFile(String filename) async {
    discardFileStarted.complete(filename);
    await finishDiscardFile.future;
  }
}

void main() {
  late Directory root;
  late StorePlaces places;

  setUp(() {
    root = Directory.systemTemp.createTempSync('provider_disposal_test');
    places = StorePlaces(dataDir: p.join(root.path, 'data'), mediaDir: p.join(root.path, 'media'));
    places.media().createSync(recursive: true);
  });

  tearDown(() => root.deleteSync(recursive: true));

  ProviderContainer container({List<Override> overrides = const []}) => createTestProviderContainer(
    overrides: [
      storePlacesProvider.overrideWith((ref) async => places),
      settingsProvider.overrideWith(() => _Settings(Settings(dataStorageDirectory: places.dataDir, mediaStorageDirectory: places.mediaDir))),
      localDTProvider.overrideWith(() => _LocalTasks()),
      ...overrides,
    ],
  );

  RecordingInfo recording({String title = 'Old title'}) => RecordingInfo(id: 'r1', title: title, files: ['local.mp4'], downloads: ['d1']);

  Download download({String title = 'Old download'}) => Download(id: 'd1', recordingId: 'r1', title: title, filename: 'local.mp4', url: 'https://example.test/local.mp4', status: 'ready');

  void saveRecording(RecordingInfo value) {
    final file = File(p.join(places.recordings().path, 'r1'));
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(jsonEncode(value.toJson()));
  }

  void saveDownload(Download value) {
    final file = File(p.join(places.downloads().path, 'd1'));
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(jsonEncode(value.toJson()));
    File(p.join(places.media().path, value.filename)).writeAsBytesSync([1, 2, 3]);
  }

  test('download cleanup finishes file deletion after the notifier is disposed', () async {
    saveRecording(recording());
    saveDownload(download());
    final playback = _DelayedPlaybackDownloads();
    final c = container(overrides: [playbackDownloadsProvider.overrideWith(() => playback)]);
    addTearDown(c.dispose);
    final subscription = c.listen(downloadsProvider('r1'), (_, _) {});
    await c.read(downloadsProvider('r1').future);
    c.read(localDTProvider.notifier).publish(LocalDownloadTask(id: 'd1', displayName: 'Download', filename: 'local.mp4', status: TaskStatus.complete));

    final cleanup = c.read(downloadsProvider('r1').notifier).cleanAll();
    await playback.started.future;
    subscription.close();
    await Future<void>.delayed(Duration.zero);
    expect(c.exists(downloadsProvider('r1')), isFalse);
    playback.finishDiscard.complete();
    await cleanup;

    expect(File(p.join(places.media().path, 'local.mp4')).existsSync(), isFalse);
    expect(c.read(localDTProvider).containsKey('d1'), isFalse);
  });

  test('stale cleanup finishes deleting a partial file after the notifier is disposed', () async {
    saveRecording(recording()..seenAt = DateTime.utc(2026));
    final partialDir = Directory(p.join(places.media().path, '.partial'))..createSync(recursive: true);
    final partial = File(p.join(partialDir.path, 'r1-local.mp4'))..writeAsBytesSync([1, 2, 3]);
    final playback = _DelayedPlaybackDownloads();
    final c = container(overrides: [playbackDownloadsProvider.overrideWith(() => playback)]);
    addTearDown(c.dispose);
    final subscription = c.listen(localMediaHousekeeperProvider, (_, _) {});
    await c.read(localMediaHousekeeperProvider.future);

    final cleanup = c.read(localMediaHousekeeperProvider.notifier).cleanStale();
    expect(await playback.discardFileStarted.future, 'r1-local.mp4');
    subscription.close();
    await Future<void>.delayed(Duration.zero);
    expect(c.exists(localMediaHousekeeperProvider), isFalse);
    playback.finishDiscardFile.complete();
    expect(await cleanup, (1, 3));

    expect(partial.existsSync(), isFalse);
  });

  test('recording refresh writes its cache after the notifier is disposed', () async {
    final placesReady = Completer<StorePlaces>();
    final placesStarted = Completer<void>();
    final response = Completer<RecordingInfo>();
    var serverReads = 0;
    var mediaListBuilds = 0;
    final c = createTestProviderContainer(
      overrides: [
        storePlacesProvider.overrideWith((ref) {
          placesStarted.complete();
          return placesReady.future;
        }),
        settingsProvider.overrideWith(() => _Settings(Settings(dataStorageDirectory: places.dataDir, mediaStorageDirectory: places.mediaDir))),
        mediaListProvider.overrideWith(() => _CountingMediaListNotifier(() => mediaListBuilds++)),
        getRecordingProvider('r1').overrideWith((ref) async {
          serverReads++;
          return response.future;
        }),
      ],
    );
    addTearDown(c.dispose);
    final mediaListSubscription = c.listen(mediaListProvider, (_, _) {});
    addTearDown(mediaListSubscription.close);
    await c.read(mediaListProvider.future);
    final subscription = c.listen(recordingProvider('r1'), (_, _) {});

    final refresh = c.read(recordingProvider('r1').notifier).refreshFromServer();
    await placesStarted.future;
    subscription.close();
    await Future<void>.delayed(Duration.zero);
    expect(c.exists(recordingProvider('r1')), isFalse);
    placesReady.complete(places);
    response.complete(recording(title: 'Updated title'));
    await refresh;

    expect(serverReads, 1);
    expect(jsonDecode(File(p.join(places.recordings().path, 'r1')).readAsStringSync())['title'], 'Updated title');
    await Future<void>.delayed(Duration.zero);
    expect(mediaListBuilds, greaterThan(1));
  });

  test('media list refresh writes its cache after the notifier is disposed', () async {
    final response = Completer<List<RecordingInfo>>();
    final started = Completer<void>();
    final c = container(
      overrides: [
        listRecordingsProvider(0, MediaListNotifier.limit).overrideWith((ref) async {
          started.complete();
          return response.future;
        }),
      ],
    );
    addTearDown(c.dispose);
    final subscription = c.listen(mediaListProvider, (_, _) {});
    await c.read(mediaListProvider.future);

    final refresh = c.read(mediaListProvider.notifier).refreshFromServer();
    await started.future;
    subscription.close();
    await Future<void>.delayed(Duration.zero);
    expect(c.exists(mediaListProvider), isFalse);
    response.complete([recording(title: 'From server')]);
    await refresh;

    expect(jsonDecode(File(p.join(places.recordings().path, 'r1')).readAsStringSync())['title'], 'From server');
  });

  test('downloads refresh writes its cache after the notifier is disposed', () async {
    final placesReady = Completer<StorePlaces>();
    final placesStarted = Completer<void>();
    final response = Completer<List<Download>>();
    var serverReads = 0;
    final c = createTestProviderContainer(
      overrides: [
        storePlacesProvider.overrideWith((ref) {
          placesStarted.complete();
          return placesReady.future;
        }),
        settingsProvider.overrideWith(() => _Settings(Settings(dataStorageDirectory: places.dataDir, mediaStorageDirectory: places.mediaDir))),
        localDTProvider.overrideWith(() => _LocalTasks()),
        listDownloadsProvider('r1').overrideWith((ref) async {
          serverReads++;
          return response.future;
        }),
      ],
    );
    addTearDown(c.dispose);
    final subscription = c.listen(downloadsProvider('r1'), (_, _) {});

    final refresh = c.read(downloadsProvider('r1').notifier).refreshFromServer();
    await placesStarted.future;
    subscription.close();
    await Future<void>.delayed(Duration.zero);
    expect(c.exists(downloadsProvider('r1')), isFalse);
    placesReady.complete(places);
    response.complete([download(title: 'Updated download')]);
    await refresh;

    expect(serverReads, 1);
    expect(jsonDecode(File(p.join(places.downloads().path, 'd1')).readAsStringSync())['title'], 'Updated download');
  });

  test('thumbnail screenshot is saved even if its provider is disposed during storage lookup', () async {
    final placesReady = Completer<StorePlaces>();
    final c = createTestProviderContainer(overrides: [storePlacesProvider.overrideWith((ref) => placesReady.future)]);
    addTearDown(c.dispose);
    const url = 'https://example.test/thumbnails/thumb-1/image';
    final subscription = c.listen(thumbnailDataProvider(url), (_, _) {});
    final bytes = Uint8List.fromList([1, 2, 3, 4]);
    final update = c.read(thumbnailDataProvider(url).notifier).updateThumbnailImg(bytes);
    await Future<void>.delayed(Duration.zero);
    subscription.close();
    await Future<void>.delayed(Duration.zero);
    expect(c.exists(thumbnailDataProvider(url)), isFalse);
    placesReady.complete(places);
    await update;

    expect(File(p.join(places.thumbnails().path, 'thumb-1')).readAsBytesSync(), bytes);
  });
}
