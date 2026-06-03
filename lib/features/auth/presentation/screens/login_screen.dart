import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:laravel_flutter_app/core/settings/settings_provider.dart';
import 'package:laravel_flutter_app/core/utils/back_press_mixin.dart';
import 'package:laravel_flutter_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:laravel_flutter_app/features/settings/presentation/screens/settings_screen.dart';
import 'package:laravel_flutter_app/l10n/app_localizations.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> with BackPressMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  // DateTime? _lastBackPress;

  // @override
  // void initState() {
  //   super.initState();
  //   BackButtonInterceptor.add(_onBackPressed);
  // }

  // @override
  // void dispose() {
  //   BackButtonInterceptor.remove(_onBackPressed);
  //   _emailController.dispose();
  //   _passwordController.dispose();
  //   super.dispose();
  // }

  // bool _onBackPressed(bool stopDefaultButtonEvent, RouteInfo? routeInfo) {
  //   final navigator = Navigator.of(context);
  //   // إذا كان هناك صفحات فرعية مفتوحة، اترك النظام يعالج الرجوع بشكل طبيعي
  //   if (navigator.canPop()) {
  //     return false;
  //   }

  //   // وإلا، نحن في الصفحة الرئيسية → منطق الخروج بضغطتين
  //   final now = DateTime.now();
  //   final l10n = AppLocalizations.of(context);
  //   if (_lastBackPress == null ||
  //       now.difference(_lastBackPress!) > const Duration(seconds: 3)) {
  //     _lastBackPress = now;
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(
  //         content: Text(l10n.locale.languageCode == 'ar'
  //             ? 'اضغط مرة أخرى للخروج'
  //             : 'Press back again to exit'),
  //         duration: const Duration(seconds: 3),
  //       ),
  //     );
  //     return true; // نمنع الخروج
  //   }
  //   // الضغطة الثانية: إغلاق التطبيق
  //   try {
  //     SystemNavigator.pop();
  //   } catch (_) {
  //     exit(0);
  //   }
  //   return true;
  // }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    await ref.read(authNotifierProvider.notifier).login(email, password);

    if (!mounted) return;
    final authState = ref.read(authNotifierProvider);

    if (authState.user != null) {
      _emailController.clear();
      _passwordController.clear();
    } else if (authState.error != null) {
      final l10n = AppLocalizations.of(context);
      final displayError = l10n.translateAuthError(authState.error!);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(displayError),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  Future<void> _biometricLogin() async {
    final success =
        await ref.read(authNotifierProvider.notifier).biometricLogin();
    if (!mounted) return;
    if (!success) {
      // يمكن تجاهل الفشل بهدوء
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final l10n = AppLocalizations.of(context);
    final hasBiometricOwner = authState.biometricOwnerEmail != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.login),
        actions: [
          IconButton(
            icon: const Icon(Icons.language),
            tooltip: 'Change Language',
            onPressed: () {
              final currentLocale = ref.read(settingsProvider).locale;
              final newLocale = currentLocale.languageCode == 'ar'
                  ? const Locale('en')
                  : const Locale('ar');
              ref.read(settingsProvider.notifier).setLocale(newLocale);
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: l10n.settings,
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: AutofillGroup(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: l10n.emailLabel,
                      border: const OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return l10n.enterEmail;
                      }
                      final emailRegex = RegExp(
                          r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
                      if (!emailRegex.hasMatch(v.trim())) {
                        return l10n.locale.languageCode == 'ar'
                            ? 'بريد إلكتروني غير صالح'
                            : 'Invalid email address';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: l10n.passwordLabel,
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                    obscureText: _obscurePassword,
                    autofillHints: const [AutofillHints.password],
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return l10n.enterPassword;
                      }
                      if (v.trim().length < 8) {
                        return l10n.passwordTooShortLocal;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  if (authState.isLoading)
                    const CircularProgressIndicator()
                  else
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          onPressed: _login,
                          child: Text(l10n.loginButton),
                        ),
                        if (hasBiometricOwner &&
                            authState.isBiometricAvailable) ...[
                          const SizedBox(width: 12),
                          IconButton(
                            icon: const Icon(Icons.fingerprint),
                            iconSize: 36,
                            tooltip: l10n.biometricLogin,
                            onPressed: _biometricLogin,
                            style: IconButton.styleFrom(
                              backgroundColor: Theme.of(context)
                                  .colorScheme
                                  .primaryContainer,
                              foregroundColor: Theme.of(context)
                                  .colorScheme
                                  .onPrimaryContainer,
                            ),
                          ),
                        ],
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
