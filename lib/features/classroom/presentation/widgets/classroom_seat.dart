import 'package:flutter/material.dart';

import '../../../../app/app_colors.dart';
import '../../../character/presentation/pixel_character.dart';
import '../models/classroom_scene_member.dart';

class ClassroomSeat extends StatefulWidget {
  const ClassroomSeat({
    required this.seatIndex,
    required this.member,
    required this.onTap,
    super.key,
  });

  final int seatIndex;
  final ClassroomSceneMember? member;
  final VoidCallback? onTap;

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
                        child: PixelCharacter(
                          seed: person.characterSeed,
                          semanticLabel: '${person.name} 도트 캐릭터',
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
                        right: 4,
                        top: 2,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: AppColors.chalk,
                            border: Border.all(
                              color: const Color(0xFF845137),
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(3),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x55000000),
                                offset: Offset(2, 2),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 3,
                              vertical: 2,
                            ),
                            child: person.isOwner
                                ? const Icon(
                                    Icons.star_rounded,
                                    size: 12,
                                    color: AppColors.yellow,
                                  )
                                : Text(
                                    person.compatibility == null
                                        ? '♥'
                                        : '♥ ${person.compatibility!.heartScore}%',
                                    style: const TextStyle(
                                      color: AppColors.coral,
                                      fontSize: 8,
                                      height: 1,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
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
