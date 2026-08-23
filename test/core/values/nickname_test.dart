import 'package:flutter_test/flutter_test.dart';
import 'package:seat_mate/core/values/nickname.dart';

void main() {
  test('normalizes outer and repeated spaces', () {
    final nickname = Nickname('  우리   반장  ');

    expect(nickname.display, '우리 반장');
    expect(nickname.normalized, '우리 반장');
  });

  test('counts visible grapheme clusters for the length limit', () {
    expect(() => Nickname('가나다라마바사아자차카타파'), throwsFormatException);
  });
}
