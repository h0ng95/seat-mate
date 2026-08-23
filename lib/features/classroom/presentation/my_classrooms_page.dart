import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_colors.dart';
import '../../../app/app_spacing.dart';
import '../../../shared/presentation/app_scaffold.dart';
import '../../auth/application/auth_providers.dart';
import '../../auth/presentation/kakao_login_button.dart';
import '../application/classroom_providers.dart';
import '../domain/classroom.dart';
import '../domain/classroom_seat_layout.dart';

class MyClassroomsPage extends ConsumerWidget {
  const MyClassroomsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(appConfigProvider);
    final authState = ref.watch(authUserProvider);
    final user = authState.value;

    if (config.hasSupabase && authState.isLoading) {
      return const AppScaffold(
        child: SizedBox(
          height: 360,
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }
    if (config.hasSupabase && user == null) {
      return const AppScaffold(child: _MyClassroomsLogin());
    }

    final classroomListKey = user?.id ?? 'demo';
    final classroomsState = ref.watch(
      savedClassroomsProvider(classroomListKey),
    );
    return AppScaffold(
      actions: config.hasSupabase
          ? [
              Tooltip(
                message: '로그아웃',
                child: IconButton(
                  onPressed: () async {
                    await ref.read(authControllerProvider.notifier).signOut();
                    if (context.mounted) context.go('/');
                  },
                  icon: const Icon(Icons.logout_rounded),
                ),
              ),
            ]
          : const [],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '내 반',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    if (user != null)
                      Text(
                        '${user.displayName}님이 만든 교실',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.inkSoft,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          classroomsState.when(
            data: (classrooms) => classrooms.isEmpty
                ? const _CreateFirstClassRedirect()
                : Column(
                    children: [
                      for (final classroom in classrooms)
                        Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: _ClassroomListItem(classroom: classroom),
                        ),
                    ],
                  ),
            loading: () => const SizedBox(
              height: 280,
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, stackTrace) => _ClassroomsError(
              onRetry: () =>
                  ref.invalidate(savedClassroomsProvider(classroomListKey)),
            ),
          ),
        ],
      ),
    );
  }
}

class _MyClassroomsLogin extends StatelessWidget {
  const _MyClassroomsLogin();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSpacing.xl),
        const Icon(Icons.school_outlined, size: 52, color: AppColors.board),
        const SizedBox(height: AppSpacing.md),
        Text(
          '내 반을 보려면\n로그인해 주세요',
          style: Theme.of(context).textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          '카카오 계정으로 내가 만든 교실을\n안전하게 관리할 수 있어요.',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppColors.inkSoft),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.lg),
        const KakaoLoginButton(redirectPath: '/my'),
      ],
    );
  }
}

class _CreateFirstClassRedirect extends StatefulWidget {
  const _CreateFirstClassRedirect();

  @override
  State<_CreateFirstClassRedirect> createState() =>
      _CreateFirstClassRedirectState();
}

class _CreateFirstClassRedirectState extends State<_CreateFirstClassRedirect> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.go('/create');
    });
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 280,
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

class _ClassroomListItem extends ConsumerWidget {
  const _ClassroomListItem({required this.classroom});

  final SavedClassroomSummary classroom;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deleteState = ref.watch(deleteClassroomControllerProvider);
    final isDeleting = deleteState?.isLoading ?? false;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.chalk,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.xs,
          AppSpacing.sm,
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.paperGreen,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(Icons.school_rounded, color: AppColors.board),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${classroom.ownerName.display}의 반',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    '${classroom.memberCount}/${ClassroomSeatLayout.capacity}명 · ${_formatDate(classroom.createdAt)}',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: AppColors.inkSoft),
                  ),
                ],
              ),
            ),
            Tooltip(
              message: '교실 열기',
              child: IconButton(
                onPressed: () => context.go('/class/${classroom.shareCode}'),
                icon: const Icon(Icons.arrow_forward_rounded),
              ),
            ),
            Tooltip(
              message: '교실 삭제',
              child: IconButton(
                onPressed: isDeleting
                    ? null
                    : () => _confirmDelete(context, ref),
                icon: const Icon(Icons.delete_outline_rounded),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('이 반을 삭제할까요?'),
        content: const Text('교실과 친구들의 참여 기록이 함께 삭제되며 되돌릴 수 없어요.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final deleted = await ref
        .read(deleteClassroomControllerProvider.notifier)
        .delete(classroom.shareCode);
    if (!deleted && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('반을 삭제하지 못했어요. 다시 시도해 주세요.')),
      );
    }
  }

  static String _formatDate(DateTime value) {
    final local = value.toLocal();
    return '${local.year}.${local.month.toString().padLeft(2, '0')}.${local.day.toString().padLeft(2, '0')}';
  }
}

class _ClassroomsError extends StatelessWidget {
  const _ClassroomsError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: AppSpacing.xl),
        const Icon(
          Icons.error_outline_rounded,
          size: 42,
          color: AppColors.error,
        ),
        const SizedBox(height: AppSpacing.sm),
        const Text('내 반 목록을 불러오지 못했어요.'),
        const SizedBox(height: AppSpacing.md),
        OutlinedButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('다시 불러오기'),
        ),
      ],
    );
  }
}
