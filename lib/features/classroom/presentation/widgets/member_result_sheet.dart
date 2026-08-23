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
    builder: (context) => FractionallySizedBox(
      heightFactor: 0.92,
      child: MemberResultSheet(
        member: member,
        shareCode: shareCode,
        ownerName: ownerName,
      ),
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
    final fortune = member.fortune;
    return SafeArea(
      top: false,
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.sm),
          Container(width: 38, height: 4, color: AppColors.line),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.xs,
              AppSpacing.sm,
              0,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    member.isOwner ? '나의 자리 운세' : '우리 사이 관계 사주',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: '닫기',
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _MemberHeading(member: member, ownerName: ownerName),
                  const SizedBox(height: AppSpacing.lg),
                  if (fortune != null) ...[
                    _HeartScorePanel(
                      score: fortune.heartScore,
                      label: fortune.heartLabel,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Text(
                      '관계 사주 풀이',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      fortune.energy,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _ReadingRow(
                      icon: Icons.auto_awesome_rounded,
                      color: AppColors.yellow,
                      title: '둘이 빛나는 순간',
                      body: fortune.strength,
                    ),
                    const Divider(height: AppSpacing.xl),
                    _ReadingRow(
                      icon: Icons.waves_rounded,
                      color: AppColors.sky,
                      title: '부딪히기 쉬운 지점',
                      body: fortune.caution,
                    ),
                    const Divider(height: AppSpacing.xl),
                    _ReadingRow(
                      icon: Icons.favorite_rounded,
                      color: AppColors.coral,
                      title: '오래 가는 관계 팁',
                      body: fortune.advice,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                  ] else ...[
                    _OwnerReading(member: member),
                    const SizedBox(height: AppSpacing.xl),
                  ],
                  Row(
                    children: [
                      Expanded(
                        child: _Metric(
                          label: '집중 기운',
                          value: member.focusDelta,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: _Metric(label: '즐거움 기운', value: member.joyDelta),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  const _EntertainmentNotice(),
                  const SizedBox(height: AppSpacing.lg),
                  FilledButton.icon(
                    onPressed: () => _shareResult(context, ref),
                    icon: const Icon(Icons.ios_share_rounded),
                    label: const Text('관계 결과 공유하기'),
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
          ),
        ],
      ),
    );
  }

  Future<void> _shareResult(BuildContext context, WidgetRef ref) async {
    final baseUrl = ref
        .read(appConfigProvider)
        .baseUrl
        .replaceFirst(RegExp(r'/$'), '');
    final fortune = member.fortune;
    final scoreText = fortune == null ? '' : ' 하트 궁합 ${fortune.heartScore}%,';
    final outcome = await ref
        .read(shareServiceProvider)
        .shareText(
          text:
              '$ownerName이네 반에서 ${member.name}님은$scoreText ${member.relationshipTitle}! 너도 우리 사이를 확인해 봐.',
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

class _MemberHeading extends StatelessWidget {
  const _MemberHeading({required this.member, required this.ownerName});

  final ClassroomSceneMember member;
  final String ownerName;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 76,
          height: 88,
          padding: const EdgeInsets.all(AppSpacing.xs),
          decoration: BoxDecoration(
            color: AppColors.sky.withValues(alpha: 0.2),
            border: Border.all(color: AppColors.sky, width: 2),
            borderRadius: BorderRadius.circular(6),
          ),
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
                member.isOwner ? member.name : '$ownerName × ${member.name}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 2),
              Text(
                member.relationshipTitle,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.board,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                member.seatDescription,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppColors.inkSoft),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HeartScorePanel extends StatelessWidget {
  const _HeartScorePanel({required this.score, required this.label});

  final int score;
  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.coral.withValues(alpha: 0.13),
        border: Border.all(color: AppColors.coral.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            SizedBox.square(
              dimension: 88,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Icon(
                    Icons.favorite_rounded,
                    size: 84,
                    color: AppColors.coral,
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Text(
                      '$score%',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.chalk,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '하트 궁합',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.coral,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(label, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: AppSpacing.xs),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: score / 100,
                      minHeight: 6,
                      backgroundColor: AppColors.chalk,
                      color: AppColors.coral,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReadingRow extends StatelessWidget {
  const _ReadingRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 20, color: color),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 2),
              Text(body, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
      ],
    );
  }
}

class _OwnerReading extends StatelessWidget {
  const _OwnerReading({required this.member});

  final ClassroomSceneMember member;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.board,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.boardDark, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.auto_awesome_rounded, color: AppColors.yellow),
            const SizedBox(height: AppSpacing.sm),
            Text(
              member.relationshipDescription,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: AppColors.chalk),
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

class _EntertainmentNotice extends StatelessWidget {
  const _EntertainmentNotice();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.sky.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.info_outline_rounded,
              size: 18,
              color: AppColors.sky,
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text(
                '생년월일의 반복 가능한 패턴을 관계 이야기로 풀어낸 엔터테인먼트 결과예요. 중요한 관계 판단은 실제 대화와 경험을 기준으로 해주세요.',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.inkSoft),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
