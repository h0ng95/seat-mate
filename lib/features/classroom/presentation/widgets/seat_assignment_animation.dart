import 'package:flutter/material.dart';

import '../../../character/presentation/pixel_character.dart';

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
            const gridLeft = 42.0;
            const gridTop = 92.0;
            const gridHorizontalGap = 7.0;
            const gridVerticalGap = 8.0;
            final gridWidth = constraints.maxWidth - 84;
            final gridHeight = constraints.maxHeight - 122;
            final cellWidth = (gridWidth - gridHorizontalGap * 2) / 3;
            final cellHeight = (gridHeight - gridVerticalGap * 2) / 3;
            final column = seatIndex % 3;
            final row = seatIndex ~/ 3;
            final target = Offset(
              gridLeft +
                  column * (cellWidth + gridHorizontalGap) +
                  cellWidth / 2 -
                  16,
              gridTop + row * (cellHeight + gridVerticalGap) + 3,
            );
            final start = Offset(constraints.maxWidth - 30, 112);

            return TweenAnimationBuilder<double>(
              key: ValueKey('entering-$characterSeed-$seatIndex'),
              tween: Tween(begin: 0, end: 1),
              duration: reduceMotion
                  ? const Duration(milliseconds: 150)
                  : const Duration(milliseconds: 1400),
              curve: Curves.easeInOutCubic,
              onEnd: onComplete,
              builder: (context, progress, child) {
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
                      width: 32,
                      height: 44,
                      child: child!,
                    ),
                  ],
                );
              },
              child: PixelCharacter(
                seed: characterSeed,
                semanticLabel: '새로운 전학생',
              ),
            );
          },
        ),
      ),
    );
  }
}
