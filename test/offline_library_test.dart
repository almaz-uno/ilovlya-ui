import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:ilovlya/src/api/api_riverpod.dart';
import 'package:ilovlya/src/api/directories_riverpod.dart';
import 'package:ilovlya/src/api/downloads_riverpod.dart';
import 'package:ilovlya/src/api/media_list_riverpod.dart';
import 'package:ilovlya/src/api/recording_riverpod.dart';
import 'package:ilovlya/src/model/download.dart';
import 'package:ilovlya/src/model/recording_info.dart';
import 'package:ilovlya/src/model/settings.dart';
import 'package:ilovlya/src/settings/settings_provider.dart';
import 'package:path/path.dart' as p;

class OfflineTestSettings extends SettingsNotifier {
  OfflineTestSettings(this.settings);
  final Settings settings;
  @override
  Future<Settings> build() async => settings;
}

void main() {
  late Directory root;
  late StorePlaces places;
  ProviderContainer? container;
  final recording = RecordingInfo(
      id: 'r1',
      title: 'Downloaded recording',
      files: ['local.mp4'],
      downloads: ['d1'],
      duration: 10);
  File recordFile() => File(p.join(places.recordings().path, 'r1'));

  ProviderContainer createContainer(
      {String server = 'http://127.0.0.1:1',
      Object? serverFailure,
      void Function()? onServerRequest,
      List<RecordingInfo>? serverRecordings,
      List<Download>? serverDownloads}) {
    final c = container = ProviderContainer(overrides: [
      if (serverRecordings != null)
        listRecordingsProvider(0, MediaListNotifier.limit)
            .overrideWith((ref) async => serverRecordings),
      if (serverDownloads != null)
        listDownloadsProvider('r1')
            .overrideWith((ref) async => serverDownloads),
      if (serverFailure != null) ...[
        listRecordingsProvider(0, MediaListNotifier.limit)
            .overrideWith((ref) async {
          onServerRequest?.call();
          throw serverFailure;
        }),
        getRecordingProvider('r1').overrideWith((ref) async {
          onServerRequest?.call();
          throw serverFailure;
        }),
      ],
      if (serverFailure != null || onServerRequest != null)
        listDownloadsProvider('r1').overrideWith((ref) async {
          onServerRequest?.call();
          throw serverFailure ?? StateError('Unexpected network fallback');
        }),
      storePlacesProvider.overrideWith((ref) async => places),
      settingsNotifierProvider.overrideWith(() => OfflineTestSettings(Settings(
          serverUrl: server,
          dataStorageDirectory: places.dataDir,
          mediaStorageDirectory: places.mediaDir))),
    ]);
    c.listen(mediaListNotifierProvider, (_, __) {});
    return c;
  }

  setUp(() {
    root = Directory.systemTemp.createTempSync('offline_library_test');
    places = StorePlaces(
        dataDir: p.join(root.path, 'data'),
        mediaDir: p.join(root.path, 'media'));
    places.media().createSync(recursive: true);
    recordFile().writeAsStringSync(jsonEncode(recording.toJson()));
    File(p.join(places.downloads().path, 'd1')).writeAsStringSync(jsonEncode(
        Download(
                id: 'd1',
                recordingId: 'r1',
                filename: 'local.mp4',
                url: 'http://127.0.0.1:1/content',
                status: 'ready')
            .toJson()));
    File(p.join(places.mediaDir, 'local.mp4')).writeAsBytesSync([1, 2, 3]);
  });
  tearDown(() {
    container?.dispose();
    container = null;
    root.deleteSync(recursive: true);
  });

  for (final body in ['', '{', 'null', '{}']) {
    test(
        'an unreadable recording ${jsonEncode(body)} does not hide the downloaded recording',
        () async {
      File(p.join(places.recordings().path, 'broken')).writeAsStringSync(body);
      final c = createContainer();
      final list = await c.read(mediaListNotifierProvider.future);
      expect(list.map((r) => r.id), ['r1']);
      expect(list.single.hasLocalFile, isTrue);
    });
  }

  test('unchanged server recordings keep their cache mtime', () async {
    final epoch = DateTime.utc(2020);
    recordFile().setLastModifiedSync(epoch);
    final c = createContainer(serverRecordings: [recording]);
    await c.read(mediaListNotifierProvider.future);
    await c.read(mediaListNotifierProvider.notifier).refreshFromServer();
    expect(recordFile().lastModifiedSync().toUtc(), epoch);
    expect(c.read(mediaListNotifierProvider).requireValue.single.id, 'r1');
    expect(places.recordings().listSync().whereType<Directory>(), isEmpty);
  });

  test('changed and new server recordings are saved and staging is ignored',
      () async {
    final changed = RecordingInfo.fromJson(recording.toJson())
      ..title = 'Changed';
    final added = RecordingInfo(id: 'r2', title: 'New');
    final staging = Directory(p.join(places.recordings().path, '.json-write'))
      ..createSync();
    File(p.join(staging.path, 'interrupted.json')).writeAsStringSync('');
    final c = createContainer(serverRecordings: [changed, added]);
    await c.read(mediaListNotifierProvider.future);
    await c.read(mediaListNotifierProvider.notifier).refreshFromServer();
    expect(jsonDecode(recordFile().readAsStringSync())['title'], 'Changed');
    expect(
        jsonDecode(File(p.join(places.recordings().path, 'r2'))
            .readAsStringSync())['title'],
        'New');
    expect(c.read(mediaListNotifierProvider).requireValue.map((r) => r.id),
        unorderedEquals(['r1', 'r2']));
    expect(places.recordings().listSync().whereType<Directory>().length, 1);
    expect(staging.listSync().map((f) => p.basename(f.path)),
        ['interrupted.json']);
  });

  test('unchanged downloads and their recording are not rewritten', () async {
    final file = File(p.join(places.downloads().path, 'd1'));
    final download = Download.fromJson(jsonDecode(file.readAsStringSync()));
    final epoch = DateTime.utc(2020);
    file.setLastModifiedSync(epoch);
    recordFile().setLastModifiedSync(epoch);
    final c = createContainer(serverDownloads: [download]);
    c.listen(downloadsNotifierProvider('r1'), (_, __) {});
    await c.read(downloadsNotifierProvider('r1').future);
    await c.read(downloadsNotifierProvider('r1').notifier).refreshFromServer();
    expect(file.lastModifiedSync().toUtc(), epoch);
    expect(recordFile().lastModifiedSync().toUtc(), epoch);
    download.title = 'Changed download';
    await c.read(downloadsNotifierProvider('r1').notifier).refreshFromServer();
    expect(jsonDecode(file.readAsStringSync())['title'], 'Changed download');
    expect(recordFile().lastModifiedSync().toUtc(), epoch);
  });

  test('a refused connection does not fail a background list refresh',
      () async {
    final port = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    final address = 'http://127.0.0.1:${port.port}';
    await port.close();
    final c = createContainer(server: address);
    expect((await c.read(mediaListNotifierProvider.future)).single.id, 'r1');
    Object? failure;
    try {
      await c.read(mediaListNotifierProvider.notifier).refreshFromServer();
    } catch (e) {
      failure = e;
    }
    expect(c.read(mediaListNotifierProvider).hasValue, isTrue,
        reason: 'native list data is local, not the HTTP provider');
    expect(failure, isNull);
  });

  for (final mode in ['empty body', 'invalid JSON', 'cut body']) {
    test(
        'a server returning $mode keeps the local list and consumes its refresh error',
        () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() => server.close(force: true));
      server.listen((request) async {
        if (mode == 'cut body') {
          final socket =
              await request.response.detachSocket(writeHeaders: false);
          socket.write(
              'HTTP/1.1 200 OK\r\nContent-Length: 100\r\nConnection: close\r\n\r\n[');
          await socket.flush();
          socket.destroy();
        } else {
          request.response.statusCode = 200;
          request.response.write(mode == 'empty body' ? '' : '{');
          await request.response.close();
        }
      });
      final c = createContainer(server: 'http://127.0.0.1:${server.port}');
      await c.read(mediaListNotifierProvider.future);
      Object? failure;
      try {
        await c.read(mediaListNotifierProvider.notifier).refreshFromServer();
      } catch (e) {
        failure = e;
      }
      expect(c.read(mediaListNotifierProvider).requireValue.single.id, 'r1');
      expect(failure, isNull);
      expect(jsonDecode(recordFile().readAsStringSync())['id'], 'r1');
    });
  }

  for (final failure in [
    http.ClientException('Failed host lookup'),
    TimeoutException('server did not answer')
  ]) {
    test('${failure.runtimeType} leaves the list and recording details usable',
        () async {
      var requests = 0;
      final c = createContainer(
          serverFailure: failure, onServerRequest: () => requests++);
      c.listen(recordingNotifierProvider('r1'), (_, __) {});
      c.listen(downloadsNotifierProvider('r1'), (_, __) {});
      await c.read(mediaListNotifierProvider.future);
      await c.read(recordingNotifierProvider('r1').future);
      await c.read(downloadsNotifierProvider('r1').future);

      await c.read(mediaListNotifierProvider.notifier).refreshFromServer();
      await c
          .read(recordingNotifierProvider('r1').notifier)
          .refreshFromServer();
      await c
          .read(downloadsNotifierProvider('r1').notifier)
          .refreshFromServer();
      expect(requests, 3);
      expect(c.read(mediaListNotifierProvider).requireValue.single.id, 'r1');
      expect(c.read(recordingNotifierProvider('r1')).requireValue.title,
          'Downloaded recording');
      expect(
          c
              .read(downloadsNotifierProvider('r1'))
              .requireValue
              .single
              .fullPathMedia,
          p.join(places.mediaDir, 'local.mp4'));
    });
  }

  test(
      'a missing recording uses server downloads and can refresh before library sync',
      () async {
    recordFile().deleteSync();
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));
    var requests = 0;
    server.listen((request) async {
      requests++;
      expect(request.uri.path, '/api/recordings/r1/downloads');
      request.response.write(jsonEncode([
        Download(
                id: 'd1',
                recordingId: 'r1',
                filename: 'local.mp4',
                url: '/content',
                status: 'ready',
                title: 'Server download $requests')
            .toJson()
      ]));
      await request.response.close();
    });
    final c = createContainer(server: 'http://127.0.0.1:${server.port}');
    c.listen(downloadsNotifierProvider('r1'), (_, __) {});
    final downloads = await c.read(downloadsNotifierProvider('r1').future);
    expect(downloads.single.title, 'Server download 1');
    await c.read(downloadsNotifierProvider('r1').notifier).refreshFromServer();
    expect(c.read(downloadsNotifierProvider('r1')).requireValue.single.title,
        'Server download 2');
    expect(
        jsonDecode(File(p.join(places.downloads().path, 'd1'))
            .readAsStringSync())['title'],
        'Server download 2');
    expect(recordFile().existsSync(), isFalse,
        reason: 'library synchronization supplies the missing recording');
    expect(requests, 2);
  });

  test(
      'a missing recording and an unavailable server yield an empty download list',
      () async {
    recordFile().deleteSync();
    var requests = 0;
    final c = createContainer(
        serverFailure: http.ClientException('offline'),
        onServerRequest: () => requests++);
    c.listen(downloadsNotifierProvider('r1'), (_, __) {});
    expect(await c.read(downloadsNotifierProvider('r1').future), isEmpty);
    expect(requests, 1);
    expect(c.read(downloadsNotifierProvider('r1')).hasError, isFalse);
  });

  test('a missing or broken download is skipped without a network fallback',
      () async {
    final r = RecordingInfo.fromJson(recording.toJson())
      ..downloads = ['missing', 'broken', 'd1'];
    recordFile().writeAsStringSync(jsonEncode(r.toJson()));
    File(p.join(places.downloads().path, 'broken')).writeAsStringSync('');
    var requests = 0;
    final c = createContainer(onServerRequest: () => requests++);
    c.listen(downloadsNotifierProvider('r1'), (_, __) {});
    final downloads = await c.read(downloadsNotifierProvider('r1').future);
    expect(requests, 0);
    expect(
        downloads.single.fullPathMedia, p.join(places.mediaDir, 'local.mp4'));
  });

  test('a wrong-shaped server recording does not overwrite downloaded metadata',
      () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));
    var requests = 0;
    server.listen((request) async {
      requests++;
      request.response.write('{}');
      await request.response.close();
    });
    final c = createContainer(server: 'http://127.0.0.1:${server.port}');
    c.listen(recordingNotifierProvider('r1'), (_, __) {});
    await c.read(recordingNotifierProvider('r1').future);
    await c.read(recordingNotifierProvider('r1').notifier).refreshFromServer();
    expect(requests, 1);
    expect(c.read(recordingNotifierProvider('r1')).requireValue.id, 'r1');
    expect(jsonDecode(recordFile().readAsStringSync())['id'], 'r1');
  });

  test('position writes and list rebuilds never expose truncated JSON',
      () async {
    recordFile().writeAsStringSync(jsonEncode(
        (RecordingInfo.fromJson(recording.toJson())..title = 'x' * 131072)
            .toJson()));
    final c = createContainer();
    c.listen(recordingNotifierProvider('r1'), (_, __) {});
    await c.read(recordingNotifierProvider('r1').future);
    await c.read(mediaListNotifierProvider.future);
    final notifier = c.read(recordingNotifierProvider('r1').notifier);
    final failures = <Object>[];
    final writes = List.generate(
        100,
        (i) => notifier
                .putPosition(Duration(seconds: i), false)
                .catchError((Object e) {
              failures.add(e);
            }));
    for (var i = 0; i < 100; i++) {
      c.invalidate(mediaListNotifierProvider);
      try {
        expect(
            (await c.read(mediaListNotifierProvider.future)).single.id, 'r1');
      } catch (e) {
        failures.add(e);
      }
      await Future<void>.delayed(Duration.zero);
    }
    await Future.wait(writes);
    expect(failures, isEmpty);
    expect(jsonDecode(recordFile().readAsStringSync())['position'], 99);
  });
}
