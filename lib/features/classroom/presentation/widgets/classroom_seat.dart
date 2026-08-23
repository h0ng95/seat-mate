import 'package:flutter/material.dart';

import '../../../../app/app_colors.dart';
import '../../../character/presentation/pixel_character.dart';
import '../models/classroom_scene_member.dart';

enum SeatIdleMotion { none, bob, lookLeft, lookRight, emote }

class ClassroomSeat extends StatefulWidget {
  const ClassroomSeat({
    required this.seatIndex,
    required this.member,
    required this.onTap,
    this.idleMotion = SeatIdleMotion.none,
    this.emote,
    super.key,
  });

  final int seatIndex;
  final ClassroomSceneMember? member;
  final VoidCallback? onTap;
  final SeatIdleMotion idleMotion;
  final String? emote;

  @override
  State<ClassroomSeat> createState() => _ClassroomSeatState();
}

class _ClassroomSeatState extends State<ClassroomSeat> {
  var _hovered = false;

  @override
  Widget build(BuildContext context) {
    final person = widget.member;
    return Semantics(
      button: person != null,
      label: person == null
          ? '빈 자리'
          : '${person.name}, ${person.seatDescription}, ${person.relationshipTitle}',
      child: MouseRegion(
        cursor: person == null ? MouseCursor.defer : SystemMouseCursors.click,
        onEnter: person == null ? null : (_) => setState(() => _hovered = true),
        onExit: person == null ? null : (_) => setState(() => _hovered = false),
        child: GestureDetector(
          key: ValueKey('seat-${widget.seatIndex}'),
          behavior: HitTestBehavior.opaque,
          onTap: widget.onTap,
          child: AnimatedScale(
            scale: _hovered ? 1.045 : 1,
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeOut,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final emote = widget.emote;
                final isBob = widget.idleMotion == SeatIdleMotion.bob;
                final isLookingLeft =
                    widget.idleMotion == SeatIdleMotion.lookLeft;
                final isLookingRight =
                    widget.idleMotion == SeatIdleMotion.lookRight;
                return Stack(
                  alignment: Alignment.topCenter,
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      top: constraints.maxHeight * 0.29,
                      width: constraints.maxWidth * 0.42,
                      height: constraints.maxHeight * 0.43,
                      child: const _ChairBack(),
                    ),
                    if (person != null)
                      Positioned(
                        top: 0,
                        width: constraints.maxWidth * 0.43,
                        height: constraints.maxHeight * 0.62,
                        child: AnimatedSlide(
                          offset: isBob
                              ? const Offset(0, -0.055)
                              : isLookingLeft
                              ? const Offset(-0.035, 0)
                              : isLookingRight
                              ? const Offset(0.035, 0)
                              : Offset.zero,
                          duration: const Duration(milliseconds: 180),
                          curve: Curves.easeOutBack,
                          child: AnimatedScale(
                            scale: isBob ? 1.025 : 1,
                            duration: const Duration(milliseconds: 180),
                            curve: Curves.easeOutBack,
                            child: AnimatedRotation(
                              turns: isLookingLeft
                                  ? -0.008
                                  : isLookingRight
                                  ? 0.008
                                  : 0,
                              duration: const Duration(milliseconds: 180),
                              curve: Curves.easeOut,
                              child: PixelCharacter(
                                seed: person.characterSeed,
                                semanticLabel: '${person.name} 도트 캐릭터',
                                gazeDirection: isLookingLeft
                                    ? -1
                                    : isLookingRight
                                    ? 1
                                    : 0,
                              ),
                            ),
                          ),
                        ),
                      ),
                    const Positioned.fill(
                      child: CustomPaint(painter: _DeskPainter()),
                    ),
                    if (person != null)
                      Positioned(
                        left: 13,
                        right: 13,
                        bottom: 6,
                        height: 20,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: const Color(0xFF315B48),
                            border: Border.all(
                              color: const Color(0xFF233D33),
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(2),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x55000000),
                                offset: Offset(2, 2),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              person.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.chalk,
                                fontSize: 10,
                                height: 1,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                      ),
                    if (person != null)
                      Positioned(
                        right: 1,
                        top: 0,
                        child: person.isOwner
                            ? const _OwnerSeatBadge()
                            : _CompatibilityHeartBadge(
                                key: ValueKey(
                                  'heart-score-${widget.seatIndex}',
                                ),
                                score: person.compatibility?.heartScore,
                              ),
                      ),
                    if (person != null &&
                        widget.idleMotion == SeatIdleMotion.emote &&
                        emote != null)
                      Positioned(
                        left: 2,
                        top: 0,
                        child: Semantics(
                          label: '${person.name}의 기분 $emote',
                          child: TweenAnimationBuilder<double>(
                            key: ValueKey('seat-emote-${widget.seatIndex}'),
                            tween: Tween(begin: 0.72, end: 1),
                            duration: const Duration(milliseconds: 180),
                            curve: Curves.easeOutBack,
                            builder: (context, scale, child) =>
                                Transform.scale(scale: scale, child: child),
                            child: _EmoteBubble(emote: emote),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _CompatibilityHeartBadge extends StatelessWidget {
  const _CompatibilityHeartBadge({required this.score, super.key});

  final int? score;

  @override
  Widget build(BuildContext context) {
    final scoreLabel = score == null ? '?' : '$score%';
    return Semantics(
      label: score == null ? '케미 지수 계산 중' : '케미 지수 $score퍼센트',
      child: ExcludeSemantics(
        child: SizedBox(
          width: 38,
          height: 32,
          child: Stack(
            alignment: Alignment.center,
            children: [
              const Positioned(
                left: 2,
                top: 3,
                child: Icon(
                  Icons.favorite_rounded,
                  size: 34,
                  color: Color(0xFF74383B),
                ),
              ),
              const Positioned(
                left: 3,
                top: 1,
                child: Icon(
                  Icons.favorite_rounded,
                  size: 32,
                  color: AppColors.coral,
                ),
              ),
              Positioned(
                top: 9,
                child: Text(
                  scoreLabel,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    height: 1,
                    fontWeight: FontWeight.w900,
                    shadows: [
                      Shadow(color: Color(0xAA74383B), offset: Offset(1, 1)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OwnerSeatBadge extends StatelessWidget {
  const _OwnerSeatBadge();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '우리 반 생성자',
      child: const ExcludeSemantics(
        child: SizedBox(
          width: 30,
          height: 30,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned(
                left: 2,
                top: 3,
                child: Icon(
                  Icons.star_rounded,
                  size: 27,
                  color: Color(0xFF735122),
                ),
              ),
              Positioned(
                left: 3,
                top: 1,
                child: Icon(
                  Icons.star_rounded,
                  size: 25,
                  color: AppColors.yellow,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmoteBubble extends StatelessWidget {
  const _EmoteBubble({required this.emote});

  final String emote;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 34,
      height: 29,
      child: CustomPaint(
        painter: const _EmoteBubblePainter(),
        child: Align(
          alignment: const Alignment(0, -0.35),
          child: ExcludeSemantics(
            child: Text(emote, style: const TextStyle(fontSize: 14, height: 1)),
          ),
        ),
      ),
    );
  }
}

class _EmoteBubblePainter extends CustomPainter {
  const _EmoteBubblePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final shadow = Paint()
      ..color = const Color(0x44000000)
      ..isAntiAlias = false;
    final fill = Paint()
      ..color = const Color(0xFFFFFBF1)
      ..isAntiAlias = false;
    final outline = Paint()
      ..color = const Color(0xFF5A4335)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..isAntiAlias = false;
    final bubble = RRect.fromRectAndRadius(
      Rect.fromLTWH(1, 1, size.width - 4, size.height - 8),
      const Radius.circular(5),
    );
    canvas.drawRRect(bubble.shift(const Offset(2, 2)), shadow);
    canvas.drawRRect(bubble, fill);
    canvas.drawRRect(bubble, outline);
    final tail = Path()
      ..moveTo(11, size.height - 7)
      ..lineTo(15, size.height - 2)
      ..lineTo(19, size.height - 7)
      ..close();
    canvas.drawPath(tail.shift(const Offset(2, 2)), shadow);
    canvas.drawPath(tail, fill);
    canvas.drawPath(tail, outline);
  }

  @override
  bool shouldRepaint(covariant _EmoteBubblePainter oldDelegate) => false;
}

class _ChairBack extends StatelessWidget {
  const _ChairBack();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFBD7042),
        border: Border.all(color: const Color(0xFF6D3E2C), width: 2),
        borderRadius: BorderRadius.circular(3),
        boxShadow: const [
          BoxShadow(color: Color(0x66000000), offset: Offset(2, 3)),
        ],
      ),
    );
  }
}

class _DeskPainter extends CustomPainter {
  const _DeskPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final outline = Paint()..color = const Color(0xFF673A28);
    final shadow = Paint()..color = const Color(0x55000000);
    final top = Paint()..color = const Color(0xFFD58A4E);
    final edge = Paint()..color = const Color(0xFFA75E37);
    final shine = Paint()..color = const Color(0xFFE7AA6D);

    canvas.drawOval(
      Rect.fromLTWH(8, size.height * 0.61, size.width - 12, size.height * 0.28),
      shadow,
    );

    final topPath = Path()
      ..moveTo(9, size.height * 0.47)
      ..lineTo(size.width - 9, size.height * 0.47)
      ..lineTo(size.width - 3, size.height * 0.68)
      ..lineTo(3, size.height * 0.68)
      ..close();
    canvas.drawPath(topPath, outline);

    final insetTop = Path()
      ..moveTo(11, size.height * 0.49)
      ..lineTo(size.width - 11, size.height * 0.49)
      ..lineTo(size.width - 6, size.height * 0.64)
      ..lineTo(6, size.height * 0.64)
      ..close();
    canvas.drawPath(insetTop, top);
    canvas.drawRect(
      Rect.fromLTWH(9, size.height * 0.51, size.width - 18, 2),
      shine,
    );

    canvas.drawRect(
      Rect.fromLTWH(5, size.height * 0.67, size.width - 10, size.height * 0.17),
      outline,
    );
    canvas.drawRect(
      Rect.fromLTWH(8, size.height * 0.68, size.width - 16, size.height * 0.12),
      edge,
    );
    canvas.drawRect(
      Rect.fromLTWH(9, size.height * 0.82, 5, size.height * 0.09),
      outline,
    );
    canvas.drawRect(
      Rect.fromLTWH(size.width - 14, size.height * 0.82, 5, size.height * 0.09),
      outline,
    );
  }

  @override
  bool shouldRepaint(covariant _DeskPainter oldDelegate) => false;
}
