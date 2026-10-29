import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:ilovlya/src/api/api_riverpod.dart';
import 'package:ilovlya/src/api/directories_riverpod.dart';
import 'package:ilovlya/src/api/media_list_riverpod.dart';
import 'package:ilovlya/src/model/recording_info.dart';
import 'package:ilovlya/src/model/settings.dart';
import 'package:ilovlya/src/settings/settings_provider.dart';
import 'package:path/path.dart' as p;

class BenchmarkSettings extends SettingsNotifier {
  BenchmarkSettings(this.settings);
  final Settings settings;
  @override
  Future<Settings> build() async => settings;
}

Future<void> runCacheRefreshBenchmark() async {
  final parent = Directory(
      Platform.environment['ILOVLYA_CACHE_BENCHMARK_ROOT'] ??
          Directory.systemTemp.path);
  final root = parent.createTempSync('ilovlya-cache-benchmark-');
  final places = StorePlaces(
      dataDir: p.join(root.path, 'data'), mediaDir: p.join(root.path, 'media'));
  places.media().createSync();
  final entries = List.generate(
      3000,
      (i) => RecordingInfo(
          id: 'r$i', title: 'Recording $i ${'x' * 128}', duration: 120));
  final files = [
    for (final entry in entries)
      File(p.join(places.recordings().path, entry.id))
  ];
  final epoch = DateTime.utc(2020);
  final container = ProviderContainer(retry: (_, _) => null, overrides: [
    storePlacesProvider.overrideWith((ref) async => places),
    settingsProvider.overrideWith(() => BenchmarkSettings(Settings(
        dataStorageDirectory: places.dataDir,
        mediaStorageDirectory: places.mediaDir))),
    listRecordingsProvider(0, MediaListNotifier.limit)
        .overrideWith((ref) async => entries),
  ]);
  container.listen(mediaListProvider, (_, _) {});
  try {
    void seed() {
      for (var i = 0; i < files.length; i++) {
        entries[i].title = 'Recording $i ${'x' * 128}';
        files[i].writeAsStringSync(jsonEncode(entries[i].toJson()));
        files[i].setLastModifiedSync(epoch);
      }
    }

    seed();
    await container.read(mediaListProvider.future);
    final notifier = container.read(mediaListProvider.notifier);
    await notifier.refreshFromServer(); // Warm up outside the measured runs.
    for (final changed in [0, 30, 3000]) {
      final times = <double>[];
      final rewrites = <int>[];
      for (var run = 0; run < 3; run++) {
        seed();
        for (var i = 0; i < changed; i++) {
          entries[i].title = 'Changed $run $i';
        }
        final timer = Stopwatch()..start();
        await notifier.refreshFromServer();
        timer.stop();
        if (container.read(mediaListProvider).requireValue.length !=
            3000) {
          throw StateError('Refresh did not retain all recordings');
        }
        times.add(timer.elapsedMicroseconds / 1000);
        rewrites.add(
            files.where((f) => f.lastModifiedSync().toUtc() != epoch).length);
        for (var i = 0; i < changed; i++) {
          if (jsonDecode(files[i].readAsStringSync())['title'] !=
              entries[i].title) {
            throw StateError('Changed recording was not saved');
          }
        }
      }
      final sorted = [...times]..sort();
      // Includes provider refresh, comparison/writes, disk reload and sorting.
      debugPrintSynchronously('CACHE_BENCH ${jsonEncode({
            'entries': 3000,
            'changed': changed,
            'milliseconds': times,
            'median_ms': sorted[1],
            'rewrites': rewrites
          })}');
    }
  } finally {
    container.dispose();
    root.deleteSync(recursive: true);
  }
}
