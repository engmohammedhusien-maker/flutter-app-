import 'dart:io' show exit;

import 'package:back_button_interceptor/back_button_interceptor.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:laravel_flutter_app/l10n/app_localizations.dart';

mixin BackPressMixin<T extends StatefulWidget> on State<T> {
  DateTime? _lastBackPress;

  void attachBackPressInterceptor() {
    BackButtonInterceptor.add(_onBackPressed);
  }

  void detachBackPressInterceptor() {
    BackButtonInterceptor.remove(_onBackPressed);
  }

  bool _onBackPressed(bool stopDefaultButtonEvent, RouteInfo? routeInfo) {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      return false; // اسمح للنظام بالرجوع للصفحة السابقة
    }

    final now = DateTime.now();
    final l10n = AppLocalizations.of(context);
    if (_lastBackPress == null ||
        now.difference(_lastBackPress!) > const Duration(seconds: 3)) {
      _lastBackPress = now;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.locale.languageCode == 'ar'
              ? 'اضغط مرة أخرى للخروج'
              : 'Press back again to exit'),
          duration: const Duration(seconds: 3),
        ),
      );
      return true;
    }
    try {
      SystemNavigator.pop();
    } catch (_) {
      exit(0);
    }
    return true;
  }
}
