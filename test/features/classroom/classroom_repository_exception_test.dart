import 'package:flutter_test/flutter_test.dart';
import 'package:seat_mate/features/classroom/domain/classroom_repository.dart';

void main() {
  test('formats join persistence diagnostics without empty details', () {
    expect(
      const ClassroomJoinPersistenceException(
        code: '23514',
        message: 'constraint failed',
      ).diagnosticMessage,
      '23514 · constraint failed',
    );
  });
}
