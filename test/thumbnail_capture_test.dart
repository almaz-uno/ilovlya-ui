import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:ilovlya/src/media/thumbnail_capture.dart';
import 'package:media_kit/media_kit.dart';

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

  group('the frame of a video', () {
    // As mpv 0.35 reports a 1920 × 1080 phone video with a display matrix of 90°, and media_kit's state with it:
    // width 1080, height 1920. The frame screenshot-raw gives is 1920 × 1080, not turned.
    const portrait = VideoParams(w: 1920, h: 1080, dw: 1920, dh: 1080, rotate: 270);

    test('of a turned video is mpv\'s display size, not turned, with the turn kept', () {
      final frame = RawFrame.ofVideo(_bgra(1920, 1080), portrait)!;
      expect((frame.width, frame.height, frame.stride, frame.rotate), (1920, 1080, 1920 * 4, 270));
    });

    test('of an anamorphic video is its display size', () {
      // 1440 × 1080 with pixels 4:3 wide: mpv gives the frame stretched to 1920 × 1080.
      const anamorphic = VideoParams(w: 1440, h: 1080, dw: 1920, dh: 1080, rotate: 0);
      final frame = RawFrame.ofVideo(_bgra(1920, 1080), anamorphic)!;
      expect((frame.width, frame.height, frame.stride), (1920, 1080, 1920 * 4));
      expect(RawFrame.ofVideo(_bgra(1440, 1080), anamorphic), isNull, reason: 'the coded size is not what mpv gives');
    });

    test('of a turned video becomes a thumbnail turned as the player shows it', () {
      // The left half of the frame is red, the right half blue. Turned 270° clockwise, as the player shows it, the
      // left half is at the bottom.
      final bytes = _bgra(1920, 1080, b: 0, g: 0, r: 255);
      for (var y = 0; y < 1080; y++) {
        for (var x = 960; x < 1920; x++) {
          final i = (y * 1920 + x) * 4;
          bytes[i] = 255;
          bytes[i + 2] = 0;
        }
      }
      final decoded = img.decodeJpg(thumbnailJpeg(RawFrame.ofVideo(bytes, portrait)!))!;
      expect((decoded.width, decoded.height), (640, 1138));
      final top = decoded.getPixel(320, 100), bottom = decoded.getPixel(320, 1038);
      expect((top.r.toInt() < 20, top.b.toInt() > 235), (true, true), reason: 'blue on top');
      expect((bottom.r.toInt() > 235, bottom.b.toInt() < 20), (true, true), reason: 'red at the bottom');
    });
  });

  group('turning', () {
    // 3 × 2, pixels numbered by their red: 1 2 3 / 4 5 6.
    final rgb = (bytes: Uint8List.fromList([for (var v = 1; v <= 6; v++) ...[v, 0, 0]]), width: 3, height: 2);
    List<int> reds(({Uint8List bytes, int width, int height}) t) => [for (var i = 0; i < t.bytes.length; i += 3) t.bytes[i]];

    test('90° clockwise', () {
      final t = rotateRgb(rgb, 90);
      expect((t.width, t.height), (2, 3));
      expect(reds(t), [4, 1, 5, 2, 6, 3]);
    });

    test('180°', () {
      final t = rotateRgb(rgb, 180);
      expect((t.width, t.height), (3, 2));
      expect(reds(t), [6, 5, 4, 3, 2, 1]);
    });

    test('270° clockwise', () {
      final t = rotateRgb(rgb, 270);
      expect((t.width, t.height), (2, 3));
      expect(reds(t), [3, 6, 2, 5, 1, 4]);
    });

    test('anything else is left as it is', () {
      expect(reds(rotateRgb(rgb, 0)), [1, 2, 3, 4, 5, 6]);
      expect(RawFrame.of(_bgra(4, 2), 4, 2, rotate: 45)!.rotate, 0);
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
