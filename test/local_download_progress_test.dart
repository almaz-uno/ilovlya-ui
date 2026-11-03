import 'dart:typed_data';

import 'package:background_downloader/background_downloader.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:ilovlya/src/api/downloads_riverpod.dart';
import 'package:ilovlya/src/api/local_download_task_riverpod.dart';
import 'package:ilovlya/src/api/recording_riverpod.dart';
import 'package:ilovlya/src/api/thumbnail_riverpod.dart';
import 'package:ilovlya/src/localization/app_localizations.dart';
import 'package:ilovlya/src/media/local_download_progress.dart';
import 'package:ilovlya/src/media/media_details.dart';
import 'package:ilovlya/src/model/download.dart';
import 'package:ilovlya/src/model/local_download.dart';
import 'package:ilovlya/src/model/recording_info.dart';
import 'package:ilovlya/src/model/settings.dart';
import 'package:ilovlya/src/playback_download/partial_source.dart';
import 'package:ilovlya/src/playback_download/playback_downloads.dart';
import 'package:ilovlya/src/settings/settings_provider.dart';
import 'package:ilovlya/src/utils/provider_retry.dart';

const _file = '4qrF5baTRiBHMRbvTtb4pv-m3u8-391-1.mp4';

LocalDownloadTask _task({TaskStatus status = TaskStatus.running, double? progress = 0.63, double? speed = 11.857, Duration? eta = const Duration(seconds: 11)}) =>
    LocalDownloadTask(id: 'd1', displayName: 'Jazz recording', filename: _file, status: status, progress: progress, networkSpeed: speed, timeRemaining: eta);

Widget _app(Widget child, {Locale locale = const Locale('en'), List<Override> overrides = const []}) => ProviderScope(
      retry: disableProviderRetry,
      overrides: overrides,
      child: MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: child),
      ),
    );

/// The lines of the block, as they read top to bottom.
List<String> _lines(WidgetTester tester) => [
      for (final t in tester.widgetList<Text>(find.descendant(of: find.byType(LocalDownloadProgress), matching: find.byType(Text)))) t.data!,
    ];

class _PlaybackDownloads extends PlaybackDownloads {
  @override
  Map<String, SourceState> build() => {};

  @override
  Duration? notAnsweringFor(String downloadId) => downloadId == 'd1' ? const Duration(seconds: 42) : null;
}

class _Settings extends SettingsNotifier {
  @override
  Future<Settings> build() async => Settings();
}

class _LocalDT extends LocalDTNotifier {
  @override
  Map<String, LocalDownloadTask> build() => {'d1': _task()};
}

class _Recording extends RecordingNotifier {
  @override
  Future<RecordingInfo> build(String recordingId) async => RecordingInfo(id: 'one', title: 'Jazz recording', thumbnailUrl: 'thumb:one');

  @override
  Future<void> refreshFromServer() async {}
}

class _Downloads extends DownloadsNotifier {
  @override
  Future<List<Download>> build(String recordingId) async => [Download(id: 'd1', recordingId: 'one', filename: _file, status: 'ready')];

  @override
  Future<void> refreshFromServer() async {}
}

class _Thumbnail extends ThumbnailDataNotifier {
  @override
  Future<Uint8List> build(String thumbnailUrl) async => Uint8List(0);
}

void main() {
  group('the line of figures', () {
    testWidgets('all parts known: the percentage first, then the speed and the time remaining', (tester) async {
      await tester.pumpWidget(_app(LocalDownloadProgress(task: _task())));
      expect(_lines(tester), ['Local download running:', _file, '63% · ≈ 11.86 MB/s · ETA 00:11']);
      expect(tester.widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator)).value, 0.63);
    });

    testWidgets('no speed yet: the speed is left out with its separator', (tester) async {
      await tester.pumpWidget(_app(LocalDownloadProgress(task: _task(speed: null, eta: null))));
      expect(_lines(tester).last, '63%');
      await tester.pumpWidget(_app(LocalDownloadProgress(task: _task(speed: -1))));
      expect(_lines(tester).last, '63% · ETA 00:11', reason: 'a negative speed is not known either');
    });

    testWidgets('no percentage: the line starts with the speed, and the bar runs without a value', (tester) async {
      await tester.pumpWidget(_app(LocalDownloadProgress(task: _task(progress: null))));
      expect(_lines(tester).last, '≈ 11.86 MB/s · ETA 00:11');
      expect(tester.widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator)).value, isNull);
      await tester.pumpWidget(_app(LocalDownloadProgress(task: _task(progress: null, speed: null, eta: null))));
      expect(_lines(tester), ['Local download running:', _file], reason: 'nothing known: no line of figures at all');
    });

    testWidgets('waiting to retry: the time the server has not answered, in place of the speed and the time remaining', (tester) async {
      await tester.pumpWidget(_app(LocalDownloadProgress(task: _task(status: TaskStatus.waitingToRetry), notAnsweringFor: const Duration(seconds: 42))));
      expect(_lines(tester).last, '63% · no answer from the server for 00:42');
    });

    testWidgets('in Russian', (tester) async {
      await tester.pumpWidget(_app(LocalDownloadProgress(task: _task()), locale: const Locale('ru')));
      expect(_lines(tester)[1], _file);
      expect(_lines(tester).last, '63% · ≈ 11.86 MB/s · ETA 00:11');
      await tester.pumpWidget(_app(LocalDownloadProgress(task: _task(status: TaskStatus.waitingToRetry), notAnsweringFor: const Duration(seconds: 42)), locale: const Locale('ru')));
      expect(_lines(tester).last, '63% · сервер не отвечает уже 00:42');
    });
  });

  group('the screens', () {
    testWidgets('the player: a playback download waiting to retry tells how long its server has not answered', (tester) async {
      final overrides = [playbackDownloadsProvider.overrideWith(_PlaybackDownloads.new)];
      await tester.pumpWidget(_app(PlayerDownloadProgress(task: _task(status: TaskStatus.waitingToRetry), downloadId: 'd1', playbackDownload: true), overrides: overrides));
      expect(_lines(tester).last, '63% · no answer from the server for 00:42');

      await tester.pumpWidget(_app(PlayerDownloadProgress(task: _task(status: TaskStatus.waitingToRetry), downloadId: 'd1', playbackDownload: false), overrides: overrides));
      expect(_lines(tester).last, '63% · ≈ 11.86 MB/s · ETA 00:11', reason: 'a download of the background downloader shows its own figures');
    });

    testWidgets("the recording's screen shows a local download as the player does", (tester) async {
      await tester.pumpWidget(ProviderScope(
        retry: disableProviderRetry,
        overrides: [
          settingsProvider.overrideWith(_Settings.new),
          localDTProvider.overrideWith(_LocalDT.new),
          recordingProvider('one').overrideWith(_Recording.new),
          downloadsProvider('one').overrideWith(_Downloads.new),
          thumbnailDataProvider('thumb:one').overrideWith(_Thumbnail.new),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const MediaDetailsView(id: 'one'),
        ),
      ));
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(find.byType(LocalDownloadProgress), findsOneWidget);
      expect(_lines(tester), ['Local download running:', _file, '63% · ≈ 11.86 MB/s · ETA 00:11']);
      expect(find.textContaining('Mb/s'), findsNothing);
      await tester.pumpWidget(const SizedBox());
    });
  });
}
