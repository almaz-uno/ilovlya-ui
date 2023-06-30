// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'url_info.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

URLInfo _$URLInfoFromJson(Map<String, dynamic> json) => URLInfo(
      url: json['url'] as String?,
      infos: (json['infos'] as List<dynamic>?)
          ?.map((e) => RecordingInfo.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$URLInfoToJson(URLInfo instance) => <String, dynamic>{
      'url': instance.url,
      'infos': instance.infos,
    };
