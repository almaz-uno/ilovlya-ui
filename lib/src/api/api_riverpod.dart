import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:ilovlya/src/api/recording_riverpod.dart';
import 'package:ilovlya/src/utils/logger_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../model/download.dart';
import '../model/recording_info.dart';
import '../model/tenant.dart';
import '../model/url_info.dart';
import '../settings/settings_provider.dart';
import 'api.dart';
import 'exceptions.dart';

part 'api_riverpod.g.dart';

typedef HttpMethod = Future<http.Response> Function(Uri, {Map<String, String>? headers});

Map<String, String> getAuthHeader(Ref ref) {
  return <String, String>{"Authorization": ref.watch(settingsNotifierProvider.select((value) => value.requireValue.token))};
}

@riverpod
Future<URLInfo> getUrlInfo(Ref ref, String url) async {
  AppLoggers.api.d('Getting URL info: $url');

  final serverURL = ref.watch(settingsNotifierProvider.select((value) => value.requireValue.serverUrl));
  const path = '/api/url-info';
  final encodedURL = Uri.encodeComponent(url);
  final u = Uri.parse("$serverURL$path?url=$encodedURL");

  try {
    final res = await http.get(u, headers: getAuthHeader(ref)).timeout(requestTimeoutLong);

    AppLoggers.api.i('URL info response: statusCode=${res.statusCode}, bodyLength=${res.body.length}');

    if (res.statusCode >= 400) {
      throw HttpStatusError.by("Unable to get propositions for $url", res);
    }

    final urlInfo = URLInfo.fromJson(jsonDecode(utf8.decode(res.bodyBytes)));
    AppLoggers.api.d('URL info parsed successfully');
    return urlInfo;
  } catch (e, st) {
    AppLoggers.api.e('Failed to get URL info', error: e, stackTrace: st);
    rethrow;
  }
}

@riverpod
Future<RecordingInfo> addRecording(Ref ref, String url) async {
  AppLoggers.api.d('Adding recording: $url');

  final serverURL = ref.watch(settingsNotifierProvider.select((value) => value.requireValue.serverUrl));
  const path = '/api/recordings';

  try {
    final res = await http
        .post(
          Uri.parse("$serverURL$path"),
          headers: getAuthHeader(ref)
            ..addAll({
              'Content-Type': 'application/json; charset=UTF-8',
            }),
          body: jsonEncode(<String, String>{
            'url': url,
          }),
        )
        .timeout(requestTimeout);

    AppLoggers.api.i('Add recording response: statusCode=${res.statusCode}');

    if (res.statusCode >= 400) {
      throw HttpStatusError.by("Unable to post recording for $url", res);
    }

    final recordingInfo = RecordingInfo.fromJson(jsonDecode(utf8.decode(res.bodyBytes)));
    AppLoggers.api.i('Recording added successfully: id=${recordingInfo.id}');
    return recordingInfo;
  } catch (e, st) {
    AppLoggers.api.e('Failed to add recording', error: e, stackTrace: st);
    rethrow;
  }
}

@riverpod
Future<List<RecordingInfo>> listRecordings(Ref ref, int offset, int limit, {String sortBy = "created_at"}) async {
  AppLoggers.api.d('Listing recordings: offset=$offset, limit=$limit, sortBy=$sortBy');

  final serverURL = ref.watch(settingsNotifierProvider.select((value) => value.requireValue.serverUrl));
  const path = '/api/recordings';

  try {
    final res = await http.get(Uri.parse("$serverURL$path?offset=$offset&limit=$limit&sort_by=$sortBy"), headers: getAuthHeader(ref)).timeout(requestTimeout);

    AppLoggers.api.i('List recordings response: statusCode=${res.statusCode}');

    if (res.statusCode >= 400) {
      throw HttpStatusError.by("Unable to get list of recordings", res);
    }

    final recordings = RecordingInfo.fromJsonList(jsonDecode(utf8.decode(res.bodyBytes)));
    for (final r in recordings) {
      r.thumbnailUrl = serverURL + r.thumbnailUrl;
    }

    AppLoggers.api.i('Recordings loaded successfully: count=${recordings.length}');
    return recordings;
  } catch (e, st) {
    AppLoggers.api.e('Failed to list recordings', error: e, stackTrace: st);
    rethrow;
  }
}

