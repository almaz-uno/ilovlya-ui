import 'dart:io';

import 'package:flutter/material.dart';
import 'package:ilovlya/src/api/directories_riverpod.dart';
import 'package:ilovlya/src/api/downloads_riverpod.dart';
import 'package:ilovlya/src/api/media_list_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:universal_platform/universal_platform.dart';

part 'housekeeper_riverpod.g.dart';

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
    sp.media().create(recursive: true);
    ref.invalidateSelf();
    return Future.value((number, size));
  }

  Future<(int, int)> cleanStale() async {
    final recordings = await ref.watch(mediaListNotifierProvider.notifier).allFromDisk();

    int number = 0, size = 0;
    for (final recording in recordings) {
      if (recording.seenAt == null && recording.hiddenAt == null) continue;
      for (final download in await ref.read(downloadsNotifierProvider(recording.id).future)) {
        if (download.fullPathMedia != null) {
          final f = File(download.fullPathMedia!);
          if (f.existsSync()) {
            number++;
            size += f.lengthSync();
            f.deleteSync();
          }
        }
      }
    }
    ref.invalidateSelf();
    return Future.value((number, size));
  }
}

@riverpod
class LocalDataNotifier extends _$LocalDataNotifier {
  @override
  (int number, int size) build() {
    if (!UniversalPlatform.isWeb) {
      return (0, 0);
    }
    return _evaluate();
  }

  (int number, int size) _evaluate() {
    return (0, 0);
  }
}
