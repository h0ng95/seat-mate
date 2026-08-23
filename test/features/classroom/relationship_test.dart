import 'package:flutter_test/flutter_test.dart';
import 'package:seat_mate/features/classroom/domain/relationship.dart';

void main() {
  test('uses the selected modern relationship titles', () {
    expect(
      RelationshipType.values.map((type) => type.title),
      [
        '찐 쏘메',
        '수다 메이트',
        '든든한 내 편',
        '성장 라이벌',
        '텐션 메이트',
        '잔잔한 찐친',
        '기분 부스터',
        '케어 메이트',
        '반전 케미',
      ],
    );
  });
}
