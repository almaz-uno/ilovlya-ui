// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recording_info.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RecordingInfo _$RecordingInfoFromJson(Map<String, dynamic> json) =>
    RecordingInfo(
      id: json['id'] as String? ?? "",
      webpageUrl: json['webpage_url'] as String? ?? "",
      title: json['title'] as String? ?? "",
      uploader: json['uploader'] as String? ?? "",
      position: json['position'] as int? ?? 0,
      duration: json['duration'] as int? ?? 0,
      extractor: json['extractor'] as String? ?? "",
      thumbnail: json['thumbnail'] as String?,
      thumbnailDataUrl: json['thumbnail_data_url'] as String?,
      formats: (json['formats'] as List<dynamic>?)
          ?.map((e) => Format.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$RecordingInfoToJson(RecordingInfo instance) =>
    <String, dynamic>{
      'id': instance.id,
      'webpage_url': instance.webpageUrl,
      'title': instance.title,
      'uploader': instance.uploader,
      'position': instance.position,
      'duration': instance.duration,
      'extractor': instance.extractor,
      'thumbnail': instance.thumbnail,
      'thumbnail_data_url': instance.thumbnailDataUrl,
      'formats': instance.formats,
    };
