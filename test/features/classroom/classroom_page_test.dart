import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:seat_mate/app/app_config.dart';
import 'package:seat_mate/core/values/nickname.dart';
import 'package:seat_mate/features/auth/application/auth_providers.dart';
import 'package:seat_mate/features/auth/domain/signed_in_user.dart';
import 'package:seat_mate/features/classroom/application/classroom_providers.dart';
import 'package:seat_mate/features/classroom/domain/classroom.dart';
import 'package:seat_mate/features/classroom/presentation/classroom_page.dart';
import 'package:seat_mate/features/sharing/application/share_providers.dart';
import 'package:seat_mate/features/sharing/application/share_service.dart';

void main() {
  testWidgets('renders twelve paired classroom seats at mobile width', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: ClassroomPage(shareCode: 'preview')),
      ),
    );
    await tester.pumpAndSettle();

    for (var index = 0; index < 12; index++) {
      expect(find.byKey(ValueKey('seat-$index')), findsOneWidget);
    }
    final heartBadge = find.byKey(const ValueKey('heart-score-4'));
    expect(heartBadge, findsOneWidget);
    final fill = tester.widget<ClipRect>(
      find.descendant(of: heartBadge, matching: find.byType(ClipRect)),
    );
    final fillRect = fill.clipper!.getClip(const Size(18, 18));
    expect(fillRect.height, closeTo(18 * 0.78, 0.001));
    expect(fillRect.bottom, 18);
    expect(find.text('우리 반 케미 순위'), findsOneWidget);
    expect(find.byKey(const ValueKey('compatibility-rank-1')), findsOneWidget);
    expect(find.byIcon(Icons.star_border_rounded), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('opens a relationship sheet for an occupied seat', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: ClassroomPage(shareCode: 'preview')),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('seat-4')));
    await tester.pumpAndSettle();

    expect(find.text('케미 지수'), findsOneWidget);
    expect(find.text('두 사람의 원국'), findsOneWidget);
    expect(find.text('점수 계산 근거'), findsOneWidget);
    expect(find.text('나도 내 반 만들어보기'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('hides the create CTA from the classroom owner', (tester) async {
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
                id: 'preview-classroom',
                shareCode: 'preview',
                ownerName: Nickname('재홍'),
                memberCount: 4,
                createdAt: DateTime(2026),
              ),
            ],
          ),
        ],
        child: const MaterialApp(home: ClassroomPage(shareCode: 'preview')),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('seat-5')));
    await tester.pumpAndSettle();

    expect(find.text('나의 사주 원국'), findsOneWidget);
    expect(find.text('나도 내 반 만들어보기'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows a brief emote without moving a student away', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: ClassroomPage(shareCode: 'preview')),
      ),
    );
    await tester.pumpAndSettle();

    await tester.pump(const Duration(milliseconds: 1200));
    await tester.pump();

    expect(find.byKey(const ValueKey('seat-emote-1')), findsOneWidget);
    expect(find.text('😊'), findsOneWidget);
    expect(find.byKey(const ValueKey('seat-0')), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1100));
    await tester.pump();

    expect(find.byKey(const ValueKey('seat-emote-1')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shares the classroom URL from the top action', (tester) async {
    final shareService = _RecordingShareService();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          shareServiceProvider.overrideWithValue(shareService),
          appConfigProvider.overrideWithValue(
            const AppConfig(
              baseUrl: 'https://seat.example',
              supabaseUrl: '',
              supabasePublishableKey: '',
            ),
          ),
        ],
        child: const MaterialApp(home: ClassroomPage(shareCode: 'preview')),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('링크 공유하기'));
    await tester.pump();

    expect(shareService.lastUrl, 'https://seat.example/class/preview');
  });
}

class _RecordingShareService implements ShareService {
  String? lastUrl;

  @override
  Future<ShareOutcome> shareText({
    required String text,
    required String url,
  }) async {
    lastUrl = url;
    return ShareOutcome.shared;
  }

  @override
  Future<ShareOutcome> sharePng({
    required Uint8List bytes,
    required String fileName,
    required String text,
  }) async {
    return ShareOutcome.shared;
  }
}
