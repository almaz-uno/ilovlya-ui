import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:ilovlya/src/playback_download/iso_bmff.dart';

import 'upstream.dart';

Uint8List box(String type, int size, [List<int> rest = const []]) =>
    Uint8List.fromList([size >> 24 & 0xff, size >> 16 & 0xff, size >> 8 & 0xff, size & 0xff, ...latin1.encode(type), ...rest]);

final ftyp = box('ftyp', 16, latin1.encode('M4A \x00\x00\x02\x00'));

void main() {
  test('an index after mdat is found from the first bytes', () {
    final file = m4aWithTrailingMoov(mdat: 1000, moov: 300);
    final probe = probeMoov(Uint8List.sublistView(file, 0, 64), file.length);
    expect(probe, isA<MoovTrailing>().having((p) => p.at, 'at', file.length - 300));
  });

  test('an index before mdat, a file that is no MP4, and an mdat to the end are not trailing', () {
    final faststart = Uint8List.fromList([...ftyp, ...box('moov', 8), ...box('mdat', 1008)]);
    expect(probeMoov(faststart, 2000), isA<MoovNotTrailing>());
    expect(probeMoov(randomBytes(64), 2000), isA<MoovNotTrailing>());
    expect(probeMoov(Uint8List.fromList([...ftyp, ...box('mdat', 0)]), 2000), isA<MoovNotTrailing>());
    expect(probeMoov(Uint8List.fromList([...ftyp, ...box('mdat', 2000 - 16)]), 2000), isA<MoovNotTrailing>(),
        reason: 'mdat runs to the end of the file');
  });

  test('a head too short asks for more, past the boxes before mdat', () {
    expect(probeMoov(Uint8List.sublistView(ftyp, 0, 4), 2000), isA<MoovNeedsMore>().having((p) => p.bytes, 'bytes', 16));
    final withFree = Uint8List.fromList([...ftyp, ...box('free', 40)]);
    expect(probeMoov(withFree, 2000), isA<MoovNeedsMore>().having((p) => p.bytes, 'bytes', 16 + 40 + 16));
  });

  test('a 64-bit mdat size is read', () {
    const big = 5 << 30;
    final size = ByteData(8)..setUint64(0, big);
    final head = Uint8List.fromList([...ftyp, ...box('mdat', 1, size.buffer.asUint8List())]);
    expect(probeMoov(head, big + 16 + 1000), isA<MoovTrailing>().having((p) => p.at, 'at', 16 + big));
  });
}
