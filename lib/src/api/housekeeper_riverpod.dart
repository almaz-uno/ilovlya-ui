import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:universal_platform/universal_platform.dart';

import '../model/recording_info.dart';
import 'directories_riverpod.dart';
import 'media_list_riverpod.dart';
import 'recording_riverpod.dart';

part 'housekeeper_riverpod.g.dart';

// Drives the housekeeping of local downloaded media files.
@riverpod
class LocalMediaHousekeeper extends _$LocalMediaHousekeeper {
  @override
  Future<(int number, int size)> build() {
    if (UniversalPlatform.isWeb) {
      return Future.value((0, 0));
    }
    return _evaluate();
  }

  Future<(int number, int size)> _evaluate() async {
    var number = 0, size = 0;
    final sp = await ref.watch(storePlacesProvider.future);

    for (final entity in sp.media().listSync(recursive: true)) {
      debugPrint(entity.path);
      if (entity is! File) continue;
      number++;
      size += entity.lengthSync();
    }

    return Future.value((number, size));
  }

  Future<(int, int)> cleanAll() async {
    final sp = await ref.watch(storePlacesProvider.future);
    final (number, size) = state.value!;
    sp.media().deleteSync(recursive: true);
    sp.media().createSync(recursive: true);
    ref.invalidateSelf();
    return Future.value((number, size));
  }

  Future<(int, int)> cleanStale() async {
    final sp = await ref.watch(storePlacesProvider.future);

    int number = 0, size = 0;
    for (final e in sp.media().listSync()) {
      switch (e) {
        case File f:
          final bn = p.basename(f.path);
          final pos = bn.indexOf('-');
          if (pos < 0) continue;
          final id = bn.substring(0, pos);
          await ref.read(recordingNotifierProvider(id).future).then((RecordingInfo ri) {
            if (ri.seenAt != null || ri.hiddenAt != null) {
              number++;
              size += f.lengthSync();
              f.deleteSync();
            }
          });
      }
    }
    ref.invalidateSelf();
    return Future.value((number, size));
  }

}

// Drives local data housekeeping
// Returns number of local recordings
@riverpod
class LocalDataNotifier extends _$LocalDataNotifier {
  @override
  Future<int> build() {
    if (UniversalPlatform.isWeb) {
      return Future.value(0);
    }
    return _evaluate();
  }

  Future<int> _evaluate() async {
    final sp = await ref.watch(storePlacesProvider.future);
    int number = 0;

    for (final entity in sp.recordings().listSync(recursive: false)) {
      if (entity is! File) continue;
      number++;
    }

    return number;
  }

  Future<int> cleanMetadata() async {
    final sp = await ref.watch(storePlacesProvider.future);
    final number = state.value!;
    sp.data().deleteSync(recursive: true);
    sp.recordings().createSync(recursive: true);
    sp.thumbnails().createSync(recursive: true);
    sp.downloads().createSync(recursive: true);
    ref.invalidateSelf();
    ref.read(mediaListNotifierProvider.notifier).refreshFromServer();
    return Future.value(number);
  }
}
