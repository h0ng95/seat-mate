import 'package:flutter_test/flutter_test.dart';
import 'package:seat_mate/core/values/local_date.dart';
import 'package:seat_mate/core/values/nickname.dart';
import 'package:seat_mate/features/character/domain/character_gender.dart';
import 'package:seat_mate/features/classroom/data/fake_classroom_repository.dart';
import 'package:seat_mate/features/classroom/domain/birth_profile.dart';
import 'package:seat_mate/features/classroom/domain/classroom_repository.dart';

void main() {
  test(
    'blocks duplicate participation and returns the existing member',
    () async {
      final repository = FakeClassroomRepository();
      final command = JoinClassroomCommand(
        shareCode: 'preview',
        name: Nickname('민수'),
        birth: BirthProfile(date: LocalDate.parseIso('1996-03-17')),
      );

      final result = await repository.joinClassroom(command);

      expect(result.isDuplicate, isTrue);
      expect(result.member.name.display, '민수');
      expect(result.classroom.members, hasLength(4));
    },
  );

  test('assigns a free seat when a new friend joins', () async {
    final repository = FakeClassroomRepository();
    final result = await repository.joinClassroom(
      JoinClassroomCommand(
        shareCode: 'preview',
        name: Nickname('소라'),
        gender: CharacterGender.female,
        birth: BirthProfile(date: LocalDate.parseIso('1998-02-21')),
      ),
    );

    final occupied = result.classroom.members.map((member) => member.seatIndex);
    expect(result.isDuplicate, isFalse);
    expect(
      CharacterIdentity.parse(result.member.characterSeed).gender,
      CharacterGender.female,
    );
    expect(occupied.toSet(), hasLength(occupied.length));
    expect(result.classroom.members, hasLength(5));
  });

  test('lists and deletes classrooms owned by the current user', () async {
    final repository = FakeClassroomRepository();
    final created = await repository.createClassroom(
      CreateClassroomCommand(
        ownerName: Nickname('재홍'),
        gender: CharacterGender.male,
        ownerBirth: BirthProfile(date: LocalDate.parseIso('1995-06-12')),
      ),
    );

    expect(
      CharacterIdentity.parse(
        created.members.firstWhere((member) => member.isOwner).characterSeed,
      ).gender,
      CharacterGender.male,
    );

    final beforeDelete = await repository.getMyClassrooms();
    expect(
      beforeDelete.map((classroom) => classroom.shareCode),
      contains(created.shareCode),
    );

    await repository.deleteMyClassroom(created.shareCode);

    final afterDelete = await repository.getMyClassrooms();
    expect(
      afterDelete.map((classroom) => classroom.shareCode),
      isNot(contains(created.shareCode)),
    );
  });

  test(
    'blocks a thirteenth member when all twelve seats are occupied',
    () async {
      final repository = FakeClassroomRepository();
      for (var index = 0; index < 8; index++) {
        await repository.joinClassroom(
          JoinClassroomCommand(
            shareCode: 'preview',
            name: Nickname('친구$index'),
            birth: BirthProfile(date: LocalDate(2000, 1, index + 1)),
          ),
        );
      }

      expect(
        () => repository.joinClassroom(
          JoinClassroomCommand(
            shareCode: 'preview',
            name: Nickname('열세번째'),
            birth: BirthProfile(date: LocalDate.parseIso('2001-01-01')),
          ),
        ),
        throwsA(isA<ClassroomFullException>()),
      );
    },
  );
}
