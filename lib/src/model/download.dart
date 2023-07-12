import 'package:json_annotation/json_annotation.dart';

part 'download.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class Download {
  String id;
  String recordingId;
  DateTime? createdAt;
  DateTime? updatedAt;
  String formatId;
  String url;
  String filename;
  String ext;
  String resolution;
  bool hasVideo;
  bool hasAudio;
  int size;
  String status;
  String progress;

  Download({
    this.id = "",
    this.recordingId = "",
    this.createdAt,
    this.updatedAt,
    this.formatId = "",
    this.url = "",
    this.filename = "",
    this.ext = "",
    this.resolution = "",
    this.hasVideo = false,
    this.hasAudio = false,
    this.size = 0,
    this.status = "",
    this.progress = "",
  });

  factory Download.fromJson(Map<String, dynamic> json) => _$DownloadFromJson(json);
  Map<String, dynamic> toJson() => _$DownloadToJson(this);

  static List<Download> fromJsonList(List<dynamic> json) {
    var infos = <Download>[];
    for (var v in json) {
      infos.add(Download.fromJson(v));
    }
    return infos;
  }
}
