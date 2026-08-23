import 'package:saju/saju.dart' as saju;

import 'relationship.dart';
import 'saju_chart.dart';

class CompatibilityEvidence {
  const CompatibilityEvidence({
    required this.title,
    required this.score,
    required this.maxScore,
    required this.summary,
  });

  final String title;
  final int score;
  final int maxScore;
  final String summary;

  Map<String, dynamic> toJson() => {
    'title': title,
    'score': score,
    'max_score': maxScore,
    'summary': summary,
  };

  factory CompatibilityEvidence.fromJson(Map<String, dynamic> json) {
    return CompatibilityEvidence(
      title: json['title'] as String,
      score: json['score'] as int,
      maxScore: json['max_score'] as int,
      summary: json['summary'] as String,
    );
  }
}

class SajuCompatibility {
  const SajuCompatibility({
    required this.heartScore,
    required this.heartLabel,
    required this.relationshipType,
    required this.energy,
    required this.strength,
    required this.caution,
    required this.advice,
    required this.evidence,
    required this.analysisDepth,
    required this.positiveRelations,
    required this.tensionRelations,
    this.rulesVersion = SajuCompatibilityEngine.rulesVersion,
  });

  final int heartScore;
  final String heartLabel;
  final RelationshipType relationshipType;
  final String energy;
  final String strength;
  final String caution;
  final String advice;
  final List<CompatibilityEvidence> evidence;
  final SajuAnalysisDepth analysisDepth;
  final int positiveRelations;
  final int tensionRelations;
  final String rulesVersion;

  String get analysisScope => analysisDepth == SajuAnalysisDepth.fourPillars
      ? '두 사람 모두 출생시간을 포함한 4/4 기둥 분석'
      : '출생시간 미입력 항목을 제외한 3/4 기둥 분석';

  Map<String, dynamic> toJson() => {
    'heart_score': heartScore,
    'heart_label': heartLabel,
    'relationship_type': relationshipType.code,
    'energy': energy,
    'strength': strength,
    'caution': caution,
    'advice': advice,
    'evidence': evidence.map((item) => item.toJson()).toList(),
    'analysis_depth': analysisDepth.name,
    'positive_relations': positiveRelations,
    'tension_relations': tensionRelations,
    'rules_version': rulesVersion,
  };

  factory SajuCompatibility.fromJson(Map<String, dynamic> json) {
    return SajuCompatibility(
      heartScore: json['heart_score'] as int,
      heartLabel: json['heart_label'] as String,
      relationshipType: RelationshipType.values.firstWhere(
        (type) => type.code == json['relationship_type'],
      ),
      energy: json['energy'] as String,
      strength: json['strength'] as String,
      caution: json['caution'] as String,
      advice: json['advice'] as String,
      evidence: (json['evidence'] as List)
          .map(
            (item) => CompatibilityEvidence.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(growable: false),
      analysisDepth: SajuAnalysisDepth.values.byName(
        json['analysis_depth'] as String,
      ),
      positiveRelations: json['positive_relations'] as int,
      tensionRelations: json['tension_relations'] as int,
      rulesVersion: json['rules_version'] as String? ?? 'compatibility-1',
    );
  }
}

class SajuCompatibilityEngine {
  const SajuCompatibilityEngine();

  static const rulesVersion = 'compatibility-1';

