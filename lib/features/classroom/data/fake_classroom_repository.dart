import '../../../core/hashing/stable_hash.dart';
import '../../../core/values/local_date.dart';
import '../../../core/values/nickname.dart';
import '../../character/domain/character_gender.dart';
import '../domain/birth_profile.dart';
import '../domain/classroom.dart';
import '../domain/classroom_repository.dart';
import '../domain/saju_chart.dart';
import '../domain/saju_compatibility.dart';
import '../domain/seat_mate_algorithm.dart';

class FakeClassroomRepository implements ClassroomRepository {
  FakeClassroomRepository() {
    _classrooms['preview'] = _previewClassroom();
    _classrooms['class00001'] = _previewClassroom(shareCode: 'class00001');
    _sequence = 1;
  }

  final _algorithm = const SeatMateAlgorithmV1();
  final Map<String, Classroom> _classrooms = {};
  int _sequence = 0;

  @override
  Future<Classroom> createClassroom(CreateClassroomCommand command) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    final ownerResult = _algorithm.deriveOwner(command.ownerBirth);
    final ownerAlgorithmSeed = StableHash.hex(
      'owner|${command.ownerBirth.canonical}',
    );
    final shareCode = 'class${(++_sequence).toString().padLeft(5, '0')}';
    final characterSeed = CharacterIdentity(
      gender: command.gender,
      baseSeed: StableHash.hex(
        '${command.ownerName.normalized}|${command.ownerBirth.canonical}',
      ),
    );
    final owner = ClassroomMember(
      id: 'owner-$_sequence',
      name: command.ownerName,
      birthProfile: command.ownerBirth,
      sajuChart: ownerResult.sajuChart,
      seatIndex: ownerResult.seatIndex,
      characterSeed: characterSeed.storedSeed,
      focusDelta: 18,
      joyDelta: 74,
      ownerProfile: ownerResult.profile,
      isOwner: true,
    );
    final classroom = Classroom(
      id: 'classroom-$_sequence',
      shareCode: shareCode,
      ownerName: command.ownerName,
      ownerBirthProfile: command.ownerBirth,
      ownerAlgorithmSeed: ownerAlgorithmSeed,
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

  @override
  Future<List<SavedClassroomSummary>> getMyClassrooms() async {
    return _classrooms.values
        .where((classroom) => classroom.shareCode != 'preview')
        .map(
          (classroom) => SavedClassroomSummary(
            id: classroom.id,
            shareCode: classroom.shareCode,
            ownerName: classroom.ownerName,
            memberCount: classroom.members.length,
            createdAt: DateTime(2026),
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<void> deleteMyClassroom(String shareCode) async {
    _classrooms.remove(shareCode);
  }

  @override
  Future<JoinClassroomResult> joinClassroom(
    JoinClassroomCommand command,
  ) async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    final classroom = _classrooms[command.shareCode];
    if (classroom == null) throw ClassroomNotFoundException(command.shareCode);

    for (final member in classroom.members) {
      if (member.name == command.name &&
          member.birthProfile?.date == command.birth.date) {
        return JoinClassroomResult(
          classroom: classroom,
          member: member,
          isDuplicate: true,
        );
      }
    }
    if (classroom.isFull) throw const ClassroomFullException();

    final result = _algorithm.deriveMember(
      classroomCode: classroom.shareCode,
      ownerAlgorithmSeed: classroom.ownerAlgorithmSeed,
      ownerSeatIndex: classroom.ownerSeatIndex,
      ownerSajuChart: classroom.members
          .firstWhere((member) => member.isOwner)
          .sajuChart!,
      memberName: command.name,
      memberBirth: command.birth,
    );
    final memberId = 'member-${++_sequence}';
    final newMember = ClassroomMember(
      id: memberId,
      name: command.name,
      birthProfile: command.birth,
      sajuChart: result.sajuChart,
      seatIndex: result.seatIndex,
      characterSeed: CharacterIdentity(
        gender: command.gender,
        baseSeed: result.characterSeed,
      ).storedSeed,
      focusDelta: result.focusDelta,
      joyDelta: result.joyDelta,
      relationship: result.relationship,
      compatibility: result.compatibility,
    );
    final reseatedMembers = _reassignMembers(classroom, [
      ...classroom.members,
      newMember,
    ]);
    final updated = classroom.copyWith(members: reseatedMembers);
    _classrooms[command.shareCode] = updated;
    return JoinClassroomResult(
      classroom: updated,
      member: reseatedMembers.firstWhere((member) => member.id == memberId),
    );
  }

  List<ClassroomMember> _reassignMembers(
    Classroom classroom,
    List<ClassroomMember> members,
  ) {
    final assignments = _algorithm.reassignMembers(
      classroomCode: classroom.shareCode,
      ownerAlgorithmSeed: classroom.ownerAlgorithmSeed,
      ownerSeatIndex: classroom.ownerSeatIndex,
      members: members.where((member) => !member.isOwner).map((member) {
        return SeatAssignmentCandidate(
          stableKey: CharacterIdentity.parse(member.characterSeed).baseSeed,
          relationship: member.relationship!,
          heartScore: member.compatibility!.heartScore,
        );
      }),
    );
    return members
        .map(
          (member) => member.isOwner
              ? member
              : member.copyWith(
                  seatIndex:
                      assignments[CharacterIdentity.parse(
                        member.characterSeed,
                      ).baseSeed],
                ),
        )
        .toList(growable: false);
  }

  Classroom _previewClassroom({String shareCode = 'preview'}) {
    final ownerBirth = BirthProfile(
      date: LocalDate.parseIso('1995-06-12'),
      hour: 10,
      minute: 30,
    );
    final ownerResult = _algorithm.deriveOwner(ownerBirth);
    final owner = ClassroomMember(
      id: 'preview-owner',
      name: Nickname('재홍'),
      birthProfile: ownerBirth,
      sajuChart: ownerResult.sajuChart,
      seatIndex: 5,
      characterSeed: const CharacterIdentity(
        gender: CharacterGender.male,
        baseSeed: '재홍|1995-06-12',
      ).storedSeed,
      focusDelta: 18,
      joyDelta: 74,
      ownerProfile: OwnerProfileType.center,
      isOwner: true,
    );
    final memberData = [
      ('지현', '1997-08-04', 8, 8, 20, CharacterGender.female),
      ('민수', '1996-03-17', 4, 14, 0, CharacterGender.male),
      ('현우', '1995-11-23', 1, null, null, CharacterGender.male),
    ];
    final members = memberData.indexed.map((entry) {
      final item = entry.$2;
      final birth = BirthProfile(
        date: LocalDate.parseIso(item.$2),
        hour: item.$4,
        minute: item.$5,
      );
      final chart = SajuChartCalculator().calculate(birth);
      final compatibility = const SajuCompatibilityEngine().analyze(
        owner: ownerResult.sajuChart,
        member: chart,
      );
      return ClassroomMember(
        id: 'preview-${entry.$1}',
        name: Nickname(item.$1),
        birthProfile: birth,
        sajuChart: chart,
        seatIndex: item.$3,
        characterSeed: CharacterIdentity(
          gender: item.$6,
          baseSeed: '${item.$1}|${item.$2}',
        ).storedSeed,
        relationship: compatibility.relationshipType,
        compatibility: compatibility,
        focusDelta: ((compatibility.evidence.first.score - 20) * 3).clamp(
          -40,
          60,
        ),
        joyDelta: compatibility.heartScore,
      );
    });
    return Classroom(
      id: 'preview-classroom',
      shareCode: shareCode,
      ownerName: owner.name,
      ownerBirthProfile: ownerBirth,
      ownerAlgorithmSeed: StableHash.hex('owner|${ownerBirth.canonical}'),
      ownerSeatIndex: 5,
      members: [owner, ...members],
    );
  }
}
