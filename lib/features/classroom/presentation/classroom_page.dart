import 'package:flutter/material.dart';

import '../../../app/app_spacing.dart';
import '../../../shared/presentation/app_scaffold.dart';
import 'models/classroom_scene_member.dart';
import 'widgets/classroom_scene.dart';
import 'widgets/member_result_sheet.dart';

class ClassroomPage extends StatelessWidget {
  const ClassroomPage({required this.shareCode, super.key});

  final String shareCode;

  static const _members = [
    ClassroomSceneMember(
      name: '지현',
      seatIndex: 0,
      relationshipTitle: '정신적 반장',
      relationshipDescription: '흔들릴 때 은근히 정신 차리게 만들어주는 사람.',
      seatDescription: '재홍님의 앞쪽 자리',
      focusDelta: 62,
      joyDelta: 41,
      color: Color(0xFF6F9E86),
    ),
    ClassroomSceneMember(
      name: '재홍',
      seatIndex: 4,
      relationshipTitle: '은근한 핵심 인물',
      relationshipDescription: '튀지는 않아도 사람들이 자연스럽게 주변에 모이는 자리.',
      seatDescription: '우리 반 생성자',
      focusDelta: 18,
      joyDelta: 74,
      color: Color(0xFF759EB5),
      isOwner: true,
    ),
    ClassroomSceneMember(
      name: '민수',
      seatIndex: 5,
      relationshipTitle: '찰떡 짝꿍',
      relationshipDescription: '말 안 해도 편하고, 붙어 있으면 하루가 금방 지나가는 관계.',
      seatDescription: '재홍님의 오른쪽 자리',
      focusDelta: -8,
      joyDelta: 92,
      color: Color(0xFFD38170),
    ),
    ClassroomSceneMember(
      name: '현우',
      seatIndex: 7,
      relationshipTitle: '공동피고인',
      relationshipDescription: '좋은 선택보다 재밌는 선택을 같이 할 가능성이 높은 사람.',
      seatDescription: '재홍님의 뒷자리',
      focusDelta: -38,
      joyDelta: 92,
      color: Color(0xFFC7A45E),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      actions: [
        IconButton(
          tooltip: '링크 공유하기',
          onPressed: () {},
          icon: const Icon(Icons.ios_share_rounded),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  '재홍이네 반',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
              Text(
                '${_members.length} / 9명',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '오늘도 전학생을 기다리는 중',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.lg),
          ClassroomScene(
            members: _members,
            onMemberTap: (member) => showMemberResultSheet(context, member),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('전학 올래?', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.xs),
          const Text('이름과 생일을 입력하면 빈자리를 찾아줄게요.'),
          const SizedBox(height: AppSpacing.md),
          OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.person_add_alt_1_rounded),
            label: const Text('내 자리 찾기'),
          ),
        ],
      ),
    );
  }
}
