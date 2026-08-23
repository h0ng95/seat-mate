enum RelationshipType {
  buddy,
  chatter,
  leader,
  rival,
  emergency,
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
    RelationshipType.emergency => 'emergency',
    RelationshipType.accomplice => 'accomplice',
    RelationshipType.quietBestie => 'quiet_bestie',
    RelationshipType.moodMaker => 'mood_maker',
    RelationshipType.caretaker => 'caretaker',
    RelationshipType.transfer => 'transfer',
  };

  String get title => switch (this) {
    RelationshipType.buddy => '찰떡 짝꿍',
    RelationshipType.chatter => '수업 방해 공범',
    RelationshipType.leader => '정신적 반장',
    RelationshipType.rival => '은근한 라이벌',
    RelationshipType.emergency => '비상연락망 1순위',
    RelationshipType.accomplice => '공동피고인',
    RelationshipType.quietBestie => '조용한 찐친',
    RelationshipType.moodMaker => '분위기 메이커',
    RelationshipType.caretaker => '챙김 담당',
    RelationshipType.transfer => '예측불가 전학생',
  };

  String get description => switch (this) {
    RelationshipType.buddy => '말 안 해도 편하고, 붙어 있으면 하루가 금방 지나가는 관계.',
    RelationshipType.chatter => '둘이 붙어 있으면 집중력은 내려가고 재미는 올라가요.',
    RelationshipType.leader => '흔들릴 때 은근히 정신 차리게 만들어주는 사람.',
    RelationshipType.rival => '평소에는 티가 안 나도 묘하게 의식하게 되는 관계.',
    RelationshipType.emergency => '자주 연락하지 않아도 필요할 때 가장 먼저 생각나는 사람.',
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
    RelationshipType.emergency => (min: 10, max: 45),
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
    RelationshipType.emergency => (min: 35, max: 75),
    RelationshipType.accomplice => (min: 80, max: 99),
    RelationshipType.quietBestie => (min: 45, max: 75),
    RelationshipType.moodMaker => (min: 75, max: 99),
    RelationshipType.caretaker => (min: 35, max: 70),
    RelationshipType.transfer => (min: 40, max: 95),
  };
}
