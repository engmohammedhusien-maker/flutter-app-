import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:laravel_flutter_app/core/utils/back_press_mixin.dart';
import 'package:laravel_flutter_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:laravel_flutter_app/features/authorization/presentation/widgets/auth_guard.dart';
import 'package:laravel_flutter_app/features/settings/presentation/screens/settings_screen.dart';
import 'package:laravel_flutter_app/l10n/app_localizations.dart';
import 'package:lottie/lottie.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen>
    with BackPressMixin {
  // DateTime? _lastBackPress;

  // @override
  // void initState() {
  //   super.initState();
  //   BackButtonInterceptor.add(_onBackPressed);
  // }

  // @override
  // void dispose() {
  //   BackButtonInterceptor.remove(_onBackPressed);
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

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final user = authState.user;
    final l10n = AppLocalizations.of(context);

    if (authState.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Hero(
          tag: 'app_title',
          child: Text('${l10n.welcome} ${user?.name ?? ""}'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: l10n.settings,
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: l10n.logout,
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text(l10n.logout),
                  content: Text(l10n.locale.languageCode == 'ar'
                      ? 'هل أنت متأكد أنك تريد تسجيل الخروج؟'
                      : 'Are you sure you want to logout?'),
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

              if (confirmed != true) return;

              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (ctx) => PopScope(
                  canPop: false,
                  child: Center(
                    child: Lottie.asset(
                      'assets/animations/Bubbles.json',
                      width: 200,
                      height: 200,
                      repeat: true,
                    ),
                  ),
                ),
              );

              await ref.read(authNotifierProvider.notifier).logout();

              if (context.mounted) {
                Navigator.of(context, rootNavigator: true)
                    .popUntil((route) => route.isFirst);
              }
            },
          ),
        ],
      ),
      body: user == null
          ? const Center(child: CircularProgressIndicator())
          : _DashboardContent(user: user, l10n: l10n),
    );
  }
}

class _DashboardContent extends StatefulWidget {
  final dynamic user;
  final AppLocalizations l10n;

  const _DashboardContent({required this.user, required this.l10n});

  @override
  State<_DashboardContent> createState() => _DashboardContentState();
}

class _DashboardContentState extends State<_DashboardContent>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Animation<double>> _animations;
  final int _itemCount = 4;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _animations = List.generate(_itemCount, (index) {
      final start = index * 0.2;
      return CurvedAnimation(
        parent: _controller,
        curve: Interval(start, 1.0, curve: Curves.easeOutBack),
      );
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildAnimatedItem(
              0,
              Card(
                child: ListTile(
                  leading: const Icon(Icons.person),
                  title: Text(widget.user.name),
                  subtitle: Text(widget.user.email),
                ),
              ),
            ),
            _buildAnimatedItem(
              1,
              Card(
                child: ListTile(
                  leading: const Icon(Icons.security),
                  title: Text(widget.l10n.roles),
                  subtitle: Text(
                    (widget.user.roles as List<dynamic>?)
                            ?.map((r) => r.displayName ?? r.name)
                            .join(", ") ??
                        "-",
                  ),
                ),
              ),
            ),
            _buildAnimatedItem(
              2,
              Card(
                child: ListTile(
                  leading: const Icon(Icons.vpn_key),
                  title: Text(widget.l10n.permissions),
                  subtitle: Text(
                    (widget.user.permissions as List<dynamic>?)
                            ?.map((p) => p.name)
                            .join(", ") ??
                        "-",
                  ),
                ),
              ),
            ),
            _buildAnimatedItem(
              3,
              AuthGuard(
                permission: 'posts:create',
                fallback: Card(
                  child: ListTile(
                    leading: const Icon(Icons.block),
                    title: Text(widget.l10n.noPermission),
                  ),
                ),
                child: ElevatedButton.icon(
                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(widget.l10n.createPost)),
                  ),
                  icon: const Icon(Icons.add),
                  label: Text(widget.l10n.createPost),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAnimatedItem(int index, Widget child) {
    if (index < _itemCount - 1) {
      return FadeTransition(
        opacity: _animations[index],
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.5, 0.0),
            end: Offset.zero,
          ).animate(_animations[index]),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: child,
          ),
        ),
      );
    } else {
      return ScaleTransition(
        scale: _animations[index],
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: child,
        ),
      );
    }
  }
}
