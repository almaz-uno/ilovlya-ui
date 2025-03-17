import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../settings/settings_provider.dart';

part 'directories_riverpod.g.dart';

class StorePlaces {
  final String dataDir;
  final String mediaDir;

  Directory recordings() {
    return Directory(p.join(dataDir, "recordings"));
  }

  Directory downloads() {
    return Directory(p.join(dataDir, "downloads"));
  }

  Directory thumbnails() {
    return Directory(p.join(dataDir, "thumbnails"));
  }

  Directory media() {
    return Directory(mediaDir);
  }

  Directory data() {
    return Directory(dataDir);
  }

  StorePlaces({
    required this.dataDir,
    required this.mediaDir,
  }) {
    recordings().createSync(recursive: true);
    downloads().createSync(recursive: true);
    thumbnails().createSync(recursive: true);
  }
}

@riverpod
Future<StorePlaces> storePlaces(Ref ref) async {
  final dataDir = ref.watch(settingsNotifierProvider.select((value) => value.requireValue.dataStorageDirectory));
  final mediaDir = ref.watch(settingsNotifierProvider.select((value) => value.requireValue.mediaStorageDirectory));

  return StorePlaces(dataDir: dataDir, mediaDir: mediaDir);
}
