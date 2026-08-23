import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seat_mate/features/classroom/presentation/classroom_page.dart';

void main() {
  testWidgets('renders nine classroom seats at mobile width', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(home: ClassroomPage(shareCode: 'preview')),
    );

    for (var index = 0; index < 9; index++) {
      expect(find.byKey(ValueKey('seat-$index')), findsOneWidget);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('opens a relationship sheet for an occupied seat', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: ClassroomPage(shareCode: 'preview')),
    );

    await tester.tap(find.byKey(const ValueKey('seat-5')));
    await tester.pumpAndSettle();

    expect(find.text('찰떡 짝꿍'), findsOneWidget);
    expect(find.text('+92%'), findsOneWidget);
  });
}
