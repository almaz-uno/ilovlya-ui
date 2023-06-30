// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'format.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Format _$FormatFromJson(Map<String, dynamic> json) => Format(
      id: json['id'] as String? ?? "",
      ext: json['ext'] as String? ?? "",
      resolution: json['resolution'] as String? ?? "",
      hasAudio: json['has_audio'] as bool? ?? false,
      hasVideo: json['has_video'] as bool? ?? false,
    );

Map<String, dynamic> _$FormatToJson(Format instance) => <String, dynamic>{
      'id': instance.id,
      'ext': instance.ext,
      'resolution': instance.resolution,
      'has_audio': instance.hasAudio,
      'has_video': instance.hasVideo,
    };
