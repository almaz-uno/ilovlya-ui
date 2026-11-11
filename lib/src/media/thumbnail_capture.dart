import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:media_kit/media_kit.dart';

/// The width a captured thumbnail is scaled down to. Server thumbnails are of that order.
const thumbnailWidth = 640;

/// The JPEG quality of a captured thumbnail.
const thumbnailQuality = 80;

/// A video frame as libmpv's `screenshot-raw` gives it: BGRA, 4 bytes a pixel, rows [stride] bytes apart.
class RawFrame {
  const RawFrame(this.bytes, this.width, this.height, this.stride);

  final Uint8List bytes;
  final int width;
  final int height;
  final int stride;

  /// The frame [bytes] of [width] × [height] as `screenshot(format: null)` returns them, or `null` if they cannot be
  /// that frame. media_kit returns the bytes alone: the size comes from the player's state, and the stride from both.
  static RawFrame? of(Uint8List? bytes, int? width, int? height) {
    if (bytes == null || width == null || height == null || width <= 0 || height <= 0) return null;
    if (bytes.length % height != 0) return null;
    final stride = bytes.length ~/ height;
    if (stride < width * 4) return null;
    return RawFrame(bytes, width, height, stride);
  }
}

/// Takes the frame the player shows, unencoded.
///
/// This is the only part that holds the player's lock: libmpv copies the frame out, with no encoding. A seek, play or
/// pause issued meanwhile waits for that copy alone. Returns `null` while there is no frame to take.
Future<RawFrame?> takeRawFrame(Player player) async {
  final width = player.state.width;
  final height = player.state.height;
  if (width == null || height == null || width <= 0 || height <= 0) return null;
  final bytes = await player.screenshot(format: null);
  return RawFrame.of(bytes, width, height);
}

/// Scales [frame] down to [thumbnailWidth] and encodes it as JPEG, off the UI isolate and outside the player's lock.
Future<Uint8List> encodeThumbnail(RawFrame frame) => compute(thumbnailJpeg, frame);

/// The frame the player shows, as a thumbnail; `null` while there is no frame.
Future<Uint8List?> captureThumbnail(Player player) async {
  final frame = await takeRawFrame(player);
  if (frame == null) return null;
  return encodeThumbnail(frame);
}

/// [frame] scaled down to [width] pixels wide, keeping its proportions, and encoded as JPEG.
///
/// Each pixel of the result is the mean of the block of the frame it covers. A frame no wider than [width] keeps its
/// size.
Uint8List thumbnailJpeg(RawFrame frame, {int width = thumbnailWidth, int quality = thumbnailQuality}) {
  final rgb = downscaleBgra(frame, width);
  final image = img.Image.fromBytes(width: rgb.width, height: rgb.height, bytes: rgb.bytes.buffer, numChannels: 3);
  return img.encodeJpg(image, quality: quality);
}

/// [frame] as RGB, 3 bytes a pixel, box-filtered down to [maxWidth] pixels wide.
({Uint8List bytes, int width, int height}) downscaleBgra(RawFrame frame, int maxWidth) {
  final sw = frame.width, sh = frame.height, stride = frame.stride, src = frame.bytes;
  final dw = sw <= maxWidth ? sw : maxWidth;
  final dh = sw <= maxWidth ? sh : ((sh * dw) / sw).round().clamp(1, sh);
  final out = Uint8List(dw * dh * 3);
  var o = 0;
  for (var y = 0; y < dh; y++) {
    final y0 = y * sh ~/ dh;
    final y1 = (y + 1) * sh ~/ dh;
    for (var x = 0; x < dw; x++) {
      final x0 = x * sw ~/ dw;
      final x1 = (x + 1) * sw ~/ dw;
      var b = 0, g = 0, r = 0;
      for (var sy = y0; sy < y1; sy++) {
        var i = sy * stride + x0 * 4;
        for (var sx = x0; sx < x1; sx++) {
          b += src[i];
          g += src[i + 1];
          r += src[i + 2];
          i += 4;
        }
      }
      final n = (y1 - y0) * (x1 - x0);
      out[o++] = r ~/ n;
      out[o++] = g ~/ n;
      out[o++] = b ~/ n;
    }
  }
  return (bytes: out, width: dw, height: dh);
}
