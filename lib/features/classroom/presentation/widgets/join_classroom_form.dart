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
import '../../domain/birth_profile.dart';
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
  final _birthTimeController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _birthController.dispose();
    _birthTimeController.dispose();
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
            const Text('열두 인연이 모두 모였어요. 이제 나만의 반을 만들어보세요.'),
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
              '양력 생일로 원국을 계산해 케미 지수와 우리 사이 풀이를 보여드려요.',
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
              label: '양력 생년월일',
              hintText: '1996-03-17',
              controller: _birthController,
              keyboardType: TextInputType.datetime,
              validator: _validateBirthDate,
            ),
            const SizedBox(height: AppSpacing.sm),
            AppTextField(
              label: '출생시간 (선택)',
              hintText: '09:30 · 모르면 비워두세요',
              controller: _birthTimeController,
              keyboardType: TextInputType.datetime,
              validator: _validateBirthTime,
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
              label: isLoading ? '우리 사이를 읽는 중...' : '내 자리와 케미 보기',
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
    final birthTime = _parseTime(_birthTimeController.text);
    final result = await ref
        .read(joinClassroomControllerProvider.notifier)
        .join(
          JoinClassroomCommand(
            shareCode: widget.shareCode,
            name: Nickname(_nameController.text),
            birth: BirthProfile(
              date: _parseDate(_birthController.text),
              hour: birthTime?.hour,
              minute: birthTime?.minute,
            ),
          ),
        );
    if (result == null || !mounted) return;
    widget.onJoined(result);
    if (!result.isDuplicate) {
      _nameController.clear();
      _birthController.clear();
      _birthTimeController.clear();
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

  String? _validateBirthTime(String? value) {
    try {
      _parseTime(value ?? '');
      return null;
    } on FormatException catch (error) {
      return error.message.toString();
    }
  }

  ({int hour, int minute})? _parseTime(String value) {
    final normalized = value.trim();
    if (normalized.isEmpty) return null;
    final match = RegExp(r'^(\d{1,2}):([0-5]\d)$').firstMatch(normalized);
    if (match == null) throw const FormatException('출생시간을 09:30 형식으로 입력해 주세요.');
    final hour = int.parse(match.group(1)!);
    if (hour > 23) throw const FormatException('시간은 00:00부터 23:59까지 입력해 주세요.');
    return (hour: hour, minute: int.parse(match.group(2)!));
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
