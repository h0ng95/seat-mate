import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/application/auth_providers.dart';
import '../features/classroom/application/classroom_providers.dart';

Future<void> openMyClassrooms(BuildContext context, WidgetRef ref) async {
  final activeShareCode = ref.read(activeClassroomShareCodeProvider);
  if (activeShareCode != null) {
    if (context.mounted) context.go('/class/$activeShareCode');
    return;
  }
  final config = ref.read(appConfigProvider);
  final authState = ref.read(authUserProvider);
  var user = authState.value;

  if (config.hasSupabase && authState.isLoading) {
    try {
      user = await ref.read(authUserProvider.future);
    } catch (_) {
      if (context.mounted) _showLoadError(context);
      return;
    }
  }

  if (config.hasSupabase && user == null) {
    if (context.mounted) context.go('/create');
    return;
  }

  try {
    final key = user?.id ?? 'demo';
    final classrooms = await ref.read(savedClassroomsProvider(key).future);
    if (!context.mounted) return;
    if (classrooms.isNotEmpty) {
      context.go('/class/${classrooms.first.shareCode}');
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: const Text('아직 만든 반이 없어요. 먼저 내 반을 만들어 주세요.'),
          action: SnackBarAction(
            label: '반 만들기',
            onPressed: () {
              if (context.mounted) context.go('/create');
            },
          ),
        ),
      );
  } catch (_) {
    if (context.mounted) _showLoadError(context);
  }
}

void _showLoadError(BuildContext context) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      const SnackBar(content: Text('내 반 정보를 확인하지 못했어요. 다시 시도해 주세요.')),
    );
}
