import 'dart:convert';

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
  int? fps;
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
    this.fps,
    this.hasVideo = false,
    this.hasAudio = false,
    this.size = 0,
    this.status = "",
    this.progress = "",
  });

  static final re = RegExp(r'\d+\.{0,1}\d+');
  static const splitter = LineSplitter();

  double? progressByLastLine() {
    var ll = splitter.convert(progress);
    if (ll.isEmpty) {
      return null;
    }
    var lastLine = ll[ll.length - 1];
    var fm = re.firstMatch(lastLine);
    if (fm == null) {
      return null;
    }
    return double.parse(fm.group(0)!) / 100.0;
  }

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
