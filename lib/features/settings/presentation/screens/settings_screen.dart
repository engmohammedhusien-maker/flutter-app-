import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:laravel_flutter_app/core/settings/settings_provider.dart';
import 'package:laravel_flutter_app/features/settings/presentation/widgets/biometric_switch.dart';
import 'package:laravel_flutter_app/l10n/app_localizations.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings)),
      body: ListView(
        children: [
          // مفتاح البصمة المستقل
          const BiometricSwitch(),
          const Divider(),
          // اللغة
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
          // السمة
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
