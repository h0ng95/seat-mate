import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seat_mate/features/classroom/presentation/my_classrooms_page.dart';

void main() {
  testWidgets('shows classrooms from the owner repository', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: MyClassroomsPage())),
    );
    await tester.pumpAndSettle();

    expect(find.text('내 반'), findsOneWidget);
    expect(find.text('재홍의 반'), findsOneWidget);
    expect(find.textContaining('/12명'), findsOneWidget);
  });
}
