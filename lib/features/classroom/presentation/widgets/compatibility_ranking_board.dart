import 'package:flutter/material.dart';

import '../../../../app/app_colors.dart';
import '../../../../app/app_spacing.dart';
import '../../domain/classroom.dart';
import '../../domain/relationship.dart';

class CompatibilityRankingBoard extends StatelessWidget {
  const CompatibilityRankingBoard({
    required this.ownerName,
    required this.members,
    super.key,
  });

  final String ownerName;
  final List<ClassroomMember> members;

  @override
  Widget build(BuildContext context) {
    final ranked = rankByCompatibility(members);
    return Semantics(
      container: true,
      label: '$ownerName님과 친구들의 케미 지수 순위',
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.board,
          border: Border.all(color: AppColors.boardDark, width: 4),
          borderRadius: BorderRadius.circular(4),
          boxShadow: const [
            BoxShadow(
              color: Color(0x44332F2C),
              offset: Offset(0, 5),
              blurRadius: 8,
            ),
          ],
        ),
        child: CustomPaint(
          painter: const _ChalkDustPainter(),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.leaderboard_rounded,
                      color: AppColors.yellow,
                      size: 24,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        '우리 반 케미 순위',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppColors.chalk,
                          fontWeight: FontWeight.w900,
                          shadows: const [
                            Shadow(color: Color(0x66FFFFFF), blurRadius: 1),
                          ],
                        ),
                      ),
                    ),
                    Text(
                      '$ownerName 기준',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.chalk.withValues(alpha: 0.78),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Container(
                  height: 2,
                  color: AppColors.chalk.withValues(alpha: 0.65),
                ),
                const SizedBox(height: AppSpacing.sm),
                if (ranked.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.lg,
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.favorite_border_rounded,
                          color: AppColors.chalk.withValues(alpha: 0.75),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          '첫 친구가 앉으면 순위가 시작돼요',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(color: AppColors.chalk),
                        ),
                      ],
                    ),
                  )
                else
                  for (final entry in ranked.indexed) ...[
                    _RankingRow(
                      key: ValueKey('compatibility-rank-${entry.$1 + 1}'),
                      rank: entry.$1 + 1,
                      member: entry.$2,
                    ),
                    if (entry.$1 != ranked.length - 1)
                      Divider(
                        height: 1,
                        color: AppColors.chalk.withValues(alpha: 0.18),
                      ),
                  ],
                const SizedBox(height: AppSpacing.sm),
                Text(
                  '친밀도 순위가 아닌 명리 계산 기반 케미 지수 순이에요.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.chalk.withValues(alpha: 0.68),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

List<ClassroomMember> rankByCompatibility(List<ClassroomMember> members) {
  final ranked = members
      .where((member) => !member.isOwner && member.compatibility != null)
      .toList();
  ranked.sort((first, second) {
    final scoreComparison = second.compatibility!.heartScore.compareTo(
      first.compatibility!.heartScore,
    );
    if (scoreComparison != 0) return scoreComparison;
    final seatComparison = first.seatIndex.compareTo(second.seatIndex);
    if (seatComparison != 0) return seatComparison;
    return first.name.normalized.compareTo(second.name.normalized);
  });
  return List.unmodifiable(ranked);
}

class _RankingRow extends StatelessWidget {
  const _RankingRow({required this.rank, required this.member, super.key});

  final int rank;
  final ClassroomMember member;

  @override
  Widget build(BuildContext context) {
    final isWinner = rank == 1;
    final chalkColor = isWinner ? AppColors.yellow : AppColors.chalk;
    return SizedBox(
      height: 50,
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: chalkColor, width: 2),
            ),
            child: Text(
              '$rank',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: chalkColor,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.name.display,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: chalkColor,
                    fontWeight: FontWeight.w900,
                    shadows: const [
                      Shadow(color: Color(0x55FFFFFF), blurRadius: 1),
                    ],
                  ),
                ),
                Text(
                  member.relationship!.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.chalk.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          const Icon(
            Icons.favorite_rounded,
            size: 17,
            color: Color(0xFFFFCBC1),
          ),
          const SizedBox(width: 3),
          SizedBox(
            width: 42,
            child: Text(
              '${member.compatibility!.heartScore}%',
              textAlign: TextAlign.right,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.chalk,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChalkDustPainter extends CustomPainter {
  const _ChalkDustPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final dust = Paint()
      ..color = AppColors.chalk.withValues(alpha: 0.035)
      ..strokeWidth = 1;
    const strokes = [
      (0.08, 0.18, 0.31),
      (0.64, 0.11, 0.22),
      (0.18, 0.72, 0.28),
      (0.58, 0.84, 0.3),
      (0.43, 0.46, 0.18),
    ];
    for (final stroke in strokes) {
      final y = size.height * stroke.$2;
      canvas.drawLine(
        Offset(size.width * stroke.$1, y),
        Offset(size.width * (stroke.$1 + stroke.$3), y + 1),
        dust,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ChalkDustPainter oldDelegate) => false;
}
