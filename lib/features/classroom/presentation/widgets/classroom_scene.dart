import 'package:flutter/material.dart';

import '../../../../app/app_colors.dart';
import '../../../../app/app_spacing.dart';
import '../models/classroom_scene_member.dart';
import 'classroom_seat.dart';
import 'seat_assignment_animation.dart';

class ClassroomScene extends StatelessWidget {
  const ClassroomScene({
    required this.members,
    required this.onMemberTap,
    this.enteringMember,
    this.onEntryComplete,
    super.key,
  });

  final List<ClassroomSceneMember> members;
  final ValueChanged<ClassroomSceneMember> onMemberTap;
  final ClassroomSceneMember? enteringMember;
  final VoidCallback? onEntryComplete;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 0.82,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.paperDeep,
          border: Border.all(color: AppColors.woodDark, width: 2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Stack(
            children: [
              const Positioned.fill(child: _ClassroomBackground()),
              Positioned(
                left: 42,
                right: 42,
                top: 92,
                bottom: 30,
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  padding: EdgeInsets.zero,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 7,
                    mainAxisSpacing: 8,
                    childAspectRatio: 0.82,
                  ),
                  itemCount: 9,
                  itemBuilder: (context, index) {
                    final member = _memberAt(index);
                    return ClassroomSeat(
                      seatIndex: index,
                      member: member,
                      onTap: member == null ? null : () => onMemberTap(member),
                    );
                  },
                ),
              ),
              if (enteringMember case final member?)
                SeatAssignmentAnimation(
                  seatIndex: member.seatIndex,
                  characterSeed: member.characterSeed,
                  onComplete: onEntryComplete ?? () {},
                ),
            ],
          ),
        ),
      ),
    );
  }

  ClassroomSceneMember? _memberAt(int seatIndex) {
    for (final member in members) {
      if (member.seatIndex == seatIndex) return member;
    }
    return null;
  }
}

class _ClassroomBackground extends StatelessWidget {
  const _ClassroomBackground();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned(
          left: 38,
          right: 38,
          top: 12,
          height: 65,
          child: _Chalkboard(),
        ),
        Positioned(
          left: 9,
          top: 112,
          child: Container(
            width: 22,
            height: 118,
            decoration: BoxDecoration(
              color: AppColors.sky.withValues(alpha: 0.7),
              border: Border.all(color: AppColors.woodDark, width: 2),
            ),
            child: const Column(
              children: [
                Expanded(child: SizedBox()),
                Divider(height: 2, color: AppColors.woodDark),
                Expanded(child: SizedBox()),
              ],
            ),
          ),
        ),
        Positioned(
          right: 8,
          top: 116,
          child: Container(
            width: 24,
            height: 74,
            decoration: BoxDecoration(
              color: AppColors.wood,
              border: Border.all(color: AppColors.woodDark, width: 2),
            ),
            child: const Align(
              alignment: Alignment.centerLeft,
              child: CircleAvatar(radius: 2, backgroundColor: AppColors.yellow),
            ),
          ),
        ),
        const Positioned(
          left: 10,
          bottom: 10,
          child: Icon(
            Icons.local_florist_rounded,
            size: 24,
            color: AppColors.leaf,
          ),
        ),
        const Positioned(
          right: 8,
          bottom: 10,
          child: Icon(
            Icons.menu_book_rounded,
            size: 22,
            color: AppColors.coral,
          ),
        ),
      ],
    );
  }
}

class _Chalkboard extends StatelessWidget {
  const _Chalkboard();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.board,
        border: Border.all(color: AppColors.woodDark, width: 3),
      ),
      child: Stack(
        children: [
          Center(
            child: Text(
              '우리 반에 앉아봐',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.chalk,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const Positioned(
            right: AppSpacing.xs,
            top: AppSpacing.xs,
            child: Icon(
              Icons.schedule_rounded,
              color: AppColors.chalk,
              size: 16,
            ),
          ),
          Positioned(
            right: 24,
            bottom: 4,
            child: Container(width: 22, height: 3, color: AppColors.yellow),
          ),
        ],
      ),
    );
  }
}
