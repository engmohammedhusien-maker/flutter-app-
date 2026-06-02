import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// دالة موحدة للتعامل مع زر الرجوع (ضغطتين للخروج)
/// تستخدم في `WillPopScope.onWillPop`.
///
/// [context] - سياق الشاشة الحالية.
/// [lastBackPress] - مرجع للمتغير الذي يحفظ وقت آخر ضغطة.
/// [l10n] - كائن الترجمة لعرض الرسالة.
///
/// تُرجع `true` للسماح بالخروج، `false` لمنعه.
Future<bool> handleBackPress({
  required BuildContext context,
  required DateTime? lastBackPress,
  required void Function(DateTime) onLastBackPressUpdate,
  required String messageBackAgain,
}) async {
  final now = DateTime.now();
  if (lastBackPress == null ||
      now.difference(lastBackPress) > const Duration(seconds: 3)) {
    onLastBackPressUpdate(now);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(messageBackAgain),
        duration: const Duration(seconds: 3),
      ),
    );
    return false; // امنع الخروج
  }
  // الخروج بعد الضغطة الثانية
  try {
    SystemNavigator.pop();
  } catch (_) {
    // fallback
  }
  return true; // اسمح بالخروج
}
