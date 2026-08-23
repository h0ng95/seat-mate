import 'package:flutter_test/flutter_test.dart';
import 'package:seat_mate/features/classroom/domain/classroom_seat_layout.dart';

void main() {
  test('numbers twelve seats from the front row near the teacher desk', () {
    expect(ClassroomSeatLayout.capacity, 12);
    expect(ClassroomSeatLayout.rowOf(0), 0);
    expect(ClassroomSeatLayout.rowOf(3), 0);
    expect(ClassroomSeatLayout.rowOf(4), 1);
    expect(ClassroomSeatLayout.rowOf(7), 1);
    expect(ClassroomSeatLayout.rowOf(8), 2);
    expect(ClassroomSeatLayout.rowOf(11), 2);
  });

  test('pairs neighboring seat numbers at the same desk', () {
    for (var firstSeat = 0; firstSeat < 12; firstSeat += 2) {
      expect(ClassroomSeatLayout.partnerOf(firstSeat), firstSeat + 1);
      expect(ClassroomSeatLayout.partnerOf(firstSeat + 1), firstSeat);
      expect(ClassroomSeatLayout.shareDesk(firstSeat, firstSeat + 1), isTrue);
    }
    expect(ClassroomSeatLayout.shareDesk(1, 2), isFalse);
    expect(ClassroomSeatLayout.shareDesk(5, 6), isFalse);
  });
}
