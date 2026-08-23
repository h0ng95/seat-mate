import 'package:flutter/material.dart';

import '../../../../app/app_colors.dart';
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
      aspectRatio: 0.75,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFF34251F),
          border: Border.all(color: const Color(0xFF34251F), width: 4),
          borderRadius: BorderRadius.circular(5),
          boxShadow: const [
            BoxShadow(
              color: Color(0x332B211B),
              offset: Offset(0, 5),
              blurRadius: 0,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(1),
          child: LayoutBuilder(
            builder: (context, constraints) => Stack(
              children: [
                Positioned.fill(
                  child: Image.asset(
                    'assets/images/classroom-room-v4.png',
                    fit: BoxFit.cover,
                    filterQuality: FilterQuality.none,
                    semanticLabel: '나무 바닥과 칠판, 창문, 책장이 있는 도트 교실',
                  ),
                ),
                Positioned(
                  left: constraints.maxWidth * 0.24,
                  right: constraints.maxWidth * 0.24,
                  bottom: constraints.maxHeight * 0.025,
                  height: constraints.maxHeight * 0.1,
                  child: Center(
                    child: Text(
                      '우리 반에 앉아봐',
                      maxLines: 1,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppColors.chalk,
                        fontWeight: FontWeight.w900,
                        shadows: const [
                          Shadow(
                            color: Color(0x66000000),
                            offset: Offset(1, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: constraints.maxWidth * 0.085,
                  right: constraints.maxWidth * 0.085,
                  top: constraints.maxHeight * 0.28,
                  bottom: constraints.maxHeight * 0.24,
                  child: GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    padding: EdgeInsets.zero,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 5,
                          mainAxisSpacing: 5,
                          childAspectRatio: 1.32,
                        ),
                    itemCount: 9,
                    itemBuilder: (context, index) {
                      final member = _memberAt(index);
                      return ClassroomSeat(
                        seatIndex: index,
                        member: member,
                        onTap: member == null
                            ? null
                            : () => onMemberTap(member),
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
