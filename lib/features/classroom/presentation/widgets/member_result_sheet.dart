import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/app_colors.dart';
import '../../../../app/app_spacing.dart';
import '../../../character/presentation/pixel_character.dart';
import '../../../sharing/application/share_providers.dart';
import '../../../sharing/application/share_service.dart';
import '../../application/classroom_providers.dart';
import '../models/classroom_scene_member.dart';

Future<void> showMemberResultSheet(
  BuildContext context,
  ClassroomSceneMember member, {
  required String shareCode,
  required String ownerName,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.paper,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
    ),
    builder: (context) => MemberResultSheet(
      member: member,
      shareCode: shareCode,
      ownerName: ownerName,
    ),
  );
}

class MemberResultSheet extends ConsumerWidget {
  const MemberResultSheet({
    required this.member,
    required this.shareCode,
    required this.ownerName,
    super.key,
  });

  final ClassroomSceneMember member;
  final String shareCode;
  final String ownerName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
            const SizedBox(height: AppSpacing.lg),
            FilledButton.icon(
              onPressed: () => _shareResult(context, ref),
              icon: const Icon(Icons.ios_share_rounded),
              label: const Text('내 자리 결과 공유하기'),
            ),
            const SizedBox(height: AppSpacing.xs),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                context.go('/create');
              },
              icon: const Icon(Icons.add_rounded),
              label: const Text('나도 내 반 만들어보기'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _shareResult(BuildContext context, WidgetRef ref) async {
    final baseUrl = ref
        .read(appConfigProvider)
        .baseUrl
        .replaceFirst(RegExp(r'/$'), '');
    final outcome = await ref
        .read(shareServiceProvider)
        .shareText(
          text:
              '$ownerName이네 반에서 ${member.name}님은 ${member.relationshipTitle}! 너도 어디 앉는지 해봐.',
          url: '$baseUrl/class/$shareCode',
        );
    if (!context.mounted || outcome == ShareOutcome.dismissed) return;
    final message = outcome == ShareOutcome.copied
        ? '링크를 복사했어요.'
        : '공유 화면을 열었어요.';
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
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
