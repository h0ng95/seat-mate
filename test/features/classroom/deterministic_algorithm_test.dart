import 'package:flutter_test/flutter_test.dart';
import 'package:seat_mate/core/values/local_date.dart';
import 'package:seat_mate/core/values/nickname.dart';
import 'package:seat_mate/features/classroom/domain/seat_mate_algorithm.dart';

void main() {
  const algorithm = SeatMateAlgorithmV1();
  final ownerBirth = LocalDate.parseIso('1995-06-12');
  final memberBirth = LocalDate.parseIso('1996-03-17');
  final memberName = Nickname('민수');

  test('returns the same owner result for the same birthday', () {
    expect(
      algorithm.deriveOwner(ownerBirth),
      algorithm.deriveOwner(ownerBirth),
    );
  });

  test('returns the same member result for the same input', () {
    final first = algorithm.deriveMember(
      classroomCode: '8fj2kd9abc',
      ownerAlgorithmSeed: 'owner-seed',
      ownerSeatIndex: 4,
      memberName: memberName,
      memberBirthDate: memberBirth,
      occupiedSeats: {0, 4, 7},
    );
    final second = algorithm.deriveMember(
      classroomCode: '8fj2kd9abc',
      ownerAlgorithmSeed: 'owner-seed',
      ownerSeatIndex: 4,
      memberName: memberName,
      memberBirthDate: memberBirth,
      occupiedSeats: {7, 0, 4},
    );

    expect(first, second);
  });

  test('never assigns an occupied seat', () {
    final result = algorithm.deriveMember(
      classroomCode: '8fj2kd9abc',
      ownerAlgorithmSeed: 'owner-seed',
      ownerSeatIndex: 4,
      memberName: memberName,
      memberBirthDate: memberBirth,
      occupiedSeats: {0, 1, 2, 3, 4, 5, 6},
    );

    expect(result.seatIndex, anyOf(7, 8));
  });

  test('rejects a tenth person when every seat is occupied', () {
    expect(
      () => algorithm.deriveMember(
        classroomCode: '8fj2kd9abc',
        ownerAlgorithmSeed: 'owner-seed',
        ownerSeatIndex: 4,
        memberName: memberName,
        memberBirthDate: memberBirth,
        occupiedSeats: {0, 1, 2, 3, 4, 5, 6, 7, 8},
      ),
      throwsStateError,
    );
  });
}
