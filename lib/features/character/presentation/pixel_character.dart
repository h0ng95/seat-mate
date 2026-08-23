import 'dart:math' as math;

import 'package:flutter/material.dart';

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
          size: const Size(32, 40),
        ),
      ),
    );
  }
}

class _PixelCharacterPainter extends CustomPainter {
  const _PixelCharacterPainter(this.parts);

  final CharacterParts parts;

  static const _outline = Color(0xFF302A2B);
  static const _shadow = Color(0x55352A24);

  static const _hairColors = [
    Color(0xFF332A29),
    Color(0xFF20252D),
    Color(0xFF633D2C),
    Color(0xFF9A5D32),
    Color(0xFF645A61),
    Color(0xFF263A54),
  ];

  static const _topColors = [
    Color(0xFFF7EEE0),
    Color(0xFF58A6C7),
    Color(0xFF65AF83),
    Color(0xFFF1C653),
    Color(0xFFE8735E),
    Color(0xFFD67EA0),
    Color(0xFF46566A),
    Color(0xFF8C7CC4),
  ];

  static const _skinColors = [
    Color(0xFFFFD5B5),
    Color(0xFFF2BE95),
    Color(0xFFE0A078),
    Color(0xFFC9805D),
    Color(0xFFA85E43),
    Color(0xFF754536),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final scale = math.min(size.width / 32, size.height / 40);
    final offsetX = (size.width - 32 * scale) / 2;
    final offsetY = size.height - 40 * scale;
    canvas.save();
    canvas.translate(offsetX, offsetY);
    canvas.scale(scale, scale);

    final outline = _paint(_outline);
    final hair = _paint(_hairColors[parts.hairColorIndex]);
    final skin = _paint(_skinColors[parts.skinColorIndex]);
    final top = _paint(_topColors[parts.topColorIndex]);
    final accent = _paint(const Color(0xFFE85F65));
    final pants = _paint(const Color(0xFF344252));
    final shoe = _paint(const Color(0xFF25272C));

    _oval(canvas, 7, 36, 18, 3, _paint(_shadow));
    _drawLegs(canvas, pants, shoe);
    _drawBody(canvas, outline, top, skin);
    _drawHairBack(canvas, hair, outline);
    _drawHead(canvas, outline, skin);
    _drawHairFront(canvas, hair);
    _drawFace(canvas, outline, accent);
    _drawAccessory(canvas, outline, accent, skin);
    _drawPose(canvas, outline, skin);

    canvas.restore();
  }

  void _drawLegs(Canvas canvas, Paint pants, Paint shoe) {
    _rect(canvas, 10, 31, 5, 6, pants);
    _rect(canvas, 17, 31, 5, 6, pants);
    _rect(canvas, 9, 36, 6, 2, shoe);
    _rect(canvas, 17, 36, 6, 2, shoe);
  }

  void _drawBody(Canvas canvas, Paint outline, Paint top, Paint skin) {
    _rect(canvas, 8, 21, 16, 12, outline);
    _rect(canvas, 10, 21, 12, 11, top);
    _rect(canvas, 7, 23, 3, 8, outline);
    _rect(canvas, 8, 24, 2, 6, skin);
    _rect(canvas, 22, 23, 3, 8, outline);
    _rect(canvas, 22, 24, 2, 6, skin);
    _rect(canvas, 14, 22, 4, 2, _paint(const Color(0x55FFFFFF)));
  }

  void _drawHead(Canvas canvas, Paint outline, Paint skin) {
    _rect(canvas, 8, 7, 16, 14, outline);
    _rect(canvas, 9, 8, 14, 12, skin);
    _rect(canvas, 6, 12, 3, 5, outline);
    _rect(canvas, 7, 13, 2, 3, skin);
    _rect(canvas, 23, 12, 3, 5, outline);
    _rect(canvas, 23, 13, 2, 3, skin);
  }

  void _drawHairBack(Canvas canvas, Paint hair, Paint outline) {
    switch (parts.hairStyle) {
      case HairStyle.long:
      case HairStyle.wave:
        _rect(canvas, 7, 5, 18, 17, outline);
        _rect(canvas, 8, 6, 16, 15, hair);
      case HairStyle.fluffy:
      case HairStyle.shortCurl:
        _rect(canvas, 6, 5, 20, 11, outline);
        _rect(canvas, 7, 4, 6, 4, hair);
        _rect(canvas, 12, 3, 7, 4, hair);
        _rect(canvas, 18, 4, 7, 4, hair);
      case HairStyle.halfTie:
        _rect(canvas, 7, 5, 18, 13, outline);
        _rect(canvas, 8, 6, 16, 11, hair);
        _rect(canvas, 24, 7, 4, 7, outline);
        _rect(canvas, 24, 8, 3, 5, hair);
      case HairStyle.beanie:
        _rect(canvas, 7, 5, 18, 8, outline);
        _rect(canvas, 8, 4, 16, 8, hair);
      case HairStyle.neat:
      case HairStyle.parted:
        _rect(canvas, 7, 5, 18, 10, outline);
        _rect(canvas, 8, 6, 16, 8, hair);
    }
  }

