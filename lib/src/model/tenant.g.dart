// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tenant.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Tenant _$TenantFromJson(Map<String, dynamic> json) => Tenant(
      id: json['id'] as String,
      telegramId: (json['telegram_id'] as num).toInt(),
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
      username: json['username'] as String? ?? "",
      firstName: json['first_name'] as String? ?? "",
      lastName: json['last_name'] as String? ?? "",
      diskQuota: (json['disk_quota'] as num?)?.toInt() ?? 0,
      diskUsage: (json['disk_usage'] as num?)?.toInt() ?? 0,
      files: (json['files'] as num?)?.toInt() ?? 0,
      blockedAt: json['blocked_at'] == null
          ? null
          : DateTime.parse(json['blocked_at'] as String),
    );

Map<String, dynamic> _$TenantToJson(Tenant instance) => <String, dynamic>{
      'id': instance.id,
      'telegram_id': instance.telegramId,
      'created_at': instance.createdAt?.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
      'username': instance.username,
      'first_name': instance.firstName,
      'last_name': instance.lastName,
      'disk_quota': instance.diskQuota,
      'disk_usage': instance.diskUsage,
      'files': instance.files,
      'blocked_at': instance.blockedAt?.toIso8601String(),
    };
