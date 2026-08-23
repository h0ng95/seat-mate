import 'package:flutter/material.dart';

import '../../../app/app_spacing.dart';
import '../../../shared/presentation/app_scaffold.dart';

class ClassroomPage extends StatelessWidget {
  const ClassroomPage({required this.shareCode, super.key});

  final String shareCode;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('우리 반', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: AppSpacing.xs),
          Text('교실 코드 $shareCode'),
        ],
      ),
    );
  }
}
