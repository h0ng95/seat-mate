import '../../../core/hashing/canonical_seed.dart';
import '../../../core/hashing/stable_hash.dart';
import '../../../core/values/local_date.dart';
import '../../../core/values/nickname.dart';
import 'relationship.dart';

enum OwnerProfileType { window, center, back, front }

extension OwnerProfileDefinition on OwnerProfileType {
  String get title => switch (this) {
    OwnerProfileType.window => '창가 감성러',
    OwnerProfileType.center => '은근한 핵심 인물',
    OwnerProfileType.back => '자유로운 영혼',
    OwnerProfileType.front => '알게 모르게 모범생',
  };

  String get description => switch (this) {
    OwnerProfileType.window => '혼자 멍 때리는 시간을 좋아하지만 친해지면 장난기가 많은 타입.',
    OwnerProfileType.center => '튀지는 않지만 사람들이 자연스럽게 주변에 모이는 자리.',
    OwnerProfileType.back => '수업보다는 쉬는 시간을 기다리는 자유로운 타입.',
    OwnerProfileType.front => '대충 하는 것 같아도 해야 할 건 결국 하는 타입.',
  };
}

class OwnerResult {
  const OwnerResult({required this.profile, required this.seatIndex});

  final OwnerProfileType profile;
  final int seatIndex;

  @override
  bool operator ==(Object other) =>
      other is OwnerResult &&
      profile == other.profile &&
      seatIndex == other.seatIndex;

  @override
  int get hashCode => Object.hash(profile, seatIndex);
}

class MemberResult {
  const MemberResult({
    required this.relationship,
    required this.seatIndex,
    required this.preferredSeats,
    required this.characterSeed,
    required this.focusDelta,
    required this.joyDelta,
  });

  final RelationshipType relationship;
  final int seatIndex;
  final List<int> preferredSeats;
  final String characterSeed;
  final int focusDelta;
  final int joyDelta;

  @override
  bool operator ==(Object other) {
    return other is MemberResult &&
        relationship == other.relationship &&
        seatIndex == other.seatIndex &&
        _sameList(preferredSeats, other.preferredSeats) &&
        characterSeed == other.characterSeed &&
        focusDelta == other.focusDelta &&
        joyDelta == other.joyDelta;
  }

