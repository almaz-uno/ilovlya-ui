import 'package:ilovlya/src/model/recording_info.dart';
import 'package:json_annotation/json_annotation.dart';

part 'url_info.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class URLInfo {
  String? url;
  List<RecordingInfo>? infos;

  URLInfo({
    this.url,
    this.infos,
  });

  factory URLInfo.fromJson(Map<String, dynamic> json) => _$URLInfoFromJson(json);
  Map<String, dynamic> toJson() => _$URLInfoToJson(this);
}
