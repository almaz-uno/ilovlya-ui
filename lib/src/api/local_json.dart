import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:path/path.dart' as p;

// Serialize updates of one cache entry, including read-modify-write operations.
// A failed write must not poison subsequent updates of the same file.
final _writes = <String, Future<void>>{};

Future<void> _serialize(File file, Future<void> Function() operation) {
  final key = p.normalize(p.absolute(file.path));
  final result =
      (_writes[key] ?? Future<void>.value()).then((_) => operation());
  final tail = result.then<void>((_) {}, onError: (Object _, StackTrace __) {});
  _writes[key] = tail;
  unawaited(tail.then((_) {
    if (identical(_writes[key], tail)) _writes.remove(key);
  }));
  return result;
}

bool _sameBytes(List<int> left, List<int> right) {
  if (left.length != right.length) return false;
  for (var i = 0; i < left.length; i++) {
    if (left[i] != right[i]) return false;
  }
  return true;
}

final _random = Random.secure();

Future<void> _replace(File file, Map<String, dynamic> json,
    {required bool flush}) async {
  final encoded = utf8.encode(jsonEncode(json));
  try {
    if (_sameBytes(await file.readAsBytes(), encoded)) return;
  } on PathNotFoundException {
    // First server refresh of this entry.
  }

  // A single directory beside the targets keeps rename on the same filesystem
  // and lets library scans ignore unfinished writes. Random names also isolate
  // concurrent writers in different processes or isolates.
  final staging = Directory(p.join(file.parent.path, '.json-write'));
  await staging.create();
  final name = List.generate(
          4, (_) => _random.nextInt(1 << 32).toRadixString(16).padLeft(8, '0'))
      .join();
  final temporary = File(p.join(staging.path, '$name.json'));
  try {
    await temporary.writeAsBytes(encoded, flush: flush);
    await temporary.rename(file.path);
  } finally {
    if (temporary.existsSync()) await temporary.delete();
  }
}

// Server cache entries can be fetched again after power loss; playback progress
// retains the flush default. Comparison runs inside the per-file queue.
Future<void> writeLocalJson(File file, Map<String, dynamic> json,
        {bool flush = true}) =>
    _serialize(file, () => _replace(file, json, flush: flush));

Future<void> updateLocalJson(
        File file, Map<String, dynamic> Function(Map<String, dynamic>) update,
        {bool flush = true}) =>
    _serialize(file, () async {
      final current =
          jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      await _replace(file, update(current), flush: flush);
    });