  SajuCompatibility analyze({
    required SajuChart owner,
    required SajuChart member,
  }) {
    final ownerStem = saju.Stem.fromHanja(owner.dayMaster);
    final memberStem = saju.Stem.fromHanja(member.dayMaster);
    final ownerDayBranch = _branchOf(owner.day);
    final memberDayBranch = _branchOf(member.day);
    final elementRelation = _elementRelation(
      ownerStem.element,
      memberStem.element,
    );
    final dayMasterEvidence = _dayMasterEvidence(
      ownerStem,
      memberStem,
      elementRelation,
    );
    final dayBranchEvidence = _dayBranchEvidence(
      ownerDayBranch,
      memberDayBranch,
    );
    final elementEvidence = _elementBalanceEvidence(owner, member);
    final chartFlow = _chartFlow(owner, member);
    final chartEvidence = CompatibilityEvidence(
      title: '전체 합충 흐름',
      score: chartFlow.score,
      maxScore: 20,
      summary: chartFlow.summary,
    );
    final evidence = [
      dayMasterEvidence,
      dayBranchEvidence,
      elementEvidence,
      chartEvidence,
    ];
    final score = evidence
        .fold<int>(0, (total, item) => total + item.score)
        .clamp(32, 98);
    final depth = owner.hasBirthTime && member.hasBirthTime
        ? SajuAnalysisDepth.fourPillars
        : SajuAnalysisDepth.threePillars;
    final relationshipType = _relationshipType(
      score: score,
      relation: elementRelation,
      ownerElement: ownerStem.element,
      memberElement: memberStem.element,
      dayBranchesCombine: _isSixCombination(ownerDayBranch, memberDayBranch),
      dayBranchesClash: _isPairIn(
        ownerDayBranch,
        memberDayBranch,
        saju.branchClashes,
      ),
      tensionRelations: chartFlow.tension,
    );

    return SajuCompatibility(
      heartScore: score,
      heartLabel: switch (score) {
        >= 90 => '상생 흐름이 아주 선명한 사이',
        >= 80 => '서로의 기운을 잘 살리는 사이',
        >= 70 => '균형을 맞추며 가까워지는 사이',
        >= 60 => '차이를 이해하면 단단해지는 사이',
        _ => '속도를 맞출수록 편안해지는 사이',
      },
      relationshipType: relationshipType,
      energy: _energyReading(ownerStem, memberStem, elementRelation),
      strength: _strengthReading(
        owner,
        member,
        ownerDayBranch,
        memberDayBranch,
      ),
      caution: _cautionReading(
        elementRelation,
        chartFlow.tension,
        ownerDayBranch,
        memberDayBranch,
      ),
      advice: _adviceReading(owner, member, chartFlow),
      evidence: List.unmodifiable(evidence),
      analysisDepth: depth,
      positiveRelations: chartFlow.positive,
      tensionRelations: chartFlow.tension,
    );
  }

  CompatibilityEvidence _dayMasterEvidence(
    saju.Stem owner,
    saju.Stem member,
    _ElementRelation relation,
  ) {
    final samePolarity = owner.polarity == member.polarity;
    final score = switch (relation) {
      _ElementRelation.same => samePolarity ? 22 : 25,
      _ElementRelation.ownerGeneratesMember ||
      _ElementRelation.memberGeneratesOwner => 30,
      _ElementRelation.ownerControlsMember ||
      _ElementRelation.memberControlsOwner => samePolarity ? 14 : 17,
    };
    return CompatibilityEvidence(
      title: '일간 오행',
      score: score,
      maxScore: 30,
      summary:
          '${owner.korean}(${owner.element.korean})와 ${member.korean}(${member.element.korean})의 ${_elementRelationLabel(relation)} 관계예요.',
    );
  }

