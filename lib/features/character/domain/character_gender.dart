enum CharacterGender { unspecified, male, female }

class CharacterIdentity {
  const CharacterIdentity({required this.gender, required this.baseSeed});

  final CharacterGender gender;
  final String baseSeed;

  String get storedSeed => switch (gender) {
    CharacterGender.male => 'male|$baseSeed',
    CharacterGender.female => 'female|$baseSeed',
    CharacterGender.unspecified => baseSeed,
  };

  factory CharacterIdentity.parse(String storedSeed) {
    if (storedSeed.startsWith('male|')) {
      return CharacterIdentity(
        gender: CharacterGender.male,
        baseSeed: storedSeed.substring(5),
      );
    }
    if (storedSeed.startsWith('female|')) {
      return CharacterIdentity(
        gender: CharacterGender.female,
        baseSeed: storedSeed.substring(7),
      );
    }
    return CharacterIdentity(
      gender: CharacterGender.unspecified,
      baseSeed: storedSeed,
    );
  }
}
