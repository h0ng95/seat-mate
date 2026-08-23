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
import '../../../shared/presentation/error_state.dart';
import '../../../shared/presentation/primary_button.dart';
import '../../../shared/presentation/separated_digits_input_formatter.dart';
import '../../character/presentation/pixel_character.dart';
import '../../character/domain/character_gender.dart';
import '../../character/presentation/character_gender_selector.dart';
import '../../auth/application/auth_providers.dart';
import '../../auth/presentation/kakao_login_button.dart';
import '../application/classroom_providers.dart';
import '../domain/birth_profile.dart';
import '../domain/classroom_repository.dart';
import '../domain/classroom_seat_layout.dart';
import '../domain/saju_chart.dart';
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
  final _birthTimeController = TextEditingController();
  final _algorithm = const SeatMateAlgorithmV1();

  _CreatePhase _phase = _CreatePhase.input;
  Nickname? _name;
  BirthProfile? _birthProfile;
  CharacterGender? _gender;
  OwnerResult? _ownerResult;

  @override
  void dispose() {
    _nameController.dispose();
    _birthController.dispose();
    _birthTimeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(appConfigProvider);
    final authState = ref.watch(authUserProvider);
    if (config.hasSupabase && authState.isLoading) {
      return const AppScaffold(
        child: SizedBox(
          height: 360,
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }
    if (config.hasSupabase && authState.value == null) {
      return const AppScaffold(child: _CreateLoginRequired());
    }

    final activeShareCode = ref.watch(activeClassroomShareCodeProvider);
    if (activeShareCode != null) {
      return AppScaffold(
        child: _ExistingClassroomRedirect(shareCode: activeShareCode),
      );
    }

    final user = authState.value;
    if (config.hasSupabase && user != null) {
      final classroomsState = ref.watch(savedClassroomsProvider(user.id));
      if (classroomsState.isLoading) {
        return const AppScaffold(
          child: SizedBox(
            height: 360,
            child: Center(child: CircularProgressIndicator()),
          ),
        );
      }
      if (classroomsState.hasError) {
        return AppScaffold(
          child: SizedBox(
            height: 360,
            child: Center(
              child: AppErrorState(
                title: '내 반을 확인하지 못했어요.',
                message: '잠시 후 다시 확인해 주세요.',
                actionLabel: '다시 확인',
                onAction: () =>
                    ref.invalidate(savedClassroomsProvider(user.id)),
              ),
            ),
          ),
        );
      }
      final classrooms = classroomsState.value ?? const [];
      if (classrooms.isNotEmpty) {
        return AppScaffold(
          child: _ExistingClassroomRedirect(
            shareCode: classrooms.first.shareCode,
          ),
        );
      }
    }

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
                messages: ['절기표 확인 중...', '사주 원국 계산 중...', '당신의 자리를 찾는 중...'],
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
          const _CreateGuide(),
          const SizedBox(height: AppSpacing.lg),
          DecoratedBox(
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    '내 반 만들기',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '양력 생일로 원국을 계산해 나의 자리부터 찾아볼게요.',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: AppColors.inkSoft),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppTextField(
                    label: '이름 또는 별명',
                    hintText: '재홍',
                    controller: _nameController,
                    validator: _validateName,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  CharacterGenderSelector(
                    onChanged: (value) => _gender = value,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    label: '양력 생년월일',
                    hintText: '1995-06-12',
                    controller: _birthController,
                    keyboardType: TextInputType.number,
                    inputFormatters: const [
                      SeparatedDigitsInputFormatter(
                        groupLengths: [4, 2, 2],
                        separator: '-',
                      ),
                    ],
                    validator: _validateBirthDate,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    label: '출생시간 (선택)',
                    hintText: '09:30 · 모르면 비워두세요',
                    controller: _birthTimeController,
                    keyboardType: TextInputType.number,
                    inputFormatters: const [
                      SeparatedDigitsInputFormatter(
                        groupLengths: [2, 2],
                        separator: ':',
                      ),
                    ],
                    validator: _validateBirthTime,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  PrimaryButton(label: '내 자리 운세 보기', onPressed: _findSeat),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.lock_outline_rounded,
                size: 17,
                color: AppColors.inkSoft,
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  '실명 대신 별명을 권장해요. 생일과 시간은 원국 계산에만 사용하며 교실에 공개하지 않아요.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.inkSoft),
                ),
              ),
            ],
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
        const SizedBox(height: AppSpacing.md),
        _OwnerChartSummary(chart: ownerResult.sajuChart),
        if (errorMessage != null) ...[
          const SizedBox(height: AppSpacing.md),
          Text(errorMessage, style: const TextStyle(color: AppColors.error)),
        ],
        const SizedBox(height: AppSpacing.lg),
        PrimaryButton(
          label: '이 원국으로 반 만들기',
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
    final birthTime = _parseTime(_birthTimeController.text);
    final birthProfile = BirthProfile(
      date: birthDate,
      hour: birthTime?.hour,
      minute: birthTime?.minute,
    );
    setState(() {
      _name = name;
      _birthProfile = birthProfile;
      _phase = _CreatePhase.calculating;
    });
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    setState(() {
      _ownerResult = _algorithm.deriveOwner(birthProfile);
      _phase = _CreatePhase.result;
    });
  }

  Future<void> _createClassroom() async {
    final classroom = await ref
        .read(createClassroomControllerProvider.notifier)
        .create(
          CreateClassroomCommand(
            ownerName: _name!,
            ownerBirth: _birthProfile!,
            gender: _gender!,
          ),
        );
    if (classroom != null && mounted) {
      context.go('/class/${classroom.shareCode}');
      return;
    }
    final error = ref.read(createClassroomControllerProvider)?.error;
    if (error case ClassroomAlreadyExistsException(:final shareCode)) {
      if (!mounted) return;
      if (shareCode != null) {
        ref.read(activeClassroomShareCodeProvider.notifier).remember(shareCode);
        context.go('/class/$shareCode');
      } else {
        context.go('/my');
      }
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

  String _seatDescription(int seatIndex) {
    const rows = ['앞줄', '가운데 줄', '뒷줄'];
    const divisions = ['1분단', '2분단'];
    const sides = ['왼쪽', '오른쪽'];
    final row = ClassroomSeatLayout.rowOf(seatIndex);
    final division = ClassroomSeatLayout.divisionOf(seatIndex);
    final side = ClassroomSeatLayout.sideOf(seatIndex);
    return '${seatIndex + 1}번 · ${rows[row]} ${divisions[division]} ${sides[side]} 자리';
  }
}

class _CreateLoginRequired extends StatelessWidget {
  const _CreateLoginRequired();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSpacing.xl),
        const Icon(
          Icons.lock_outline_rounded,
          size: 52,
          color: AppColors.board,
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          '반을 만들려면\n로그인해 주세요',
          style: Theme.of(context).textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          '로그인하면 링크를 잃어버려도\n내 반에서 다시 찾을 수 있어요.',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppColors.inkSoft),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.lg),
        const KakaoLoginButton(),
      ],
    );
  }
}

