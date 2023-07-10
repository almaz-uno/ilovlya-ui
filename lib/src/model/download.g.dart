// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'download.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Download _$DownloadFromJson(Map<String, dynamic> json) => Download(
      id: json['id'] as String? ?? "",
      recordingId: json['recording_id'] as String? ?? "",
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
      formatId: json['format_id'] as String? ?? "",
      url: json['url'] as String? ?? "",
      ext: json['ext'] as String? ?? "",
      resolution: json['resolution'] as String? ?? "",
      hasVideo: json['has_video'] as bool? ?? false,
      hasAudio: json['has_audio'] as bool? ?? false,
      size: json['size'] as int? ?? 0,
      done: json['done'] as bool? ?? false,
      progress: json['progress'] as String? ?? "",
    );

Map<String, dynamic> _$DownloadToJson(Download instance) => <String, dynamic>{
      'id': instance.id,
      'recording_id': instance.recordingId,
      'created_at': instance.createdAt?.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
      'format_id': instance.formatId,
      'url': instance.url,
      'ext': instance.ext,
      'resolution': instance.resolution,
      'has_video': instance.hasVideo,
      'has_audio': instance.hasAudio,
      'size': instance.size,
      'done': instance.done,
      'progress': instance.progress,
    };
