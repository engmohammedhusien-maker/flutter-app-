import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  /// ترجع [AppLocalizations] من شجرة الواجهة. ترمي استثناء إذا لم توجد.
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

  // ---------- النصوص المترجمة ----------
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
  String get invalidCredentials => locale.languageCode == 'ar'
      ? 'بيانات الدخول غير صحيحة'
      : 'Invalid credentials';
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
  String get biometricFailed => locale.languageCode == 'ar'
      ? 'فشل التحقق من البصمة'
      : 'Biometric authentication failed';

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
