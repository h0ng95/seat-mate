import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'app_scaffold.dart';
import 'error_state.dart';

class NotFoundPage extends StatelessWidget {
  const NotFoundPage({required this.location, super.key});

  final String location;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height - 140,
        child: Center(
          child: AppErrorState(
            title: '앗, 교실을 못 찾았어요.',
            message: '링크가 오래됐거나 잘못된 주소일 수 있어요.',
            actionLabel: '내 반 만들기',
            onAction: () => context.go('/create'),
          ),
        ),
      ),
    );
  }
}
