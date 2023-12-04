// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'download.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Download _$DownloadFromJson(Map<String, dynamic> json) => Download(
      id: json['id'] as String? ?? "",
      title: json['title'] as String? ?? "",
      recordingId: json['recording_id'] as String? ?? "",
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
      formatId: json['format_id'] as String? ?? "",
      url: json['url'] as String? ?? "",
      filename: json['filename'] as String? ?? "",
      ext: json['ext'] as String? ?? "",
      resolution: json['resolution'] as String? ?? "",
      fps: json['fps'] as int?,
      hasVideo: json['has_video'] as bool? ?? false,
      hasAudio: json['has_audio'] as bool? ?? false,
      size: json['size'] as int? ?? 0,
      status: json['status'] as String? ?? "",
      progress: json['progress'] as String? ?? "",
    );

Map<String, dynamic> _$DownloadToJson(Download instance) => <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'recording_id': instance.recordingId,
      'created_at': instance.createdAt?.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
      'format_id': instance.formatId,
      'url': instance.url,
      'filename': instance.filename,
      'ext': instance.ext,
      'resolution': instance.resolution,
      'fps': instance.fps,
      'has_video': instance.hasVideo,
      'has_audio': instance.hasAudio,
      'size': instance.size,
      'status': instance.status,
      'progress': instance.progress,
    };
