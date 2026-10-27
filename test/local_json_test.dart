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
    expect(root.listSync().whereType<File>().map((e) => p.basename(e.path)),
        ['r1']);
    expect(Directory(p.join(root.path, '.json-write')).listSync(), isEmpty);
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
    expect(root.listSync().whereType<File>().length, 1);
    expect(Directory(p.join(root.path, '.json-write')).listSync(), isEmpty);
  });
  for (final flush in [true, false]) {
    test('an unchanged JSON entry is not replaced (flush=$flush)', () async {
      final epoch = DateTime.utc(2020);
      file.setLastModifiedSync(epoch);
      await writeLocalJson(
          file,
          {
            'position': 0,
            'downloads': ['d1']
          },
          flush: flush);
      expect(file.lastModifiedSync().toUtc(), epoch);
      expect(root.listSync().length, 1,
          reason: 'no staging directory is needed');
    });
  }

  test('comparison and bulk replacements share the position update queue',
      () async {
    await Future.wait([
      writeLocalJson(
          file,
          {
            'position': 1,
            'downloads': ['d2']
          },
          flush: false),
      writeLocalJson(
          file,
          {
            'position': 0,
            'downloads': ['d1']
          },
          flush: false),
      updateLocalJson(file, (json) => json..['position'] = 21),
    ]);
    expect(jsonDecode(file.readAsStringSync()), {
      'position': 21,
      'downloads': ['d1']
    });
    expect(Directory(p.join(root.path, '.json-write')).listSync(), isEmpty);
  });

  test('invalid UTF-8 in the cache is replaced by valid server JSON', () async {
    file.writeAsBytesSync([255]);
    await writeLocalJson(file, {'position': 21}, flush: false);
    expect(jsonDecode(file.readAsStringSync()), {'position': 21});
  });

  test('a killed writer leaves the committed JSON intact', () async {
    final sdk = Platform.environment['FLUTTER_ROOT'];
    final dart = sdk == null
        ? 'dart'
        : p.join(sdk, 'bin', 'cache', 'dart-sdk', 'bin', 'dart');
    // Linux kills this child with SIGXFSZ while its staging write exceeds 8 KiB.
    // The target must still contain the old complete JSON, even without fsync.
    final result = await Process.run('bash', [
      '-c',
      r'ulimit -c 0; ulimit -f 8; exec "$@"',
      '--',
      dart,
      '--packages=${p.absolute('.dart_tool/package_config.json')}',
      p.absolute('test/fixtures/interrupted_json_write.dart'),
      file.path,
    ]);
    expect(result.exitCode, isNot(0), reason: result.stderr.toString());
    expect(jsonDecode(file.readAsStringSync()), {
      'position': 0,
      'downloads': ['d1']
    });
    final partial = Directory(p.join(root.path, '.json-write'))
        .listSync()
        .whereType<File>()
        .single;
    expect(partial.lengthSync(), greaterThan(0));
    expect(partial.lengthSync(), lessThan(65536));
    await writeLocalJson(file, {'position': 21}, flush: false);
    expect(jsonDecode(file.readAsStringSync()), {'position': 21});
  }, skip: !Platform.isLinux);
}
