import 'package:flutter_test/flutter_test.dart';
import 'package:seat_mate/features/character/domain/character_generator.dart';
import 'package:seat_mate/features/character/domain/character_gender.dart';
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

  test('gender-tagged seeds produce matching character silhouettes', () {
    final male = CharacterGenerator.fromSeed(
      const CharacterIdentity(
        gender: CharacterGender.male,
        baseSeed: 'same-person',
      ).storedSeed,
    );
    final female = CharacterGenerator.fromSeed(
      const CharacterIdentity(
        gender: CharacterGender.female,
        baseSeed: 'same-person',
      ).storedSeed,
    );

    expect(male.gender, CharacterGender.male);
    expect(female.gender, CharacterGender.female);
    expect(
      male.hairStyle,
      isIn(const [
        HairStyle.neat,
        HairStyle.parted,
        HairStyle.fluffy,
        HairStyle.shortCurl,
        HairStyle.beanie,
      ]),
    );
    expect(
      female.hairStyle,
      isIn(const [
        HairStyle.wave,
        HairStyle.long,
        HairStyle.halfTie,
        HairStyle.neat,
      ]),
    );
  });

  test('old untagged character seeds remain supported', () {
    final parts = CharacterGenerator.fromSeed('legacy-student');

    expect(parts.gender, CharacterGender.unspecified);
  });
}
