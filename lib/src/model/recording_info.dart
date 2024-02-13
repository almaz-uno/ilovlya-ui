import 'package:ilovlya/src/model/download.dart';
import 'package:ilovlya/src/model/format.dart';
import 'package:json_annotation/json_annotation.dart';

part 'recording_info.g.dart';

final zero = DateTime.fromMillisecondsSinceEpoch(0);

@JsonSerializable(fieldRename: FieldRename.snake)
class RecordingInfo {
  String id;
  DateTime? createdAt;
  DateTime? updatedAt;
  String webpageUrl;
  String title;
  String uploader;
  int position;
  int duration;
  String extractor;
  String thumbnailUrl;
  String? thumbnailDataUrl;
  DateTime? seenAt;
  DateTime? hiddenAt;
  List<Format>? formats;
  bool hasFile;
  List<String> files;
  @JsonKey(includeFromJson: false, includeToJson: false)
  bool hasLocalFile;
  List<String> downloads;

  RecordingInfo({
    this.id = "",
    this.createdAt,
    this.updatedAt,
    this.webpageUrl = "",
    this.title = "",
    this.uploader = "",
    this.position = 0,
    this.duration = 0,
    this.extractor = "",
    this.thumbnailUrl = "",
    this.thumbnailDataUrl,
    this.seenAt,
    this.hiddenAt,
    this.formats,
    this.hasFile = false,
    this.files = const [],
    this.hasLocalFile = false,
    this.downloads = const [],
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
