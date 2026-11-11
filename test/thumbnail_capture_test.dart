import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:ilovlya/src/media/thumbnail_capture.dart';

/// A BGRA frame filled with one colour, each row padded to [stride] with 0xFF.
Uint8List _bgra(int width, int height, {int? stride, int b = 10, int g = 20, int r = 30}) {
  final s = stride ?? width * 4;
  final bytes = Uint8List(s * height)..fillRange(0, s * height, 0xFF);
  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      final i = y * s + x * 4;
      bytes[i] = b;
      bytes[i + 1] = g;
      bytes[i + 2] = r;
      bytes[i + 3] = 0;
    }
  }
  return bytes;
}

void main() {
  group('the raw frame', () {
    test('takes the stride from the length of the bytes', () {
      final frame = RawFrame.of(_bgra(4, 2, stride: 20), 4, 2)!;
      expect(frame.stride, 20);
    });

    test('is none without bytes, without a size, or with bytes that cannot be that frame', () {
      expect(RawFrame.of(null, 4, 2), isNull);
      expect(RawFrame.of(_bgra(4, 2), null, 2), isNull);
      expect(RawFrame.of(_bgra(4, 2), 4, 0), isNull);
      expect(RawFrame.of(Uint8List(33), 4, 2), isNull, reason: 'not whole rows');
      expect(RawFrame.of(_bgra(4, 2), 8, 2), isNull, reason: 'rows shorter than the width');
    });
  });

  group('downscaling', () {
    test('a 1080p frame becomes 640 × 360, in RGB, the padding of the rows left out', () {
      final frame = RawFrame.of(_bgra(1920, 1080, stride: 1920 * 4 + 64), 1920, 1080)!;
      final rgb = downscaleBgra(frame, 640);
      expect((rgb.width, rgb.height), (640, 360));
      expect(rgb.bytes.length, 640 * 360 * 3);
      expect(rgb.bytes.sublist(0, 3), [30, 20, 10]);
      expect(rgb.bytes.sublist(rgb.bytes.length - 3), [30, 20, 10]);
    });

    test('each pixel is the mean of the block it covers', () {
      // 4 × 1: black, white, and two of 100; to 2 × 1 they make 127 and 100.
      final bytes = Uint8List.fromList([0, 0, 0, 0, 255, 255, 255, 0, 100, 100, 100, 0, 100, 100, 100, 0]);
      final rgb = downscaleBgra(RawFrame(bytes, 4, 1, 16), 2);
      expect((rgb.width, rgb.height), (2, 1));
      expect(rgb.bytes, [127, 127, 127, 100, 100, 100]);
    });

    test('a frame no wider than the thumbnail keeps its size', () {
      final rgb = downscaleBgra(RawFrame.of(_bgra(320, 240), 320, 240)!, 640);
      expect((rgb.width, rgb.height), (320, 240));
    });

    test('a 4K frame keeps its proportions', () {
      final rgb = downscaleBgra(RawFrame.of(_bgra(3840, 1600), 3840, 1600)!, 640);
      expect((rgb.width, rgb.height), (640, 267));
    });
  });

  test('the thumbnail is a JPEG of 640 px wide, in the colour of the frame', () {
    final jpeg = thumbnailJpeg(RawFrame.of(_bgra(1920, 1080), 1920, 1080)!);
    expect(jpeg.sublist(0, 3), [0xFF, 0xD8, 0xFF]);
    final decoded = img.decodeJpg(jpeg)!;
    expect((decoded.width, decoded.height), (640, 360));
    final p = decoded.getPixel(320, 180);
    expect(p.r.toInt(), closeTo(30, 3));
    expect(p.g.toInt(), closeTo(20, 3));
    expect(p.b.toInt(), closeTo(10, 3));
  });
}
