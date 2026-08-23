import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_constants.dart';
import '../../../app/app_colors.dart';
import '../../../app/app_spacing.dart';
import '../../../shared/presentation/app_scaffold.dart';
import '../../../shared/presentation/primary_button.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      showBrand: false,
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height - 96,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const _LandingClassroomPreview(),
              const SizedBox(height: AppSpacing.xl),
              Text(
                AppConstants.serviceName,
                style: Theme.of(context).textTheme.displaySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                AppConstants.serviceTagline,
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xl),
              PrimaryButton(
                label: '내 반 만들기',
                icon: Icons.add_rounded,
                onPressed: () => context.go('/create'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LandingClassroomPreview extends StatelessWidget {
  const _LandingClassroomPreview();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 210,
      height: 150,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.paperDeep,
          border: Border.all(color: AppColors.woodDark, width: 2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Column(
            children: [
              Container(
                height: 38,
                alignment: Alignment.center,
                color: AppColors.board,
                child: const Text(
                  '오늘도 자리 찾는 중',
                  style: TextStyle(
                    color: AppColors.chalk,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: const [
                    _PreviewDesk(color: AppColors.sky),
                    _PreviewDesk(color: AppColors.coral),
                    _PreviewDesk(color: AppColors.leaf),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PreviewDesk extends StatelessWidget {
  const _PreviewDesk({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(width: 22, height: 25, color: color),
        Container(width: 42, height: 18, color: AppColors.wood),
      ],
    );
  }
}
