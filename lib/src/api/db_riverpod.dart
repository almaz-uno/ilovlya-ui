import 'package:idb_shim/idb.dart';
import 'package:idb_shim/idb_browser.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'db_riverpod.g.dart';

const _dbName = "media.db";

@riverpod
Future<Database> db(DbRef ref, String storeName) async {

  return getIdbFactory()!.open(_dbName, version: 1, onUpgradeNeeded: (VersionChangeEvent event) {
    var db = event.database;
    db.createObjectStore(storeName, autoIncrement: true);
    ref.onDispose(() => db.close());
  });
}
