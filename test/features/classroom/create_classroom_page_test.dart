import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seat_mate/features/classroom/presentation/create_classroom_page.dart';

void main() {
  testWidgets('validates and shows an owner seat result', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: CreateClassroomPage())),
    );

    await tester.enterText(find.byType(TextFormField).at(0), '재홍');
    await tester.enterText(find.byType(TextFormField).at(1), '1995-06-12');
    await tester.tap(find.text('내 자리 운세 보기'));
    await tester.pump();

    expect(find.text('절기표 확인 중...'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1000));
    await tester.pumpAndSettle();

    expect(find.text('재홍님의 자리는'), findsOneWidget);
    expect(find.text('이 원국으로 반 만들기'), findsOneWidget);
  });
}
