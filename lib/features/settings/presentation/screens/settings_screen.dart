import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:laravel_flutter_app/features/auth/presentation/providers/auth_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('الإعدادات')),
      body: ListView(
        children: [
          SwitchListTile(
            secondary: const Icon(Icons.fingerprint),
            title: const Text('الدخول بالبصمة'),
            subtitle: const Text('تسجيل الدخول بسرعة باستخدام بصمة الإصبع'),
            value: authState.isBiometricEnabled,
            onChanged: (value) async {
              if (value) {
                final user = authState.user;
                if (user == null) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('يجب أن تكون مسجلاً دخول')),
                    );
                  }
                  return;
                }

                final passwordController = TextEditingController();
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('تأكيد كلمة المرور'),
                    content: TextField(
                      controller: passwordController,
                      obscureText: true,
                      decoration:
                          const InputDecoration(labelText: 'كلمة المرور'),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('إلغاء'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('تأكيد'),
                      ),
                    ],
                  ),
                );

                if (confirmed == true && context.mounted) {
                  final password = passwordController.text.trim();
                  if (password.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('كلمة المرور لا يمكن أن تكون فارغة')),
                    );
                    return;
                  }
                  // استدعاء التحقق من كلمة المرور وتفعيل البصمة
                  final error = await ref
                      .read(authNotifierProvider.notifier)
                      .enableBiometricWithPassword(user.email, password);

                  if (context.mounted) {
                    if (error == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('تم تفعيل الدخول بالبصمة بنجاح')),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(error)),
                      );
                    }
                  }
                }
              } else {
                await ref
                    .read(authNotifierProvider.notifier)
                    .disableBiometric();
              }
            },
          ),
          const Divider(),
          // لاحقًا: إعدادات اللغة والسمة
        ],
      ),
    );
  }
}
