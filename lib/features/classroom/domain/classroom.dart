import '../../../core/values/local_date.dart';
import '../../../core/values/nickname.dart';
import 'relationship.dart';
import 'seat_mate_algorithm.dart';

class ClassroomMember {
  const ClassroomMember({
    required this.id,
    required this.name,
    required this.birthDate,
    required this.seatIndex,
    required this.characterSeed,
    required this.focusDelta,
    required this.joyDelta,
    this.relationship,
    this.ownerProfile,
    this.isOwner = false,
  });

  final String id;
  final Nickname name;
  final LocalDate? birthDate;
  final int seatIndex;
  final String characterSeed;
  final int focusDelta;
  final int joyDelta;
  final RelationshipType? relationship;
  final OwnerProfileType? ownerProfile;
  final bool isOwner;
}

class Classroom {
  const Classroom({
    required this.id,
    required this.shareCode,
    required this.ownerName,
    required this.ownerBirthDate,
    required this.ownerAlgorithmSeed,
    required this.ownerSeatIndex,
    required this.members,
    this.algorithmVersion = SeatMateAlgorithmV1.version,
  });

  final String id;
  final String shareCode;
  final Nickname ownerName;
  final LocalDate? ownerBirthDate;
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
      ownerBirthDate: ownerBirthDate,
      ownerAlgorithmSeed: ownerAlgorithmSeed,
      ownerSeatIndex: ownerSeatIndex,
      members: members ?? this.members,
      algorithmVersion: algorithmVersion,
    );
  }
}
