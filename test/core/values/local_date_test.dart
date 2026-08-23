import 'package:flutter_test/flutter_test.dart';
import 'package:seat_mate/core/values/local_date.dart';

void main() {
  test('parses and formats an ISO local date', () {
    final date = LocalDate.parseIso('1995-06-12');

    expect(date.iso, '1995-06-12');
    expect(date.display, '1995. 06. 12');
  });

  test('rejects an invalid calendar date', () {
    expect(() => LocalDate.parseIso('2025-02-30'), throwsFormatException);
  });
}
