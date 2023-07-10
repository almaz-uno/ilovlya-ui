import 'package:json_annotation/json_annotation.dart';

part 'format.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class Format {
  String id;
  String ext;
  String resolution;
  int fps;
  bool hasAudio;
  bool hasVideo;

  Format({
    this.id = "",
    this.ext = "",
    this.resolution = "",
    this.fps = 0,
    this.hasAudio = false,
    this.hasVideo = false,
  });

  factory Format.fromJson(Map<String, dynamic> json) => _$FormatFromJson(json);
  Map<String, dynamic> toJson() => _$FormatToJson(this);

  static List<Format> fromJsonList(List<dynamic> json) {
    var infos = <Format>[];
    for (var v in json) {
      infos.add(Format.fromJson(v));
    }
    return infos;
  }
}
