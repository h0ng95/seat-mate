import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_colors.dart';
import '../../../app/app_constants.dart';
import '../../../app/app_spacing.dart';
import '../../../shared/presentation/app_scaffold.dart';
import '../../../shared/presentation/primary_button.dart';
import '../../character/presentation/pixel_character.dart';
import '../../auth/application/auth_providers.dart';
import '../../auth/presentation/kakao_login_button.dart';
import '../../classroom/application/classroom_providers.dart';

class LandingPage extends ConsumerWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(appConfigProvider);
    final authState = ref.watch(authUserProvider);
    final user = authState.value;
    return AppScaffold(
      showBrand: false,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _LandingMascotBand(),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.xl,
              AppSpacing.lg,
              AppSpacing.xxl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  AppConstants.serviceName,
                  style: Theme.of(context).textTheme.displaySmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  '생일로 읽는 우리 사이\n친구가 들어올수록 우리 반이 채워져요.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(color: AppColors.inkSoft),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xl),
                if (config.hasSupabase && user == null)
                  const KakaoLoginButton()
                else
                  PrimaryButton(
                    label: '내 반 만들기',
                    icon: Icons.auto_awesome_rounded,
                    onPressed: () => context.go('/create'),
                  ),
                if (config.hasSupabase && user != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  OutlinedButton.icon(
                    onPressed: () => context.go('/my'),
                    icon: const Icon(Icons.school_outlined),
                    label: const Text('내 반 보기'),
                  ),
                ],
                const SizedBox(height: AppSpacing.sm),
                OutlinedButton.icon(
                  onPressed: () => context.go('/class/preview'),
                  icon: const Icon(Icons.visibility_rounded),
                  label: const Text('완성된 교실 구경하기'),
                ),
                const SizedBox(height: AppSpacing.xl),
                const _LandingSignals(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LandingMascotBand extends StatelessWidget {
  const _LandingMascotBand();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 260,
      child: ColoredBox(
        color: AppColors.paperGreen,
        child: Stack(
          alignment: Alignment.center,
          children: [
            const Positioned(left: 30, top: 38, child: _PixelSparkle()),
            const Positioned(right: 42, top: 68, child: _PixelHeart()),
            const Positioned(right: 76, bottom: 34, child: _PixelSparkle()),
            Positioned(
              bottom: 26,
              child: Container(
                width: 184,
                height: 22,
                decoration: BoxDecoration(
                  color: AppColors.wood.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const Align(
              alignment: Alignment(-0.38, 0.58),
              child: SizedBox(
                width: 76,
                height: 104,
                child: PixelCharacter(seed: 'landing-owner'),
              ),
            ),
            const Align(
              alignment: Alignment(0.38, 0.58),
              child: SizedBox(
                width: 76,
                height: 104,
                child: PixelCharacter(seed: 'landing-friend'),
              ),
            ),
            Positioned(
              top: 28,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.chalk,
                  border: Border.all(color: AppColors.lineDark),
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: const [
                    BoxShadow(color: Color(0x1F332F2C), offset: Offset(0, 3)),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.favorite_rounded,
                        size: 18,
                        color: AppColors.coral,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        '우리 케미는 몇 퍼센트?',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LandingSignals extends StatelessWidget {
  const _LandingSignals();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Expanded(
          child: _Signal(icon: Icons.cake_rounded, label: '생일로 찾는 자리'),
        ),
        Expanded(
          child: _Signal(icon: Icons.favorite_rounded, label: '우리 사이 풀이'),
        ),
        Expanded(
          child: _Signal(icon: Icons.link_rounded, label: '링크로 함께하기'),
        ),
      ],
    );
  }
}

class _Signal extends StatelessWidget {
  const _Signal({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 22, color: AppColors.board),
        const SizedBox(height: AppSpacing.xs),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w800),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _PixelSparkle extends StatelessWidget {
  const _PixelSparkle();

  @override
  Widget build(BuildContext context) {
    return const Icon(
      Icons.auto_awesome_rounded,
      color: AppColors.yellow,
      size: 28,
    );
  }
}

class _PixelHeart extends StatelessWidget {
  const _PixelHeart();

  @override
  Widget build(BuildContext context) {
    return const Icon(Icons.favorite_rounded, color: AppColors.coral, size: 30);
  }
}
