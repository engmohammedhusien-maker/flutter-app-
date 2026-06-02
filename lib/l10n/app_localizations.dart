import 'package:flutter/material.dart';
import 'package:laravel_flutter_app/features/auth/presentation/providers/auth_provider.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    final localizations =
        Localizations.of<AppLocalizations>(context, AppLocalizations);
    if (localizations == null) {
      throw FlutterError(
          'AppLocalizations not found. Did you add AppLocalizations.delegate?');
    }
    return localizations;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  // ---------- النصوص الأساسية ----------
  String get appTitle => 'Laravel Flutter App';
  String get login => locale.languageCode == 'ar' ? 'تسجيل الدخول' : 'Login';
  String get emailLabel =>
      locale.languageCode == 'ar' ? 'البريد الإلكتروني' : 'Email';
  String get passwordLabel =>
      locale.languageCode == 'ar' ? 'كلمة المرور' : 'Password';
  String get loginButton => locale.languageCode == 'ar' ? 'دخول' : 'Login';
  String get biometricLogin =>
      locale.languageCode == 'ar' ? 'الدخول بالبصمة' : 'Biometric Login';
  String get settings => locale.languageCode == 'ar' ? 'الإعدادات' : 'Settings';
  String get biometricSettings =>
      locale.languageCode == 'ar' ? 'الدخول بالبصمة' : 'Biometric Login';
  String get biometricSubtitle => locale.languageCode == 'ar'
      ? 'تسجيل الدخول بسرعة باستخدام بصمة الإصبع'
      : 'Login quickly using fingerprint';
  String get enable => locale.languageCode == 'ar' ? 'تفعيل' : 'Enable';
  String get disable => locale.languageCode == 'ar' ? 'تعطيل' : 'Disable';
  String get confirmPassword =>
      locale.languageCode == 'ar' ? 'تأكيد كلمة المرور' : 'Confirm Password';
  String get cancel => locale.languageCode == 'ar' ? 'إلغاء' : 'Cancel';
  String get confirm => locale.languageCode == 'ar' ? 'تأكيد' : 'Confirm';
  String get success => locale.languageCode == 'ar' ? 'نجاح' : 'Success';
  String get error => locale.languageCode == 'ar' ? 'خطأ' : 'Error';
  String get biometricActivated => locale.languageCode == 'ar'
      ? 'تم تفعيل الدخول بالبصمة بنجاح'
      : 'Biometric login activated successfully';
  String get biometricDeactivated => locale.languageCode == 'ar'
      ? 'تم تعطيل الدخول بالبصمة'
      : 'Biometric login deactivated';
  String get biometricFailed => locale.languageCode == 'ar'
      ? 'فشل التحقق من البصمة'
      : 'Biometric authentication failed';
  String get enterEmail =>
      locale.languageCode == 'ar' ? 'أدخل البريد' : 'Enter email';
  String get enterPassword =>
      locale.languageCode == 'ar' ? 'أدخل كلمة المرور' : 'Enter password';
  String get language => locale.languageCode == 'ar' ? 'اللغة' : 'Language';
  String get theme => locale.languageCode == 'ar' ? 'السمة' : 'Theme';
  String get light => locale.languageCode == 'ar' ? 'فاتح' : 'Light';
  String get dark => locale.languageCode == 'ar' ? 'داكن' : 'Dark';
  String get logout => locale.languageCode == 'ar' ? 'تسجيل الخروج' : 'Logout';
  String get welcome => locale.languageCode == 'ar' ? 'مرحباً' : 'Welcome';
  String get roles => locale.languageCode == 'ar' ? 'الأدوار' : 'Roles';
  String get permissions =>
      locale.languageCode == 'ar' ? 'الصلاحيات' : 'Permissions';
  String get createPost =>
      locale.languageCode == 'ar' ? 'إنشاء منشور' : 'Create Post';
  String get noPermission => locale.languageCode == 'ar'
      ? 'لا تملك صلاحية إنشاء منشور'
      : 'You do not have permission';
  String get replaceBiometric => locale.languageCode == 'ar'
      ? 'استبدال حساب البصمة'
      : 'Replace biometric account';
  String get confirmBiometric =>
      locale.languageCode == 'ar' ? 'تفعيل البصمة' : 'Enable biometric';
  // ---------- رسائل الخطأ المترجمة ----------
  String get invalidCredentials => locale.languageCode == 'ar'
      ? 'البريد الالكتروني او كلمة المرور خطأ'
      : 'Incorrect email address or password';

  String get passwordTooShortLocal => locale.languageCode == 'ar'
      ? 'كلمة المرور قصيرة (8 أحرف على الأقل)'
      : 'Password too short (min 8 characters)';

  // ---------- دالة ترجمة AuthError ----------
  String translateAuthError(AuthError error) {
    switch (error) {
      case AuthError.serverUnavailable:
        return locale.languageCode == 'ar'
            ? 'الخادم غير متاح حالياً'
            : 'Server is currently unavailable';
      case AuthError.invalidCredentials:
        return invalidCredentials;
      case AuthError.emailRequired:
        return locale.languageCode == 'ar'
            ? 'البريد الإلكتروني مطلوب'
            : 'Email is required';
      case AuthError.emailInvalid:
        return locale.languageCode == 'ar'
            ? 'صيغة البريد غير صحيحة'
            : 'Invalid email format';
      case AuthError.passwordRequired:
        return locale.languageCode == 'ar'
            ? 'كلمة المرور مطلوبة'
            : 'Password is required';
      case AuthError.passwordTooShort:
        return locale.languageCode == 'ar'
            ? 'كلمة المرور قصيرة (8 أحرف على الأقل)'
            : 'Password too short (min 8 characters)';
      case AuthError.serverError:
        return locale.languageCode == 'ar' ? 'خطأ في الخادم' : 'Server error';
      case AuthError.networkError:
        return locale.languageCode == 'ar' ? 'خطأ في الاتصال' : 'Network error';
      case AuthError.unknown:
        return locale.languageCode == 'ar'
            ? 'حدث خطأ غير متوقع'
            : 'An unexpected error occurred';
    }
  }

  static const localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    _AppLocalizationsDelegate(),
  ];

  static const supportedLocales = <Locale>[
    Locale('en'),
    Locale('ar'),
  ];
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'ar'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppLocalizations> old) =>
      false;
}
