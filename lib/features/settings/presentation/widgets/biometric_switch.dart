import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:laravel_flutter_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:laravel_flutter_app/l10n/app_localizations.dart';

class BiometricSwitch extends ConsumerStatefulWidget {
  const BiometricSwitch({super.key});

  @override
  ConsumerState<BiometricSwitch> createState() => _BiometricSwitchState();
}

class _BiometricSwitchState extends ConsumerState<BiometricSwitch> {
  late bool _localActive;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _localActive = ref.read(isBiometricOwnerProvider);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final authState = ref.read(authNotifierProvider);
    final user = authState.user;
    // مالك البصمة الحقيقي المخزن (قد يكون null)
    final biometricOwner = authState.biometricOwnerEmail;
    // هل هناك بصمة مفعلة ولكن لحساب آخر؟
    final hasOtherOwner =
        biometricOwner != null && biometricOwner != user?.email;

    if (user == null) return const SizedBox.shrink();

    if (_isLoading) {
      return const ListTile(
        leading: Icon(Icons.fingerprint),
        title: Text('...'),
        trailing: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    return SwitchListTile(
      secondary: const Icon(Icons.fingerprint),
      title: Text(_localActive
          ? '${l10n.biometricSettings} (${l10n.enable})'
          : l10n.biometricSettings),
      subtitle: Text(
        hasOtherOwner
            ? '${l10n.biometricSubtitle} ($biometricOwner)'
            : l10n.biometricSubtitle,
      ),
      value: _localActive,
      onChanged: (value) async {
        final notifier = ref.read(authNotifierProvider.notifier);
        if (value) {
          // اختيار النص المناسب
          final dialogTitle =
              hasOtherOwner ? l10n.replaceBiometric : l10n.confirmBiometric;

          final passwordController = TextEditingController();
          bool obscure = true;
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (ctx) => StatefulBuilder(
              builder: (ctx, setDialogState) => AlertDialog(
                title: Text(dialogTitle),
                content: TextField(
                  controller: passwordController,
                  obscureText: obscure,
                  decoration: InputDecoration(
                    labelText: l10n.passwordLabel,
                    suffixIcon: IconButton(
                      icon: Icon(
                          obscure ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setDialogState(() => obscure = !obscure),
                    ),
                  ),
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
            ),
          );

          if (confirmed != true || !context.mounted) return;

          final password = passwordController.text.trim();
          if (password.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.enterPassword)),
            );
            return;
          }
          if (password.length < 8) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.passwordTooShortLocal)),
            );
            return;
          }

          setState(() => _isLoading = true);

          final AuthError? error;
          if (hasOtherOwner) {
            error = await notifier.replaceBiometricOwner(user.email, password);
          } else {
            error = await notifier.enableBiometricWithPassword(
                user.email, password);
          }

          setState(() => _isLoading = false);
          if (!context.mounted) return;

          if (error == null) {
            setState(() => _localActive = true);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.biometricActivated)),
            );
          } else {
            String displayError;
            if (error == AuthError.invalidCredentials) {
              displayError = l10n.locale.languageCode == 'ar'
                  ? 'كلمة المرور غير صحيحة'
                  : 'Incorrect password';
            } else {
              displayError = l10n.translateAuthError(error);
            }
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(displayError)),
            );
          }
        } else {
          setState(() => _localActive = false);
          await notifier.disableBiometric();
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.biometricDeactivated)),
            );
          }
        }
      },
    );
  }
}
