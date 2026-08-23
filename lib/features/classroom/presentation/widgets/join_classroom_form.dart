import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/app_colors.dart';
import '../../../../app/app_spacing.dart';
import '../../../../core/values/local_date.dart';
import '../../../../core/values/nickname.dart';
import '../../../../shared/presentation/app_text_field.dart';
import '../../../../shared/presentation/primary_button.dart';
import '../../application/classroom_providers.dart';
import '../../domain/classroom_repository.dart';

class JoinClassroomForm extends ConsumerStatefulWidget {
  const JoinClassroomForm({
    required this.shareCode,
    required this.isFull,
    required this.onJoined,
    super.key,
  });

  final String shareCode;
  final bool isFull;
  final ValueChanged<JoinClassroomResult> onJoined;

  @override
  ConsumerState<JoinClassroomForm> createState() => _JoinClassroomFormState();
}

class _JoinClassroomFormState extends ConsumerState<JoinClassroomForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _birthController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _birthController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isFull) {
      return _JoinPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('우리 반 완성!', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppSpacing.xs),
            const Text('아홉 인연이 모두 모였어요. 이제 나만의 관계 교실을 만들어보세요.'),
            const SizedBox(height: AppSpacing.md),
            PrimaryButton(
              label: '내 반 만들기',
              icon: Icons.add_rounded,
              onPressed: () => context.go('/create'),
            ),
          ],
        ),
      );
    }

    final joinState = ref.watch(joinClassroomControllerProvider);
    final isLoading = joinState?.isLoading ?? false;
    final error = joinState?.error;
    final errorMessage = switch (error) {
      ClassroomFullException() => '방금 마지막 자리가 찼어요. 내 반을 새로 만들어볼까요?',
      ClassroomNotFoundException() => '교실을 찾지 못했어요. 링크를 다시 확인해 주세요.',
      _ when error != null => '자리를 찾는 중 문제가 생겼어요. 다시 시도해 주세요.',
      _ => null,
    };

    return _JoinPanel(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.favorite_rounded, color: AppColors.coral),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    '우리 사이도 알아볼까요?',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '자리를 찾으면 하트 궁합과 관계 풀이가 함께 나와요.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.inkSoft),
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              label: '이름 또는 별명',
              hintText: '민수',
              controller: _nameController,
              validator: _validateName,
            ),
            const SizedBox(height: AppSpacing.sm),
            AppTextField(
              label: '생년월일',
              hintText: '1996-03-17',
              controller: _birthController,
              keyboardType: TextInputType.datetime,
              validator: _validateBirthDate,
            ),
            if (errorMessage != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                errorMessage,
                style: const TextStyle(color: AppColors.error),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            PrimaryButton(
              label: isLoading ? '관계 기운을 읽는 중...' : '내 자리와 하트 궁합 보기',
              isLoading: isLoading,
              onPressed: isLoading ? null : _join,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _join() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final result = await ref
        .read(joinClassroomControllerProvider.notifier)
        .join(
          JoinClassroomCommand(
            shareCode: widget.shareCode,
            name: Nickname(_nameController.text),
            birthDate: _parseDate(_birthController.text),
          ),
        );
    if (result == null || !mounted) return;
    widget.onJoined(result);
    if (!result.isDuplicate) {
      _nameController.clear();
      _birthController.clear();
    }
    ref.read(joinClassroomControllerProvider.notifier).reset();
  }

  String? _validateName(String? value) {
    try {
      Nickname(value ?? '');
      return null;
    } on FormatException catch (error) {
      return error.message.toString();
    }
  }

  String? _validateBirthDate(String? value) {
    try {
      final date = _parseDate(value ?? '');
      final today = DateTime.now();
      if (date.compareTo(LocalDate(1900, 1, 1)) < 0 ||
          date.compareTo(LocalDate(today.year, today.month, today.day)) > 0) {
        return '1900년 이후의 생년월일을 입력해 주세요.';
      }
      return null;
    } on FormatException catch (error) {
      return error.message.toString();
    }
  }

  LocalDate _parseDate(String value) {
    final normalized = value
        .trim()
        .replaceAll(RegExp(r'[.\s/]+'), '-')
        .replaceAll(RegExp(r'-+'), '-');
    return LocalDate.parseIso(normalized);
  }
}

class _JoinPanel extends StatelessWidget {
  const _JoinPanel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.chalk,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
            color: Color(0x17332F2C),
            offset: Offset(0, 4),
            blurRadius: 12,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: child,
      ),
    );
  }
}
