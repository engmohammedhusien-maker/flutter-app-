import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:laravel_flutter_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:lottie/lottie.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  @override
  void initState() {
    super.initState();
    // تأخير لمدة 3 ثوانٍ ثم الانتقال إلى الوجهة الصحيحة
    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      final authState = ref.read(authNotifierProvider);
      final isLoggedIn = authState.user != null;
      // استخدام GoRouter للانتقال
      if (isLoggedIn) {
        context.go('/dashboard');
      } else {
        context.go('/login');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: Center(
        child: Lottie.asset(
          'assets/animations/Bubbles.json',
          width: 250,
          height: 250,
          fit: BoxFit.contain,
          repeat: false,
          onLoaded: (composition) {
            // يمكننا استخدام المتحكم للتحكم بالحركة لكن التأخير يكفي
          },
        ),
      ),
    );
  }
}
