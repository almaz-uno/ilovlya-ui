import 'dart:convert';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:http/http.dart' as http;
import '../model/download.dart';
import '../model/recording_info.dart';
import '../model/url_info.dart';
import '../settings/settings_provider.dart';
import 'api.dart';

part 'api_riverpod.g.dart';

typedef HttpMethod = Future<http.Response> Function(Uri, {Map<String, String>? headers});

@riverpod
Future<URLInfo> getUrlInfo(GetUrlInfoRef ref, String url) async {
  final serverURL = ref.watch(settingsNotifierProvider.select((value) => value.requireValue.serverUrl));
  const path = '/api/url-info';
  final encodedURL = Uri.encodeComponent(url);
  var u = Uri.parse("$serverURL$path?url=$encodedURL");
  var res = await http.get(u).timeout(requestTimeoutLong);

  if (res.statusCode >= 400) {
    throw Exception("unable to get propositions for $url. Status code is: ${res.statusCode}");
  }
  return URLInfo.fromJson(jsonDecode(res.body));
}

@riverpod
Future<RecordingInfo> addRecording(AddRecordingRef ref, String url) async {
  final serverURL = ref.watch(settingsNotifierProvider.select((value) => value.requireValue.serverUrl));
  const path = '/api/recordings';

  var res = await http
      .post(
        Uri.parse("$serverURL$path"),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          'url': url,
        }),
      )
      .timeout(requestTimeout);

  if (res.statusCode >= 400) {
    throw Exception("unable to post recording for $url. Status code is: ${res.statusCode}");
  }
  return RecordingInfo.fromJson(jsonDecode(res.body));
}

@riverpod
Future<List<RecordingInfo>> listRecordings(ListRecordingsRef ref, int offset, int limit, {String sortBy = "created_at"}) async {
  final serverURL = ref.watch(settingsNotifierProvider.select((value) => value.requireValue.serverUrl));
  const path = '/api/recordings';

  var res = await http.get(Uri.parse("$serverURL$path?offset=$offset&limit=$limit&sort_by=$sortBy")).timeout(requestTimeout);

  if (res.statusCode >= 400) {
    throw Exception("unable to get list of recordings. Status code is: ${res.statusCode}");
  }
  final recordings = RecordingInfo.fromJsonList(jsonDecode(res.body));
  for (var r in recordings) {
    r.thumbnailUrl = serverURL + r.thumbnailUrl;
  }
  return recordings;
}

@riverpod
Future<RecordingInfo> getRecording(GetRecordingRef ref, String id) async {
  final serverURL = ref.watch(settingsNotifierProvider.select((value) => value.requireValue.serverUrl));
  var path = '/api/recordings/$id';

  var res = await http.get(Uri.parse("$serverURL$path")).timeout(requestTimeout);

  if (res.statusCode >= 400) {
    throw Exception("unable to get recording with id=$id. Status code is: ${res.statusCode}");
  }
  final recording = RecordingInfo.fromJson(jsonDecode(res.body));
  recording.thumbnailUrl = serverURL + recording.thumbnailUrl;
  return recording;
}

@riverpod
Future<Download> getDownload(GetDownloadRef ref, String id) async {
  final serverURL = ref.watch(settingsNotifierProvider.select((value) => value.requireValue.serverUrl));
  var path = '/api/recordings/downloads/$id';

  var res = await http.get(Uri.parse("$serverURL$path")).timeout(requestTimeout);

  if (res.statusCode >= 400) {
    throw Exception("unable to get download with id=$id. Status code is: ${res.statusCode}");
  }
  final download = Download.fromJson(jsonDecode(res.body));
  download.url = serverURL + download.url;
  return download;
}

@riverpod
Future<List<Download>> listDownloads(ListDownloadsRef ref, String recordingId) async {
  final serverURL = ref.watch(settingsNotifierProvider.select((value) => value.requireValue.serverUrl));
  var path = '/api/recordings/$recordingId/downloads';

  var res = await http.get(Uri.parse("$serverURL$path")).timeout(requestTimeout);

  if (res.statusCode >= 400) {
    throw Exception("unable to get list of downloads for $recordingId. Status code is: ${res.statusCode}");
  }

  final downloads = Download.fromJsonList(jsonDecode(res.body));
  for (var d in downloads) {
    d.url = serverURL + d.url;
  }
  return downloads;
}

@riverpod
Future<Download> newDownload(NewDownloadRef ref, String recordingId, String format) async {
  final serverURL = ref.watch(settingsNotifierProvider.select((value) => value.requireValue.serverUrl));
  var path = '/api/recordings/$recordingId/downloads';

  var res = await http.post(
    Uri.parse("$serverURL$path"),
    body: <String, String>{
      "format": format,
    },
  ).timeout(requestTimeout);

  if (res.statusCode >= 400) {
    throw Exception("unable to start downloading format $format for $recordingId. Status code is: ${res.statusCode}");
  }
  return Download.fromJson(jsonDecode(res.body));
}

@riverpod
Future<void> setHidden(SetHiddenRef ref, String recordingId) async {
  final serverURL = ref.watch(settingsNotifierProvider.select((value) => value.requireValue.serverUrl));
  await _hidden(serverURL, recordingId, http.put);
}

@riverpod
Future<void> unsetHidden(UnsetHiddenRef ref, String recordingId) async {
  final serverURL = ref.watch(settingsNotifierProvider.select((value) => value.requireValue.serverUrl));
  await _hidden(serverURL, recordingId, http.delete);
}

Future<void> _hidden(String serverURL, String recordingId, HttpMethod httpMethod) async {
  var path = '/api/recordings/$recordingId/hidden';

  var res = await httpMethod(
    Uri.parse("$serverURL$path"),
  ).timeout(requestTimeout);

  if (res.statusCode >= 400) {
    throw Exception("unable to set or unset hidden for $recordingId. Status code is: ${res.statusCode}");
  }
}

Future<void> _seen(String serverURL, String recordingId, HttpMethod httpMethod) async {
  var path = '/api/recordings/$recordingId/seen';

  var res = await httpMethod(
    Uri.parse("$serverURL$path"),
  ).timeout(requestTimeout);

  if (res.statusCode >= 400) {
    throw Exception("unable to set or unset seen for $recordingId. Status code is: ${res.statusCode}");
  }
}

@riverpod
Future<void> setSeen(SetSeenRef ref, String recordingId) async {
  final serverURL = ref.watch(settingsNotifierProvider.select((value) => value.requireValue.serverUrl));
  await _seen(serverURL, recordingId, http.put);
}

@riverpod
Future<void> unsetSeen(UnsetSeenRef ref, String recordingId) async {
  final serverURL = ref.watch(settingsNotifierProvider.select((value) => value.requireValue.serverUrl));
  await _seen(serverURL, recordingId, http.delete);
}

//g.PUT("/recordings/:id/position", cont.putPosition)
@riverpod
Future<void> putPosition(PutPositionRef ref, String recordingId, Duration position, bool finished) async {
  final serverURL = ref.watch(settingsNotifierProvider.select((value) => value.requireValue.serverUrl));
  var path = '/api/recordings/$recordingId/position';

  var res = await http
      .put(
        Uri.parse("$serverURL$path"),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, dynamic>{
          'position': position.inSeconds,
          'finished': finished,
        }),
      )
      .timeout(const Duration(seconds: 5));

  if (res.statusCode >= 400) {
    throw Exception("unable to post position $position for $recordingId. Status code is: ${res.statusCode}");
  }
}
