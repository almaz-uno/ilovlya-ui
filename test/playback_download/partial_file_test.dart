import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:ilovlya/src/playback_download/partial_file.dart';
import 'package:path/path.dart' as p;

const _url = 'https://example.invalid/api/recordings/downloads/d1/content/f.mp4';

void main() {
  late Directory media;

  setUp(() => media = Directory.systemTemp.createTempSync('partial_file_test'));
  tearDown(() => media.deleteSync(recursive: true));

  PartialFile open({String url = _url}) => PartialFile.open(mediaDir: media.path, downloadId: 'd1', filename: 'f.mp4', url: url);

  Uint8List source(int n, [int seed = 1]) {
    final rnd = Random(seed);
    return Uint8List.fromList(List.generate(n, (_) => rnd.nextInt(256)));
  }

  // The plan rests on this: FileMode.append must open read-write *without* O_APPEND, so that a write goes where
  // setPosition put it. If this fails, the storage design is revisited before anything is built on it.
  test('FileMode.append writes at the position it is given, not at the end', () async {
    final f = File(p.join(media.path, 'probe'));
    var raf = await f.open(mode: FileMode.append);
    await raf.setPosition(100);
    await raf.writeFrom([1, 2, 3]);
    await raf.setPosition(0);
    await raf.writeFrom([9]);
    await raf.close();
    raf = await f.open(mode: FileMode.append);
    await raf.setPosition(101);
    await raf.writeFrom([7]);
    await raf.close();
    final bytes = f.readAsBytesSync();
    expect(bytes.length, 103);
    expect(bytes[0], 9);
    expect(bytes.sublist(100), [1, 7, 3]);
  });

  test('writes at random offsets read back intact, and completion leaves one final file', () async {
    final src = source(1 << 20);
    final pf = open()..setLength(src.length, 'Tue, 22 Sep 2026 18:11:30 GMT');
    final chunks = [for (var o = 0; o < src.length; o += 65536) o]..shuffle(Random(7));
    for (final o in chunks) {
      await pf.write(o, src.sublist(o, min(o + 65536, src.length)));
      final back = await pf.read(o, 65536);
      expect(back, src.sublist(o, min(o + 65536, src.length)));
    }
    expect(pf.isComplete, isTrue);

    final path = await pf.complete();
    expect(path, p.join(media.path, 'f.mp4'));
    expect(File(path).readAsBytesSync(), src);
    expect(Directory(p.join(media.path, PartialFile.partialDirName)).listSync(), isEmpty);
    expect(await pf.read(12345, 10), src.sublist(12345, 12355), reason: 'reads continue after the rename');
    expect(() => pf.write(0, [1]), throwsStateError);
  });

  test('a read stops where the stored interval ends', () async {
    final pf = open()..setLength(100, null);
    await pf.write(10, List.filled(20, 5));
    expect((await pf.read(10, 50)).length, 20);
    expect(await pf.read(0, 10), isEmpty);
    expect(await pf.read(30, 10), isEmpty);
  });

  test('after a crash only checkpointed bytes are believed stored', () async {
    final src = source(300000);
    final pf = open()..setLength(src.length, 'lm');
    await pf.write(0, src.sublist(0, 100000));
    await pf.checkpoint();
    await pf.write(200000, src.sublist(200000, 250000)); // never checkpointed

    final again = open(); // the first one is abandoned without close(), as a killed process would
    expect(again.ranges.intervals, [(0, 100000)]);
    expect(again.length, src.length);
    expect(again.lastModified, 'lm');
    expect(await again.read(0, 100000), src.sublist(0, 100000));
  });

  test('a record replaced half-way — temporary file written, not renamed — leaves the previous record in force', () async {
    final pf = open()..setLength(1000, null);
    await pf.write(0, List.filled(400, 1));
    await pf.checkpoint();
    File('${pf.statePath}.tmp').writeAsStringSync('{"version": 1, "ranges": [[0, 10');

    final again = open();
    expect(again.ranges.intervals, [(0, 400)]);
    expect(File('${pf.statePath}.tmp').existsSync(), isFalse);
  });

  test('a record that does not fit is discarded and the download starts from nothing', () async {
    final pf = open()..setLength(1000, null);
    await pf.write(0, List.filled(400, 1));
    await pf.close();

    expect(open(url: '$_url?other').ranges.isEmpty, isTrue, reason: 'another URL');

    final pf2 = open()..setLength(1000, null);
    await pf2.write(0, List.filled(400, 1));
    await pf2.close();
    File(pf2.dataPath).writeAsBytesSync([1, 2, 3]); // shorter than the record says
    final shrunk = open();
    expect(shrunk.ranges.isEmpty, isTrue);
    expect(shrunk.length, isNull);
    expect(File(shrunk.statePath).existsSync(), isFalse);

    final pf3 = open()..setLength(1000, null);
    await pf3.write(0, List.filled(400, 1));
    await pf3.close();
    final state = jsonDecode(File(pf3.statePath).readAsStringSync()) as Map<String, dynamic>;
    File(pf3.statePath).writeAsStringSync(jsonEncode({...state, 'version': 99}));
    expect(open().ranges.isEmpty, isTrue, reason: 'another version');

    File(pf3.statePath).writeAsStringSync('not json');
    expect(open().ranges.isEmpty, isTrue, reason: 'unparseable');
  });

  test('close keeps the download resumable; discard removes it', () async {
    final pf = open()..setLength(1000, null);
    await pf.write(0, List.filled(100, 1));
    await pf.close();
    expect(open().ranges.intervals, [(0, 100)]);

    final pf2 = open();
    await pf2.discard();
    expect(File(pf2.dataPath).existsSync(), isFalse);
    expect(File(pf2.statePath).existsSync(), isFalse);
    expect(open().ranges.isEmpty, isTrue);
  });

  test('refuses what would break its invariants', () async {
    final pf = open()..setLength(100, null);
    expect(() => pf.write(90, List.filled(20, 0)), throwsRangeError);
    expect(() => pf.setLength(200, null), throwsStateError);
    expect(pf.complete, throwsStateError);
  });

  test('a checkpoint is due after 8 MiB of new data', () async {
    final pf = open()..setLength(PartialFile.checkpointBytes + 1, null);
    expect(pf.checkpointDue, isFalse);
    await pf.write(0, Uint8List(PartialFile.checkpointBytes - 1));
    expect(pf.checkpointDue, isFalse);
    await pf.write(PartialFile.checkpointBytes - 1, [0]);
    expect(pf.checkpointDue, isTrue);
    await pf.checkpoint();
    expect(pf.checkpointDue, isFalse);
  });
}
