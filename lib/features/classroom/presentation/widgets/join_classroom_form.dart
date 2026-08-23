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
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('우리 반 완성!', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.xs),
          const Text('이 반은 이미 꽉 찼어요. 그래도 내 반을 만들어볼래요?'),
          const SizedBox(height: AppSpacing.md),
          PrimaryButton(
            label: '내 반 만들기',
            icon: Icons.add_rounded,
            onPressed: () => context.go('/create'),
          ),
        ],
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

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('전학 올래?', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.xs),
          const Text('실명 대신 별명을 사용해도 좋아요.'),
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
            Text(errorMessage, style: const TextStyle(color: AppColors.error)),
          ],
          const SizedBox(height: AppSpacing.md),
          PrimaryButton(
            label: isLoading ? '자리를 찾는 중...' : '내 자리 찾기',
            isLoading: isLoading,
            onPressed: isLoading ? null : _join,
          ),
        ],
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
