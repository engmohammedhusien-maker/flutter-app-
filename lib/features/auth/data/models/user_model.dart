import 'package:json_annotation/json_annotation.dart';

part 'user_model.g.dart';

@JsonSerializable()
class PermissionModel {
  final int id;
  final String name;
  final String? group;

  PermissionModel({required this.id, required this.name, this.group});

  factory PermissionModel.fromJson(Map<String, dynamic> json) =>
      _$PermissionModelFromJson(json);
  Map<String, dynamic> toJson() => _$PermissionModelToJson(this);
}


@JsonSerializable()
class RoleModel {
  final int id;
  final String name;
  @JsonKey(name: 'display_name')
  final String displayName;
  final List<PermissionModel>? permissions;

  RoleModel({
    required this.id,
    required this.name,
    required this.displayName,
    this.permissions,
  });

  factory RoleModel.fromJson(Map<String, dynamic> json) =>
      _$RoleModelFromJson(json);
  Map<String, dynamic> toJson() => _$RoleModelToJson(this);
}

@JsonSerializable()
class UserModel {
  final int id;
  final String name;
  final String email;
  @JsonKey(name: 'email_verified_at')
  final String? emailVerifiedAt;
  @JsonKey(name: 'created_at')
  final String? createdAt;
  @JsonKey(name: 'updated_at')
  final String? updatedAt;
  final List<RoleModel>? roles;
  final List<PermissionModel>? permissions; // صلاحيات مباشرة (قد تكون فارغة)

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.emailVerifiedAt,
    this.createdAt,
    this.updatedAt,
    this.roles,
    this.permissions,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);
  Map<String, dynamic> toJson() => _$UserModelToJson(this);

  /// استخراج جميع أسماء الصلاحيات (من الأدوار والصلاحيات المباشرة)
  List<String> getAllPermissionNames() {
    final names = <String>{};
    if (permissions != null) {
      names.addAll(permissions!.map((p) => p.name));
    }
    if (roles != null) {
      for (final role in roles!) {
        if (role.permissions != null) {
          names.addAll(role.permissions!.map((p) => p.name));
        }
      }
    }
    return names.toList();
  }
}
