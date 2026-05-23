class PermissionModel {
  final String name; // مثال: "posts:view"
  final String? group; // مثال: "posts" (اختياري)

  const PermissionModel({required this.name, this.group});

  factory PermissionModel.fromJson(Map<String, dynamic> json) {
    return PermissionModel(
      name: json['name'] as String,
      group: json['group'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {'name': name, 'group': group};
}
