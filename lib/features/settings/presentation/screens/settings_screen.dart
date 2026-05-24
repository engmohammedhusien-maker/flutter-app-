import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:laravel_flutter_app/core/settings/settings_provider.dart';
import 'package:laravel_flutter_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:laravel_flutter_app/l10n/app_localizations.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final user = authState.user;
    final isOwner = authState.isCurrentUserBiometricOwner;
    final hasOtherOwner = authState.biometricOwnerEmail != null && !isOwner;
    final settings = ref.watch(settingsProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings)),
      body: ListView(
        children: [
          if (user != null) ...[
            SwitchListTile(
              secondary: const Icon(Icons.fingerprint),
              title: Text(isOwner
                  ? '${l10n.biometricSettings} (${l10n.enable})'
                  : l10n.biometricSettings),
              subtitle: Text(
                hasOtherOwner
                    ? '${l10n.biometricSubtitle} (${authState.biometricOwnerEmail})'
                    : l10n.biometricSubtitle,
              ),
              value: isOwner,
              onChanged: (value) async {
                if (value) {
                  final passwordController = TextEditingController();
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: Text(hasOtherOwner
                          ? 'استبدال حساب البصمة'
                          : l10n.confirmPassword),
                      content: TextField(
                        controller: passwordController,
                        obscureText: true,
                        decoration:
                            InputDecoration(labelText: l10n.passwordLabel),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: Text(l10n.cancel),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: Text(l10n.confirm),
                        ),
                      ],
                    ),
                  );

                  if (confirmed == true && context.mounted) {
                    final password = passwordController.text.trim();
                    if (password.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l10n.enterPassword)),
                      );
                      return;
                    }
                    final String? error;
                    if (hasOtherOwner) {
                      error = await ref
                          .read(authNotifierProvider.notifier)
                          .replaceBiometricOwner(user.email, password);
                    } else {
                      error = await ref
                          .read(authNotifierProvider.notifier)
                          .enableBiometricWithPassword(user.email, password);
                    }
                    if (context.mounted) {
                      if (error == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(l10n.biometricActivated)),
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
          ],
          // Language selector
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(l10n.language),
            trailing: DropdownButton<String>(
              value: settings.locale.languageCode,
              onChanged: (value) {
                if (value != null) {
                  ref.read(settingsProvider.notifier).setLocale(Locale(value));
                }
              },
              items: const [
                DropdownMenuItem(value: 'en', child: Text('English')),
                DropdownMenuItem(value: 'ar', child: Text('العربية')),
              ],
            ),
          ),
          const Divider(),
          // Theme switch
          SwitchListTile(
            secondary: const Icon(Icons.brightness_6),
            title: Text(l10n.theme),
            subtitle: Text(
                settings.themeMode == ThemeMode.dark ? l10n.dark : l10n.light),
            value: settings.themeMode == ThemeMode.dark,
            onChanged: (value) {
              final mode = value ? ThemeMode.dark : ThemeMode.light;
              ref.read(settingsProvider.notifier).setThemeMode(mode);
            },
          ),
        ],
      ),
    );
  }
}
