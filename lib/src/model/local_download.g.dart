// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'local_download.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LocalDownloadTask _$LocalDownloadTaskFromJson(Map<String, dynamic> json) =>
    LocalDownloadTask(
      id: json['id'] as String,
      displayName: json['display_name'] as String,
      filename: json['filename'] as String,
      status: $enumDecodeNullable(_$TaskStatusEnumMap, json['status']),
      progress: (json['progress'] as num?)?.toDouble(),
      networkSpeed: (json['network_speed'] as num?)?.toDouble(),
      timeRemaining: json['time_remaining'] == null
          ? null
          : Duration(microseconds: (json['time_remaining'] as num).toInt()),
    );

Map<String, dynamic> _$LocalDownloadTaskToJson(LocalDownloadTask instance) =>
    <String, dynamic>{
      'id': instance.id,
      'display_name': instance.displayName,
      'filename': instance.filename,
      'status': _$TaskStatusEnumMap[instance.status],
      'progress': instance.progress,
      'network_speed': instance.networkSpeed,
      'time_remaining': instance.timeRemaining?.inMicroseconds,
    };

const _$TaskStatusEnumMap = {
  TaskStatus.enqueued: 'enqueued',
  TaskStatus.running: 'running',
  TaskStatus.complete: 'complete',
  TaskStatus.notFound: 'notFound',
  TaskStatus.failed: 'failed',
  TaskStatus.canceled: 'canceled',
  TaskStatus.waitingToRetry: 'waitingToRetry',
  TaskStatus.paused: 'paused',
};
