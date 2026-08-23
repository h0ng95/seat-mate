enum RelationshipType {
  buddy,
  chatter,
  leader,
  rival,
  accomplice,
  quietBestie,
  moodMaker,
  caretaker,
  transfer,
}

extension RelationshipTypeDefinition on RelationshipType {
  String get code => switch (this) {
    RelationshipType.buddy => 'buddy',
    RelationshipType.chatter => 'chatter',
    RelationshipType.leader => 'leader',
    RelationshipType.rival => 'rival',
    RelationshipType.accomplice => 'accomplice',
    RelationshipType.quietBestie => 'quiet_bestie',
    RelationshipType.moodMaker => 'mood_maker',
    RelationshipType.caretaker => 'caretaker',
    RelationshipType.transfer => 'transfer',
  };

  String get title => switch (this) {
    RelationshipType.buddy => '찐 쏘메',
    RelationshipType.chatter => '수다 메이트',
    RelationshipType.leader => '든든한 내 편',
    RelationshipType.rival => '성장 라이벌',
    RelationshipType.accomplice => '텐션 메이트',
    RelationshipType.quietBestie => '잔잔한 찐친',
    RelationshipType.moodMaker => '기분 부스터',
    RelationshipType.caretaker => '케어 메이트',
    RelationshipType.transfer => '반전 케미',
  };

  String get description => switch (this) {
    RelationshipType.buddy => '말 안 해도 편하고, 붙어 있으면 하루가 금방 지나가는 관계.',
    RelationshipType.chatter => '둘이 붙어 있으면 집중력은 내려가고 재미는 올라가요.',
    RelationshipType.leader => '흔들릴 때 은근히 정신 차리게 만들어주는 사람.',
    RelationshipType.rival => '평소에는 티가 안 나도 묘하게 의식하게 되는 관계.',
    RelationshipType.accomplice => '좋은 선택보다 재밌는 선택을 같이 할 가능성이 높은 사람.',
    RelationshipType.quietBestie => '자주 붙어 있지 않아도 어색하지 않은 오래가는 관계.',
    RelationshipType.moodMaker => '갑자기 등장해 평범한 하루를 재미있게 만들어주는 사람.',
    RelationshipType.caretaker => '말은 안 해도 이상하게 이것저것 챙겨주는 사람.',
    RelationshipType.transfer => '가까운 듯 멀고, 멀어진 듯하다가 갑자기 가까워지는 관계.',
  };

  ({int min, int max}) get focusRange => switch (this) {
    RelationshipType.buddy => (min: -10, max: 20),
    RelationshipType.chatter => (min: -55, max: -25),
    RelationshipType.leader => (min: 45, max: 80),
    RelationshipType.rival => (min: 20, max: 65),
    RelationshipType.accomplice => (min: -60, max: -30),
    RelationshipType.quietBestie => (min: 5, max: 35),
    RelationshipType.moodMaker => (min: -20, max: 10),
    RelationshipType.caretaker => (min: 30, max: 70),
    RelationshipType.transfer => (min: -35, max: 35),
  };

  ({int min, int max}) get joyRange => switch (this) {
    RelationshipType.buddy => (min: 70, max: 95),
    RelationshipType.chatter => (min: 75, max: 99),
    RelationshipType.leader => (min: 20, max: 55),
    RelationshipType.rival => (min: 25, max: 70),
    RelationshipType.accomplice => (min: 80, max: 99),
    RelationshipType.quietBestie => (min: 45, max: 75),
    RelationshipType.moodMaker => (min: 75, max: 99),
    RelationshipType.caretaker => (min: 35, max: 70),
    RelationshipType.transfer => (min: 40, max: 95),
  };

  int get heartBase => switch (this) {
    RelationshipType.buddy => 92,
    RelationshipType.chatter => 79,
    RelationshipType.leader => 82,
    RelationshipType.rival => 66,
    RelationshipType.accomplice => 78,
    RelationshipType.quietBestie => 89,
    RelationshipType.moodMaker => 84,
    RelationshipType.caretaker => 87,
    RelationshipType.transfer => 63,
  };

  String get energyReading => switch (this) {
    RelationshipType.buddy => '비슷한 속도로 흐르는 기운이라 긴 설명 없이도 서로의 마음을 금방 알아차려요.',
    RelationshipType.chatter =>
      '서로의 흥을 빠르게 끌어올리는 기운이에요. 함께 있으면 평범한 일도 사건이 됩니다.',
    RelationshipType.leader => '한 사람의 중심을 다른 사람이 단단히 잡아주는 보완형 기운이에요.',
    RelationshipType.rival => '닮은 욕심이 서로를 자극하는 기운이에요. 가까울수록 성장 속도가 빨라집니다.',
    RelationshipType.accomplice => '호기심과 행동력이 한 방향으로 붙어 예상 밖의 추억을 만드는 기운이에요.',
    RelationshipType.quietBestie => '말보다 익숙함이 먼저 쌓이는 기운이라 시간이 지날수록 편안해져요.',
    RelationshipType.moodMaker => '감정의 온도를 빠르게 바꾸는 기운으로, 서로의 하루에 생기를 더해요.',
    RelationshipType.caretaker => '부족한 부분을 자연스럽게 메워주는 돌봄의 기운이 강한 관계예요.',
    RelationshipType.transfer => '서로 다른 결이 계속 새롭게 부딪혀 예측하기 어려운 변화를 만드는 기운이에요.',
  };