@riverpod
Future<RecordingInfo> getRecording(Ref ref, String id) async {
  final serverURL = ref.watch(settingsNotifierProvider.select((value) => value.requireValue.serverUrl));
  final path = '/api/recordings/$id';

  final res = await http.get(Uri.parse("$serverURL$path"), headers: getAuthHeader(ref)).timeout(requestTimeout);

  if (res.statusCode >= 400) {
    throw HttpStatusError.by("Unable to get recording with id=$id", res);
  }
  final recording = RecordingInfo.fromJson(jsonDecode(utf8.decode(res.bodyBytes)));
  recording.thumbnailUrl = serverURL + recording.thumbnailUrl;
  return recording;
}

@riverpod
Future<Download> getDownload(Ref ref, String id) async {
  final serverURL = ref.watch(settingsNotifierProvider.select((value) => value.requireValue.serverUrl));
  final path = '/api/recordings/downloads/$id';

  final res = await http.get(Uri.parse("$serverURL$path"), headers: getAuthHeader(ref)).timeout(requestTimeout);

  if (res.statusCode >= 400) {
    throw HttpStatusError.by("Unable to get download with id=$id", res);
  }
  final download = Download.fromJson(jsonDecode(utf8.decode(res.bodyBytes)));
  download.url = serverURL + download.url;
  return download;
}

@riverpod
Future<List<Download>> listDownloads(Ref ref, String recordingId) async {
  final serverURL = ref.watch(settingsNotifierProvider.select((value) => value.requireValue.serverUrl));

  final path = '/api/recordings/$recordingId/downloads';

  final res = await http.get(Uri.parse("$serverURL$path"), headers: getAuthHeader(ref)).timeout(requestTimeout);

  if (res.statusCode >= 400) {
    throw HttpStatusError.by("Unable to get list of downloads for $recordingId", res);
  }

  final downloads = Download.fromJsonList(jsonDecode(utf8.decode(res.bodyBytes)));
  for (final d in downloads) {
    d.url = serverURL + d.url;
  }
  return downloads;
}

@riverpod
Future<Download> newDownload(Ref ref, String recordingId, String format) async {
  final serverURL = ref.watch(settingsNotifierProvider.select((value) => value.requireValue.serverUrl));
  final path = '/api/recordings/$recordingId/downloads';

  final res = await http
      .post(
        Uri.parse("$serverURL$path"),
        body: <String, String>{
          "format": format,
        },
        headers: getAuthHeader(ref),
      )
      .timeout(requestTimeout);

  if (res.statusCode >= 400) {
    throw HttpStatusError.by("Unable to start downloading format $format for $recordingId", res);
  }
  return Download.fromJson(jsonDecode(utf8.decode(res.bodyBytes)));
}

@riverpod
Future<void> setHidden(Ref ref, String recordingId) async {
  final serverURL = ref.watch(settingsNotifierProvider.select((value) => value.requireValue.serverUrl));
  await _hidden(serverURL, recordingId, http.put, getAuthHeader(ref));
}

@riverpod
Future<void> unsetHidden(Ref ref, String recordingId) async {
  final serverURL = ref.watch(settingsNotifierProvider.select((value) => value.requireValue.serverUrl));
  await _hidden(serverURL, recordingId, http.delete, getAuthHeader(ref));
}

