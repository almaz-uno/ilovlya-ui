import 'package:ilovlya/src/model/format.dart';
import 'package:json_annotation/json_annotation.dart';

part 'recording_info.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class RecordingInfo {
  String id;
  String webpageUrl;
  String title;
  String uploader;
  int position;
  int duration;
  String extractor;
  String? thumbnail;
  String? thumbnailDataUrl;
  List<Format>? formats;

  RecordingInfo({
    this.id = "",
    this.webpageUrl = "",
    this.title = "",
    this.uploader = "",
    this.position = 0,
    this.duration = 0,
    this.extractor = "",
    this.thumbnail,
    this.thumbnailDataUrl,
    this.formats,
  });

  factory RecordingInfo.fromJson(Map<String, dynamic> json) => _$RecordingInfoFromJson(json);
  Map<String, dynamic> toJson() => _$RecordingInfoToJson(this);

  static List<RecordingInfo> fromJsonList(List<dynamic> json) {
    var infos = <RecordingInfo>[];
    for (var v in json) {
      infos.add(RecordingInfo.fromJson(v));
    }
    return infos;
  }
}
