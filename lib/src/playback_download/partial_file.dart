import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:path/path.dart' as p;

import 'range_set.dart';

/// A file being downloaded in pieces, in `<media>/.partial/`, with a durable record of which bytes it holds.
///
/// Two paths live in `.partial/`: the data, `<filename>`, written at the server's offsets, and the record,
/// `<filename>.state.json`. The invariant is *ranges in the record ⊆ bytes durably written*: [checkpoint] flushes the
/// data before it replaces the record, and replaces it by renaming a temporary file over it, so a crash at any point
/// leaves a record describing flushed data. After a crash, what was written since the last checkpoint is fetched again.
///
/// Writes and flushes go through the asynchronous [RandomAccessFile] methods, which run on the I/O pool rather than
/// the UI isolate, and are chained, because a [RandomAccessFile] refuses overlapping asynchronous operations.
class PartialFile {
  static const partialDirName = '.partial';
  static const stateVersion = 1;

  /// A checkpoint is due after this much new data…
  static const checkpointBytes = 8 << 20;

  /// …or this long after the previous one, whichever comes first.
  static const checkpointInterval = Duration(seconds: 5);

  final String downloadId;
  final String url;
  final String dataPath;
  final String statePath;
  final String finalPath;

  /// Bytes written, including those not yet covered by a checkpoint. What readers may read.
  final RangeSet ranges;

  final _changes = StreamController<void>.broadcast();
  int? _length;
  String? _lastModified;
  RandomAccessFile? _writer;
  RandomAccessFile? _reader;
  Future<void> _writes = Future.value();
  Future<void> _reads = Future.value();
  int _uncheckpointed = 0;
  DateTime _lastCheckpoint = DateTime.now();
  bool _completed = false;
  bool _closed = false;

  PartialFile._(this.downloadId, this.url, this.dataPath, this.statePath, this.finalPath, this.ranges, this._length, this._lastModified);

  /// Opens the partial file of [downloadId] in [mediaDir], resuming from its record when the record is usable.
  ///
  /// A record is discarded — and the download starts from nothing — when it belongs to another download or URL, has
  /// another version, cannot be parsed, or describes more data than the data file holds.
  static PartialFile open({required String mediaDir, required String downloadId, required String filename, required String url}) {
    final dir = Directory(p.join(mediaDir, partialDirName))..createSync(recursive: true);
    final dataPath = p.join(dir.path, filename);
    final statePath = '$dataPath.state.json';
    final tmp = File('$statePath.tmp');
    if (tmp.existsSync()) tmp.deleteSync();

    var ranges = RangeSet();
    int? length;
    String? lastModified;
    final state = File(statePath);
    if (state.existsSync()) {
      try {
        final json = jsonDecode(state.readAsStringSync()) as Map<String, dynamic>;
        final restored = RangeSet.fromJson(json['ranges'] as List<dynamic>);
        final data = File(dataPath);
        final lastEnd = restored.isEmpty ? 0 : restored.intervals.last.$2;
        if (json['version'] == stateVersion &&
            json['download_id'] == downloadId &&
            json['url'] == url &&
            data.existsSync() &&
            data.lengthSync() >= lastEnd) {
          ranges = restored;
          length = json['length'] as int?;
          lastModified = json['last_modified'] as String?;
        }
      } on FormatException {
        // An unreadable record is the same as no record.
      } on TypeError {
        // Neither is a record of the wrong shape.
      }
    }
    if (ranges.isEmpty) {
      length = null;
      lastModified = null;
      if (state.existsSync()) state.deleteSync();
    }
    return PartialFile._(downloadId, url, dataPath, statePath, p.join(mediaDir, filename), ranges, length, lastModified);
  }

  /// Deletes the partial file of [filename] and its record, if there are any; for cleaning a partial file no session
  /// holds, such as one paused in an earlier run of the application.
  static void deleteFor(String mediaDir, String filename) {
    final dataPath = p.join(mediaDir, partialDirName, filename);
    for (final path in [dataPath, '$dataPath.state.json', '$dataPath.state.json.tmp']) {
      final f = File(path);
      if (f.existsSync()) f.deleteSync();
    }
  }

  /// The file's length, known from the server's first answer and fixed afterwards.
  int? get length => _length;

  /// The server's `Last-Modified` for the file, used as `If-Range` when resuming.
  String? get lastModified => _lastModified;

  bool get isComplete => _length != null && ranges.isComplete(_length!);

  bool get isCompleted => _completed;