  String get strengthReading => switch (this) {
    RelationshipType.buddy => '취향과 리듬이 맞는 일을 함께할 때 편안함과 재미가 동시에 커져요.',
    RelationshipType.chatter => '아이디어를 내거나 분위기를 풀어야 할 때 둘의 합이 특히 좋아요.',
    RelationshipType.leader => '선택이 어려운 순간에 현실적인 기준을 잡고 끝까지 밀어주는 힘이 있어요.',
    RelationshipType.rival => '공부, 운동, 프로젝트처럼 목표가 분명할수록 서로의 잠재력을 끌어냅니다.',
    RelationshipType.accomplice => '새로운 장소와 경험을 함께 시도할 때 최고의 팀이 됩니다.',
    RelationshipType.quietBestie => '오랜만에 만나도 어색하지 않고 각자의 시간을 존중하는 힘이 있어요.',
    RelationshipType.moodMaker => '지친 날 서로의 기분을 환기하고 다시 움직이게 만드는 재주가 있어요.',
    RelationshipType.caretaker => '생활의 작은 빈틈을 잘 발견해 안정감 있는 팀워크를 만들어요.',
    RelationshipType.transfer => '고정관념을 흔들고 서로에게 없던 관점을 선물하는 관계예요.',
  };

  String get cautionReading => switch (this) {
    RelationshipType.buddy => '편하다는 이유로 중요한 속마음을 미루면 작은 오해가 오래 남을 수 있어요.',
    RelationshipType.chatter => '즐거움이 앞서 약속이나 해야 할 일을 함께 놓치지 않도록 주의해요.',
    RelationshipType.leader => '조언이 지시처럼 들리거나 기대는 쪽이 지나치게 의존하지 않도록 균형이 필요해요.',
    RelationshipType.rival => '비교가 응원보다 커지는 순간에는 잠깐 거리를 두고 각자의 목표를 확인해요.',
    RelationshipType.accomplice =>
      '둘 다 브레이크를 잊기 쉬워 중요한 결정에는 한 번 더 현실 점검이 필요해요.',
    RelationshipType.quietBestie =>
      '표현이 적은 둘이라 서운함까지 조용히 묻어두지 않도록 가끔은 말로 확인해요.',
    RelationshipType.moodMaker =>
      '항상 밝아야 한다는 부담을 주지 말고 진지한 감정도 편하게 꺼낼 자리를 남겨요.',
    RelationshipType.caretaker => '주는 사람과 받는 사람이 굳어지지 않도록 역할을 가끔 바꿔보세요.',
    RelationshipType.transfer =>
      '연락과 거리의 변화가 큰 편이라 상대의 침묵을 곧바로 마음의 변화로 단정하지 마세요.',
  };

  String get adviceReading => switch (this) {
    RelationshipType.buddy => '익숙한 일상 사이에 둘만의 작은 새 루틴을 하나 만들면 오래 갑니다.',
    RelationshipType.chatter => '신나게 놀 시간과 집중할 시간을 함께 정하면 장점만 더 선명해져요.',
    RelationshipType.leader => '정답을 주기보다 서로의 선택을 한 번씩 물어봐 주는 관계가 좋아요.',
    RelationshipType.rival => '결과보다 서로의 과정을 칭찬하면 경쟁이 가장 건강한 응원이 됩니다.',
    RelationshipType.accomplice => '큰 모험 하나 뒤에는 차분한 휴식 하나를 함께 약속해 보세요.',
    RelationshipType.quietBestie => '자주 보지 않아도 다음 만남을 구체적으로 정해두면 인연이 단단해져요.',
    RelationshipType.moodMaker => '웃음뿐 아니라 힘든 이야기에도 같은 온도로 귀 기울여 주세요.',
    RelationshipType.caretaker => '고맙다는 표현과 작은 보답이 돌봄을 부담이 아닌 애정으로 남겨줍니다.',
    RelationshipType.transfer => '관계의 속도를 정하려 하지 말고 달라진 점을 재미있게 공유해 보세요.',
  };

  RelationshipFortune fortune({
    required int focusDelta,
    required int joyDelta,
  }) {
    final balance = 100 - (focusDelta.abs() * 0.35).round();
    final score = (heartBase * 0.65 + joyDelta * 0.25 + balance * 0.1)
        .round()
        .clamp(42, 98);
    return RelationshipFortune(
      heartScore: score,
      heartLabel: switch (score) {
        >= 90 => '운명처럼 잘 맞는 사이',
        >= 80 => '마음이 자주 통하는 사이',
        >= 70 => '서로를 살리는 사이',
        >= 60 => '알수록 깊어지는 사이',
        _ => '다름이 매력인 사이',
      },
      energy: energyReading,
      strength: strengthReading,
      caution: cautionReading,
      advice: adviceReading,
    );
  }
}

class RelationshipFortune {
  const RelationshipFortune({
    required this.heartScore,
    required this.heartLabel,
    required this.energy,
    required this.strength,
    required this.caution,
    required this.advice,
  });

  final int heartScore;
  final String heartLabel;
  final String energy;
  final String strength;
  final String caution;
  final String advice;
}
