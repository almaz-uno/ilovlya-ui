import 'dart:io';

import 'package:idb_shim/idb.dart';
import 'package:idb_shim/idb_browser.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:universal_platform/universal_platform.dart';
part 'directories_riverpod.g.dart';

const _dbName = "media.db";
const _desktopDir = "ilovlya";

class StorePlaces {
  final Directory _dataDir;
  final Directory _mediaDir;

  Directory recordings() {
    return Directory(p.join(_dataDir.path, "recordings"))..createSync(recursive: true);
  }

  Directory downloads() {
    return Directory(p.join(_dataDir.path, "downloads"))..createSync(recursive: true);
  }

  Directory media() {
    return _mediaDir;
  }

  Directory data() {
    return _dataDir;
  }

  StorePlaces(
    Directory documentsDir,
  )   : _dataDir = Directory(p.join(documentsDir.path, "data")),
        _mediaDir = Directory(p.join(documentsDir.path, "media")) {
    _dataDir.createSync(recursive: true);
    _mediaDir.createSync(recursive: true);
  }
}

@riverpod
Future<Database> db(DbRef ref, String storeName) async {
  return getIdbFactory()!.open(_dbName, version: 1, onUpgradeNeeded: (VersionChangeEvent event) {
    var db = event.database;
    db.createObjectStore(storeName, autoIncrement: true);
    ref.onDispose(() => db.close());
  });
}

@riverpod
Future<StorePlaces> storePlaces(StorePlacesRef ref) async {
  final dd = await getApplicationDocumentsDirectory();
  if (UniversalPlatform.isDesktop) {
    return StorePlaces(Directory(p.join(dd.path, _desktopDir)));
  }
  return StorePlaces(dd);
}

// the root directory
// @riverpod
// Future<Directory> documentsDir(DocumentsDirRef ref) async {
//   var dd = await getApplicationDocumentsDirectory();
//   if (UniversalPlatform.isDesktop) {
//     return Directory(p.join(dd.path, _desktopDir)).create(recursive: true);
//   }
//   return dd.create(recursive: true);
// }

// @riverpod
// Future<Directory> dataDir(DataDirRef ref) async {
//   final docDir = await ref.watch(documentsDirProvider.future);
//   return Directory(p.join(docDir.path, _dataDir)).create(recursive: true);
// }

// @riverpod
// Future<Directory> mediaDir(MediaDirRef ref) async {
//   final docDir = await ref.watch(documentsDirProvider.future);
//   return Directory(p.join(docDir.path, _mediaDir)).create(recursive: true);
// }