  CompatibilityEvidence _dayBranchEvidence(
    saju.Branch owner,
    saju.Branch member,
  ) {
    if (_isSixCombination(owner, member)) {
      return CompatibilityEvidence(
        title: '일지 관계',
        score: 25,
        maxScore: 25,
        summary: '${owner.korean}와 ${member.korean}는 육합으로 보는 결속 관계예요.',
      );
    }
    if (_isPairIn(owner, member, saju.branchClashes)) {
      return CompatibilityEvidence(
        title: '일지 관계',
        score: 6,
        maxScore: 25,
        summary: '${owner.korean}와 ${member.korean}는 충 관계라 생활 리듬의 차이가 크게 드러나요.',
      );
    }
    if (_isPairIn(owner, member, saju.branchHarms)) {
      return CompatibilityEvidence(
        title: '일지 관계',
        score: 10,
        maxScore: 25,
        summary:
            '${owner.korean}와 ${member.korean}는 해 관계라 말하지 않은 기대가 엇갈리기 쉬워요.',
      );
    }
    if (_isPairIn(owner, member, saju.branchDestructions)) {
      return CompatibilityEvidence(
        title: '일지 관계',
        score: 12,
        maxScore: 25,
        summary: '${owner.korean}와 ${member.korean}는 파 관계라 약속과 거리 조절이 중요해요.',
      );
    }
    if (_isPunishment(owner, member)) {
      return CompatibilityEvidence(
        title: '일지 관계',
        score: 9,
        maxScore: 25,
        summary:
            '${owner.korean}와 ${member.korean}는 형의 작용이 있어 감정이 쌓이기 전에 확인이 필요해요.',
      );
    }
    if (owner == member) {
      return CompatibilityEvidence(
        title: '일지 관계',
        score: 19,
        maxScore: 25,
        summary: '같은 ${owner.korean} 일지라 익숙한 생활 감각을 공유해요.',
      );
    }
    return CompatibilityEvidence(
      title: '일지 관계',
      score: 16,
      maxScore: 25,
      summary: '${owner.korean}와 ${member.korean} 사이에 강한 합충이 없어 차분히 맞춰가는 관계예요.',
    );
  }

  CompatibilityEvidence _elementBalanceEvidence(
    SajuChart owner,
    SajuChart member,
  ) {
    final combined = <String, int>{};
    for (final element in saju.Element.values) {
      combined[element.key] =
          (owner.elementCounts[element.key] ?? 0) +
          (member.elementCounts[element.key] ?? 0);
    }
    final total = combined.values.fold<int>(0, (sum, value) => sum + value);
    final ideal = total / saju.Element.values.length;
    final deviation = combined.values.fold<double>(
      0,
      (sum, value) => sum + (value - ideal).abs(),
    );
    final maximumDeviation = 2 * total * 0.8;
    final balance = maximumDeviation == 0
        ? 0.0
        : (1 - deviation / maximumDeviation).clamp(0.0, 1.0);
    final score = 10 + (balance * 15).round();
    final covered = combined.values.where((count) => count > 0).length;
    return CompatibilityEvidence(
      title: '오행 균형',
      score: score,
      maxScore: 25,
      summary: '두 원국을 합치면 오행 $covered가지를 채우며 균형도 ${score - 10}/15로 계산돼요.',
    );
  }

  ({int score, int positive, int tension, String summary}) _chartFlow(
    SajuChart owner,
    SajuChart member,
  ) {
    var positive = 0;
    var tension = 0;
    for (final ownerPillar in owner.availablePillars) {
      final ownerStem = _stemOf(ownerPillar);
      final ownerBranch = _branchOf(ownerPillar);
      for (final memberPillar in member.availablePillars) {
        final memberStem = _stemOf(memberPillar);
        final memberBranch = _branchOf(memberPillar);
        if (_isStemCombination(ownerStem, memberStem)) positive++;
        if (_isSixCombination(ownerBranch, memberBranch)) positive++;
        if (ownerBranch == memberBranch) positive++;
        if (_isPairIn(ownerBranch, memberBranch, saju.branchClashes)) {
          tension++;
        }
        if (_isPairIn(ownerBranch, memberBranch, saju.branchHarms)) tension++;
        if (_isPairIn(ownerBranch, memberBranch, saju.branchDestructions)) {
          tension++;
        }
      }
    }
    final score = (12 + positive.clamp(0, 4) * 2 - tension.clamp(0, 4) * 2)
        .clamp(3, 20);
    final summary = positive == 0 && tension == 0
        ? '전체 기둥 사이에 강한 합충이 없어 관계를 만들어가는 선택의 영향이 커요.'
        : '전체 기둥에서 합·동기운 $positive개, 충·해·파 $tension개를 확인했어요.';
    return (
      score: score,
      positive: positive,
      tension: tension,
      summary: summary,
    );
  }

