import 'dart:async';

import 'package:background_downloader/background_downloader.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show ProviderBase;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../api/directories_riverpod.dart';
import '../api/downloads_riverpod.dart';
import '../api/local_download_task_riverpod.dart';
import '../api/media_list_riverpod.dart';
import '../api/recording_riverpod.dart';
import '../model/download.dart';
import '../model/local_download.dart';
import '../settings/settings_provider.dart';
import '../utils/logger_provider.dart';
import 'local_endpoint.dart';
import 'partial_file.dart';
import 'partial_source.dart';

part 'playback_downloads.g.dart';

class _Session {
  final Download download;
  final PartialSource source;
  final Uri url;
  bool attached = false;
  bool announced = false;

  _Session(this.download, this.source, this.url);
}

/// The owner of the playback downloads: one [PartialSource] per download, served by one [LocalMediaEndpoint].
///
/// At most one playback download is active. Opening another pauses the previous one, whose partial file stays where it
/// is and is resumed the next time that download is played. A download outlives the player: [detach] lets it continue
/// unattended until it completes, fails eight times in a row, or another one starts.
///
/// The state is the [SourceState] of every download it owns; the progress itself is published into
/// [localDTNotifierProvider], beside the `background_downloader` tasks, which is where the player's progress line and
/// the explicit download's guard already look.
@Riverpod(keepAlive: true)
class PlaybackDownloads extends _$PlaybackDownloads {
  /// How long [open] waits for the server's first answer before handing the player the URL regardless.
  static const lengthWait = Duration(seconds: 5);

  final Map<String, _Session> _sessions = {};
  Future<LocalMediaEndpoint>? _endpoint;
  Timer? _ticker;

  @override
  Map<String, SourceState> build() {
    ref.onDispose(() {
      _ticker?.cancel();
      for (final s in _sessions.values) {
        unawaited(s.source.dispose());
      }
      _sessions.clear();
      unawaited(_endpoint?.then((e) => e.close()));
    });
    return const {};
  }

  /// Whether a playback download of [downloadId] exists, active or paused.
  bool owns(String downloadId) => _sessions.containsKey(downloadId);

  /// Whether the playback download of [downloadId] is transferring right now.
  bool isActive(String downloadId) => _sessions[downloadId]?.source.isRunning ?? false;

  /// Whether the playback download of [downloadId] stopped saving because its file could not be written.
  bool savingFailed(String downloadId) => _sessions[downloadId]?.source.writeFailed ?? false;

  /// Starts or resumes the playback download of [d] and returns the URL the player opens.
  ///
  /// If the server's first answer carries no length — which `http.ServeContent` never does, but a proxy in front of
  /// the server might — nothing can be stored, and the server's own URL is returned: the playback streams, as with the
  /// setting off.
  Future<Uri> open(Download d) async {
    final endpoint = await (_endpoint ??= LocalMediaEndpoint.start());
    for (final other in _sessions.values.toList()) {
      if (other.download.id != d.id && other.source.isRunning) {
        other.attached = false;
        other.source.fetcher.playerAttached = false;
        await other.source.pause();
        AppLoggers.download.i('Playback download of ${other.download.id} paused for ${d.id}');
      }
    }

    var s = _sessions[d.id];
    if (s != null && (s.source.isGone || s.source.state == SourceState.passThrough)) {
      await _drop(d.id);
      s = null;
    }
    if (s == null) {
      final sp = await ref.read(storePlacesProvider.future);
      final file = PartialFile.open(mediaDir: sp.media().path, downloadId: d.id, filename: d.filename, url: d.url);
      final source = PartialSource(file: file, url: Uri.parse(d.url), authorization: await _authorization());
      s = _Session(d, source, endpoint.register(d.id, d.filename, source));
      source.onChange = () => _changed(d.id);
      _sessions[d.id] = s;
      AppLoggers.download.i('Playback download of ${d.id} opened: ${file.ranges.stored} of ${file.length ?? '?'} bytes stored');
    }
    s.attached = true;
    s.source.fetcher.playerAttached = true;
    s.source.resume(0);
    _changed(d.id);

    if (s.source.file.length == null) {
      try {
        await s.source.length().timeout(lengthWait);
      } on SourceGone catch (e) {
        AppLoggers.download.w('Playback download of ${d.id} abandoned, streaming instead: $e');
        await _drop(d.id);
        return Uri.parse(d.url);
      } on TimeoutException {
        // The server is slow to answer. The endpoint keeps waiting for the length, as the player would on a stream.
      }
    }
    return s.url;
  }

