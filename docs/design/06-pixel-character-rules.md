# 06. 도트 캐릭터 생성 규칙

## 캐릭터 목표

- 3x3 교실의 작은 책상에서도 사람마다 구분된다.
- 성별을 추측하거나 강하게 구분하는 파츠를 사용하지 않는다.
- 같은 정규화 이름과 생년월일은 언제나 같은 모습이다.
- 따뜻한 학교 세계관과 어울리되 지나치게 유아적이지 않다.
- 에셋 수와 초기 다운로드 크기를 작게 유지한다.

## 기본 캔버스

```text
logical sprite: 24 x 32 px
render scale: 2x 또는 3x 정수 배율
pixel filtering: nearest neighbor
```

논리 픽셀을 정수 배율로 확대해 경계가 흐려지지 않게 한다. 좌석 카드 안에서는 캐릭터 렌더 영역의 aspect ratio를 고정해 이름 길이나 강조 상태가 레이아웃을 밀지 않게 한다.

## 레이어 순서

```text
1. 뒤쪽 헤어/모자
2. 목과 귀
3. 얼굴
4. 앞쪽 헤어
5. 상의와 팔
6. 표정
7. 액세서리
8. 책상에 가려지는 마스크
9. 관계 아이콘과 선택 강조
```

캐릭터 자체와 책상 마스크를 분리하면 걷기 상태와 앉은 상태에 같은 파츠를 재사용할 수 있다.

## 파츠 카탈로그

### 헤어 8종

| id | 이름 | 실루엣 |
| --- | --- | --- |
| 0 | 짧은 단정 | 둥근 짧은 앞머리 |
| 1 | 가르마 | 비대칭 앞머리 |
| 2 | 중간 웨이브 | 귀 아래 작은 굴곡 |
| 3 | 긴 생머리 | 어깨까지 곧은 실루엣 |
| 4 | 몽글 곱슬 | 둥근 픽셀 덩어리 |
| 5 | 짧은 곱슬 | 위쪽 볼륨 강조 |
| 6 | 반묶음 | 뒤쪽 작은 묶음 |
| 7 | 비니 | 머리 형태를 감싼 모자 |

긴 머리, 짧은 머리, 모자는 성별과 연결하지 않고 모든 상의 및 표정과 조합한다.

### 헤어 색 6종

```text
ink brown      #3A302B
soft black     #252729
chestnut       #68473A
warm brown     #8A624B
ash brown      #706761
deep navy      #303846
```

### 상의 8종

형태는 기본 교복풍 셔츠, 카디건, 후드, 맨투맨 네 가지이며 색과 조합한다. 실제 학교 교복이나 특정 학교를 연상시키는 문장/마크는 넣지 않는다.

```text
chalk white    #F4F0E5
sky blue       #93BAD0
leaf green     #91B39A
soft yellow    #E7C875
coral          #D98372
rose pink      #D79AA3
charcoal       #4A5052
lavender gray  #AAA4B8
```

### 표정 5종

| id | 이름 | 특징 |
| --- | --- | --- |
| 0 | 기본 | 점 눈, 짧은 입 |
| 1 | 웃음 | 굽은 눈, 미소 |
| 2 | 무표정 | 점 눈, 수평 입 |
| 3 | 장난 | 한쪽 눈, 작은 웃음 |
| 4 | 졸림 | 반쯤 감긴 눈 |

### 액세서리 6종

```text
0 없음
1 둥근 안경
2 네모 안경
3 작은 머리핀
4 헤드폰
5 볼펜 꽂이
```

액세서리는 얼굴을 가리거나 실루엣을 과도하게 키우지 않는다. 모자 헤어와 머리핀처럼 겹치는 조합은 호환성 표로 제외한다.

### 포즈 4종

```text
0 앉아서 정면 보기
1 책 펼쳐 보기
2 작은 손 인사
3 옆 친구 쪽 보기
```

교실 기본 상태에서는 포즈 0~2를 사용한다. 포즈 3은 생성자와의 상대 방향에 맞춰 좌우 반전한다.

## Stable hash 매핑

입력:

```text
normalizedName
birthDate
algorithmVersion
```

`character` purpose의 SHA-256 digest를 사용한다.

