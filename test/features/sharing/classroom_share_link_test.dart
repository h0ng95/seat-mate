import 'package:flutter_test/flutter_test.dart';
import 'package:seat_mate/features/sharing/domain/classroom_share_link.dart';

void main() {
  test('builds a crawler-friendly classroom share URL', () {
    expect(
      buildClassroomShareUrl(
        baseUrl: 'https://seat.example/app',
        shareCode: 'class00001',
      ),
      'https://seat.example/app/?class=class00001',
    );
  });

  test('turns a shared query URL into the classroom route', () {
    expect(
      sharedClassroomPath(
        Uri.parse('https://seat.example/app/?class=class00001'),
      ),
      '/class/class00001',
    );
    expect(
      sharedClassroomPath(Uri.parse('https://seat.example/app/?class=../my')),
      isNull,
    );
  });
}