  /// The player has closed. The download continues unattended, or ends here if there is nothing left to do.
  void detach(String downloadId) {
    final s = _sessions[downloadId];
    if (s == null) return;
    s.attached = false;
    s.source.fetcher.playerAttached = false;
    if (s.source.state != SourceState.running && s.source.state != SourceState.idle) unawaited(_drop(downloadId));
  }

  /// Stops the playback download of [downloadId] and deletes its partial file.
  Future<void> discard(String downloadId) async {
    final s = _sessions[downloadId];
    if (s == null) return;
    await s.source.discard('discarded');
    await _drop(downloadId);
  }

  /// Stops and deletes the playback download whose file is [filename], if one is held; for cleaning by file name.
  Future<void> discardFile(String filename) async {
    for (final s in _sessions.values.toList()) {
      if (s.download.filename == filename) await discard(s.download.id);
    }
  }

  /// Deletes every partial file, before the media directory is cleaned. A download a player is reading from turns into
  /// a pass-through, so that the playback continues as a plain stream; the others end.
  Future<void> stopAll() async {
    for (final id in _sessions.keys.toList()) {
      final s = _sessions[id]!;
      if (s.source.state == SourceState.complete) {
        if (!s.attached) await _drop(id);
      } else if (s.attached) {
        await s.source.passThrough('the media was cleaned');
      } else {
        await discard(id);
      }
    }
  }

  /// The `Authorization` value the rest of the client sends (`getAuthHeader`): the bare token.
  Future<String?> _authorization() async {
    final token = (await ref.read(settingsNotifierProvider.future)).token;
    return token.isEmpty ? null : token;
  }

  Future<void> _drop(String id) async {
    final s = _sessions.remove(id);
    if (s == null) return;
    (await _endpoint)?.unregister(id);
    await s.source.dispose();
    if (s.source.state != SourceState.complete) ref.read(localDTNotifierProvider.notifier).forget(id);
    state = {...state}..remove(id);
  }

  void _changed(String id) {
    final s = _sessions[id];
    if (s == null) return;
    _publish(s);
    state = {...state, id: s.source.state};
    if (s.source.state == SourceState.complete && !s.announced) {
      s.announced = true;
      // By *recording* identifier, which the family parameter is. Only what is shown needs re-reading: invalidating a
      // provider nobody watches would build it once for nothing.
      final rid = s.download.recordingId;
      for (final provider in <ProviderBase<Object?>>[downloadsNotifierProvider(rid), recordingNotifierProvider(rid), mediaListNotifierProvider]) {
        if (ref.exists(provider)) ref.invalidate(provider);
      }
      AppLoggers.download.i('Playback download of $id complete: ${s.source.file.finalPath}');
      if (!s.attached) unawaited(_drop(id));
    }
    _tick();
  }

  void _publish(_Session s) {
    final src = s.source;
    final length = src.file.length;
    final stored = src.file.ranges.stored;
    final rate = src.fetcher.rate;
    final complete = src.state == SourceState.complete;
    ref.read(localDTNotifierProvider.notifier).publish(LocalDownloadTask(
          id: s.download.id,
          displayName: s.download.title,
          filename: s.download.filename,
          status: switch (src.state) {
            SourceState.running => TaskStatus.running,
            SourceState.idle => TaskStatus.paused,
            SourceState.complete => TaskStatus.complete,
            SourceState.passThrough => TaskStatus.failed,
            SourceState.gone => TaskStatus.canceled,
          },
          progress: complete ? 1.0 : (length == null || length == 0 ? null : stored / length),
          networkSpeed: src.isRunning && rate > 0 ? rate / 1e6 : null,
          timeRemaining: src.isRunning && rate > 0 && length != null ? Duration(seconds: ((length - stored) / rate).round()) : null,
        ));
  }

  /// Publishes progress once a second while anything transfers.
  void _tick() {
    final running = _sessions.values.any((s) => s.source.isRunning);
    if (running && _ticker == null) {
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
        for (final s in _sessions.values) {
          if (s.source.isRunning) _publish(s);
        }
        if (!_sessions.values.any((s) => s.source.isRunning)) {
          _ticker?.cancel();
          _ticker = null;
        }
      });
    } else if (!running) {
      _ticker?.cancel();
      _ticker = null;
    }
  }
}