```text
hairStyle    = digest[0] * hairStyleCount ~/ 256
hairColor    = digest[1] * hairColorCount ~/ 256
topShape     = digest[2] * topShapeCount ~/ 256
topColor     = digest[3] * topColorCount ~/ 256
face         = digest[4] * faceCount ~/ 256
accessory    = digest[5] * accessoryCount ~/ 256
pose         = digest[6] * poseCount ~/ 256
skinPalette  = digest[7] * skinPaletteCount ~/ 256
```

`byte * count ~/ 256` 매핑으로 단순 modulo보다 고르게 분배한다.

## 호환성 보정

보정은 결과를 다시 random하게 뽑지 않고 고정 규칙으로 다음 호환 항목으로 이동한다.

```text
비니 + 머리핀 -> 액세서리 목록에서 다음 호환 항목
긴 뒤쪽 헤어 + 헤드폰 충돌 -> 헤드폰 전용 앞 레이어 사용
상의와 헤어가 매우 유사한 색 -> 상의 색 index를 +1 순환
얼굴 대비가 기준 미달 -> 얼굴 outline 팔레트를 어두운 값으로 고정
```

## 피부 팔레트

다양한 피부 톤 6종을 밝기 순서가 아니라 고정 id로 제공한다. 모든 톤은 얼굴 특징과 outline이 WCAG 비텍스트 대비에 가깝게 구분되도록 직접 검수한다. 피부 톤은 이름이나 생일 의미를 해석한 결과가 아니라 hash 조합일 뿐이다.

## 상태별 렌더링

### 빈 좌석

캐릭터 없이 책상, 의자, 작은 빈 이름표만 표시한다. 참여 가능한 자리임을 점선이나 큰 `+` 버튼으로 과도하게 강조하지 않는다.

### 착석

상체와 얼굴은 책상 위에 보이고 하체는 책상 마스크 아래로 가린다. 이름표와 관계 아이콘은 sprite 바깥 Flutter UI로 렌더링해 가독성과 접근성을 확보한다.

### 입장 애니메이션

걷기용 2프레임 몸통을 재사용한다.

```text
0~200ms   문 열림
200~900ms 문에서 목표 책상까지 이동
900~1200ms 의자 쪽으로 정렬
1200~1500ms 앉은 sprite로 전환
1500~1800ms 이름표와 관계 아이콘 등장
```

`prefers-reduced-motion`에 해당하면 이동 경로를 생략하고 150ms fade로 착석 상태를 표시한다.

## 구현 방식

MVP 권장 방식은 투명 PNG sprite atlas 한 장과 JSON/Dart 상수 메타데이터다.

- 파츠별 작은 파일 다수를 네트워크에서 요청하지 않는다.
- atlas는 lossless 압축하고 1x 논리 해상도를 기준으로 만든다.
- Flutter의 `Image` 또는 `CustomPainter`에서 source rect를 잘라 합성한다.
- atlas 전체 크기는 초기 목표 200KB 이하로 둔다.
- 웹 렌더러에서 nearest-neighbor 결과를 실제 Chrome과 Safari로 확인한다.

파츠 제작 전에는 코드로 만든 임시 pixel shape를 사용하되 최종 출시 에셋은 동일한 24x32 grid와 제한 팔레트로 통일한다.

## 접근성과 식별

- 색상만으로 사용자를 구분하지 않고 이름표를 항상 표시한다.
- 캐릭터 tap target은 책상 전체를 포함해 최소 44x44 CSS px를 확보한다.
- semantics label은 `민수, 재홍님의 뒷자리, 공동피고인`처럼 제공한다.
- 긴 이름은 한 줄 말줄임하되 BottomSheet에서는 전체 이름을 표시한다.
- 선택과 신규 참여 강조는 outline과 짧은 움직임을 함께 사용한다.

## 테스트

- 동일 seed가 모든 파츠에서 동일한 결과를 만드는지 확인
- 모든 byte 값 0~255가 유효한 index를 만드는지 확인
- 금지된 파츠 조합이 보정되는지 확인
- 360px 교실에서 9명 이름과 캐릭터가 겹치지 않는지 golden test
- CanvasKit과 HTML 렌더링 환경에서 pixel edge를 비교
- reduced motion에서 걷기 애니메이션이 제거되는지 widget test