  static bool _sameList(List<int> first, List<int> second) {
    if (first.length != second.length) return false;
    for (var index = 0; index < first.length; index++) {
      if (first[index] != second[index]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
    relationship,
    seatIndex,
    Object.hashAll(preferredSeats),
    characterSeed,
    focusDelta,
    joyDelta,
  );
}

class SeatMateAlgorithmV1 {
  const SeatMateAlgorithmV1();

  static const version = 1;

  OwnerResult deriveOwner(LocalDate birthDate) {
    final profileSeed = _seed('owner-profile', {'ownerBirth': birthDate.iso});
    final profile = OwnerProfileType.values[StableHash.uint16(profileSeed) % 4];
    final candidates = switch (profile) {
      OwnerProfileType.window => [3, 0, 6, 4],
      OwnerProfileType.center => [4, 1, 7, 3, 5],
      OwnerProfileType.back => [7, 6, 8, 4],
      OwnerProfileType.front => [1, 0, 2, 4],
    };
    final seatSeed = _seed('owner-seat', {'ownerBirth': birthDate.iso});
    return OwnerResult(
      profile: profile,
      seatIndex: candidates[StableHash.uint16(seatSeed) % candidates.length],
    );
  }

  MemberResult deriveMember({
    required String classroomCode,
    required String ownerAlgorithmSeed,
    required int ownerSeatIndex,
    required Nickname memberName,
    required LocalDate memberBirthDate,
    Set<int> occupiedSeats = const {},
  }) {
    if (ownerSeatIndex < 0 || ownerSeatIndex > 8) {
      throw ArgumentError.value(ownerSeatIndex, 'ownerSeatIndex');
    }
    final fields = {
      'classroom': classroomCode,
      'ownerSeed': ownerAlgorithmSeed,
      'memberName': memberName.normalized,
      'memberBirth': memberBirthDate.iso,
    };
    final relationshipSeed = _seed('relationship', fields);
    final relationship = _relationshipFor(
      StableHash.uint16(relationshipSeed) % 100,
    );
    final preferredSeats = _rankSeats(
      relationship: relationship,
      ownerSeat: ownerSeatIndex,
      fields: fields,
    );
    final unavailable = {...occupiedSeats, ownerSeatIndex};
    final seatIndex = preferredSeats.cast<int?>().firstWhere(
      (seat) => !unavailable.contains(seat),
      orElse: () => null,
    );
    if (seatIndex == null) throw StateError('교실에 빈자리가 없습니다.');

    final metrics = StableHash.bytes(_seed('fun-metrics', fields));
    final characterSeed = StableHash.hex(
      _seed('character', {
        'memberName': memberName.normalized,
        'memberBirth': memberBirthDate.iso,
      }),
    );
    return MemberResult(
      relationship: relationship,
      seatIndex: seatIndex,
      preferredSeats: preferredSeats,
      characterSeed: characterSeed,
      focusDelta: StableHash.mapByteToRange(
        metrics[0],
        relationship.focusRange,
      ),
      joyDelta: StableHash.mapByteToRange(metrics[1], relationship.joyRange),
    );
  }

  List<int> _rankSeats({
    required RelationshipType relationship,
    required int ownerSeat,
    required Map<String, String> fields,
  }) {
    final seats = [
      for (var seat = 0; seat < 9; seat++)
        if (seat != ownerSeat) seat,
    ];
    seats.sort((first, second) {
      final scoreComparison = _seatScore(
        relationship,
        ownerSeat,
        second,
      ).compareTo(_seatScore(relationship, ownerSeat, first));
      if (scoreComparison != 0) return scoreComparison;
      final firstTie = StableHash.uint32(
        _seed('seat-order', {...fields, 'seat': '$first'}),
      );
      final secondTie = StableHash.uint32(
        _seed('seat-order', {...fields, 'seat': '$second'}),
      );
      final tieComparison = firstTie.compareTo(secondTie);
      return tieComparison != 0 ? tieComparison : first.compareTo(second);
    });
    return List.unmodifiable(seats);
  }

  int _seatScore(RelationshipType type, int ownerSeat, int seat) {
    final ownerRow = ownerSeat ~/ 3;
    final ownerColumn = ownerSeat % 3;
    final row = seat ~/ 3;
    final column = seat % 3;
    final rowDelta = row - ownerRow;
    final columnDelta = column - ownerColumn;
    final rowDistance = rowDelta.abs();
    final columnDistance = columnDelta.abs();
    final manhattan = rowDistance + columnDistance;
    final side = rowDelta == 0 && columnDistance == 1;
    final diagonal = rowDistance == 1 && columnDistance == 1;

    return switch (type) {
      RelationshipType.buddy => side ? 100 : (diagonal ? 80 : 20 - manhattan),
      RelationshipType.chatter =>
        rowDelta > 0 && diagonal ? 100 : (rowDelta > 0 ? 80 + row : 20),
      RelationshipType.leader =>
        rowDelta < 0 && columnDelta == 0 ? 100 : (rowDelta < 0 ? 80 : 20 - row),
      RelationshipType.rival =>
        columnDelta == 0 ? 70 + rowDistance * 10 : 30 + manhattan * 5,
      RelationshipType.emergency => diagonal ? 100 : (manhattan == 1 ? 75 : 20),
      RelationshipType.accomplice =>
        rowDelta > 0 && columnDelta == 0 ? 100 : (rowDelta > 0 ? 80 + row : 20),
      RelationshipType.quietBestie =>
        column == 0 ? 80 + manhattan * 5 : 30 + manhattan * 4,
      RelationshipType.moodMaker => column == 2 ? 90 + row : 30 + row,
      RelationshipType.caretaker =>
        rowDelta < 0 && diagonal ? 100 : (rowDelta < 0 || side ? 75 : 20),
      RelationshipType.transfer => 30 + manhattan * 20,
    };
  }

  RelationshipType _relationshipFor(int bucket) {
    if (bucket < 12) return RelationshipType.buddy;
    if (bucket < 23) return RelationshipType.chatter;
    if (bucket < 32) return RelationshipType.leader;
    if (bucket < 41) return RelationshipType.rival;
    if (bucket < 51) return RelationshipType.emergency;
    if (bucket < 62) return RelationshipType.accomplice;
    if (bucket < 72) return RelationshipType.quietBestie;
    if (bucket < 82) return RelationshipType.moodMaker;
    if (bucket < 91) return RelationshipType.caretaker;
    return RelationshipType.transfer;
  }

  String _seed(String purpose, Map<String, String> fields) {
    return CanonicalSeed.build(
      version: version,
      purpose: purpose,
      fields: fields,
    );
  }
}
