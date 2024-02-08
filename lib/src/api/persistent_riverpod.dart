import 'dart:io';

import 'package:idb_shim/idb.dart';
import 'package:idb_shim/idb_browser.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
part 'persistent_riverpod.g.dart';

const _dbName = "media.db";
const _recordingsDir = "recordings";
const _mediaDir = "media";

@riverpod
Future<Database> db(DbRef ref, String storeName) async {
  return getIdbFactory()!.open(_dbName, version: 1, onUpgradeNeeded: (VersionChangeEvent event) {
    var db = event.database;
    db.createObjectStore(storeName, autoIncrement: true);
    ref.onDispose(() => db.close());
  });
}

// the root directory
@riverpod
Future<Directory> documentsDir(DocumentsDirRef ref) async {
  return getApplicationDocumentsDirectory();
}

@riverpod
Future<Directory> recordingsDir(RecordingsDirRef ref) async {
  final docDir = await ref.watch(documentsDirProvider.future);
  return Directory(path.join(docDir.path, _recordingsDir))..create(recursive: true);
}

@riverpod
Future<Directory> mediaDir(MediaDirRef ref) async {
  final docDir = await ref.watch(documentsDirProvider.future);
  return Directory(path.join(docDir.path, _mediaDir))..create(recursive: true);
}

