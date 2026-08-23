import 'dart:convert';

import 'package:crypto/crypto.dart';

import 'character_parts.dart';

abstract final class CharacterGenerator {
  static CharacterParts fromSeed(String seed) {
    final bytes = sha256.convert(utf8.encode('v1|character|$seed')).bytes;
    final hairStyle =
        HairStyle.values[_index(bytes[0], HairStyle.values.length)];
    var accessory =
        AccessoryStyle.values[_index(bytes[4], AccessoryStyle.values.length)];

    if (hairStyle == HairStyle.beanie && accessory == AccessoryStyle.hairPin) {
      accessory = AccessoryStyle.none;
    }

    return CharacterParts(
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
