// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recording_info.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RecordingInfo _$RecordingInfoFromJson(Map<String, dynamic> json) =>
    RecordingInfo(
      id: json['id'] as String? ?? "",
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
      webpageUrl: json['webpage_url'] as String? ?? "",
      title: json['title'] as String? ?? "",
      uploader: json['uploader'] as String? ?? "",
      position: json['position'] as int? ?? 0,
      duration: json['duration'] as int? ?? 0,
      extractor: json['extractor'] as String? ?? "",
      thumbnailUrl: json['thumbnail_url'] as String? ?? "",
      thumbnailDataUrl: json['thumbnail_data_url'] as String?,
      seenAt: json['seen_at'] == null
          ? null
          : DateTime.parse(json['seen_at'] as String),
      hiddenAt: json['hidden_at'] == null
          ? null
          : DateTime.parse(json['hidden_at'] as String),
      formats: (json['formats'] as List<dynamic>?)
          ?.map((e) => Format.fromJson(e as Map<String, dynamic>))
          .toList(),
      hasFile: json['has_file'] as bool? ?? false,
      files:
          (json['files'] as List<dynamic>?)?.map((e) => e as String).toList() ??
              const [],
      downloads: (json['downloads'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
    );

Map<String, dynamic> _$RecordingInfoToJson(RecordingInfo instance) =>
    <String, dynamic>{
      'id': instance.id,
      'created_at': instance.createdAt?.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
      'webpage_url': instance.webpageUrl,
      'title': instance.title,
      'uploader': instance.uploader,
      'position': instance.position,
      'duration': instance.duration,
      'extractor': instance.extractor,
      'thumbnail_url': instance.thumbnailUrl,
      'thumbnail_data_url': instance.thumbnailDataUrl,
      'seen_at': instance.seenAt?.toIso8601String(),
      'hidden_at': instance.hiddenAt?.toIso8601String(),
      'formats': instance.formats,
      'has_file': instance.hasFile,
      'files': instance.files,
      'downloads': instance.downloads,
    };
