import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../app/app_colors.dart';
import '../models/classroom_scene_member.dart';
import 'classroom_seat.dart';
import 'seat_assignment_animation.dart';
import 'wandering_student.dart';

class ClassroomScene extends StatefulWidget {
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
  State<ClassroomScene> createState() => _ClassroomSceneState();
}

class _ClassroomSceneState extends State<ClassroomScene> {
  Timer? _wanderTimer;
  Timer? _idleTimer;
  int? _walkingSeatIndex;
  int? _idleSeatIndex;
  var _wanderCursor = 0;
  var _idleCursor = 0;
  var _motionDisabled = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final disabled = MediaQuery.disableAnimationsOf(context);
    if (_motionDisabled == disabled &&
        (_motionDisabled || _wanderTimer != null)) {
      return;
    }
    _motionDisabled = disabled;
    if (disabled) {
      _wanderTimer?.cancel();
      _idleTimer?.cancel();
      _wanderTimer = null;
      _idleTimer = null;
      _walkingSeatIndex = null;
      _idleSeatIndex = null;
      return;
    }
    _scheduleWander(const Duration(milliseconds: 2600));
    _scheduleIdle(const Duration(milliseconds: 1100));
  }

  @override
  void didUpdateWidget(covariant ClassroomScene oldWidget) {
    super.didUpdateWidget(oldWidget);
    final seatIndexes = widget.members
        .map((member) => member.seatIndex)
        .toSet();
    if (!seatIndexes.contains(_walkingSeatIndex) ||
        widget.enteringMember != null) {
      _walkingSeatIndex = null;
    }
    if (!seatIndexes.contains(_idleSeatIndex)) {
      _idleSeatIndex = null;
    }
    if (oldWidget.enteringMember != widget.enteringMember &&
        widget.enteringMember == null) {
      _scheduleWander(const Duration(milliseconds: 1800));
    }
  }

  @override
  void dispose() {
    _wanderTimer?.cancel();
    _idleTimer?.cancel();
    super.dispose();
  }

  void _scheduleWander(Duration delay) {
    if (_motionDisabled || _wanderTimer != null || _walkingSeatIndex != null) {
      return;
    }
    _wanderTimer = Timer(delay, () {
      _wanderTimer = null;
      if (!mounted) return;
      if (widget.enteringMember != null || widget.members.isEmpty) {
        _scheduleWander(const Duration(milliseconds: 1600));
        return;
      }
      final members = [...widget.members]
        ..sort((a, b) => a.seatIndex.compareTo(b.seatIndex));
      final member = members[_wanderCursor % members.length];
      _wanderCursor += 1;
      setState(() {
        _walkingSeatIndex = member.seatIndex;
        if (_idleSeatIndex == member.seatIndex) _idleSeatIndex = null;
      });
    });
  }

  void _completeWander() {
    if (!mounted) return;
    setState(() => _walkingSeatIndex = null);
    _scheduleWander(const Duration(milliseconds: 2400));
  }

  void _scheduleIdle(Duration delay) {
    if (_motionDisabled || _idleTimer != null) return;
    _idleTimer = Timer(delay, () {
      _idleTimer = null;
      if (!mounted || widget.members.isEmpty) return;
      final available =
          widget.members
              .where((member) => member.seatIndex != _walkingSeatIndex)
              .toList()
            ..sort((a, b) => a.seatIndex.compareTo(b.seatIndex));
      if (available.isEmpty) {
        _scheduleIdle(const Duration(milliseconds: 900));
        return;
      }
      final member = available[_idleCursor % available.length];
      _idleCursor += 1;
      setState(() => _idleSeatIndex = member.seatIndex);
      _idleTimer = Timer(const Duration(milliseconds: 320), () {
        _idleTimer = null;
        if (!mounted) return;
        setState(() => _idleSeatIndex = null);
        _scheduleIdle(const Duration(milliseconds: 1700));
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final walkingMember = _memberAt(_walkingSeatIndex);
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
                    'assets/images/classroom-room-v5.png',
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
                        isAway: _walkingSeatIndex == index,
                        isIdle: _idleSeatIndex == index,
                        onTap: member == null
                            ? null
                            : () => widget.onMemberTap(member),
                      );
                    },
                  ),
                ),
                if (widget.enteringMember case final member?)
                  SeatAssignmentAnimation(
                    seatIndex: member.seatIndex,
                    characterSeed: member.characterSeed,
                    onComplete: widget.onEntryComplete ?? () {},
                  ),
                if (walkingMember != null && widget.enteringMember == null)
                  WanderingStudent(
                    member: walkingMember,
                    onTap: () => widget.onMemberTap(walkingMember),
                    onComplete: _completeWander,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  ClassroomSceneMember? _memberAt(int? seatIndex) {
    if (seatIndex == null) return null;
    for (final member in widget.members) {
      if (member.seatIndex == seatIndex) return member;
    }
    return null;
  }
}