class _ExistingClassroomRedirect extends StatefulWidget {
  const _ExistingClassroomRedirect({required this.shareCode});

  final String shareCode;

  @override
  State<_ExistingClassroomRedirect> createState() =>
      _ExistingClassroomRedirectState();
}

class _ExistingClassroomRedirectState
    extends State<_ExistingClassroomRedirect> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.go('/class/${widget.shareCode}');
    });
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 360,
      child: Center(child: ChalkLoading(messages: ['이미 만든 내 반으로 돌아가는 중...'])),
    );
  }
}

class _OwnerChartSummary extends StatelessWidget {
  const _OwnerChartSummary({required this.chart});

  final SajuChart chart;

  @override
  Widget build(BuildContext context) {
    final values = [
      ('년주', chart.year.hanja),
      ('월주', chart.month.hanja),
      ('일주', chart.day.hanja),
      ('시주', chart.hour?.hanja ?? '--'),
    ];
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.paperGreen,
        border: Border.all(color: AppColors.leaf),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.fact_check_outlined,
                  size: 20,
                  color: AppColors.board,
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    chart.depth.label,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                for (final value in values)
                  Container(
                    width: 62,
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.chalk,
                      border: Border.all(color: AppColors.line),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Column(
                      children: [
                        Text(
                          value.$1,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        Text(
                          value.$2,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              chart.depth.description,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.inkSoft),
            ),
          ],
        ),
      ),
    );
  }
}

class _CreateGuide extends StatelessWidget {
  const _CreateGuide();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 118,
      child: ColoredBox(
        color: AppColors.paperBlue,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Row(
            children: [
              const SizedBox(
                width: 72,
                height: 96,
                child: PixelCharacter(seed: 'create-guide'),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '오늘 당신의 자리는 어디일까요?',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '먼저 나의 자리 기운을 읽고 친구들을 초대해요.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.inkSoft,
                      ),
                    ),
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
