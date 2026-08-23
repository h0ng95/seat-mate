import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_colors.dart';
import '../../../app/app_spacing.dart';
import '../../../core/values/local_date.dart';
import '../../../core/values/nickname.dart';
import '../../../shared/presentation/app_scaffold.dart';
import '../../../shared/presentation/app_text_field.dart';
import '../../../shared/presentation/chalk_loading.dart';
import '../../../shared/presentation/primary_button.dart';
import '../application/classroom_providers.dart';
import '../domain/classroom_repository.dart';
import '../domain/seat_mate_algorithm.dart';

enum _CreatePhase { input, calculating, result }

class CreateClassroomPage extends ConsumerStatefulWidget {
  const CreateClassroomPage({super.key});

  @override
  ConsumerState<CreateClassroomPage> createState() =>
      _CreateClassroomPageState();
}

class _CreateClassroomPageState extends ConsumerState<CreateClassroomPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _birthController = TextEditingController();
  final _algorithm = const SeatMateAlgorithmV1();

  _CreatePhase _phase = _CreatePhase.input;
  Nickname? _name;
  LocalDate? _birthDate;
  OwnerResult? _ownerResult;

  @override
  void dispose() {
    _nameController.dispose();
    _birthController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final createState = ref.watch(createClassroomControllerProvider);
    return AppScaffold(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        child: switch (_phase) {
          _CreatePhase.input => _buildInput(),
          _CreatePhase.calculating => const SizedBox(
            key: ValueKey('calculating'),
            height: 420,
            child: Center(
              child: ChalkLoading(
                messages: ['칠판 닦는 중...', '책상 옮기는 중...', '당신의 자리를 찾는 중...'],
              ),
            ),
          ),
          _CreatePhase.result => _buildResult(createState),
        },
      ),
    );
  }

  Widget _buildInput() {
    return Form(
      key: _formKey,
      child: Column(
        key: const ValueKey('input'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '내 반을 만들어볼까요?',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: AppSpacing.xs),
          const Text('실명 대신 별명을 사용해도 좋아요.'),
          const SizedBox(height: AppSpacing.xl),
          AppTextField(
            label: '이름 또는 별명',
            hintText: '재홍',
            controller: _nameController,
            validator: _validateName,
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            label: '생년월일',
            hintText: '1995-06-12',
            controller: _birthController,
            keyboardType: TextInputType.datetime,
            validator: _validateBirthDate,
          ),
          const SizedBox(height: AppSpacing.lg),
          PrimaryButton(label: '내 자리 찾기', onPressed: _findSeat),
          const SizedBox(height: AppSpacing.md),
          Text(
            '입력한 생일은 재미있는 자리 결과를 만드는 데만 사용해요.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.inkSoft),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildResult(AsyncValue<Object?>? createState) {
    final ownerResult = _ownerResult!;
    final profile = ownerResult.profile;
    final isLoading = createState?.isLoading ?? false;
    final errorMessage = createState?.hasError ?? false
        ? '교실을 만드는 데 실패했어요. 다시 시도해 주세요.'
        : null;

    return Column(
      key: const ValueKey('result'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '${_name!.display}님의 자리는',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          _seatDescription(ownerResult.seatIndex),
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(color: AppColors.board),
        ),
        const SizedBox(height: AppSpacing.lg),
        DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.board,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.boardDark, width: 2),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.auto_awesome_rounded, color: AppColors.yellow),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  profile.title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(color: AppColors.chalk),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  profile.description,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(color: AppColors.chalk),
                ),
              ],
            ),
          ),
        ),
        if (errorMessage != null) ...[
          const SizedBox(height: AppSpacing.md),
          Text(errorMessage, style: const TextStyle(color: AppColors.error)),
        ],
        const SizedBox(height: AppSpacing.lg),
        PrimaryButton(
          label: '이 자리로 반 만들기',
          icon: Icons.school_rounded,
          isLoading: isLoading,
          onPressed: isLoading ? null : _createClassroom,
        ),
        const SizedBox(height: AppSpacing.sm),
        TextButton(
          onPressed: isLoading ? null : _editInput,
          child: const Text('입력 다시 하기'),
        ),
      ],
    );
  }

  Future<void> _findSeat() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final name = Nickname(_nameController.text);
    final birthDate = _parseDate(_birthController.text);
    setState(() {
      _name = name;
      _birthDate = birthDate;
      _phase = _CreatePhase.calculating;
    });
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    setState(() {
      _ownerResult = _algorithm.deriveOwner(birthDate);
      _phase = _CreatePhase.result;
    });
  }

  Future<void> _createClassroom() async {
    final classroom = await ref
        .read(createClassroomControllerProvider.notifier)
        .create(
          CreateClassroomCommand(
            ownerName: _name!,
            ownerBirthDate: _birthDate!,
          ),
        );
    if (classroom != null && mounted) {
      context.go('/class/${classroom.shareCode}');
    }
  }

  void _editInput() {
    ref.invalidate(createClassroomControllerProvider);
    setState(() => _phase = _CreatePhase.input);
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
      final todayDate = LocalDate(today.year, today.month, today.day);
      if (date.compareTo(LocalDate(1900, 1, 1)) < 0 ||
          date.compareTo(todayDate) > 0) {
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

  String _seatDescription(int seatIndex) {
    const rows = ['앞줄', '가운데 줄', '뒷줄'];
    const columns = ['창가', '가운데', '문 쪽'];
    return '${columns[seatIndex % 3]} ${rows[seatIndex ~/ 3]} 자리';
  }
}