  RelationshipType _relationshipType({
    required int score,
    required _ElementRelation relation,
    required saju.Element ownerElement,
    required saju.Element memberElement,
    required bool dayBranchesCombine,
    required bool dayBranchesClash,
    required int tensionRelations,
  }) {
    if (dayBranchesCombine) return RelationshipType.buddy;
    if (dayBranchesClash) return RelationshipType.rival;
    if (relation == _ElementRelation.ownerGeneratesMember) {
      return RelationshipType.caretaker;
    }
    if (relation == _ElementRelation.memberGeneratesOwner) {
      return RelationshipType.leader;
    }
    if (score >= 88) return RelationshipType.quietBestie;
    if (ownerElement == memberElement) return RelationshipType.accomplice;
    if (tensionRelations >= 4) return RelationshipType.transfer;
    if (score >= 72) return RelationshipType.moodMaker;
    return RelationshipType.chatter;
  }

  String _energyReading(
    saju.Stem owner,
    saju.Stem member,
    _ElementRelation relation,
  ) {
    final prefix =
        '${owner.korean}(${owner.element.korean}) 일간과 ${member.korean}(${member.element.korean}) 일간은';
    return switch (relation) {
      _ElementRelation.same => '$prefix 같은 오행을 공유해 서로의 반응을 빠르게 알아차리는 흐름이에요.',
      _ElementRelation.ownerGeneratesMember =>
        '$prefix 앞사람의 기운이 뒷사람을 생하는 흐름이라 응원과 지원이 자연스럽게 이어져요.',
      _ElementRelation.memberGeneratesOwner =>
        '$prefix 뒷사람의 기운이 앞사람을 생하는 흐름이라 지친 순간에 힘을 보태기 좋아요.',
      _ElementRelation.ownerControlsMember =>
        '$prefix 앞사람이 관계의 기준과 속도를 잡기 쉬운 상극 흐름이에요.',
      _ElementRelation.memberControlsOwner =>
        '$prefix 뒷사람이 관계의 기준과 속도를 잡기 쉬운 상극 흐름이에요.',
    };
  }

  String _strengthReading(
    SajuChart owner,
    SajuChart member,
    saju.Branch ownerDayBranch,
    saju.Branch memberDayBranch,
  ) {
    if (_isSixCombination(ownerDayBranch, memberDayBranch)) {
      return '두 사람의 일지가 육합을 이루어 일상의 호흡과 친밀감을 쌓는 데 강점이 있어요.';
    }
    final combined = {
      for (final element in saju.Element.values)
        element:
            (owner.elementCounts[element.key] ?? 0) +
            (member.elementCounts[element.key] ?? 0),
    };
    final strongest = combined.entries.reduce(
      (first, second) => first.value >= second.value ? first : second,
    );
    return '함께 있을 때 ${strongest.key.korean} 기운이 가장 선명해져, ${_elementStrength(strongest.key)} 상황에서 합이 좋아요.';
  }

  String _cautionReading(
    _ElementRelation relation,
    int tension,
    saju.Branch ownerDayBranch,
    saju.Branch memberDayBranch,
  ) {
    if (_isPairIn(ownerDayBranch, memberDayBranch, saju.branchClashes)) {
      return '일지에 충이 있어 생활 속도와 표현 방식이 정반대로 느껴질 수 있어요. 차이를 틀림으로 단정하지 마세요.';
    }
    if (tension >= 4) {
      return '원국 사이 충·해·파가 여러 번 겹쳐 가까울수록 사소한 기대 차이가 커질 수 있어요.';
    }
    if (relation == _ElementRelation.ownerControlsMember ||
        relation == _ElementRelation.memberControlsOwner) {
      return '일간에 상극 흐름이 있어 한쪽의 기준이 다른 쪽에게 압박으로 전달되지 않도록 주의해요.';
    }
    return '기운이 편안한 만큼 필요한 말을 미루기 쉬워요. 서운함은 작을 때 확인하는 편이 좋습니다.';
  }

