enum HairStyle { neat, parted, wave, long, fluffy, shortCurl, halfTie, beanie }

enum FaceStyle { calm, smile, blank, playful, sleepy }

enum AccessoryStyle {
  none,
  roundGlasses,
  squareGlasses,
  hairPin,
  headphones,
  pen,
}

enum PoseStyle { front, reading, waving, side }

class CharacterParts {
  const CharacterParts({
    required this.hairStyle,
    required this.hairColorIndex,
    required this.topColorIndex,
    required this.faceStyle,
    required this.accessoryStyle,
    required this.poseStyle,
    required this.skinColorIndex,
  });

  final HairStyle hairStyle;
  final int hairColorIndex;
  final int topColorIndex;
  final FaceStyle faceStyle;
  final AccessoryStyle accessoryStyle;
  final PoseStyle poseStyle;
  final int skinColorIndex;

  @override
  bool operator ==(Object other) {
    return other is CharacterParts &&
        hairStyle == other.hairStyle &&
        hairColorIndex == other.hairColorIndex &&
        topColorIndex == other.topColorIndex &&
        faceStyle == other.faceStyle &&
        accessoryStyle == other.accessoryStyle &&
        poseStyle == other.poseStyle &&
        skinColorIndex == other.skinColorIndex;
  }

  @override
  int get hashCode => Object.hash(
    hairStyle,
    hairColorIndex,
    topColorIndex,
    faceStyle,
    accessoryStyle,
    poseStyle,
    skinColorIndex,
  );
}
