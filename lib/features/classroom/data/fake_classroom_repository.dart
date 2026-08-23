import '../../../core/hashing/stable_hash.dart';
import '../../../core/values/local_date.dart';
import '../../../core/values/nickname.dart';
import '../domain/classroom.dart';
import '../domain/classroom_repository.dart';
import '../domain/relationship.dart';
import '../domain/seat_mate_algorithm.dart';

class FakeClassroomRepository implements ClassroomRepository {
  FakeClassroomRepository() {
    _classrooms['preview'] = _previewClassroom();
  }

  final _algorithm = const SeatMateAlgorithmV1();
  final Map<String, Classroom> _classrooms = {};
  int _sequence = 0;

  @override
  Future<Classroom> createClassroom(CreateClassroomCommand command) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    final ownerResult = _algorithm.deriveOwner(command.ownerBirthDate);
    final shareCode = 'class${(++_sequence).toString().padLeft(5, '0')}';
    final characterSeed = StableHash.hex(
      '${command.ownerName.normalized}|${command.ownerBirthDate.iso}',
    );
    final owner = ClassroomMember(
      id: 'owner-$_sequence',
      name: command.ownerName,
      birthDate: command.ownerBirthDate,
      seatIndex: ownerResult.seatIndex,
      characterSeed: characterSeed,
      focusDelta: 18,
      joyDelta: 74,
      ownerProfile: ownerResult.profile,
      isOwner: true,
    );
    final classroom = Classroom(
      id: 'classroom-$_sequence',
      shareCode: shareCode,
      ownerName: command.ownerName,
      ownerBirthDate: command.ownerBirthDate,
      ownerSeatIndex: ownerResult.seatIndex,
      members: [owner],
    );
    _classrooms[shareCode] = classroom;
    return classroom;
  }

  @override
  Future<Classroom> getClassroom(String shareCode) async {
    await Future<void>.delayed(const Duration(milliseconds: 160));
    final classroom = _classrooms[shareCode];
    if (classroom == null) throw ClassroomNotFoundException(shareCode);
    return classroom;
  }

  Classroom _previewClassroom() {
    final ownerBirth = LocalDate.parseIso('1995-06-12');
    final owner = ClassroomMember(
      id: 'preview-owner',
      name: Nickname('재홍'),
      birthDate: ownerBirth,
      seatIndex: 4,
      characterSeed: '재홍|1995-06-12',
      focusDelta: 18,
      joyDelta: 74,
      ownerProfile: OwnerProfileType.center,
      isOwner: true,
    );
    final memberData = [
      ('지현', '1997-08-04', 0, RelationshipType.leader, 62, 41),
      ('민수', '1996-03-17', 5, RelationshipType.buddy, -8, 92),
      ('현우', '1995-11-23', 7, RelationshipType.accomplice, -38, 92),
    ];
    final members = memberData.indexed.map((entry) {
      final item = entry.$2;
      return ClassroomMember(
        id: 'preview-${entry.$1}',
        name: Nickname(item.$1),
        birthDate: LocalDate.parseIso(item.$2),
        seatIndex: item.$3,
        characterSeed: '${item.$1}|${item.$2}',
        relationship: item.$4,
        focusDelta: item.$5,
        joyDelta: item.$6,
      );
    });
    return Classroom(
      id: 'preview-classroom',
      shareCode: 'preview',
      ownerName: owner.name,
      ownerBirthDate: ownerBirth,
      ownerSeatIndex: 4,
      members: [owner, ...members],
    );
  }
}
