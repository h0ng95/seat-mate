import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../character/presentation/pixel_character.dart';
import '../models/classroom_scene_member.dart';

class WanderingStudent extends StatelessWidget {
  const WanderingStudent({
    required this.member,
    required this.onTap,
    required this.onComplete,
    super.key,
  });

  final ClassroomSceneMember member;
  final VoidCallback onTap;
  final VoidCallback onComplete;

  static const duration = Duration(milliseconds: 6800);

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final route = _WanderRoute.fromScene(
            constraints.biggest,
            member.seatIndex,
          );
          return TweenAnimationBuilder<double>(
            key: ValueKey('wander-${member.characterSeed}'),
            tween: Tween(begin: 0, end: 1),
            duration: duration,
            curve: Curves.linear,
            onEnd: onComplete,
            builder: (context, progress, child) {
              final position = route.positionAt(progress);
              final previous = route.positionAt(math.max(0, progress - 0.004));
              final delta = position - previous;
              final isPaused = progress >= 0.52 && progress <= 0.64;
              final isWalking = progress > 0.01 && !isPaused;
              final step = (progress * 48).floor();
              final bob = isWalking
                  ? -math.sin(progress * math.pi * 48).abs() * 1.8
                  : 0.0;
              final mirrored = delta.dx.abs() > 0.15
                  ? delta.dx < 0
                  : member.seatIndex.isOdd;

              return Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: position.dx,
                    top: position.dy + bob,
                    width: route.characterWidth,
                    height: route.characterHeight,
                    child: Semantics(
                      button: true,
                      label: '${member.name}, 교실을 산책 중',
                      child: GestureDetector(
                        key: const ValueKey('classroom-wandering-student'),
                        behavior: HitTestBehavior.opaque,
                        onTap: onTap,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Positioned.fill(
                              child: PixelCharacter(
                                seed: member.characterSeed,
                                semanticLabel: '${member.name} 도트 캐릭터',
                                walkFrame: isWalking
                                    ? (step.isEven ? 1 : 2)
                                    : 0,
                                mirrored: mirrored,
                              ),
                            ),
                            if (isPaused)
                              Positioned(
                                right: -4,
                                top: -8,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF9F4E8),
                                    border: Border.all(
                                      color: const Color(0xFF5A4335),
                                      width: 1.5,
                                    ),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                  child: const Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 3,
                                    ),
                                    child: Text(
                                      '···',
                                      style: TextStyle(
                                        color: Color(0xFF5A4335),
                                        fontSize: 8,
                                        height: 1.2,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _WanderRoute {
  const _WanderRoute({
    required this.start,
    required this.exit,
    required this.lane,
    required this.target,
    required this.characterWidth,
    required this.characterHeight,
  });

  factory _WanderRoute.fromScene(Size size, int seatIndex) {
    const horizontalGap = 5.0;
    const verticalGap = 5.0;
    final gridLeft = size.width * 0.085;
    final gridTop = size.height * 0.28;
    final gridWidth = size.width - gridLeft * 2;
    final cellWidth = (gridWidth - horizontalGap * 2) / 3;
    final cellHeight = cellWidth / 1.32;
    final characterWidth = (cellWidth * 0.36).clamp(30.0, 44.0);
    final characterHeight = characterWidth * 1.28;
    final column = seatIndex % 3;
    final row = seatIndex ~/ 3;
    final cellLeft = gridLeft + column * (cellWidth + horizontalGap);
    final rowTop = gridTop + row * (cellHeight + verticalGap);
    final start = Offset(cellLeft + (cellWidth - characterWidth) / 2, rowTop);
    final exit = Offset(start.dx, rowTop + cellHeight * 0.56);
    final useRightLane = column == 2 || (column == 1 && seatIndex.isEven);
    final laneCenter = useRightLane
        ? gridLeft + cellWidth * 2 + horizontalGap * 1.5
        : gridLeft + cellWidth + horizontalGap * 0.5;
    final laneX = (laneCenter - characterWidth / 2).clamp(
      4.0,
      size.width - characterWidth - 4,
    );
    final lane = Offset(laneX, exit.dy);
    final targetY = row == 2
        ? gridTop - cellHeight * 0.76
        : gridTop + (cellHeight + verticalGap) * 3 + cellHeight * 0.03;

    return _WanderRoute(
      start: start,
      exit: exit,
      lane: lane,
      target: Offset(laneX, targetY),
      characterWidth: characterWidth,
      characterHeight: characterHeight,
    );
  }

  final Offset start;
  final Offset exit;
  final Offset lane;
  final Offset target;
  final double characterWidth;
  final double characterHeight;

  Offset positionAt(double progress) {
    if (progress <= 0.10) {
      return Offset.lerp(start, exit, progress / 0.10)!;
    }
    if (progress <= 0.25) {
      return Offset.lerp(exit, lane, (progress - 0.10) / 0.15)!;
    }
    if (progress <= 0.52) {
      return Offset.lerp(lane, target, (progress - 0.25) / 0.27)!;
    }
    if (progress <= 0.64) return target;
    if (progress <= 0.86) {
      return Offset.lerp(target, lane, (progress - 0.64) / 0.22)!;
    }
    if (progress <= 0.96) {
      return Offset.lerp(lane, exit, (progress - 0.86) / 0.10)!;
    }
    return Offset.lerp(exit, start, (progress - 0.96) / 0.04)!;
  }
}
