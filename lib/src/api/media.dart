import 'dart:convert';

import 'package:ilovlya/src/api/api.dart';
import 'package:http/http.dart' as http;
import 'package:ilovlya/src/model/recording_info.dart';
import 'package:ilovlya/src/model/url_info.dart';

Future<URLInfo> getUrlInfo(String url) async {
  const path = '/api/url-info';
  final encodedURL = Uri.encodeComponent(url);
  var u = Uri.parse("${server()}$path?url=$encodedURL");
  var res = await http.get(u).timeout(requestTimeout);

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
        Uri.parse("${server()}$path"),
      )
      .timeout(requestTimeout);

  if (res.statusCode >= 400) {
    throw Exception("unable to get list recordings. Status code is: ${res.statusCode}");
  }
  return RecordingInfo.fromJsonList(jsonDecode(res.body));
}

Future<RecordingInfo> getRecording(String id) async {
  var path = '/api/recordings/$id';

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
