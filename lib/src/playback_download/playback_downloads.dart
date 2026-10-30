import 'dart:async';
import 'dart:io';

import 'package:background_downloader/background_downloader.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter/widgets.dart' show AppLifecycleListener, AppLifecycleState;
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
import 'fetcher.dart';
import 'local_endpoint.dart';
import 'partial_file.dart';
import 'partial_source.dart';

part 'playback_downloads.g.dart';

class _Session {
  final Download download;
  final PartialSource source;
  bool attached = false;
  bool announced = false;

  _Session(this.download, this.source);
}

/// The owner of the playback downloads: one [PartialSource] per download, served by one [LocalMediaEndpoint].
///
/// At most one playback download is active. Opening another pauses the previous one, whose partial file stays where it
/// is and is resumed the next time that download is played. A download outlives the player: [detach] lets it continue
/// unattended until it completes, fails eight times in a row, or another one starts.
///
/// The state is the [SourceState] of every download it owns; the progress itself is published into
/// [localDTProvider], beside the `background_downloader` tasks, which is where the player's progress line and
/// the explicit download's guard already look.
///
/// On iOS the endpoint listens only while it may be needed: with the application in front, or with the player playing,
/// which keeps the process running in the background. Otherwise the process is about to be suspended, and its sockets
/// reclaimed; the endpoint stops listening and listens again on the same port on return, so that the player's URL stays
/// valid (spec 004, "On iOS").
@Riverpod(keepAlive: true)
class PlaybackDownloads extends _$PlaybackDownloads {
  /// How long [open] waits for the server's first answer before handing the player the URL regardless.
  static const lengthWait = Duration(seconds: 5);

  /// [Fetcher.silenceTimeout], [Fetcher.flowingWithin], [Fetcher.recoveredAfter] and [PartialSource.giveUpAfter] of the
  /// downloads opened from now on; tests shorten them.
  @visibleForTesting
  Duration silenceTimeout = Fetcher.defaultSilenceTimeout;
  @visibleForTesting
  Duration flowingWithin = Fetcher.defaultFlowingWithin;
  @visibleForTesting
  Duration recoveredAfter = Fetcher.defaultRecoveredAfter;
  @visibleForTesting
  Duration giveUpAfter = PartialSource.defaultGiveUpAfter;

  final Map<String, _Session> _sessions = {};
  Future<LocalMediaEndpoint>? _endpoint;
  Timer? _ticker;
  AppLifecycleListener? _lifecycle;
  bool _inFront = true;
  bool _playerPlaying = false;
  Future<void> _listening = Future.value();

