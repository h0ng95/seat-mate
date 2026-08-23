import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:seat_mate/app/app_config.dart';
import 'package:seat_mate/features/classroom/application/classroom_providers.dart';
import 'package:seat_mate/features/classroom/presentation/classroom_page.dart';
import 'package:seat_mate/features/sharing/application/share_providers.dart';
import 'package:seat_mate/features/sharing/application/share_service.dart';

void main() {
  testWidgets('renders nine classroom seats at mobile width', (tester) async {
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

    for (var index = 0; index < 9; index++) {
      expect(find.byKey(ValueKey('seat-$index')), findsOneWidget);
    }
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

    await tester.tap(find.byKey(const ValueKey('seat-5')));
    await tester.pumpAndSettle();

    expect(find.text('명리 궁합 점수'), findsOneWidget);
    expect(find.text('두 사람의 원국'), findsOneWidget);
    expect(find.text('점수 계산 근거'), findsOneWidget);
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
