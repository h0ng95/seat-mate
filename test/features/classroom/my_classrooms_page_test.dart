import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:seat_mate/features/classroom/application/classroom_providers.dart';
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

  testWidgets('redirects to creation when no classroom exists', (tester) async {
    final router = GoRouter(
      initialLocation: '/my',
      routes: [
        GoRoute(
          path: '/my',
          builder: (context, state) => const MyClassroomsPage(),
        ),
        GoRoute(
          path: '/create',
          builder: (context, state) => const Scaffold(body: Text('반 만들기')),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          savedClassroomsProvider('demo').overrideWith((ref) async => const []),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(router.routeInformationProvider.value.uri.path, '/create');
    expect(find.text('반 만들기'), findsOneWidget);
  });
}
