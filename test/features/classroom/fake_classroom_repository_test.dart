import 'package:flutter_test/flutter_test.dart';
import 'package:seat_mate/core/values/local_date.dart';
import 'package:seat_mate/core/values/nickname.dart';
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
        birth: BirthProfile(date: LocalDate.parseIso('1998-02-21')),
      ),
    );

    final occupied = result.classroom.members.map((member) => member.seatIndex);
    expect(result.isDuplicate, isFalse);
    expect(occupied.toSet(), hasLength(occupied.length));
    expect(result.classroom.members, hasLength(5));
  });

  test('blocks a tenth member when all nine seats are occupied', () async {
    final repository = FakeClassroomRepository();
    for (var index = 0; index < 5; index++) {
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
          name: Nickname('열번째'),
          birth: BirthProfile(date: LocalDate.parseIso('2001-01-01')),
        ),
      ),
      throwsA(isA<ClassroomFullException>()),
    );
  });
}
