import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_colors.dart';
import '../../app/app_constants.dart';
import '../../app/app_spacing.dart';

class AppScaffold extends StatelessWidget {
  const AppScaffold({
    required this.child,
    this.showBrand = true,
    this.showNavigation = true,
    this.actions = const [],
    this.padding,
    super.key,
  });

  final Widget child;
  final bool showBrand;
  final bool showNavigation;
  final List<Widget> actions;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    final hasRouter = GoRouter.maybeOf(context) != null;
    return Scaffold(
      bottomNavigationBar: showNavigation && hasRouter
          ? const _AppBottomNavigation()
          : null,
      body: Stack(
        children: [
          const Positioned.fill(
            child: IgnorePointer(child: CustomPaint(painter: _PaperPattern())),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: AppSpacing.pageMaxWidth,
                ),
                child: Column(
                  children: [
                    if (showBrand) _AppHeader(actions: actions),
                    Expanded(
                      child: SingleChildScrollView(
                        padding:
                            padding ??
                            const EdgeInsets.fromLTRB(
                              AppSpacing.md,
                              AppSpacing.lg,
                              AppSpacing.md,
                              AppSpacing.xxl,
                            ),
                        child: child,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AppHeader extends StatelessWidget {
  const _AppHeader({required this.actions});

  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.chalk,
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      child: SizedBox(
        height: 58,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.board,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.school_rounded,
                  size: 19,
                  color: AppColors.chalk,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  AppConstants.serviceName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              ...actions,
            ],
          ),
        ),
      ),
    );
  }
}

class _AppBottomNavigation extends StatelessWidget {
  const _AppBottomNavigation();

  @override
  Widget build(BuildContext context) {
    final path =
        GoRouter.maybeOf(context)?.routeInformationProvider.value.uri.path ??
        '/';
    final selectedIndex = path.startsWith('/class') || path.startsWith('/my')
        ? 2
        : path.startsWith('/create')
        ? 1
        : 0;

    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.chalk,
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      child: SafeArea(
        top: false,
        child: Align(
          heightFactor: 1,
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppSpacing.pageMaxWidth,
            ),
            child: NavigationBar(
              selectedIndex: selectedIndex,
              onDestinationSelected: (index) {
                switch (index) {
                  case 0:
                    context.go('/');
                  case 1:
                    context.go('/create');
                  case 2:
                    context.go('/my');
                }
              },
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home_rounded),
                  label: '시작',
                ),
                NavigationDestination(
                  icon: Icon(Icons.add_box_outlined),
                  selectedIcon: Icon(Icons.add_box_rounded),
                  label: '내 반 만들기',
                ),
                NavigationDestination(
                  icon: Icon(Icons.favorite_border_rounded),
                  selectedIcon: Icon(Icons.favorite_rounded),
                  label: '내 반',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PaperPattern extends CustomPainter {
  const _PaperPattern();

  @override
  void paint(Canvas canvas, Size size) {
    final dot = Paint()
      ..color = AppColors.woodDark.withValues(alpha: 0.045)
      ..isAntiAlias = false;
    for (var y = 14.0; y < size.height; y += 32) {
      for (var x = 14.0; x < size.width; x += 32) {
        canvas.drawRect(Rect.fromLTWH(x, y, 1.5, 1.5), dot);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _PaperPattern oldDelegate) => false;
}
