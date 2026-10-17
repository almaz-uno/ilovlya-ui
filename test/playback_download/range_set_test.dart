import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:ilovlya/src/playback_download/range_set.dart';

void main() {
  group('RangeSet.add', () {
    test('keeps disjoint ranges apart and in order', () {
      final s = RangeSet()
        ..add(20, 30)
        ..add(0, 10);
      expect(s.intervals, [(0, 10), (20, 30)]);
      expect(s.stored, 20);
    });

    test('merges overlapping, adjacent and contained ranges', () {
      final s = RangeSet()
        ..add(0, 10)
        ..add(10, 20) // adjacent at the end
        ..add(30, 40)
        ..add(25, 30) // adjacent at the start
        ..add(33, 35) // contained
        ..add(15, 27); // bridges the two
      expect(s.intervals, [(0, 40)]);
      expect(s.stored, 40);
    });

    test('absorbs several intervals at once', () {
      final s = RangeSet()
        ..add(0, 2)
        ..add(4, 6)
        ..add(8, 10)
        ..add(12, 14)
        ..add(3, 13);
      expect(s.intervals, [(0, 2), (3, 14)]);
      expect(s.stored, 13);
    });

    test('ignores an empty range and refuses an invalid one', () {
      final s = RangeSet()..add(5, 5);
      expect(s.isEmpty, isTrue);
      expect(() => s.add(-1, 3), throwsArgumentError);
      expect(() => s.add(4, 3), throwsArgumentError);
    });
  });

  group('RangeSet.end', () {
    final s = RangeSet()
      ..add(10, 20)
      ..add(30, 40);

    test('reaches the end of the interval containing the offset', () {
      expect(s.end(10), 20);
      expect(s.end(19), 20);
      expect(s.end(35), 40);
    });

    test('returns the offset itself where nothing is stored', () {
      expect(s.end(0), 0);
      expect(s.end(20), 20);
      expect(s.end(25), 25);
      expect(s.end(40), 40);
      expect(s.contains(20), isFalse);
      expect(s.contains(19), isTrue);
    });
  });

  group('RangeSet.nextGap', () {
    test('of an empty set is the whole file from the read position', () {
      expect(RangeSet().nextGap(0, 100), (0, 100));
      expect(RangeSet().nextGap(40, 100), (40, 100));
    });

    test('runs forward from the read position, bounded by the next stored interval', () {
      final s = RangeSet()
        ..add(0, 10)
        ..add(50, 60);
      expect(s.nextGap(0, 100), (10, 50));
      expect(s.nextGap(55, 100), (60, 100));
      expect(s.nextGap(20, 100), (20, 50), reason: 'a read position inside a gap starts the range there');
    });

    test('wraps to the lowest gap once nothing is missing ahead', () {
      final s = RangeSet()
        ..add(0, 10)
        ..add(50, 100);
      expect(s.nextGap(60, 100), (10, 50));
      expect(s.nextGap(100, 100), (10, 50));
      expect(s.nextGap(500, 100), (10, 50), reason: 'a position past the end is clamped');
    });

    test('is null for a complete file, which isComplete agrees with', () {
      final s = RangeSet()
        ..add(0, 60)
        ..add(60, 100);
      expect(s.nextGap(0, 100), isNull);
      expect(s.nextGap(70, 100), isNull);
      expect(s.isComplete(100), isTrue);
      expect(RangeSet().isComplete(0), isTrue);
      expect((RangeSet()..add(1, 100)).isComplete(100), isFalse);
    });
  });

  test('survives a JSON round trip and normalises what it reads', () {
    final s = RangeSet()
      ..add(0, 41943040)
      ..add(587202560, 599785472);
    expect(RangeSet.fromJson(s.toJson()).intervals, s.intervals);
    expect(RangeSet.fromJson([
      [10, 20],
      [0, 10],
      [15, 30]
    ]).intervals, [(0, 30)]);
    expect(() => RangeSet.fromJson([
          [1]
        ]), throwsFormatException);
  });

  test('agrees with a bitmap over 10 000 random insertions', () {
    const length = 4096;
    final rnd = Random(20261005);
    var insertions = 0;
    for (var round = 0; round < 50; round++) {
      final s = RangeSet();
      final bits = List<bool>.filled(length, false);
      for (var k = 0; k < 200; k++, insertions++) {
        final a = rnd.nextInt(length);
        final b = min(length, a + 1 + rnd.nextInt(rnd.nextBool() ? 8 : 64));
        s.add(a, b);
        bits.fillRange(a, b, true);

        expect(s.stored, bits.where((x) => x).length);
        final from = rnd.nextInt(length + 1);
        expect(s.end(min(from, length - 1)), _end(bits, min(from, length - 1)));
        expect(s.nextGap(from, length), _nextGap(bits, from));
      }
      expect(s.intervals, _intervals(bits), reason: 'round $round');
      expect(s.isComplete(length), bits.every((x) => x));
    }
    expect(insertions, 10000);
  });
}

int _end(List<bool> bits, int offset) {
  var i = offset;
  while (i < bits.length && bits[i]) {
    i++;
  }
  return i;
}

(int, int)? _gapFrom(List<bool> bits, int from) {
  var a = from;
  while (a < bits.length && bits[a]) {
    a++;
  }
  if (a >= bits.length) return null;
  var b = a;
  while (b < bits.length && !bits[b]) {
    b++;
  }
  return (a, b);
}

(int, int)? _nextGap(List<bool> bits, int from) {
  return _gapFrom(bits, min(from, bits.length)) ?? (from > 0 ? _gapFrom(bits, 0) : null);
}

List<(int, int)> _intervals(List<bool> bits) {
  final out = <(int, int)>[];
  var i = 0;
  while (i < bits.length) {
    if (!bits[i]) {
      i++;
      continue;
    }
    final a = i;
    while (i < bits.length && bits[i]) {
      i++;
    }
    out.add((a, i));
  }
  return out;
}
