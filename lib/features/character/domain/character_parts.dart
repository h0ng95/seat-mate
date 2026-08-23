import 'character_gender.dart';

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
    this.gender = CharacterGender.unspecified,
    required this.hairStyle,
    required this.hairColorIndex,
    required this.topColorIndex,
    required this.faceStyle,
    required this.accessoryStyle,
    required this.poseStyle,
    required this.skinColorIndex,
    required this.bottomColorIndex,
    required this.shoeColorIndex,
  });

  final CharacterGender gender;
  final HairStyle hairStyle;
  final int hairColorIndex;
  final int topColorIndex;
  final FaceStyle faceStyle;
  final AccessoryStyle accessoryStyle;
  final PoseStyle poseStyle;
  final int skinColorIndex;
  final int bottomColorIndex;
  final int shoeColorIndex;

  CharacterParts copyWith({
    CharacterGender? gender,
    HairStyle? hairStyle,
    int? hairColorIndex,
    int? topColorIndex,
    FaceStyle? faceStyle,
    AccessoryStyle? accessoryStyle,
    PoseStyle? poseStyle,
    int? skinColorIndex,
    int? bottomColorIndex,
    int? shoeColorIndex,
  }) {
    return CharacterParts(
      gender: gender ?? this.gender,
      hairStyle: hairStyle ?? this.hairStyle,
      hairColorIndex: hairColorIndex ?? this.hairColorIndex,
      topColorIndex: topColorIndex ?? this.topColorIndex,
      faceStyle: faceStyle ?? this.faceStyle,
      accessoryStyle: accessoryStyle ?? this.accessoryStyle,
      poseStyle: poseStyle ?? this.poseStyle,
      skinColorIndex: skinColorIndex ?? this.skinColorIndex,
      bottomColorIndex: bottomColorIndex ?? this.bottomColorIndex,
      shoeColorIndex: shoeColorIndex ?? this.shoeColorIndex,
    );
  }

  Map<String, Object> toJson() => {
    'gender': gender.name,
    'hairStyle': hairStyle.name,
    'hairColorIndex': hairColorIndex,
    'topColorIndex': topColorIndex,
    'faceStyle': faceStyle.name,
    'accessoryStyle': accessoryStyle.name,
    'poseStyle': poseStyle.name,
    'skinColorIndex': skinColorIndex,
    'bottomColorIndex': bottomColorIndex,
    'shoeColorIndex': shoeColorIndex,
  };

  factory CharacterParts.fromJson(Map<String, Object?> json) {
    return CharacterParts(
      gender: CharacterGender.values.byName(
        json['gender'] as String? ?? CharacterGender.unspecified.name,
      ),
      hairStyle: HairStyle.values.byName(json['hairStyle']! as String),
      hairColorIndex: json['hairColorIndex']! as int,
      topColorIndex: json['topColorIndex']! as int,
      faceStyle: FaceStyle.values.byName(json['faceStyle']! as String),
      accessoryStyle: AccessoryStyle.values.byName(
        json['accessoryStyle']! as String,
      ),
      poseStyle: PoseStyle.values.byName(json['poseStyle']! as String),
      skinColorIndex: json['skinColorIndex']! as int,
      bottomColorIndex: json['bottomColorIndex']! as int,
      shoeColorIndex: json['shoeColorIndex']! as int,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is CharacterParts &&
        gender == other.gender &&
        hairStyle == other.hairStyle &&
        hairColorIndex == other.hairColorIndex &&
        topColorIndex == other.topColorIndex &&
        faceStyle == other.faceStyle &&
        accessoryStyle == other.accessoryStyle &&
        poseStyle == other.poseStyle &&
        skinColorIndex == other.skinColorIndex &&
        bottomColorIndex == other.bottomColorIndex &&
        shoeColorIndex == other.shoeColorIndex;
  }

  @override
  int get hashCode => Object.hash(
    gender,
    hairStyle,
    hairColorIndex,
    topColorIndex,
    faceStyle,
    accessoryStyle,
    poseStyle,
    skinColorIndex,
    bottomColorIndex,
    shoeColorIndex,
  );
}
