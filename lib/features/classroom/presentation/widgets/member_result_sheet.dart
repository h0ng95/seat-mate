import 'package:flutter/material.dart';

import '../../../../app/app_colors.dart';
import '../../../../app/app_spacing.dart';
import '../../../character/presentation/pixel_character.dart';
import '../models/classroom_scene_member.dart';

Future<void> showMemberResultSheet(
  BuildContext context,
  ClassroomSceneMember member,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.paper,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
    ),
    builder: (context) => MemberResultSheet(member: member),
  );
}

class MemberResultSheet extends StatelessWidget {
  const MemberResultSheet({required this.member, super.key});

  final ClassroomSceneMember member;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                tooltip: '닫기',
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded),
              ),
            ),
            Row(
              children: [
                SizedBox(
                  width: 54,
                  height: 66,
                  child: PixelCharacter(
                    seed: member.characterSeed,
                    semanticLabel: '${member.name} 도트 캐릭터',
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        member.name,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Text(member.seatDescription),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                const Icon(Icons.bookmark_rounded, color: AppColors.coral),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  member.relationshipTitle,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(member.relationshipDescription),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: _Metric(label: '집중력', value: member.focusDelta),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _Metric(label: '재미', value: member.joyDelta),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    final sign = value > 0 ? '+' : '';
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.chalk,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          children: [
            Text(label, style: Theme.of(context).textTheme.bodyMedium),
            Text(
              '$sign$value%',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: value >= 0 ? AppColors.board : AppColors.coral,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
