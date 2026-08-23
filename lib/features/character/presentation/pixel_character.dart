import 'package:flutter/material.dart';

import '../../../app/app_colors.dart';
import '../domain/character_generator.dart';
import '../domain/character_parts.dart';

class PixelCharacter extends StatelessWidget {
  const PixelCharacter({required this.seed, this.semanticLabel, super.key});

  final String seed;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: semanticLabel,
      child: ExcludeSemantics(
        child: CustomPaint(
          painter: _PixelCharacterPainter(CharacterGenerator.fromSeed(seed)),
          size: const Size(24, 32),
        ),
      ),
    );
  }
}

class _PixelCharacterPainter extends CustomPainter {
  const _PixelCharacterPainter(this.parts);

  final CharacterParts parts;

  static const _hairColors = [
    Color(0xFF3A302B),
    Color(0xFF252729),
    Color(0xFF68473A),
    Color(0xFF8A624B),
    Color(0xFF706761),
    Color(0xFF303846),
  ];

  static const _topColors = [
    Color(0xFFF4F0E5),
    Color(0xFF93BAD0),
    Color(0xFF91B39A),
    Color(0xFFE7C875),
    Color(0xFFD98372),
    Color(0xFFD79AA3),
    Color(0xFF4A5052),
    Color(0xFFAAA4B8),
  ];

  static const _skinColors = [
    Color(0xFFF3C7A5),
    Color(0xFFE8B58F),
    Color(0xFFD89B76),
    Color(0xFFC98562),
    Color(0xFFA9694E),
    Color(0xFF80503F),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 24;
    canvas.save();
    canvas.scale(scale, scale);

    final hair = Paint()..color = _hairColors[parts.hairColorIndex];
    final skin = Paint()..color = _skinColors[parts.skinColorIndex];
    final top = Paint()..color = _topColors[parts.topColorIndex];
    final ink = Paint()..color = AppColors.ink;
    final accent = Paint()..color = AppColors.coral;

    _drawBackHair(canvas, hair);
    _rect(canvas, 8, 8, 8, 11, skin);
    _drawFrontHair(canvas, hair);
    _rect(canvas, 6, 18, 12, 11, top);
    _rect(canvas, 4, 21, 2, 7, skin);
    _rect(canvas, 18, 21, 2, 7, skin);
    _rect(canvas, 7, 29, 4, 3, ink);
    _rect(canvas, 13, 29, 4, 3, ink);

    _drawFace(canvas, ink, accent);
    _drawAccessory(canvas, ink, accent);
    _drawPose(canvas, skin, ink);
    canvas.restore();
  }

  void _drawBackHair(Canvas canvas, Paint paint) {
    switch (parts.hairStyle) {
      case HairStyle.long:
      case HairStyle.wave:
        _rect(canvas, 6, 5, 12, 15, paint);
      case HairStyle.fluffy:
      case HairStyle.shortCurl:
        _rect(canvas, 5, 5, 14, 10, paint);
        _rect(canvas, 4, 8, 2, 5, paint);
        _rect(canvas, 18, 8, 2, 5, paint);
      case HairStyle.halfTie:
        _rect(canvas, 6, 5, 12, 11, paint);
        _rect(canvas, 18, 7, 3, 6, paint);
      case HairStyle.beanie:
        _rect(canvas, 6, 4, 12, 8, paint);
      case HairStyle.neat:
      case HairStyle.parted:
        _rect(canvas, 6, 5, 12, 9, paint);
    }
  }

  void _drawFrontHair(Canvas canvas, Paint paint) {
    _rect(canvas, 7, 5, 10, 4, paint);
    switch (parts.hairStyle) {
      case HairStyle.parted:
        _rect(canvas, 7, 8, 4, 3, paint);
      case HairStyle.wave:
      case HairStyle.long:
        _rect(canvas, 6, 8, 2, 9, paint);
        _rect(canvas, 16, 8, 2, 9, paint);
      case HairStyle.fluffy:
      case HairStyle.shortCurl:
        _rect(canvas, 6, 7, 3, 3, paint);
        _rect(canvas, 11, 6, 3, 3, paint);
        _rect(canvas, 16, 7, 2, 3, paint);
      case HairStyle.halfTie:
      case HairStyle.neat:
        _rect(canvas, 7, 8, 3, 2, paint);
      case HairStyle.beanie:
        _rect(canvas, 5, 7, 14, 3, paint);
    }
  }

  void _drawFace(Canvas canvas, Paint ink, Paint accent) {
    switch (parts.faceStyle) {
      case FaceStyle.smile:
        _rect(canvas, 9, 12, 2, 1, ink);
        _rect(canvas, 14, 12, 2, 1, ink);
        _rect(canvas, 11, 15, 3, 1, accent);
      case FaceStyle.blank:
        _rect(canvas, 9, 12, 1, 1, ink);
        _rect(canvas, 15, 12, 1, 1, ink);
        _rect(canvas, 11, 15, 3, 1, ink);
      case FaceStyle.playful:
        _rect(canvas, 9, 12, 2, 1, ink);
        _rect(canvas, 15, 12, 1, 2, ink);
        _rect(canvas, 11, 15, 4, 1, accent);
      case FaceStyle.sleepy:
        _rect(canvas, 9, 13, 2, 1, ink);
        _rect(canvas, 14, 13, 2, 1, ink);
        _rect(canvas, 12, 15, 2, 1, ink);
      case FaceStyle.calm:
        _rect(canvas, 9, 12, 1, 2, ink);
        _rect(canvas, 15, 12, 1, 2, ink);
        _rect(canvas, 12, 15, 2, 1, ink);
    }
  }

  void _drawAccessory(Canvas canvas, Paint ink, Paint accent) {
    switch (parts.accessoryStyle) {
      case AccessoryStyle.none:
        return;
      case AccessoryStyle.roundGlasses:
      case AccessoryStyle.squareGlasses:
        _rect(canvas, 8, 11, 4, 4, ink);
        _rect(canvas, 13, 11, 4, 4, ink);
        _rect(canvas, 12, 12, 1, 1, ink);
        final skin = Paint()..color = _skinColors[parts.skinColorIndex];
        _rect(canvas, 9, 12, 2, 2, skin);
        _rect(canvas, 14, 12, 2, 2, skin);
      case AccessoryStyle.hairPin:
        _rect(canvas, 16, 8, 3, 1, accent);
      case AccessoryStyle.headphones:
        _rect(canvas, 5, 10, 2, 6, accent);
        _rect(canvas, 17, 10, 2, 6, accent);
      case AccessoryStyle.pen:
        _rect(canvas, 16, 19, 1, 5, accent);
    }
  }

  void _drawPose(Canvas canvas, Paint skin, Paint ink) {
    switch (parts.poseStyle) {
      case PoseStyle.reading:
        _rect(canvas, 8, 23, 8, 4, Paint()..color = AppColors.chalk);
        _rect(canvas, 12, 23, 1, 4, ink);
      case PoseStyle.waving:
        _rect(canvas, 19, 18, 2, 5, skin);
      case PoseStyle.side:
        _rect(canvas, 16, 20, 4, 2, skin);
      case PoseStyle.front:
        return;
    }
  }

  void _rect(
    Canvas canvas,
    double x,
    double y,
    double width,
    double height,
    Paint paint,
  ) {
    canvas.drawRect(Rect.fromLTWH(x, y, width, height), paint);
  }

  @override
  bool shouldRepaint(covariant _PixelCharacterPainter oldDelegate) {
    return oldDelegate.parts != parts;
  }
}
