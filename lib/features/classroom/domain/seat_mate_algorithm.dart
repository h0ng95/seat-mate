import '../../../core/hashing/canonical_seed.dart';
import '../../../core/hashing/stable_hash.dart';
import '../../../core/values/nickname.dart';
import 'birth_profile.dart';
import 'relationship.dart';
import 'saju_chart.dart';
import 'saju_compatibility.dart';

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
  const OwnerResult({
    required this.profile,
    required this.seatIndex,
    required this.sajuChart,
  });

  final OwnerProfileType profile;
  final int seatIndex;
  final SajuChart sajuChart;

  @override
  bool operator ==(Object other) =>
      other is OwnerResult &&
      profile == other.profile &&
      seatIndex == other.seatIndex &&
      sajuChart.toJson().toString() == other.sajuChart.toJson().toString();

  @override
  int get hashCode => Object.hash(profile, seatIndex, sajuChart.day.hanja);
}

class MemberResult {
  const MemberResult({
    required this.relationship,
    required this.seatIndex,
    required this.preferredSeats,
    required this.characterSeed,
    required this.focusDelta,
    required this.joyDelta,
    required this.sajuChart,
    required this.compatibility,
  });

  final RelationshipType relationship;
  final int seatIndex;
  final List<int> preferredSeats;
  final String characterSeed;
  final int focusDelta;
  final int joyDelta;
  final SajuChart sajuChart;
  final SajuCompatibility compatibility;

  @override
  bool operator ==(Object other) {
    return other is MemberResult &&
        relationship == other.relationship &&
        seatIndex == other.seatIndex &&
        _sameList(preferredSeats, other.preferredSeats) &&
        characterSeed == other.characterSeed &&
        focusDelta == other.focusDelta &&
        joyDelta == other.joyDelta &&
        sajuChart.toJson().toString() == other.sajuChart.toJson().toString() &&
        compatibility.toJson().toString() ==
            other.compatibility.toJson().toString();
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
    sajuChart.day.hanja,
    compatibility.heartScore,
  );
}

class SeatMateAlgorithmV1 {
  const SeatMateAlgorithmV1();

  static const version = 2;

  OwnerResult deriveOwner(BirthProfile birth) {
    final chart = SajuChartCalculator().calculate(birth);
    final profile = switch (chart.dayMasterElement) {
      'wood' => OwnerProfileType.window,
      'fire' => OwnerProfileType.center,
      'earth' => OwnerProfileType.center,
      'metal' => OwnerProfileType.front,
      _ => OwnerProfileType.back,
    };
    final candidates = switch (profile) {
      OwnerProfileType.window => [3, 0, 6, 4],
      OwnerProfileType.center => [4, 1, 7, 3, 5],
      OwnerProfileType.back => [7, 6, 8, 4],
      OwnerProfileType.front => [1, 0, 2, 4],
    };
    final seatSeed = _seed('owner-seat', {
      'ownerBirth': birth.canonical,
      'dayPillar': chart.day.hanja,
    });
    return OwnerResult(
      profile: profile,
      seatIndex: candidates[StableHash.uint16(seatSeed) % candidates.length],
      sajuChart: chart,
    );
  }

  MemberResult deriveMember({
    required String classroomCode,
    required String ownerAlgorithmSeed,
    required int ownerSeatIndex,
    required SajuChart ownerSajuChart,
    required Nickname memberName,
    required BirthProfile memberBirth,
    Set<int> occupiedSeats = const {},
  }) {
    if (ownerSeatIndex < 0 || ownerSeatIndex > 8) {
      throw ArgumentError.value(ownerSeatIndex, 'ownerSeatIndex');
    }
    final fields = {
      'classroom': classroomCode,
      'ownerSeed': ownerAlgorithmSeed,
      'memberName': memberName.normalized,
      'memberBirth': memberBirth.canonical,
    };
    final memberSajuChart = SajuChartCalculator().calculate(memberBirth);
    final compatibility = const SajuCompatibilityEngine().analyze(
      owner: ownerSajuChart,
      member: memberSajuChart,
    );
    final relationship = compatibility.relationshipType;
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

    final characterSeed = StableHash.hex(
      _seed('character', {
        'memberName': memberName.normalized,
        'memberBirth': memberBirth.canonical,
      }),
    );
    final dayMasterScore = compatibility.evidence.first.score;
    return MemberResult(
      relationship: relationship,
      seatIndex: seatIndex,
      preferredSeats: preferredSeats,
      characterSeed: characterSeed,
      focusDelta: ((dayMasterScore - 20) * 3).clamp(-40, 60),
      joyDelta: compatibility.heartScore,
      sajuChart: memberSajuChart,
      compatibility: compatibility,
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

  String _seed(String purpose, Map<String, String> fields) {
    return CanonicalSeed.build(
      version: version,
      purpose: purpose,
      fields: fields,
    );
  }
}
