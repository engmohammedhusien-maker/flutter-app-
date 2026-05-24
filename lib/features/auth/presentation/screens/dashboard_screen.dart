import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:laravel_flutter_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:laravel_flutter_app/features/authorization/presentation/widgets/auth_guard.dart';
import 'package:laravel_flutter_app/features/settings/presentation/screens/settings_screen.dart';
import 'package:laravel_flutter_app/l10n/app_localizations.dart';
import 'package:lottie/lottie.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final user = authState.user;
    final l10n = AppLocalizations.of(context)!;

    if (authState.isLoading) {
      return Scaffold(
        body: Center(
          child: Lottie.asset('assets/animations/loading.json', width: 150),
        ),
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
            onPressed: () {
              ref.read(authNotifierProvider.notifier).logout();
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
