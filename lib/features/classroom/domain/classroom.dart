import '../../../core/values/nickname.dart';
import 'birth_profile.dart';
import 'relationship.dart';
import 'saju_chart.dart';
import 'saju_compatibility.dart';
import 'seat_mate_algorithm.dart';

class ClassroomMember {
  const ClassroomMember({
    required this.id,
    required this.name,
    required this.birthProfile,
    required this.sajuChart,
    required this.seatIndex,
    required this.characterSeed,
    required this.focusDelta,
    required this.joyDelta,
    this.relationship,
    this.compatibility,
    this.ownerProfile,
    this.isOwner = false,
  });

  final String id;
  final Nickname name;
  final BirthProfile? birthProfile;
  final SajuChart? sajuChart;
  final int seatIndex;
  final String characterSeed;
  final int focusDelta;
  final int joyDelta;
  final RelationshipType? relationship;
  final SajuCompatibility? compatibility;
  final OwnerProfileType? ownerProfile;
  final bool isOwner;
}

class Classroom {
  const Classroom({
    required this.id,
    required this.shareCode,
    required this.ownerName,
    required this.ownerBirthProfile,
    required this.ownerAlgorithmSeed,
    required this.ownerSeatIndex,
    required this.members,
    this.algorithmVersion = SeatMateAlgorithmV1.version,
  });

  final String id;
  final String shareCode;
  final Nickname ownerName;
  final BirthProfile? ownerBirthProfile;
  final String ownerAlgorithmSeed;
  final int ownerSeatIndex;
  final List<ClassroomMember> members;
  final int algorithmVersion;

  bool get isFull => members.length >= 9;

  Classroom copyWith({List<ClassroomMember>? members}) {
    return Classroom(
      id: id,
      shareCode: shareCode,
      ownerName: ownerName,
      ownerBirthProfile: ownerBirthProfile,
      ownerAlgorithmSeed: ownerAlgorithmSeed,
      ownerSeatIndex: ownerSeatIndex,
      members: members ?? this.members,
      algorithmVersion: algorithmVersion,
    );
  }
}
