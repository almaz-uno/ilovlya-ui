import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:ilovlya/src/api/api.dart';
import 'package:ilovlya/src/api/api_riverpod.dart';
import 'package:ilovlya/src/api/exceptions.dart';
import 'package:ilovlya/src/settings/settings_provider.dart';
import 'package:ilovlya/src/utils/logger_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'tv_models.dart';

part 'tv_api.g.dart';

/// How often the control surface asks the server what the television is doing.
/// Commands travel as their own requests, so this only refreshes what is shown.
const tvPollPeriod = Duration(seconds: 1);

const _pathSessions = "/api/tv/sessions";
const _pathPair = "/api/tv/pair";

String _serverURL(Ref ref) => ref.watch(settingsNotifierProvider.select((value) => value.requireValue.serverUrl));

Map<String, String> _jsonHeaders(Ref ref) => {...getAuthHeader(ref), "Content-Type": "application/json"};

/// Pairs the code shown on a television with this tenant. The server answers
/// 404 for an unknown, spent or expired code alike.
@riverpod
Future<TvSession> pairTv(Ref ref, String code) async {
  AppLoggers.api.d('Pairing a tv receiver');

  final res = await http.post(Uri.parse("${_serverURL(ref)}$_pathPair"), headers: _jsonHeaders(ref), body: jsonEncode({"code": code})).timeout(requestTimeout);

  if (res.statusCode >= 400) {
    throw HttpStatusError.by("Unable to pair with the code", res);
  }

  return TvSession.fromJson(jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>);
}

/// Sessions of this tenant that have not ended.
@riverpod
Future<List<TvSession>> tvSessions(Ref ref) async {
  final res = await http.get(Uri.parse("${_serverURL(ref)}$_pathSessions"), headers: getAuthHeader(ref)).timeout(requestTimeout);

  if (res.statusCode >= 400) {
    throw HttpStatusError.by("Unable to list tv sessions", res);
  }

  final list = jsonDecode(utf8.decode(res.bodyBytes)) as List<dynamic>;
  return list.map((e) => TvSession.fromJson(e as Map<String, dynamic>)).toList();
}

Future<TvSession> _getSession(String serverURL, Map<String, String> headers, String sessionId) async {
  final res = await http.get(Uri.parse("$serverURL$_pathSessions/$sessionId"), headers: headers).timeout(requestTimeout);

  if (res.statusCode >= 400) {
    throw HttpStatusError.by("Unable to get the tv session", res);
  }

  return TvSession.fromJson(jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>);
}

/// The state of one session, refreshed while somebody is looking at it. The
/// timer is cancelled with the provider, so a closed sheet stops polling.
@riverpod
class TvSessionState extends _$TvSessionState {
  Timer? _timer;

  @override
  Future<TvSession> build(String sessionId) async {
    final serverURL = _serverURL(ref);
    final headers = getAuthHeader(ref);

    _timer?.cancel();
    _timer = Timer.periodic(tvPollPeriod, (_) async {
      try {
        final session = await _getSession(serverURL, headers, sessionId);
        state = AsyncData(session);
      } catch (e, st) {
        AppLoggers.api.w('Failed to poll the tv session', error: e, stackTrace: st);
        state = AsyncError(e, st);
      }
    });

    ref.onDispose(() {
      _timer?.cancel();
      _timer = null;
    });

    return _getSession(serverURL, headers, sessionId);
  }

  /// Sends a command and adopts the session the server answers with. The answer
  /// says the command was handed to a connected receiver, not that playback
  /// already changed; the effect arrives with the next poll.
  Future<void> command(TvCommand cmd) async {
    final serverURL = _serverURL(ref);

    final res = await http
        .post(Uri.parse("$serverURL$_pathSessions/$sessionId/commands"), headers: _jsonHeaders(ref), body: jsonEncode(cmd.toJson()))
        .timeout(requestTimeout);

    if (res.statusCode >= 400) {
      throw HttpStatusError.by("Unable to command the tv receiver", res);
    }

    state = AsyncData(TvSession.fromJson(jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>));
  }

  /// Ends the session: the television goes back to showing a pairing code.
  Future<void> end() async {
    final res = await http.delete(Uri.parse("${_serverURL(ref)}$_pathSessions/$sessionId"), headers: getAuthHeader(ref)).timeout(requestTimeout);

    if (res.statusCode >= 400) {
      throw HttpStatusError.by("Unable to end the tv session", res);
    }

    _timer?.cancel();
  }
}
