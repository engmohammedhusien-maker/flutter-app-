import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:laravel_flutter_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:laravel_flutter_app/features/auth/presentation/screens/dashboard_screen.dart';
import 'package:laravel_flutter_app/features/auth/presentation/screens/login_screen.dart';
import 'package:laravel_flutter_app/features/splash/presentation/screens/splash_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authNotifierProvider);
  final isLoggedIn = authState.user != null;

  return GoRouter(
    initialLocation: '/splash', // البداية من شاشة البداية
    redirect: (context, state) {
      final isLoginPage = state.matchedLocation == '/login';
      if (!isLoggedIn && state.matchedLocation == '/dashboard') return '/login';
      if (isLoggedIn && isLoginPage) return '/dashboard';
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const LoginScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.0, 0.3),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOut,
                )),
                child: child,
              ),
            );
          },
        ),
      ),
      GoRoute(
        path: '/dashboard',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const DashboardScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1.0, 0.0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeInOut,
              )),
              child: child,
            );
          },
        ),
      ),
    ],
  );
});
