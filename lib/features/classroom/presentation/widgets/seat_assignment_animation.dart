import 'package:flutter/material.dart';

import '../../../character/presentation/pixel_character.dart';
import '../../domain/classroom_seat_layout.dart';

class SeatAssignmentAnimation extends StatelessWidget {
  const SeatAssignmentAnimation({
    required this.seatIndex,
    required this.characterSeed,
    required this.onComplete,
    super.key,
  });

  final int seatIndex;
  final String characterSeed;
  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return Positioned.fill(
      child: IgnorePointer(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final gridLeft = constraints.maxWidth * 0.055;
            final gridTop = constraints.maxHeight * 0.29;
            const deskHorizontalGap = 16.0;
            const deskVerticalGap = 3.0;
            final gridWidth = constraints.maxWidth - gridLeft * 2;
            final deskWidth = (gridWidth - deskHorizontalGap) / 2;
            final deskHeight = deskWidth / 2.05;
            final row = ClassroomSeatLayout.rowOf(seatIndex);
            final rowFromBack = ClassroomSeatLayout.rowCount - 1 - row;
            final division = ClassroomSeatLayout.divisionOf(seatIndex);
            final side = ClassroomSeatLayout.sideOf(seatIndex);
            final halfDeskWidth = deskWidth / 2;
            final target = Offset(
              gridLeft +
                  division * (deskWidth + deskHorizontalGap) +
                  side * halfDeskWidth +
                  halfDeskWidth / 2 -
                  18,
              gridTop + rowFromBack * (deskHeight + deskVerticalGap) + 4,
            );
            final start = Offset(
              constraints.maxWidth * 0.88,
              constraints.maxHeight * 0.22,
            );

            return TweenAnimationBuilder<double>(
              key: ValueKey('entering-$characterSeed-$seatIndex'),
              tween: Tween(begin: 0, end: 1),
              duration: reduceMotion
                  ? const Duration(milliseconds: 150)
                  : const Duration(milliseconds: 1400),
              curve: Curves.easeInOutCubic,
              onEnd: onComplete,
              builder: (context, progress, _) {
                final position = Offset.lerp(start, target, progress)!;
                final bob = reduceMotion
                    ? 0.0
                    : (progress * 12).round().isEven
                    ? 0.0
                    : -2.0;
                return Stack(
                  children: [
                    Positioned(
                      left: position.dx,
                      top: position.dy + bob,
                      width: 36,
                      height: 48,
                      child: PixelCharacter(
                        seed: characterSeed,
                        semanticLabel: '새로운 전학생',
                        walkFrame: reduceMotion
                            ? 0
                            : (progress * 18).floor().isEven
                            ? 1
                            : 2,
                        mirrored: target.dx < start.dx,
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}
