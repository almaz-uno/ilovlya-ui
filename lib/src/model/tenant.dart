import 'package:json_annotation/json_annotation.dart';

import '../media/format.dart';

part 'tenant.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class Tenant {
  String id;
  int telegramId;
  DateTime? createdAt;
  DateTime? updatedAt;
  String username;
  String firstName;
  String lastName;
  int diskQuota;
  int diskUsage;
  int files;
  DateTime? blockedAt;

  Tenant({
    required this.id,
    required this.telegramId,
    this.createdAt,
    this.updatedAt,
    this.username = "",
    this.firstName = "",
    this.lastName = "",
    this.diskQuota = 0,
    this.diskUsage = 0,
    this.files = 0,
    this.blockedAt,
  });

  String quotaStr() {
    return fileSizeHumanReadable(diskQuota);
  }

  String usageStr() {
    return fileSizeHumanReadable(diskUsage);
  }

  String freeStr() {
    return fileSizeHumanReadable(diskQuota - diskUsage);
  }

  factory Tenant.fromJson(Map<String, dynamic> json) => _$TenantFromJson(json);
  Map<String, dynamic> toJson() => _$TenantToJson(this);
}
