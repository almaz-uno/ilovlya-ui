import 'package:http/http.dart';

class HttpStatusError implements Exception {
  int statusCode;
  String reasonPhrase;
  String message;
  String method;
  String url;
  String? body;

  HttpStatusError({
    required this.statusCode,
    this.reasonPhrase = "",
    required this.message,
    this.url = "",
    this.method = "",
    this.body,
  });

  factory HttpStatusError.by(String message, BaseResponse response) {
    return HttpStatusError(
      statusCode: response.statusCode,
      reasonPhrase: response.reasonPhrase ?? "",
      message: message,
      method: response.request?.method ?? "",
      url: response.request?.url.toString() ?? "",
      body: (response is Response) ? response.body : "",
    );
  }

  @override
  String toString() {
    return "$message. $statusCode $reasonPhrase for $method $url";
  }
}
