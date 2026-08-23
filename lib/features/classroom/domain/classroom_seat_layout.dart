abstract final class ClassroomSeatLayout {
  static const rowCount = 3;
  static const divisionCount = 2;
  static const seatsPerDesk = 2;
  static const seatsPerRow = divisionCount * seatsPerDesk;
  static const deskCount = rowCount * divisionCount;
  static const capacity = rowCount * seatsPerRow;

  static int rowOf(int seatIndex) => seatIndex ~/ seatsPerRow;

  static int divisionOf(int seatIndex) {
    return (seatIndex % seatsPerRow) ~/ seatsPerDesk;
  }

  static int sideOf(int seatIndex) => seatIndex % seatsPerDesk;

  static int partnerOf(int seatIndex) =>
      seatIndex.isEven ? seatIndex + 1 : seatIndex - 1;

  static bool shareDesk(int first, int second) {
    return rowOf(first) == rowOf(second) &&
        divisionOf(first) == divisionOf(second);
  }

  static int firstSeatOfDesk({required int row, required int division}) {
    return row * seatsPerRow + division * seatsPerDesk;
  }

  static bool isValid(int seatIndex) {
    return seatIndex >= 0 && seatIndex < capacity;
  }
}
