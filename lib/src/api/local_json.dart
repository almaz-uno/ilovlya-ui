import 'dart:async';
import 'dart:convert';
import 'dart:io';

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

Future<void> _replace(File file, Map<String, dynamic> json) async {
  // A directory beside the target keeps rename on the same filesystem, and
  // prevents cache scans from mistaking a pending JSON file for a recording.
  final staging = await file.parent.createTemp('.json-write-');
  try {
    final temporary = File(p.join(staging.path, 'entry.json'));
    await temporary.writeAsString(jsonEncode(json), flush: true);
    await temporary.rename(file.path);
  } finally {
    await staging.delete(recursive: true);
  }
}

Future<void> writeLocalJson(File file, Map<String, dynamic> json) =>
    _serialize(file, () => _replace(file, json));

Future<void> updateLocalJson(File file,
        Map<String, dynamic> Function(Map<String, dynamic>) update) =>
    _serialize(file, () async {
      final current =
          jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      await _replace(file, update(current));
    });
