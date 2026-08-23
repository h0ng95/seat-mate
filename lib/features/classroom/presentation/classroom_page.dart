import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/app_colors.dart';
import '../../../app/app_spacing.dart';
import '../../../shared/presentation/app_scaffold.dart';
import '../../../shared/presentation/chalk_loading.dart';
import '../../../shared/presentation/error_state.dart';
import '../application/classroom_providers.dart';
import '../domain/classroom.dart';
import '../domain/classroom_repository.dart';
import '../domain/relationship.dart';
import '../domain/seat_mate_algorithm.dart';
import 'models/classroom_scene_member.dart';
import 'widgets/classroom_scene.dart';
import 'widgets/join_classroom_form.dart';
import 'widgets/member_result_sheet.dart';

class ClassroomPage extends ConsumerWidget {
  const ClassroomPage({required this.shareCode, super.key});

  final String shareCode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final classroomState = ref.watch(classroomProvider(shareCode));
    return AppScaffold(
      actions: [
        IconButton(
          tooltip: '링크 공유하기',
          onPressed: () {},
          icon: const Icon(Icons.ios_share_rounded),
        ),
      ],
      child: classroomState.when(
        loading: () =>
            const SizedBox(height: 460, child: Center(child: ChalkLoading())),
        error: (error, stackTrace) => SizedBox(
          height: 460,
          child: Center(
            child: AppErrorState(
              title: '앗, 교실을 못 찾았어요.',
              message: '링크가 오래됐거나 잘못된 주소일 수 있어요.',
              actionLabel: '다시 시도',
              onAction: () => ref.invalidate(classroomProvider(shareCode)),
            ),
          ),
        ),
        data: (classroom) => _ClassroomContent(classroom: classroom),
      ),
    );
  }
}

class _ClassroomContent extends StatefulWidget {
  const _ClassroomContent({required this.classroom});

  final Classroom classroom;

  @override
  State<_ClassroomContent> createState() => _ClassroomContentState();
}

class _ClassroomContentState extends State<_ClassroomContent> {
  late Classroom _classroom;
  ClassroomSceneMember? _enteringMember;
  JoinClassroomResult? _pendingResult;

  @override
  void initState() {
    super.initState();
    _classroom = widget.classroom;
  }

  @override
  void didUpdateWidget(covariant _ClassroomContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.classroom != widget.classroom && _pendingResult == null) {
      _classroom = widget.classroom;
    }
  }

  @override
  Widget build(BuildContext context) {
    final sceneMembers = _classroom.members
        .map((member) => _toSceneMember(_classroom, member))
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Text(
                '${_classroom.ownerName.display}이네 반',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
            Text(
              '${_classroom.members.length} / 9명',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: Text(
            _enteringMember == null
                ? (_classroom.isFull ? '아홉 자리가 모두 찼어요!' : '오늘도 전학생을 기다리는 중')
                : '새로운 전학생이 왔어요!',
            key: ValueKey(_enteringMember?.name ?? _classroom.members.length),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: _enteringMember == null
                  ? AppColors.inkSoft
                  : AppColors.coral,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        ClassroomScene(
          members: sceneMembers,
          enteringMember: _enteringMember,
          onEntryComplete: _completeEntry,
          onMemberTap: (member) => showMemberResultSheet(context, member),
        ),
        const SizedBox(height: AppSpacing.lg),
        JoinClassroomForm(
          shareCode: _classroom.shareCode,
          isFull: _classroom.isFull,
          onJoined: _handleJoinResult,
        ),
      ],
    );
  }

  void _handleJoinResult(JoinClassroomResult result) {
    final sceneMember = _toSceneMember(result.classroom, result.member);
    if (result.isDuplicate) {
      setState(() => _classroom = result.classroom);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('이미 이 반에 앉아 있어요!')));
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) showMemberResultSheet(context, sceneMember);
      });
      return;
    }
    setState(() {
      _pendingResult = result;
      _enteringMember = sceneMember;
    });
  }

  void _completeEntry() {
    final result = _pendingResult;
    if (result == null || !mounted) return;
    final sceneMember = _toSceneMember(result.classroom, result.member);
    setState(() {
      _classroom = result.classroom;
      _pendingResult = null;
      _enteringMember = null;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) showMemberResultSheet(context, sceneMember);
    });
  }

  ClassroomSceneMember _toSceneMember(
    Classroom classroom,
    ClassroomMember member,
  ) {
    final relationship = member.relationship;
    final profile = member.ownerProfile;
    return ClassroomSceneMember(
      name: member.name.display,
      seatIndex: member.seatIndex,
      relationshipTitle: member.isOwner ? profile!.title : relationship!.title,
      relationshipDescription: member.isOwner
          ? profile!.description
          : relationship!.description,
      seatDescription: member.isOwner
          ? '우리 반 생성자'
          : _relativeSeatDescription(
              classroom,
              classroom.ownerSeatIndex,
              member.seatIndex,
            ),
      focusDelta: member.focusDelta,
      joyDelta: member.joyDelta,
      color: _memberColors[member.seatIndex % _memberColors.length],
      characterSeed: member.characterSeed,
      isOwner: member.isOwner,
    );
  }

  String _relativeSeatDescription(
    Classroom classroom,
    int ownerSeat,
    int memberSeat,
  ) {
    final rowDelta = memberSeat ~/ 3 - ownerSeat ~/ 3;
    final columnDelta = memberSeat % 3 - ownerSeat % 3;
    final owner = classroom.ownerName.display;
    if (rowDelta == 0 && columnDelta == -1) return '$owner님의 왼쪽 자리';
    if (rowDelta == 0 && columnDelta == 1) return '$owner님의 오른쪽 자리';
    if (rowDelta == -1 && columnDelta == 0) return '$owner님의 앞자리';
    if (rowDelta == 1 && columnDelta == 0) return '$owner님의 뒷자리';
    if (rowDelta.abs() == 1 && columnDelta.abs() == 1) {
      return '$owner님의 대각선 자리';
    }
    return '$owner님과 조금 먼 자리';
  }
}

const _memberColors = [
  AppColors.leaf,
  AppColors.sky,
  AppColors.coral,
  AppColors.yellow,
];
