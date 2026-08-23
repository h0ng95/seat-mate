import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/app_colors.dart';
import '../../../app/app_spacing.dart';
import '../application/auth_providers.dart';

class KakaoLoginButton extends ConsumerWidget {
  const KakaoLoginButton({this.redirectPath = '/create', super.key});

  final String redirectPath;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(authControllerProvider);
    final isLoading = state?.isLoading ?? false;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 50,
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFFEE500),
              foregroundColor: const Color(0xFF191919),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: isLoading
                ? null
                : () => ref
                      .read(authControllerProvider.notifier)
                      .signInWithKakao(redirectPath: redirectPath),
            icon: isLoading
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.chat_bubble_rounded, size: 20),
            label: const Text(
              '카카오로 시작하기',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ),
        if (state?.hasError ?? false) ...[
          const SizedBox(height: AppSpacing.sm),
          const Text(
            '카카오 로그인을 시작하지 못했어요. 잠시 후 다시 시도해 주세요.',
            style: TextStyle(color: AppColors.error),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}