Future<void> _hidden(String serverURL, String recordingId, HttpMethod httpMethod, Map<String, String> headers) async {
  final path = '/api/recordings/$recordingId/hidden';

  final res = await httpMethod(
    Uri.parse("$serverURL$path"),
    headers: headers,
  ).timeout(requestTimeout);

  if (res.statusCode >= 400) {
    throw HttpStatusError.by("Unable to set or unset hidden for $recordingId", res);
  }
}

Future<void> _seen(String serverURL, String recordingId, HttpMethod httpMethod, Map<String, String> headers) async {
  final path = '/api/recordings/$recordingId/seen';

  final res = await httpMethod(
    Uri.parse("$serverURL$path"),
    headers: headers,
  ).timeout(requestTimeout);

  if (res.statusCode >= 400) {
    throw HttpStatusError.by("Unable to set or unset seen for $recordingId", res);
  }
}

@riverpod
Future<void> setSeen(Ref ref, String recordingId) async {
  ref.read(recordingNotifierProvider(recordingId).notifier).putPosition(null, true);
  final serverURL = ref.watch(settingsNotifierProvider.select((value) => value.requireValue.serverUrl));
  await _seen(serverURL, recordingId, http.put, getAuthHeader(ref));
}

@riverpod
Future<void> unsetSeen(Ref ref, String recordingId) async {
  ref.read(recordingNotifierProvider(recordingId).notifier).putPosition(null, false);
  final serverURL = ref.watch(settingsNotifierProvider.select((value) => value.requireValue.serverUrl));
  await _seen(serverURL, recordingId, http.delete, getAuthHeader(ref));
}

//g.PUT("/recordings/:id/position", cont.putPosition)
@riverpod
Future<void> putPosition(Ref ref, String recordingId, Duration position, bool finished) async {

  final serverURL = ref.watch(settingsNotifierProvider.select((value) => value.requireValue.serverUrl));
  final path = '/api/recordings/$recordingId/position';

  final res = await http
      .put(
        Uri.parse("$serverURL$path"),
        headers: getAuthHeader(ref)
          ..addAll({
            'Content-Type': 'application/json; charset=UTF-8',
          }),
        body: jsonEncode(<String, dynamic>{
          'position': position.inSeconds,
          'finished': finished,
        }),
      )
      .timeout(const Duration(seconds: 5));

  if (res.statusCode >= 400) {
    throw HttpStatusError.by("Unable to post position $position for $recordingId", res);
  }
}

@riverpod
Future<Tenant> getTenant(Ref ref) async {
  final serverURL = ref.watch(settingsNotifierProvider.select((value) => value.requireValue.serverUrl));
  const path = '/api/tenant';

  final res = await http.get(Uri.parse("$serverURL$path"), headers: getAuthHeader(ref)).timeout(requestTimeout);

  if (res.statusCode >= 400) {
    throw HttpStatusError.by("Unable to get tenant info", res);
  }
  return Tenant.fromJson(jsonDecode(utf8.decode(res.bodyBytes)));
}

@riverpod
Future<void> deleteDownloadContent(Ref ref, String downloadId) async {
  final serverURL = ref.watch(settingsNotifierProvider.select((value) => value.requireValue.serverUrl));
  final path = '/api/recordings/downloads/$downloadId/content';
  final res = await http.delete(Uri.parse("$serverURL$path"), headers: getAuthHeader(ref)).timeout(requestTimeout);
  if (res.statusCode >= 400) {
    throw HttpStatusError.by("Unable to delete content for download $downloadId", res);
  }
}

@riverpod
Future<void> deleteRecordingDownloadsContent(Ref ref, String recordingId) async {
  final serverURL = ref.watch(settingsNotifierProvider.select((value) => value.requireValue.serverUrl));
  final path = '/api/recordings/$recordingId/content';
  final res = await http.delete(Uri.parse("$serverURL$path"), headers: getAuthHeader(ref)).timeout(requestTimeout);
  if (res.statusCode >= 400) {
    throw HttpStatusError.by("Unable to delete content all downloads for recording $recordingId", res);
  }
}
