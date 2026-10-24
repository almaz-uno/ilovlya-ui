import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ilovlya/src/api/local_json.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory root;
  late File file;
  setUp(() {
    root = Directory.systemTemp.createTempSync('atomic_json_test');
    file = File(p.join(root.path, 'r1'))
      ..writeAsStringSync('{"position":0,"downloads":["d1"]}');
  });
  tearDown(() => root.deleteSync(recursive: true));

  test('queued read-modify-write operations preserve other fields and ordering',
      () async {
    await Future.wait(List.generate(
        40,
        (_) => updateLocalJson(file, (value) {
              value['position'] = (value['position'] as int) + 1;
              return value;
            })));
    expect(jsonDecode(file.readAsStringSync()), {
      'position': 40,
      'downloads': ['d1']
    });
    expect(root.listSync().map((e) => p.basename(e.path)), ['r1']);
  });

  test(
      'an interrupted replacement keeps the old JSON and does not poison the queue',
      () async {
    await expectLater(writeLocalJson(file, {'bad': Object()}),
        throwsA(isA<JsonUnsupportedObjectError>()));
    expect(jsonDecode(file.readAsStringSync()), {
      'position': 0,
      'downloads': ['d1']
    });
    expect(root.listSync().length, 1,
        reason: 'failed staging files must be removed');
    await writeLocalJson(file, {'position': 21});
    expect(jsonDecode(file.readAsStringSync()), {'position': 21});
    expect(root.listSync().length, 1);
  });
}
