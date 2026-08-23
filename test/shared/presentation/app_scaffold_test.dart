import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:seat_mate/app/app_config.dart';
import 'package:seat_mate/core/values/nickname.dart';
import 'package:seat_mate/features/auth/application/auth_providers.dart';
import 'package:seat_mate/features/auth/domain/signed_in_user.dart';
import 'package:seat_mate/features/classroom/application/classroom_providers.dart';
import 'package:seat_mate/features/classroom/domain/classroom.dart';
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

  testWidgets('opens the single saved classroom directly', (tester) async {
    final router = _router();
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(child: MaterialApp.router(routerConfig: router)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('내 반'));
    await tester.pumpAndSettle();

    expect(router.routeInformationProvider.value.uri.path, '/class/class00001');
  });

  testWidgets('removes the create destination after owning a classroom', (
    tester,
  ) async {
    final router = _router();
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appConfigProvider.overrideWithValue(
            const AppConfig(
              baseUrl: 'https://seat.example',
              supabaseUrl: 'https://project.supabase.co',
              supabasePublishableKey: 'publishable-key',
            ),
          ),
          authUserProvider.overrideWith(
            (ref) => Stream.value(
              const SignedInUser(id: 'owner-user', displayName: '재홍'),
            ),
          ),
          savedClassroomsProvider('owner-user').overrideWith(
            (ref) async => [
              SavedClassroomSummary(
                id: 'saved-classroom',
                shareCode: 'saved123',
                ownerName: Nickname('재홍'),
                memberCount: 4,
                createdAt: DateTime(2026),
              ),
            ],
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsNothing);
    expect(find.text('내 반 만들기'), findsNothing);
    expect(router.routeInformationProvider.value.uri.path, '/');
  });

  testWidgets('hides navigation inside a classroom', (tester) async {
    final router = _router(initialLocation: '/class/friend123');
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(child: MaterialApp.router(routerConfig: router)),
    );
    await tester.pumpAndSettle();

    expect(find.text('교실'), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    expect(find.text('시작'), findsNothing);
  });
}

GoRouter _router({String? initialLocation}) {
  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(path: '/', builder: (context, state) => const _TestPage('시작')),
      GoRoute(
        path: '/create',
        builder: (context, state) => const _TestPage('만들기'),
      ),
      GoRoute(path: '/my', builder: (context, state) => const _TestPage('목록')),
      GoRoute(
        path: '/class/:shareCode',
        builder: (context, state) => const _TestPage('교실'),
      ),
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
