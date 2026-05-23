import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:laravel_flutter_app/features/authorization/domain/permission_checker.dart';

/// ويدجت يخفي الطفل إلا إذا امتلك المستخدم الصلاحية المطلوبة
class AuthGuard extends ConsumerWidget {
  final String permission; // صلاحية واحدة
  final Widget child; // العنصر المراد حمايته
  final Widget? fallback; // بديل يظهر عند عدم وجود صلاحية

  const AuthGuard({
    super.key,
    required this.permission,
    required this.child,
    this.fallback,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final checker = ref.watch(permissionCheckerProvider);
    if (checker.hasPermission(permission)) {
      return child;
    }
    return fallback ?? const SizedBox.shrink();
  }
}