  void _drawHairFront(Canvas canvas, Paint hair) {
    _rect(canvas, 9, 7, 14, 4, hair);
    switch (parts.hairStyle) {
      case HairStyle.parted:
        _rect(canvas, 9, 10, 5, 3, hair);
        _rect(canvas, 19, 9, 4, 2, hair);
      case HairStyle.wave:
      case HairStyle.long:
        _rect(canvas, 8, 9, 3, 9, hair);
        _rect(canvas, 21, 9, 3, 9, hair);
      case HairStyle.fluffy:
      case HairStyle.shortCurl:
        _rect(canvas, 8, 8, 5, 3, hair);
        _rect(canvas, 14, 7, 5, 3, hair);
        _rect(canvas, 20, 8, 4, 3, hair);
      case HairStyle.halfTie:
      case HairStyle.neat:
        _rect(canvas, 9, 9, 5, 3, hair);
      case HairStyle.beanie:
        _rect(canvas, 7, 8, 18, 3, hair);
    }
  }

  void _drawFace(Canvas canvas, Paint outline, Paint accent) {
    switch (parts.faceStyle) {
      case FaceStyle.smile:
        _rect(canvas, 11, 14, 2, 2, outline);
        _rect(canvas, 19, 14, 2, 2, outline);
        _rect(canvas, 14, 18, 4, 1, accent);
      case FaceStyle.blank:
        _rect(canvas, 11, 14, 2, 2, outline);
        _rect(canvas, 19, 14, 2, 2, outline);
        _rect(canvas, 15, 18, 3, 1, outline);
      case FaceStyle.playful:
        _rect(canvas, 11, 14, 2, 2, outline);
        _rect(canvas, 19, 15, 2, 1, outline);
        _rect(canvas, 14, 18, 5, 1, accent);
      case FaceStyle.sleepy:
        _rect(canvas, 11, 15, 3, 1, outline);
        _rect(canvas, 18, 15, 3, 1, outline);
        _rect(canvas, 15, 18, 2, 1, outline);
      case FaceStyle.calm:
        _rect(canvas, 11, 14, 2, 2, outline);
        _rect(canvas, 19, 14, 2, 2, outline);
        _rect(canvas, 15, 18, 2, 1, outline);
    }
  }

  void _drawAccessory(Canvas canvas, Paint outline, Paint accent, Paint skin) {
    switch (parts.accessoryStyle) {
      case AccessoryStyle.none:
        return;
      case AccessoryStyle.roundGlasses:
      case AccessoryStyle.squareGlasses:
        _rect(canvas, 10, 13, 5, 4, outline);
        _rect(canvas, 18, 13, 5, 4, outline);
        _rect(canvas, 15, 14, 3, 1, outline);
        _rect(canvas, 11, 14, 3, 2, skin);
        _rect(canvas, 19, 14, 3, 2, skin);
      case AccessoryStyle.hairPin:
        _rect(canvas, 21, 9, 4, 2, accent);
      case AccessoryStyle.headphones:
        _rect(canvas, 6, 10, 3, 7, accent);
        _rect(canvas, 23, 10, 3, 7, accent);
      case AccessoryStyle.pen:
        _rect(canvas, 21, 22, 2, 6, accent);
    }
  }

  void _drawPose(Canvas canvas, Paint outline, Paint skin) {
    switch (parts.poseStyle) {
      case PoseStyle.reading:
        _rect(canvas, 10, 27, 12, 5, outline);
        _rect(canvas, 11, 27, 5, 4, _paint(const Color(0xFFF9F5DE)));
        _rect(canvas, 17, 27, 4, 4, _paint(const Color(0xFFF9F5DE)));
      case PoseStyle.waving:
        _rect(canvas, 23, 19, 3, 8, outline);
        _rect(canvas, 24, 18, 2, 8, skin);
      case PoseStyle.side:
        _rect(canvas, 22, 24, 5, 3, outline);
        _rect(canvas, 22, 24, 4, 2, skin);
      case PoseStyle.front:
        return;
    }
  }

  Paint _paint(Color color) => Paint()
    ..color = color
    ..isAntiAlias = false;

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

  void _oval(
    Canvas canvas,
    double x,
    double y,
    double width,
    double height,
    Paint paint,
  ) {
    canvas.drawOval(Rect.fromLTWH(x, y, width, height), paint);
  }

  @override
  bool shouldRepaint(covariant _PixelCharacterPainter oldDelegate) {
    return oldDelegate.parts != parts;
  }
}
