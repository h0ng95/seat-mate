import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../app/app_colors.dart';
import '../models/classroom_scene_member.dart';
import 'classroom_seat.dart';
import 'seat_assignment_animation.dart';

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
  static const _momentSequence = [
    SeatIdleMotion.emote,
    SeatIdleMotion.lookLeft,
    SeatIdleMotion.bob,
    SeatIdleMotion.lookRight,
    SeatIdleMotion.emote,
  ];
  static const _emotes = ['😊', '✨', '😴', '📚', '💛', '🤔'];

  Timer? _momentTimer;
  int? _activeSeatIndex;
  var _activeMotion = SeatIdleMotion.none;
  String? _activeEmote;
  var _momentCursor = 0;
  var _motionDisabled = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final disabled = MediaQuery.disableAnimationsOf(context);
    if (_motionDisabled == disabled &&
        (_motionDisabled || _momentTimer != null)) {
      return;
    }
    _motionDisabled = disabled;
    if (disabled) {
      _momentTimer?.cancel();
      _momentTimer = null;
      _clearMoment();
      return;
    }
    _scheduleMoment(const Duration(milliseconds: 1100));
  }

  @override
  void didUpdateWidget(covariant ClassroomScene oldWidget) {
    super.didUpdateWidget(oldWidget);
    final seatIndexes = widget.members
        .map((member) => member.seatIndex)
        .toSet();
    if (!seatIndexes.contains(_activeSeatIndex) ||
        widget.enteringMember != null) {
      _clearMoment();
    }
    if (oldWidget.enteringMember != widget.enteringMember &&
        widget.enteringMember == null) {
      _scheduleMoment(const Duration(milliseconds: 900));
    }
  }

  @override
  void dispose() {
    _momentTimer?.cancel();
    super.dispose();
  }

  void _scheduleMoment(Duration delay) {
    if (_motionDisabled || _momentTimer != null) return;
    _momentTimer = Timer(delay, () {
      _momentTimer = null;
      if (!mounted) return;
      if (widget.enteringMember != null || widget.members.isEmpty) {
        _scheduleMoment(const Duration(milliseconds: 1000));
        return;
      }
      final members = [...widget.members]
        ..sort((a, b) => a.seatIndex.compareTo(b.seatIndex));
      final member = members[_momentCursor % members.length];
      final motion = _momentSequence[_momentCursor % _momentSequence.length];
      final emote = motion == SeatIdleMotion.emote
          ? _emotes[_momentCursor % _emotes.length]
          : null;
      _momentCursor += 1;
      setState(() {
        _activeSeatIndex = member.seatIndex;
        _activeMotion = motion;
        _activeEmote = emote;
      });
      final visibleDuration = motion == SeatIdleMotion.emote
          ? const Duration(milliseconds: 1050)
          : const Duration(milliseconds: 720);
      _momentTimer = Timer(visibleDuration, () {
        _momentTimer = null;
        if (!mounted) return;
        setState(_clearMoment);
        final pause = Duration(milliseconds: 1250 + (_momentCursor % 3) * 250);
        _scheduleMoment(pause);
      });
    });
  }

  void _clearMoment() {
    _activeSeatIndex = null;
    _activeMotion = SeatIdleMotion.none;
    _activeEmote = null;
  }

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
                        idleMotion: _activeSeatIndex == index
                            ? _activeMotion
                            : SeatIdleMotion.none,
                        emote: _activeSeatIndex == index ? _activeEmote : null,
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  ClassroomSceneMember? _memberAt(int seatIndex) {
    for (final member in widget.members) {
      if (member.seatIndex == seatIndex) return member;
    }
    return null;
  }
}