  @override
  Map<String, SourceState> build() {
    if (Platform.isIOS) {
      _lifecycle = AppLifecycleListener(onStateChange: (s) => inFront = s != AppLifecycleState.paused && s != AppLifecycleState.detached);
    }
    ref.onDispose(() {
      _lifecycle?.dispose();
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

  /// Whether the playback download of [downloadId] has given up on its server for now; see [PartialSource.serverAway].
  bool serverAway(String downloadId) => _sessions[downloadId]?.source.serverAway ?? false;

  /// How long the server of the running playback download of [downloadId] has not been answering it
  /// ([Fetcher.notAnsweringFor]); `null` while it answers, or when the download is not running. What the progress line
  /// shows while the download waits to retry.
  Duration? notAnsweringFor(String downloadId) {
    final s = _sessions[downloadId];
    return s != null && s.source.isRunning ? s.source.fetcher.notAnsweringFor : null;
  }

  /// Where a playback of [downloadId] is played from, as the user should see it: the server's URL while the file is
  /// still arriving, the local file once all of it has. The endpoint's own loopback URL is an implementation detail.
  /// `null` when no playback download of [downloadId] exists.
  String? shownSource(String downloadId) {
    final s = _sessions[downloadId];
    if (s == null) return null;
    return s.source.state == SourceState.complete ? s.source.file.finalPath : s.download.url;
  }

  /// Starts or resumes the playback download of [d] and returns the URL the player opens.
  ///
  /// If the server's first answer carries no length — which `http.ServeContent` never does, but a proxy in front of
  /// the server might — nothing can be stored, and the server's own URL is returned: the playback streams, as with the
  /// setting off.
  Future<Uri> open(Download d) async {
    await _listening;
    if (!ref.mounted) return Uri.parse(d.url);
    final endpoint = await (_endpoint ??= LocalMediaEndpoint.start());
    if (!ref.mounted) return Uri.parse(d.url);
    for (final other in _sessions.values.toList()) {
      if (other.download.id != d.id && other.source.isRunning) {
        other.attached = false;
        other.source.fetcher.playerAttached = false;
        await other.source.pause();
        AppLoggers.download.i('Playback download of ${other.download.id} paused for ${d.id}');
      }
    }
    if (!ref.mounted) return Uri.parse(d.url);

    var s = _sessions[d.id];
    if (s != null && (s.source.isGone || s.source.state == SourceState.passThrough)) {
      await _drop(d.id);
      if (!ref.mounted) return Uri.parse(d.url);
      s = null;
    }
    if (s == null) {
      final sp = await ref.read(storePlacesProvider.future);
      if (!ref.mounted) return Uri.parse(d.url);
      final file = PartialFile.open(mediaDir: sp.media().path, downloadId: d.id, filename: d.filename, url: d.url);
      final authorization = await _authorization();
      if (!ref.mounted) return Uri.parse(d.url);
      final source = PartialSource(
          file: file, url: Uri.parse(d.url), authorization: authorization, silenceTimeout: silenceTimeout, flowingWithin: flowingWithin, recoveredAfter: recoveredAfter, giveUpAfter: giveUpAfter);
      s = _Session(d, source);
      source.onChange = () => _changed(d.id);
      _sessions[d.id] = s;
      AppLoggers.download.i('Playback download of ${d.id} opened: ${file.ranges.stored} of ${file.length ?? '?'} bytes stored');
    }
    // On every open: the endpoint may be a new one, after the old one could not listen again.
    final url = endpoint.register(d.id, d.filename, s.source);
    s.attached = true;
    s.source.fetcher.playerAttached = true;
    s.source.resume(0);
    _changed(d.id);

    // A fresh download waits for its length; a resumed one for the server to confirm that the file did not change, so
    // that the player is not handed the old file's length.
    if (s.source.file.length == null || !s.source.confirmed) {
      try {
        await s.source.length().timeout(lengthWait);
      } on SourceGone catch (e) {
        AppLoggers.download.w('Playback download of ${d.id} abandoned, streaming instead: $e');
        await _drop(d.id);
        return Uri.parse(d.url);
      } on TimeoutException {
        // The server is slow to answer. The endpoint keeps waiting for the length, as the player would on a stream.
      } on UpstreamUnavailable catch (e) {
        // The server has been away for long already. The endpoint answers the player that it is unavailable, and serves
        // the URL once the server is back.
        AppLoggers.download.w('Playback download of ${d.id} opened while the server is away: $e');
      } on TransferStopped {
        // Stopped meanwhile: paused for another download that opened, turned into a pass-through when the media was
        // cleaned, or closed. The endpoint answers the player as for a server away. A discard — the download removed, or
        // its file cleaned — ends the wait with [SourceGone] above instead, and the player streams.
      }
    }
    return url;
  }

  /// Whether the player reading from the endpoint is playing; set by the player. While it plays, iOS keeps the process
  /// running in the background, and the endpoint keeps listening.
  set playerPlaying(bool playing) {
    if (_playerPlaying == playing) return;
    _playerPlaying = playing;
    _listenWhileNeeded();
    _followSuspension();
  }

  /// Whether the application is in front; followed on iOS only, so that elsewhere the endpoint never stops listening.
  @visibleForTesting
  set inFront(bool inFront) {
    if (_inFront == inFront) return;
    _inFront = inFront;
    _listenWhileNeeded();
    _followSuspension();
    // Back in front, the network is likely back too: a transfer sleeping out a backoff tries at once.
    if (inFront) {
      for (final s in _sessions.values) {
        if (s.source.isRunning && s.source.fetcher.failingFor != null) s.source.fetcher.wake();
      }
    }
  }

  /// Completes once the endpoint listens or not as the last change of [inFront] or [playerPlaying] asked.
  @visibleForTesting
  Future<void> get listeningSettled => _listening;

  /// Tells the transfers whether the application is about to be suspended, by the same rule the endpoint follows: out
  /// of the front with the player not playing, which happens on iOS only. Time spent so does not count as the server's
  /// silence ([Fetcher.suspend]).
  void _followSuspension() {
    final suspended = !_inFront && !_playerPlaying;
    for (final s in _sessions.values) {
      suspended ? s.source.fetcher.suspend() : s.source.fetcher.resume();
    }
  }

  /// Suspends or resumes the endpoint for the state at the time the change runs; changes run one after another.
  void _listenWhileNeeded() {
    _listening = _listening.then((_) async {
      final pending = _endpoint;
      if (pending == null) return;
      final endpoint = await pending;
      if (!_inFront && !_playerPlaying) return endpoint.suspend();
      try {
        await endpoint.resume();
      } on SocketException {
        // The URLs handed out are dead. The player takes the refused connection for an interruption, and its reopening
        // registers the downloads on a new endpoint.
        if (_endpoint == pending) _endpoint = null;
        await endpoint.close();
      }
    }).catchError((Object e) => AppLoggers.download.w('Local media endpoint: changing whether it listens failed', error: e));
  }

  /// The player has closed. The download continues unattended, or ends here if there is nothing left to do.
  void detach(String downloadId) {
    final s = _sessions[downloadId];
    if (s == null) return;
    s.attached = false;
    s.source.fetcher.playerAttached = false;
    if (s.source.state != SourceState.running && s.source.state != SourceState.idle) unawaited(_drop(downloadId));
  }

  /// The player has played [downloadId] to its end. A pass-through after a failed write drops what it kept for the way
  /// through: nothing ahead needs it, and a seek back is served from the server like any byte it did not keep.
  Future<void> ended(String downloadId) async {
    final s = _sessions[downloadId];
    if (s != null && s.source.state == SourceState.passThrough) await s.source.releaseStored();
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
    final token = (await ref.read(settingsProvider.future)).token;
    return token.isEmpty ? null : token;
  }

  Future<void> _drop(String id) async {
    final s = _sessions.remove(id);
    if (s == null) return;
    (await _endpoint)?.unregister(id);
    await s.source.dispose();
    if (s.source.state == SourceState.passThrough) await s.source.releaseStored();
    if (!ref.mounted) return;
    if (s.source.state != SourceState.complete) ref.read(localDTProvider.notifier).forget(id);
    state = {...state}..remove(id);
  }

  void _changed(String id) {
    if (!ref.mounted) return;
    final s = _sessions[id];
    if (s == null) return;
    _publish(s);
    state = {...state, id: s.source.state};
    if (s.source.state == SourceState.complete && !s.announced) {
      s.announced = true;
      // By *recording* identifier, which the family parameter is. Only what is shown needs re-reading: invalidating a
      // provider nobody watches would build it once for nothing.
      final rid = s.download.recordingId;
      final downloads = downloadsProvider(rid);
      if (ref.exists(downloads)) ref.invalidate(downloads);
      final recording = recordingProvider(rid);
      if (ref.exists(recording)) ref.invalidate(recording);
      if (ref.exists(mediaListProvider)) ref.invalidate(mediaListProvider);
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
    // While its server does not answer — tries failing, or answering with a portion and falling silent again — the
    // transfer shows as waiting to retry, with neither a speed nor a time remaining: the measured ones say nothing about
    // such a server. A stall that has not failed yet shows the speed decaying, and no time remaining.
    final waiting = src.isRunning && src.fetcher.notAnsweringFor != null;
    final measured = src.isRunning && !waiting && rate > 0;
    ref.read(localDTProvider.notifier).publish(LocalDownloadTask(
          id: s.download.id,
          displayName: s.download.title,
          filename: s.download.filename,
          status: switch (src.state) {
            SourceState.running => waiting ? TaskStatus.waitingToRetry : TaskStatus.running,
            SourceState.idle => TaskStatus.paused,
            SourceState.complete => TaskStatus.complete,
            SourceState.passThrough => TaskStatus.failed,
            SourceState.gone => TaskStatus.canceled,
          },
          progress: complete ? 1.0 : (length == null || length == 0 ? null : stored / length),
          networkSpeed: measured ? rate / 1e6 : null,
          timeRemaining: measured && src.fetcher.flowing && length != null ? Duration(seconds: ((length - stored) / rate).round()) : null,
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
