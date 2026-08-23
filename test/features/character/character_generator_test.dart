import 'package:flutter_test/flutter_test.dart';
import 'package:seat_mate/features/character/domain/character_generator.dart';
import 'package:seat_mate/features/character/domain/character_parts.dart';

void main() {
  test('the same seed always produces the same character', () {
    final first = CharacterGenerator.fromSeed('재홍|1995-06-12');
    final second = CharacterGenerator.fromSeed('재홍|1995-06-12');

    expect(first, second);
  });

  test('generated part indexes stay inside their palettes', () {
    for (var index = 0; index < 512; index++) {
      final parts = CharacterGenerator.fromSeed('person-$index');

      expect(parts.hairColorIndex, inInclusiveRange(0, 5));
      expect(parts.topColorIndex, inInclusiveRange(0, 7));
      expect(parts.skinColorIndex, inInclusiveRange(0, 5));
      expect(parts.bottomColorIndex, inInclusiveRange(0, 5));
      expect(parts.shoeColorIndex, inInclusiveRange(0, 3));
      expect(parts.hairStyle, isA<HairStyle>());
      expect(parts.faceStyle, isA<FaceStyle>());
    }
  });

  test('appearance can be customized and serialized', () {
    final generated = CharacterGenerator.fromSeed('custom-student');
    final customized = generated.copyWith(
      hairStyle: HairStyle.wave,
      topColorIndex: 3,
      bottomColorIndex: 4,
      accessoryStyle: AccessoryStyle.headphones,
    );

    expect(customized.hairStyle, HairStyle.wave);
    expect(customized.topColorIndex, 3);
    expect(customized.bottomColorIndex, 4);
    expect(customized.accessoryStyle, AccessoryStyle.headphones);
    expect(CharacterParts.fromJson(customized.toJson()), customized);
  });
}
