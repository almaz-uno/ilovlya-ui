import 'package:background_downloader/background_downloader.dart';
import 'package:json_annotation/json_annotation.dart';

part 'local_download.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class LocalDownloadTask {
  String id;
  String displayName;
  String filename;
  TaskStatus? status;
  double? progress;
  double? networkSpeed; // in MB/s
  Duration? timeRemaining;

  LocalDownloadTask({
    required this.id ,
    required this.displayName,
    required this.filename,
    this.status,
    this.progress,
    this.networkSpeed,
    this.timeRemaining,
  });

  factory LocalDownloadTask.fromJson(Map<String, dynamic> json) => _$LocalDownloadTaskFromJson(json);
  Map<String, dynamic> toJson() => _$LocalDownloadTaskToJson(this);

  static List<LocalDownloadTask> fromJsonList(List<dynamic> json) {
    var infos = <LocalDownloadTask>[];
    for (var v in json) {
      infos.add(LocalDownloadTask.fromJson(v));
    }
    return infos;
  }
}
