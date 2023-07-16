import 'dart:convert';

import 'package:ilovlya/src/api/api.dart';
import 'package:http/http.dart' as http;
import 'package:ilovlya/src/model/download.dart';
import 'package:ilovlya/src/model/recording_info.dart';
import 'package:ilovlya/src/model/url_info.dart';

typedef HttpMethod = Future<http.Response> Function(Uri, {Map<String, String>? headers});

Future<URLInfo> getUrlInfo(String url) async {
  const path = '/api/url-info';
  final encodedURL = Uri.encodeComponent(url);
  var u = Uri.parse("${server()}$path?url=$encodedURL");
  var res = await http.get(u).timeout(requestTimeoutLong);

  // if (res.statusCode == 404) {
  //   throw notfou
  // } else
  if (res.statusCode >= 400) {
    throw Exception("unable to get propositions for $url. Status code is: ${res.statusCode}");
  }
  return URLInfo.fromJson(jsonDecode(res.body));
}

Future<RecordingInfo> addRecording(String url) async {
  const path = '/api/recordings';

  var res = await http
      .post(
        Uri.parse("${server()}$path"),
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

Future<List<RecordingInfo>> listRecordings(int offset, int limit) async {
  const path = '/api/recordings';

  var res = await http
      .get(
        Uri.parse("${server()}$path?offset=$offset&limit=$limit"),
      )
      .timeout(requestTimeout);

  if (res.statusCode >= 400) {
    throw Exception("unable to get list of recordings. Status code is: ${res.statusCode}");
  }
  return RecordingInfo.fromJsonList(jsonDecode(res.body));
}

Future<RecordingInfo> getRecording(String id, {bool updateFormats = true}) async {
  var path = '/api/recordings/$id?updateFormats=$updateFormats';

  var res = await http
      .get(
        Uri.parse("${server()}$path"),
      )
      .timeout(requestTimeout);

  if (res.statusCode >= 400) {
    throw Exception("unable to get recording with id=$id. Status code is: ${res.statusCode}");
  }
  return RecordingInfo.fromJson(jsonDecode(res.body));
}

Future<List<Download>> listDownloads(String recordingId) async {
  var path = '/api/recordings/$recordingId/downloads';

  var res = await http
      .get(
        Uri.parse("${server()}$path"),
      )
      .timeout(requestTimeout);

  if (res.statusCode >= 400) {
    throw Exception("unable to get list of downloads for $recordingId. Status code is: ${res.statusCode}");
  }
  return Download.fromJsonList(jsonDecode(res.body));
}

Future<Download> newDownload(String recordingId, String format) async {
  var path = '/api/recordings/$recordingId/downloads';

  var res = await http.post(
    Uri.parse("${server()}$path"),
    body: <String, String>{
      "format": format,
    },
  ).timeout(requestTimeout);

  if (res.statusCode >= 400) {
    throw Exception("unable to start downloading format $format for $recordingId. Status code is: ${res.statusCode}");
  }
  return Download.fromJson(jsonDecode(res.body));
}

Future<void> _hidden(String recordingId, HttpMethod httpMethod) async {
  var path = '/api/recordings/$recordingId/hidden';

  var res = await httpMethod(
    Uri.parse("${server()}$path"),
  ).timeout(requestTimeout);

  if (res.statusCode >= 400) {
    throw Exception("unable to set or unset hidden for $recordingId. Status code is: ${res.statusCode}");
  }
}

Future<void> setHidden(String recordingId) async {
  await _hidden(recordingId, http.put);
}

Future<void> unsetHidden(String recordingId) async {
  await _hidden(recordingId, http.delete);
}

Future<void> _seen(String recordingId, HttpMethod httpMethod) async {
  var path = '/api/recordings/$recordingId/seen';

  var res = await httpMethod(
    Uri.parse("${server()}$path"),
  ).timeout(requestTimeout);

  if (res.statusCode >= 400) {
    throw Exception("unable to set or unset seen for $recordingId. Status code is: ${res.statusCode}");
  }
}

Future<void> setSeen(String recordingId) async {
  await _seen(recordingId, http.put);
}

Future<void> unsetSeen(String recordingId) async {
  await _seen(recordingId, http.delete);
}

//g.PUT("/recordings/:id/position", cont.putPosition)
Future<void> putPosition(String recordingId, Duration position, bool finished) async {
  var path = '/api/recordings/$recordingId/position';

  var res = await http
      .put(
        Uri.parse("${server()}$path"),
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
