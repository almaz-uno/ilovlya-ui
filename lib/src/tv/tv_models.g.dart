// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tv_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TvSession _$TvSessionFromJson(Map<String, dynamic> json) => TvSession(
      id: json['id'] as String? ?? "",
      phase: json['phase'] as String? ?? TvPhase.created,
      connected: json['connected'] as bool? ?? false,
      pairedAt: json['paired_at'] == null
          ? null
          : DateTime.parse(json['paired_at'] as String),
      expiresAt: json['expires_at'] == null
          ? null
          : DateTime.parse(json['expires_at'] as String),
      lastSeenAt: json['last_seen_at'] == null
          ? null
          : DateTime.parse(json['last_seen_at'] as String),
      recordingId: json['recording_id'] as String? ?? "",
      downloadId: json['download_id'] as String? ?? "",
      position: (json['position'] as num?)?.toInt() ?? 0,
      duration: (json['duration'] as num?)?.toInt() ?? 0,
      error: json['error'] == null
          ? null
          : TvError.fromJson(json['error'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$TvSessionToJson(TvSession instance) => <String, dynamic>{
      'id': instance.id,
      'phase': instance.phase,
      'connected': instance.connected,
      'paired_at': instance.pairedAt?.toIso8601String(),
      'expires_at': instance.expiresAt?.toIso8601String(),
      'last_seen_at': instance.lastSeenAt?.toIso8601String(),
      'recording_id': instance.recordingId,
      'download_id': instance.downloadId,
      'position': instance.position,
      'duration': instance.duration,
      'error': instance.error,
    };

TvError _$TvErrorFromJson(Map<String, dynamic> json) => TvError(
      code: json['code'] as String? ?? "",
      message: json['message'] as String? ?? "",
    );

Map<String, dynamic> _$TvErrorToJson(TvError instance) => <String, dynamic>{
      'code': instance.code,
      'message': instance.message,
    };

TvCommand _$TvCommandFromJson(Map<String, dynamic> json) => TvCommand(
      type: json['type'] as String,
      downloadId: json['download_id'] as String?,
      position: (json['position'] as num?)?.toInt(),
    );

Map<String, dynamic> _$TvCommandToJson(TvCommand instance) => <String, dynamic>{
      'type': instance.type,
      'download_id': instance.downloadId,
      'position': instance.position,
    };