  String _adviceReading(
    SajuChart owner,
    SajuChart member,
    ({int score, int positive, int tension, String summary}) flow,
  ) {
    final missing = saju.Element.values.where(
      (element) =>
          (owner.elementCounts[element.key] ?? 0) +
              (member.elementCounts[element.key] ?? 0) ==
          0,
    );
    if (missing.isNotEmpty) {
      final element = missing.first;
      return '두 원국에 부족한 ${element.korean} 기운을 보완하도록 ${_elementAdvice(element)} 활동을 함께해 보세요.';
    }
    if (flow.positive > flow.tension) {
      return '합의 흐름이 강한 관계라 함께 세운 작은 약속을 꾸준히 지킬수록 장점이 더 선명해져요.';
    }
    return '관계의 결론을 서두르기보다 연락 빈도와 각자의 경계를 구체적으로 맞추면 편안해져요.';
  }

  String _elementRelationLabel(_ElementRelation relation) => switch (relation) {
    _ElementRelation.same => '비화',
    _ElementRelation.ownerGeneratesMember ||
    _ElementRelation.memberGeneratesOwner => '상생',
    _ElementRelation.ownerControlsMember ||
    _ElementRelation.memberControlsOwner => '상극',
  };

  String _elementStrength(saju.Element element) => switch (element) {
    saju.Element.wood => '새 계획을 시작하고 서로의 성장을 밀어주는',
    saju.Element.fire => '표현하고 분위기를 끌어올리는',
    saju.Element.earth => '약속을 지키고 일상을 안정시키는',
    saju.Element.metal => '기준을 세우고 결정을 내리는',
    saju.Element.water => '대화하고 새로운 관점을 나누는',
  };

  String _elementAdvice(saju.Element element) => switch (element) {
    saju.Element.wood => '산책이나 새로운 배움처럼 성장의 리듬을 만드는',
    saju.Element.fire => '감정과 고마움을 말로 표현하는',
    saju.Element.earth => '정기적인 약속과 생활 루틴을 만드는',
    saju.Element.metal => '서로의 기준과 경계를 분명히 정하는',
    saju.Element.water => '결론 없이도 충분히 대화하고 쉬어가는',
  };

  _ElementRelation _elementRelation(saju.Element owner, saju.Element member) {
    if (owner == member) return _ElementRelation.same;
    if (owner.generates == member) return _ElementRelation.ownerGeneratesMember;
    if (member.generates == owner) return _ElementRelation.memberGeneratesOwner;
    if (owner.controls == member) return _ElementRelation.ownerControlsMember;
    return _ElementRelation.memberControlsOwner;
  }

  saju.Stem _stemOf(SajuPillarValue pillar) {
    return saju.Stem.fromHanja(pillar.hanja.substring(0, 1));
  }

  saju.Branch _branchOf(SajuPillarValue pillar) {
    return saju.Branch.fromHanja(pillar.hanja.substring(1, 2));
  }

  bool _isStemCombination(saju.Stem first, saju.Stem second) {
    return saju.stemCombinations.any(
      (item) =>
          (item.stem1 == first && item.stem2 == second) ||
          (item.stem1 == second && item.stem2 == first),
    );
  }

  bool _isSixCombination(saju.Branch first, saju.Branch second) {
    return saju.branchSixCombinations.any(
      (item) =>
          (item.branch1 == first && item.branch2 == second) ||
          (item.branch1 == second && item.branch2 == first),
    );
  }

  bool _isPairIn(
    saju.Branch first,
    saju.Branch second,
    List<List<saju.Branch>> pairs,
  ) {
    return pairs.any(
      (pair) =>
          (pair[0] == first && pair[1] == second) ||
          (pair[0] == second && pair[1] == first),
    );
  }

  bool _isPunishment(saju.Branch first, saju.Branch second) {
    return saju.branchPunishments.any((item) {
      if (item.branches.length == 2) {
        return item.branches.contains(first) && item.branches.contains(second);
      }
      return first == second &&
          item.branches.every((branch) => branch == first);
    });
  }
}

enum _ElementRelation {
  same,
  ownerGeneratesMember,
  memberGeneratesOwner,
  ownerControlsMember,
  memberControlsOwner,
}
