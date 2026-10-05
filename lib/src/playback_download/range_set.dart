import 'dart:math';

/// The stored bytes of a file, as a sorted list of disjoint, non-adjacent half-open intervals `[start, end)`.
///
/// Overlapping and adjacent intervals are merged on insertion, so the representation is canonical: two sets holding
/// the same bytes hold the same list. The number of intervals stays small in practice — one per seek that left a gap
/// behind, merged away as the gaps are filled.
class RangeSet {
  final List<int> _starts = [];
  final List<int> _ends = [];
  int _stored = 0;

  RangeSet();

  /// Restores a set from [toJson]. Intervals are re-added, so a hand-edited or overlapping list is normalised and an
  /// invalid one is refused.
  factory RangeSet.fromJson(List<dynamic> json) {
    final set = RangeSet();
    for (final pair in json) {
      final p = pair as List<dynamic>;
      if (p.length != 2) throw FormatException('A range must be [start, end], got $p');
      set.add(p[0] as int, p[1] as int);
    }
    return set;
  }

  /// Number of stored bytes, kept incrementally.
  int get stored => _stored;

  bool get isEmpty => _starts.isEmpty;

  /// The intervals in ascending order.
  List<(int, int)> get intervals => [for (var i = 0; i < _starts.length; i++) (_starts[i], _ends[i])];

  /// Marks `[start, end)` as stored. O(log n + k) for k intervals absorbed.
  void add(int start, int end) {
    if (start < 0 || end < start) throw ArgumentError('Invalid range [$start, $end)');
    if (start == end) return;

    // Intervals before i end before `start` and cannot touch it; `>=` makes an interval ending exactly at `start`
    // adjacent, and adjacent intervals are merged.
    final i = _firstEndAtLeast(start);
    var j = i;
    var s = start, e = end;
    while (j < _starts.length && _starts[j] <= end) {
      s = min(s, _starts[j]);
      e = max(e, _ends[j]);
      _stored -= _ends[j] - _starts[j];
      j++;
    }
    _starts.replaceRange(i, j, [s]);
    _ends.replaceRange(i, j, [e]);
    _stored += e - s;
  }

  /// The end of the stored interval containing [offset], or [offset] itself if that byte is not stored. This is how far
  /// a read starting at [offset] can go right now.
  int end(int offset) {
    final i = _firstStartAbove(offset) - 1;
    if (i >= 0 && offset < _ends[i]) return _ends[i];
    return offset;
  }

  bool contains(int offset) => end(offset) > offset;

  /// The first missing range within `[0, length)` at or after [from]; if there is none, the first missing range from 0.
  /// `null` when the file is complete.
  ///
  /// This is the filling order of the specification: forward from the most recent read position, then the gaps left
  /// behind, lowest first. A [from] inside a gap yields a range starting at [from], not at the gap's start.
  (int, int)? nextGap(int from, int length) {
    final ahead = _gapFrom(from.clamp(0, length), length);
    if (ahead != null) return ahead;
    return from > 0 ? _gapFrom(0, length) : null;
  }

  /// Whether every byte of `[0, length)` is stored.
  bool isComplete(int length) => length == 0 || (_starts.length == 1 && _starts[0] == 0 && _ends[0] >= length);

  List<List<int>> toJson() => [for (var i = 0; i < _starts.length; i++) [_starts[i], _ends[i]]];

  @override
  String toString() => 'RangeSet(${intervals.map((r) => '[${r.$1}, ${r.$2})').join(' ')})';

  (int, int)? _gapFrom(int from, int length) {
    if (from >= length) return null;
    final gapStart = end(from);
    if (gapStart >= length) return null;
    final next = _firstStartAbove(gapStart);
    return (gapStart, next < _starts.length ? min(_starts[next], length) : length);
  }

  /// Smallest index whose interval ends at or after [x]; ends are ascending because the intervals are disjoint.
  int _firstEndAtLeast(int x) {
    var lo = 0, hi = _ends.length;
    while (lo < hi) {
      final mid = (lo + hi) >> 1;
      if (_ends[mid] < x) {
        lo = mid + 1;
      } else {
        hi = mid;
      }
    }
    return lo;
  }

  /// Smallest index whose interval starts after [x].
  int _firstStartAbove(int x) {
    var lo = 0, hi = _starts.length;
    while (lo < hi) {
      final mid = (lo + hi) >> 1;
      if (_starts[mid] <= x) {
        lo = mid + 1;
      } else {
        hi = mid;
      }
    }
    return lo;
  }
}
