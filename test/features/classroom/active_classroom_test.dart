import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:seat_mate/core/values/local_date.dart';
import 'package:seat_mate/core/values/nickname.dart';
import 'package:seat_mate/features/classroom/application/classroom_providers.dart';
import 'package:seat_mate/features/classroom/data/active_classroom_storage.dart';
import 'package:seat_mate/features/classroom/domain/birth_profile.dart';
import 'package:seat_mate/features/classroom/domain/classroom_repository.dart';
import 'package:seat_mate/features/landing/presentation/landing_page.dart';

void main() {
  test('remembers a classroom immediately after creation', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final classroom = await container
        .read(createClassroomControllerProvider.notifier)
        .create(
          CreateClassroomCommand(
            ownerName: Nickname('재홍'),
            ownerBirth: BirthProfile(date: LocalDate.parseIso('1995-06-12')),
          ),
        );

    expect(classroom, isNotNull);
    expect(
      container.read(activeClassroomShareCodeProvider),
      classroom!.shareCode,
    );
  });

  test('restores the remembered classroom in a new app container', () {
    final storage = MemoryActiveClassroomStorage();
    final first = ProviderContainer(
      overrides: [activeClassroomStorageProvider.overrideWithValue(storage)],
    );
    first
        .read(activeClassroomShareCodeProvider.notifier)
        .remember('remembered123');
    first.dispose();

    final restored = ProviderContainer(
      overrides: [activeClassroomStorageProvider.overrideWithValue(storage)],
    );
    addTearDown(restored.dispose);

    expect(restored.read(activeClassroomShareCodeProvider), 'remembered123');
  });

  testWidgets('redirects the start route to the remembered classroom', (
    tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container
        .read(activeClassroomShareCodeProvider.notifier)
        .remember('remembered123');
    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (context, state) => const LandingPage()),
        GoRoute(
          path: '/class/:shareCode',
          builder: (context, state) => const Scaffold(body: Text('기억한 반')),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      router.routeInformationProvider.value.uri.path,
      '/class/remembered123',
    );
    expect(find.text('기억한 반'), findsOneWidget);
    expect(find.text('내 반 만들기'), findsNothing);
  });
}
