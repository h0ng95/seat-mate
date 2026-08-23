import 'package:flutter/material.dart';

import '../../../app/app_spacing.dart';
import '../../../shared/presentation/app_scaffold.dart';
import '../../../shared/presentation/app_text_field.dart';
import '../../../shared/presentation/primary_button.dart';

class CreateClassroomPage extends StatelessWidget {
  const CreateClassroomPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '내 반을 만들어볼까요?',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: AppSpacing.xs),
          const Text('실명 대신 별명을 사용해도 좋아요.'),
          const SizedBox(height: AppSpacing.xl),
          const AppTextField(label: '이름 또는 별명', hintText: '재홍'),
          const SizedBox(height: AppSpacing.md),
          const AppTextField(label: '생년월일', hintText: '1995. 06. 12'),
          const SizedBox(height: AppSpacing.lg),
          PrimaryButton(label: '내 자리 찾기', onPressed: () {}),
        ],
      ),
    );
  }
}
