import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/app_colors.dart';
import '../../../app/app_spacing.dart';
import '../../../shared/presentation/app_scaffold.dart';
import '../../../shared/presentation/chalk_loading.dart';
import '../../../shared/presentation/error_state.dart';
import '../application/classroom_providers.dart';
import '../domain/classroom.dart';
import '../domain/relationship.dart';
import '../domain/seat_mate_algorithm.dart';
import 'models/classroom_scene_member.dart';
import 'widgets/classroom_scene.dart';
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

class _ClassroomContent extends StatelessWidget {
  const _ClassroomContent({required this.classroom});

  final Classroom classroom;

  @override
  Widget build(BuildContext context) {
    final sceneMembers = classroom.members
        .map((member) => _toSceneMember(classroom, member))
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Text(
                '${classroom.ownerName.display}이네 반',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
            Text(
              '${classroom.members.length} / 9명',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          classroom.isFull ? '아홉 자리가 모두 찼어요!' : '오늘도 전학생을 기다리는 중',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: AppSpacing.lg),
        ClassroomScene(
          members: sceneMembers,
          onMemberTap: (member) => showMemberResultSheet(context, member),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          classroom.isFull ? '우리 반 완성!' : '전학 올래?',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          classroom.isFull
              ? '이 반은 꽉 찼지만 자리 결과는 계속 구경할 수 있어요.'
              : '이름과 생일을 입력하면 빈자리를 찾아줄게요.',
        ),
        const SizedBox(height: AppSpacing.md),
        OutlinedButton.icon(
          onPressed: classroom.isFull ? null : () {},
          icon: Icon(
            classroom.isFull
                ? Icons.celebration_rounded
                : Icons.person_add_alt_1_rounded,
          ),
          label: Text(classroom.isFull ? '우리 반 완성' : '내 자리 찾기'),
        ),
      ],
    );
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

  String _relativeSeatDescription(int ownerSeat, int memberSeat) {
    final rowDelta = memberSeat ~/ 3 - ownerSeat ~/ 3;
    final columnDelta = memberSeat % 3 - ownerSeat % 3;
    if (rowDelta == 0 && columnDelta == -1) {
      return '${classroom.ownerName.display}님의 왼쪽 자리';
    }
    if (rowDelta == 0 && columnDelta == 1) {
      return '${classroom.ownerName.display}님의 오른쪽 자리';
    }
    if (rowDelta == -1 && columnDelta == 0) {
      return '${classroom.ownerName.display}님의 앞자리';
    }
    if (rowDelta == 1 && columnDelta == 0) {
      return '${classroom.ownerName.display}님의 뒷자리';
    }
    if (rowDelta.abs() == 1 && columnDelta.abs() == 1) {
      return '${classroom.ownerName.display}님의 대각선 자리';
    }
    return '${classroom.ownerName.display}님과 조금 먼 자리';
  }
}

const _memberColors = [
  AppColors.leaf,
  AppColors.sky,
  AppColors.coral,
  AppColors.yellow,
];
