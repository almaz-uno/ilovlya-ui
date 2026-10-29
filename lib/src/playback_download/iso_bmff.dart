import 'dart:typed_data';

/// What the first bytes of a file tell about where its ISO-BMFF index, `moov`, lies.
///
/// A player cannot start an MP4 or M4A before it has read `moov`. yt-dlp leaves it after `mdat`, at the end of the
/// file, unless the file is remuxed to "faststart"; the player then reads the header, jumps to the end, and only then
/// plays from the front (ilovlya-ui#176).
sealed class MoovProbe {
  const MoovProbe();
}

/// The bytes given end before the answer: at least [bytes] from the start of the file are needed.
final class MoovNeedsMore extends MoovProbe {
  final int bytes;
  const MoovNeedsMore(this.bytes);
}

/// The file is not ISO-BMFF, or keeps `moov` before `mdat`, or its layout is not one this probe knows.
final class MoovNotTrailing extends MoovProbe {
  const MoovNotTrailing();
}

/// `mdat` ends at [at], before the end of the file: what follows it is the index.
final class MoovTrailing extends MoovProbe {
  final int at;
  const MoovTrailing(this.at);
}

/// How far into a file the top-level boxes before `mdat` are looked for. `ftyp` and a `free` or `wide` box take some
/// dozens of bytes; a file that has not reached `mdat` by then keeps its index elsewhere.
const moovProbeLimit = 64 << 10;

/// Walks the top-level boxes of [head], the first bytes of a file of [length] bytes, up to `mdat`.
MoovProbe probeMoov(Uint8List head, int length) {
  final data = ByteData.sublistView(head);
  var pos = 0;
  while (true) {
    if (pos >= moovProbeLimit || pos >= length) return const MoovNotTrailing();
    if (pos + 8 > head.length) return MoovNeedsMore(pos + 16);
    var size = data.getUint32(pos);
    final type = String.fromCharCodes(head, pos + 4, pos + 8);
    if (pos == 0 && type != 'ftyp') return const MoovNotTrailing();
    if (size == 1) {
      // A 64-bit size follows the type; `mdat` of a file over 4 GiB has one.
      if (pos + 16 > head.length) return MoovNeedsMore(pos + 16);
      size = data.getUint64(pos + 8);
    } else if (size == 0) {
      // The box runs to the end of the file, so nothing follows it.
      return const MoovNotTrailing();
    }
    if (size < 8) return const MoovNotTrailing();
    switch (type) {
      case 'moov':
        return const MoovNotTrailing();
      case 'mdat':
        final end = pos + size;
        return end < length ? MoovTrailing(end) : const MoovNotTrailing();
    }
    pos += size;
  }
}
