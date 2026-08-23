import 'package:flutter_test/flutter_test.dart';
import 'package:seat_mate/app/seat_mate_app.dart';

void main() {
  testWidgets('shows the service landing page', (tester) async {
    await tester.pumpWidget(const SeatMateApp());
    await tester.pumpAndSettle();

    expect(find.text('내 반에 앉아봐'), findsOneWidget);
    expect(find.text('내 반 만들기'), findsOneWidget);
  });
}
