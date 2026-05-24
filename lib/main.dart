import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
// أضف هذا الاستيراد
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:laravel_flutter_app/core/notifications/notification_service.dart';
import 'package:laravel_flutter_app/core/settings/settings_provider.dart';
import 'package:laravel_flutter_app/l10n/app_localizations.dart';
import 'package:laravel_flutter_app/routing/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  final notificationService = NotificationService();
  await notificationService.initLocalNotifications();
  final hasPermission = await notificationService.requestPermission();
  if (hasPermission) {
    notificationService.handleForegroundMessages();
    notificationService.getToken().then((token) {
      debugPrint('FCM Token: $token');
    });
  }

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'Laravel Flutter App',
      debugShowCheckedModeBanner: false,
      locale: settings.locale,
      // 👇 هذا هو الإصلاح: أضفنا تفويضات النظام الأساسية
      localizationsDelegates: const [
        ...AppLocalizations.localizationsDelegates,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: settings.themeMode,
      routerConfig: router,
    );
  }
}