  /// Fires after every write that added bytes to [ranges]; a reader waiting for an offset listens here.
  Stream<void> get changes => _changes.stream;

  /// Fixes the length and `Last-Modified` of a download that has none yet.
  void setLength(int length, String? lastModified) {
    if (_length != null && _length != length) throw StateError('Length is already $_length, got $length');
    _length = length;
    _lastModified = lastModified;
  }

  /// Writes [bytes] at [offset]. The bytes become readable, and part of [ranges], once the returned future completes.
  Future<void> write(int offset, List<int> bytes) {
    if (_completed || _closed) throw StateError('Partial file $dataPath is no longer writable');
    final length = _length;
    if (length != null && offset + bytes.length > length) throw RangeError('Write [$offset, ${offset + bytes.length}) past the length $length');
    return _chainWrite(() async {
      final w = _writer ??= await File(dataPath).open(mode: FileMode.append);
      await w.setPosition(offset);
      await w.writeFrom(bytes);
      ranges.add(offset, offset + bytes.length);
      _uncheckpointed += bytes.length;
      _changes.add(null);
    });
  }

  /// Whether enough new data or time has accumulated for [checkpoint] to be worth its flush.
  bool get checkpointDue => _uncheckpointed >= checkpointBytes || (_uncheckpointed > 0 && DateTime.now().difference(_lastCheckpoint) >= checkpointInterval);

  /// Makes the bytes written so far durable and records them. Does nothing if nothing was written since the last one.
  Future<void> checkpoint() {
    return _chainWrite(() async {
      if (_uncheckpointed == 0 || _completed) return;
      // Everything chained before this point has completed, so [ranges] describes exactly what the flush covers.
      final snapshot = ranges.toJson();
      await _writer?.flush();
      final tmp = File('$statePath.tmp');
      await tmp.writeAsString(jsonEncode({
        'version': stateVersion,
        'download_id': downloadId,
        'url': url,
        'length': _length,
        'last_modified': _lastModified,
        'ranges': snapshot,
      }), flush: true);
      await tmp.rename(statePath);
      _uncheckpointed = 0;
      _lastCheckpoint = DateTime.now();
    });
  }

  /// Reads up to [count] stored bytes at [offset]; fewer if the stored interval ends sooner, none if [offset] is not
  /// stored. Keeps working after [complete], because the open handle follows the file across the rename.
  Future<Uint8List> read(int offset, int count) {
    final available = min(count, ranges.end(offset) - offset);
    if (available <= 0) return Future.value(Uint8List(0));
    return _chainRead(() async {
      final r = _reader ??= await File(_completed ? finalPath : dataPath).open(mode: FileMode.read);
      await r.setPosition(offset);
      return r.read(available);
    });
  }

  /// Turns a complete partial file into the final one: flush, rename into the media directory, delete the record.
  /// Returns the final path.
  Future<String> complete() async {
    if (!isComplete) throw StateError('Partial file $dataPath is not complete: $ranges of $_length');
    await _chainWrite(() async {
      await _writer?.flush();
      await _writer?.close();
      _writer = null;
      File(dataPath).renameSync(finalPath);
      final state = File(statePath);
      if (state.existsSync()) state.deleteSync();
      _completed = true;
    });
    return finalPath;
  }

  /// Checkpoints and releases the file handles, keeping everything on disk for a later [open].
  Future<void> close() async {
    if (_closed) return;
    await checkpoint();
    _closed = true;
    await _releaseHandles();
  }

  /// Releases the handles and deletes the data and the record.
  Future<void> discard() async {
    _closed = true;
    await _releaseHandles();
    for (final path in [dataPath, statePath, '$statePath.tmp']) {
      final f = File(path);
      if (f.existsSync()) f.deleteSync();
    }
  }

  Future<void> _releaseHandles() async {
    await _chainWrite(() async {
      await _writer?.close();
      _writer = null;
    });
    await _chainRead(() async {
      await _reader?.close();
      _reader = null;
    });
  }

  /// Runs [op] after every write chained before it. Its failure is returned to the caller and does not poison the
  /// chain for the operations after it.
  Future<T> _chainWrite<T>(Future<T> Function() op) {
    final result = _writes.then((_) => op());
    _writes = result.then((_) {}, onError: (_) {});
    return result;
  }

  Future<T> _chainRead<T>(Future<T> Function() op) {
    final result = _reads.then((_) => op());
    _reads = result.then((_) {}, onError: (_) {});
    return result;
  }
}
