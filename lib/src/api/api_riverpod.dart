import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:ilovlya/src/api/recording_riverpod.dart';
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

Map<String, String> getAuthHeader(AutoDisposeRef ref) {
  return <String, String>{"Authorization": ref.watch(settingsNotifierProvider.select((value) => value.requireValue.token))};
}

@riverpod
Future<URLInfo> getUrlInfo(GetUrlInfoRef ref, String url) async {
  final serverURL = ref.watch(settingsNotifierProvider.select((value) => value.requireValue.serverUrl));
  const path = '/api/url-info';
  final encodedURL = Uri.encodeComponent(url);
  final u = Uri.parse("$serverURL$path?url=$encodedURL");
  final res = await http.get(u, headers: getAuthHeader(ref)).timeout(requestTimeoutLong);

  if (res.statusCode >= 400) {
    throw HttpStatusError.by("Unable to get propositions for $url", res);
  }
  return URLInfo.fromJson(jsonDecode(res.body));
}

@riverpod
Future<RecordingInfo> addRecording(AddRecordingRef ref, String url) async {
  final serverURL = ref.watch(settingsNotifierProvider.select((value) => value.requireValue.serverUrl));
  const path = '/api/recordings';

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

  if (res.statusCode >= 400) {
    throw HttpStatusError.by("Unable to post recording for $url", res);
  }
  return RecordingInfo.fromJson(jsonDecode(res.body));
}

@riverpod
Future<List<RecordingInfo>> listRecordings(ListRecordingsRef ref, int offset, int limit, {String sortBy = "created_at"}) async {
  final serverURL = ref.watch(settingsNotifierProvider.select((value) => value.requireValue.serverUrl));
  const path = '/api/recordings';

  final res = await http.get(Uri.parse("$serverURL$path?offset=$offset&limit=$limit&sort_by=$sortBy"), headers: getAuthHeader(ref)).timeout(requestTimeout);

  if (res.statusCode >= 400) {
    throw HttpStatusError.by("Unable to get list of recordings", res);
  }
  final recordings = RecordingInfo.fromJsonList(jsonDecode(res.body));
  for (final r in recordings) {
    r.thumbnailUrl = serverURL + r.thumbnailUrl;
  }
  return recordings;
}

@riverpod
Future<RecordingInfo> getRecording(GetRecordingRef ref, String id) async {
  final serverURL = ref.watch(settingsNotifierProvider.select((value) => value.requireValue.serverUrl));
  final path = '/api/recordings/$id';

  final res = await http.get(Uri.parse("$serverURL$path"), headers: getAuthHeader(ref)).timeout(requestTimeout);

  if (res.statusCode >= 400) {
    throw HttpStatusError.by("Unable to get recording with id=$id", res);
  }
  final recording = RecordingInfo.fromJson(jsonDecode(res.body));
  recording.thumbnailUrl = serverURL + recording.thumbnailUrl;
  return recording;
}

@riverpod
Future<Download> getDownload(GetDownloadRef ref, String id) async {
  final serverURL = ref.watch(settingsNotifierProvider.select((value) => value.requireValue.serverUrl));
  final path = '/api/recordings/downloads/$id';

  final res = await http.get(Uri.parse("$serverURL$path"), headers: getAuthHeader(ref)).timeout(requestTimeout);

  if (res.statusCode >= 400) {
    throw HttpStatusError.by("Unable to get download with id=$id", res);
  }
  final download = Download.fromJson(jsonDecode(res.body));
  download.url = serverURL + download.url;
  return download;
}

@riverpod
Future<List<Download>> listDownloads(ListDownloadsRef ref, String recordingId) async {
  final serverURL = ref.watch(settingsNotifierProvider.select((value) => value.requireValue.serverUrl));

  final path = '/api/recordings/$recordingId/downloads';

  final res = await http.get(Uri.parse("$serverURL$path"), headers: getAuthHeader(ref)).timeout(requestTimeout);

  if (res.statusCode >= 400) {
    throw HttpStatusError.by("Unable to get list of downloads for $recordingId", res);
  }

  final downloads = Download.fromJsonList(jsonDecode(res.body));
  for (final d in downloads) {
    d.url = serverURL + d.url;
  }
  return downloads;
}

@riverpod
Future<Download> newDownload(NewDownloadRef ref, String recordingId, String format) async {
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
  return Download.fromJson(jsonDecode(res.body));
}

@riverpod
Future<void> setHidden(SetHiddenRef ref, String recordingId) async {
  final serverURL = ref.watch(settingsNotifierProvider.select((value) => value.requireValue.serverUrl));
  await _hidden(serverURL, recordingId, http.put, getAuthHeader(ref));
}

@riverpod
Future<void> unsetHidden(UnsetHiddenRef ref, String recordingId) async {
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
Future<void> setSeen(SetSeenRef ref, String recordingId) async {
  ref.read(recordingNotifierProvider(recordingId).notifier).putPosition(null, true);
  final serverURL = ref.watch(settingsNotifierProvider.select((value) => value.requireValue.serverUrl));
  await _seen(serverURL, recordingId, http.put, getAuthHeader(ref));
}

@riverpod
Future<void> unsetSeen(UnsetSeenRef ref, String recordingId) async {
  ref.read(recordingNotifierProvider(recordingId).notifier).putPosition(null, false);
  final serverURL = ref.watch(settingsNotifierProvider.select((value) => value.requireValue.serverUrl));
  await _seen(serverURL, recordingId, http.delete, getAuthHeader(ref));
}

//g.PUT("/recordings/:id/position", cont.putPosition)
@riverpod
Future<void> putPosition(PutPositionRef ref, String recordingId, Duration position, bool finished) async {

  ref.read(recordingNotifierProvider(recordingId).notifier).putPosition(position, finished);

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
Future<Tenant> getTenant(GetTenantRef ref) async {
  final serverURL = ref.watch(settingsNotifierProvider.select((value) => value.requireValue.serverUrl));
  const path = '/api/tenant';

  final res = await http.get(Uri.parse("$serverURL$path"), headers: getAuthHeader(ref)).timeout(requestTimeout);

  if (res.statusCode >= 400) {
    throw HttpStatusError.by("Unable to get tenant info", res);
  }
  return Tenant.fromJson(jsonDecode(res.body));
}

@riverpod
Future<void> deleteDownloadContent(DeleteDownloadContentRef ref, String downloadId) async {
  final serverURL = ref.watch(settingsNotifierProvider.select((value) => value.requireValue.serverUrl));
  final path = '/api/recordings/downloads/$downloadId/content';
  final res = await http.delete(Uri.parse("$serverURL$path"), headers: getAuthHeader(ref)).timeout(requestTimeout);
  if (res.statusCode >= 400) {
    throw HttpStatusError.by("Unable to delete content for download $downloadId", res);
  }
}

@riverpod
Future<void> deleteRecordingDownloadsContent(DeleteRecordingDownloadsContentRef ref, String recordingId) async {
  final serverURL = ref.watch(settingsNotifierProvider.select((value) => value.requireValue.serverUrl));
  final path = '/api/recordings/$recordingId/content';
  final res = await http.delete(Uri.parse("$serverURL$path"), headers: getAuthHeader(ref)).timeout(requestTimeout);
  if (res.statusCode >= 400) {
    throw HttpStatusError.by("Unable to delete content all downloads for recording $recordingId", res);
  }
}
