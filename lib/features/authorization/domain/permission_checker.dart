import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:laravel_flutter_app/features/auth/presentation/providers/auth_provider.dart';

class PermissionChecker {
  final List<String> _userPermissions;

  PermissionChecker(this._userPermissions);

  bool hasPermission(String permission) {
    return _userPermissions.contains(permission);
  }

  bool hasAnyPermission(List<String> permissions) {
    return permissions.any((p) => _userPermissions.contains(p));
  }

  bool hasAllPermissions(List<String> permissions) {
    return permissions.every((p) => _userPermissions.contains(p));
  }
}

final permissionCheckerProvider = Provider<PermissionChecker>((ref) {
  // نقرأ الصلاحيات المستخرجة مسبقاً من authState
  final permNames = ref.watch(authNotifierProvider).permissionNames;
  return PermissionChecker(permNames);
});
