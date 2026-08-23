import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:seat_mate/features/classroom/application/classroom_providers.dart';
import 'package:seat_mate/shared/presentation/app_scaffold.dart';

void main() {
  testWidgets('keeps the current page when no saved classroom exists', (
    tester,
  ) async {
    final router = _router();
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

    await tester.tap(find.text('내 반'));
    await tester.pumpAndSettle();

    expect(router.routeInformationProvider.value.uri.path, '/');
    expect(find.text('아직 만든 반이 없어요. 먼저 내 반을 만들어 주세요.'), findsOneWidget);
  });

  testWidgets('opens my classrooms when a saved classroom exists', (
    tester,
  ) async {
    final router = _router();
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(child: MaterialApp.router(routerConfig: router)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('내 반'));
    await tester.pumpAndSettle();

    expect(router.routeInformationProvider.value.uri.path, '/my');
  });
}

GoRouter _router() {
  return GoRouter(
    routes: [
      GoRoute(path: '/', builder: (context, state) => const _TestPage('시작')),
      GoRoute(
        path: '/create',
        builder: (context, state) => const _TestPage('만들기'),
      ),
      GoRoute(path: '/my', builder: (context, state) => const _TestPage('목록')),
    ],
  );
}

class _TestPage extends StatelessWidget {
  const _TestPage(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(child: Text(label));
  }
}
