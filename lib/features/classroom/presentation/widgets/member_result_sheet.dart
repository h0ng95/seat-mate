import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/app_colors.dart';
import '../../../../app/app_spacing.dart';
import '../../../character/presentation/pixel_character.dart';
import '../../../sharing/application/share_providers.dart';
import '../../../sharing/application/share_service.dart';
import '../../application/classroom_providers.dart';
import '../../domain/saju_chart.dart';
import '../../domain/saju_compatibility.dart';
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
      heightFactor: 0.94,
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
    final compatibility = member.compatibility;
    final chart = member.sajuChart;
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
                    member.isOwner ? '나의 사주 원국' : '전통 명리 관계 풀이',
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
                  if (compatibility != null &&
                      chart != null &&
                      member.ownerSajuChart != null) ...[
                    _HeartScorePanel(
                      score: compatibility.heartScore,
                      label: compatibility.heartLabel,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _AnalysisScope(compatibility: compatibility),
                    const SizedBox(height: AppSpacing.xl),
                    Text(
                      '두 사람의 원국',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    _ChartRow(
                      name: ownerName,
                      chart: member.ownerSajuChart!,
                      color: AppColors.board,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _ChartRow(
                      name: member.name,
                      chart: chart,
                      color: AppColors.coral,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Text(
                      '점수 계산 근거',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '네 항목을 더한 값이 하트 궁합 점수예요.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.inkSoft,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    for (final evidence in compatibility.evidence) ...[
                      _EvidenceRow(evidence: evidence),
                      const SizedBox(height: AppSpacing.xs),
                    ],
                    const SizedBox(height: AppSpacing.xl),
                    Text(
                      '관계 명리 풀이',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      compatibility.energy,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _ReadingRow(
                      icon: Icons.auto_awesome_rounded,
                      color: AppColors.yellow,
                      title: '둘이 빛나는 순간',
                      body: compatibility.strength,
                    ),
                    const Divider(height: AppSpacing.xl),
                    _ReadingRow(
                      icon: Icons.compare_arrows_rounded,
                      color: AppColors.sky,
                      title: '부딪히기 쉬운 지점',
                      body: compatibility.caution,
                    ),
                    const Divider(height: AppSpacing.xl),
                    _ReadingRow(
                      icon: Icons.favorite_rounded,
                      color: AppColors.coral,
                      title: '오래 가는 관계 팁',
                      body: compatibility.advice,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                  ] else if (member.isOwner && chart != null) ...[
                    _AnalysisScope.forChart(chart),
                    const SizedBox(height: AppSpacing.lg),
                    _ChartRow(
                      name: member.name,
                      chart: chart,
                      color: AppColors.board,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _OwnerReading(member: member),
                    const SizedBox(height: AppSpacing.xl),
                  ] else ...[
                    const _LegacyResultNotice(),
                    const SizedBox(height: AppSpacing.xl),
                  ],
                  const _MethodNotice(),
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
    final compatibility = member.compatibility;
    final scoreText = compatibility == null
        ? ''
        : ' 명리 궁합 ${compatibility.heartScore}%,';
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
                    '명리 궁합 점수',
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

class _AnalysisScope extends StatelessWidget {
  const _AnalysisScope({required this.compatibility}) : chart = null;

  const _AnalysisScope.forChart(this.chart) : compatibility = null;

  final SajuCompatibility? compatibility;
  final SajuChart? chart;

  @override
  Widget build(BuildContext context) {
    final scope = compatibility?.analysisScope ?? chart!.depth.description;
    final isDetailed =
        compatibility?.analysisDepth == SajuAnalysisDepth.fourPillars ||
        chart?.depth == SajuAnalysisDepth.fourPillars;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: isDetailed ? AppColors.paperGreen : AppColors.paperBlue,
        border: Border.all(color: isDetailed ? AppColors.leaf : AppColors.sky),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Row(
          children: [
            Icon(
              isDetailed ? Icons.verified_rounded : Icons.info_outline_rounded,
              size: 20,
              color: isDetailed ? AppColors.board : AppColors.sky,
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text(
                scope,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChartRow extends StatelessWidget {
  const _ChartRow({
    required this.name,
    required this.chart,
    required this.color,
  });

  final String name;
  final SajuChart chart;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final pillars = [
      ('년주', chart.year),
      ('월주', chart.month),
      ('일주', chart.day),
      ('시주', chart.hour),
    ];
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.chalk,
        border: Border(left: BorderSide(color: color, width: 4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '$name · ${chart.dayMasterKorean}(${_elementLabel(chart.dayMasterElement)}) 일간',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Text(
                  chart.depth == SajuAnalysisDepth.fourPillars ? '4주' : '3주',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final item in pillars)
                  _PillarTile(label: item.$1, pillar: item.$2, color: color),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PillarTile extends StatelessWidget {
  const _PillarTile({
    required this.label,
    required this.pillar,
    required this.color,
  });

  final String label;
  final SajuPillarValue? pillar;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 58,
      height: 64,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: pillar == null ? AppColors.paper : color.withValues(alpha: 0.08),
        border: Border.all(
          color: pillar == null ? AppColors.line : color.withValues(alpha: 0.4),
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.inkSoft),
          ),
          Text(
            pillar?.hanja ?? '--',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: pillar == null ? AppColors.inkSoft : color,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _EvidenceRow extends StatelessWidget {
  const _EvidenceRow({required this.evidence});

  final CompatibilityEvidence evidence;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.chalk,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    evidence.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Text(
                  '${evidence.score} / ${evidence.maxScore}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.coral,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 3),
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: evidence.score / evidence.maxScore,
                minHeight: 4,
                color: AppColors.board,
                backgroundColor: AppColors.paperGreen,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              evidence.summary,
              style: Theme.of(context).textTheme.bodySmall,
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

class _LegacyResultNotice extends StatelessWidget {
  const _LegacyResultNotice();

  @override
  Widget build(BuildContext context) {
    return Text(
      '이 자리는 이전 계산 방식으로 만들어져 원국과 점수 근거를 표시할 수 없어요. 새 교실에서는 명리 계산 결과가 함께 저장됩니다.',
      style: Theme.of(context).textTheme.bodyLarge,
    );
  }
}

class _MethodNotice extends StatelessWidget {
  const _MethodNotice();

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
              Icons.fact_check_outlined,
              size: 18,
              color: AppColors.sky,
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text(
                'KST 양력과 절기 경계로 원국을 계산하고, 일간 오행·일지 합충·오행 균형·전체 합충을 합산합니다. 점수는 AI가 임의 생성하지 않습니다. 전통 명리는 과학적으로 검증된 관계 예측 도구가 아니므로 실제 판단은 대화와 경험을 기준으로 해주세요.\n계산 버전: saju-0.1.1 · compatibility-1',
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

String _elementLabel(String key) => switch (key) {
  'wood' => '목',
  'fire' => '화',
  'earth' => '토',
  'metal' => '금',
  _ => '수',
};
