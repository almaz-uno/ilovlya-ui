import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:media_kit/media_kit.dart';

/// The width a captured thumbnail is scaled down to. Server thumbnails are of that order.
const thumbnailWidth = 640;

/// The JPEG quality of a captured thumbnail.
const thumbnailQuality = 80;

/// A video frame as libmpv's `screenshot-raw` gives it: BGRA, 4 bytes a pixel, rows [stride] bytes apart.
///
/// mpv gives the frame at its display size, `dw` × `dh` (an anamorphic frame is already stretched), but not turned:
/// [rotate] is how many degrees clockwise the player turns it when it shows it, 0, 90, 180 or 270.
class RawFrame {
  const RawFrame(this.bytes, this.width, this.height, this.stride, {this.rotate = 0});

  final Uint8List bytes;
  final int width;
  final int height;
  final int stride;
  final int rotate;

  /// The frame [bytes] of [width] × [height] as `screenshot(format: null)` returns them, or `null` if they cannot be
  /// that frame. media_kit returns the bytes alone: the stride comes from their length.
  static RawFrame? of(Uint8List? bytes, int? width, int? height, {int? rotate}) {
    if (bytes == null || width == null || height == null || width <= 0 || height <= 0) return null;
    if (bytes.length % height != 0) return null;
    final stride = bytes.length ~/ height;
    if (stride < width * 4) return null;
    final turn = rotate ?? 0;
    return RawFrame(bytes, width, height, stride, rotate: const [90, 180, 270].contains(turn) ? turn : 0);
  }

  /// The frame [bytes] of a video of [params].
  ///
  /// The size is `dw` × `dh` as mpv reports them. `player.state.width` and `height` are no good here: media_kit swaps
  /// them for a video turned by 90 or 270 degrees, while the frame mpv gives is not turned.
  static RawFrame? ofVideo(Uint8List? bytes, VideoParams params) => of(bytes, params.dw, params.dh, rotate: params.rotate);
}

/// Takes the frame the player shows, unencoded.
///
/// This is the only part that holds the player's lock: libmpv copies the frame out, with no encoding. A seek, play or
/// pause issued meanwhile waits for that copy alone. Returns `null` while there is no frame to take.
Future<RawFrame?> takeRawFrame(Player player) async {
  final params = player.state.videoParams;
  if ((params.dw ?? 0) <= 0 || (params.dh ?? 0) <= 0) return null;
  final bytes = await player.screenshot(format: null);
  // The size or the turn may have changed while the frame was awaited.
  final now = player.state.videoParams;
  if (now.dw != params.dw || now.dh != params.dh || now.rotate != params.rotate) return null;
  return RawFrame.ofVideo(bytes, params);
}

/// Scales [frame] down to [thumbnailWidth] and encodes it as JPEG, off the UI isolate and outside the player's lock.
Future<Uint8List> encodeThumbnail(RawFrame frame) => compute(thumbnailJpeg, frame);

/// The frame the player shows, as a thumbnail; `null` while there is no frame.
Future<Uint8List?> captureThumbnail(Player player) async {
  final frame = await takeRawFrame(player);
  if (frame == null) return null;
  return encodeThumbnail(frame);
}

/// [frame] as the player shows it, turned, scaled down to [width] pixels wide keeping its proportions, and encoded as
/// JPEG.
///
/// Each pixel of the result is the mean of the block of the frame it covers. A frame no wider than [width], as shown,
/// keeps its size.
Uint8List thumbnailJpeg(RawFrame frame, {int width = thumbnailWidth, int quality = thumbnailQuality}) {
  final turned = frame.rotate == 90 || frame.rotate == 270;
  // Shown turned, the frame's height is its width on screen.
  final across = turned ? frame.height : frame.width;
  final scaled = across <= width ? frame.width : (frame.width * width / across).round().clamp(1, frame.width);
  final rgb = rotateRgb(downscaleBgra(frame, scaled), frame.rotate);
  final image = img.Image.fromBytes(width: rgb.width, height: rgb.height, bytes: rgb.bytes.buffer, numChannels: 3);
  return img.encodeJpg(image, quality: quality);
}

/// [rgb], 3 bytes a pixel, turned [rotate] degrees clockwise: 0, 90, 180 or 270.
({Uint8List bytes, int width, int height}) rotateRgb(({Uint8List bytes, int width, int height}) rgb, int rotate) {
  if (rotate != 90 && rotate != 180 && rotate != 270) return rgb;
  final w = rgb.width, h = rgb.height, src = rgb.bytes;
  final turned = rotate != 180;
  final ow = turned ? h : w;
  final oh = turned ? w : h;
  final out = Uint8List(src.length);
  var i = 0;
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      final (ox, oy) = switch (rotate) {
        90 => (h - 1 - y, x),
        180 => (w - 1 - x, h - 1 - y),
        _ => (y, w - 1 - x),
      };
      final o = (oy * ow + ox) * 3;
      out[o] = src[i];
      out[o + 1] = src[i + 1];
      out[o + 2] = src[i + 2];
      i += 3;
    }
  }
  return (bytes: out, width: ow, height: oh);
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
