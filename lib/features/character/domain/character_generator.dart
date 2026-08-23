import 'dart:convert';

import 'package:crypto/crypto.dart';

import 'character_gender.dart';
import 'character_parts.dart';

abstract final class CharacterGenerator {
  static CharacterParts fromSeed(String seed) {
    final identity = CharacterIdentity.parse(seed);
    final bytes = sha256
        .convert(utf8.encode('v1|character|${identity.baseSeed}'))
        .bytes;
    final hairStyles = switch (identity.gender) {
      CharacterGender.male => const [
        HairStyle.neat,
        HairStyle.parted,
        HairStyle.fluffy,
        HairStyle.shortCurl,
        HairStyle.beanie,
      ],
      CharacterGender.female => const [
        HairStyle.wave,
        HairStyle.long,
        HairStyle.halfTie,
        HairStyle.neat,
      ],
      CharacterGender.unspecified => HairStyle.values,
    };
    final accessories = switch (identity.gender) {
      CharacterGender.male => const [
        AccessoryStyle.none,
        AccessoryStyle.roundGlasses,
        AccessoryStyle.squareGlasses,
        AccessoryStyle.headphones,
        AccessoryStyle.pen,
      ],
      _ => AccessoryStyle.values,
    };
    final hairStyle = hairStyles[_index(bytes[0], hairStyles.length)];
    var accessory = accessories[_index(bytes[4], accessories.length)];

    if (hairStyle == HairStyle.beanie && accessory == AccessoryStyle.hairPin) {
      accessory = AccessoryStyle.none;
    }

    return CharacterParts(
      gender: identity.gender,
      hairStyle: hairStyle,
      hairColorIndex: _index(bytes[1], 6),
      topColorIndex: _index(bytes[2], 8),
      faceStyle: FaceStyle.values[_index(bytes[3], FaceStyle.values.length)],
      accessoryStyle: accessory,
      poseStyle: PoseStyle.values[_index(bytes[5], PoseStyle.values.length)],
      skinColorIndex: _index(bytes[6], 6),
      bottomColorIndex: _index(bytes[7], 6),
      shoeColorIndex: _index(bytes[8], 4),
    );
  }

  static int _index(int byte, int count) => byte * count ~/ 256;
}
