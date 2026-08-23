# 05. 생년월일 기반 Deterministic 알고리즘

## 목적

같은 교실에서 동일한 생성자와 동일한 참여자 입력은 앱을 다시 열거나 다른 기기에서 실행해도 같은 관계, 캐릭터, 좌석 후보, 재미용 수치를 만들어야 한다.

완전 무작위 값, 현재 시간, 플랫폼 의존 hash는 결과 계산에 사용하지 않는다.

## 알고리즘 버전

```text
algorithmVersion = 1
```

버전은 교실과 구성원 레코드에 저장한다. 규칙이 바뀌어도 기존 교실은 저장된 버전의 계산기를 사용한다.

```dart
abstract interface class SeatMateAlgorithm {
  int get version;
  OwnerResult deriveOwner(OwnerInput input);
  MemberResult deriveMember(MemberInput input);
}
```

## 입력 정규화

### 이름

표시 이름과 비교 이름을 분리한다.

```text
displayName
  = 앞뒤 공백 제거
  = 연속 공백을 하나로 축소
  = 원래 대소문자와 한글 보존

normalizedName
  = displayName
  = Unicode NFKC 정규화
  = locale 비의존 lowercase
```

MVP 이름 길이는 사용자에게 보이는 grapheme 기준 1~12자로 제한한다. DB에서도 문자 길이와 빈 문자열을 재검증한다.

### 생년월일

시간대가 없는 ISO 날짜로 고정한다.

```text
YYYY-MM-DD
```

`DateTime.toUtc()` 변환으로 날짜를 만들지 않는다. `LocalDate(year, month, day)` 형태의 값 객체가 유효한 달력 날짜를 검증하고 직접 문자열로 직렬화한다.

## Canonical seed 포맷

각 필드는 길이 prefix를 붙여 구분자 충돌을 막는다.

```text
v1|purpose=<length>:<value>|field=<length>:<value>...
```

예시:

```text
v1|purpose=12:relationship|class=10:8fj2kd9abc|ownerBirth=10:1995-06-12|memberName=6:민수|memberBirth=10:1996-03-17
```

실제 구현은 UTF-8 byte 길이를 사용하며 필드 순서를 고정한다.

## Hash 함수

```text
digest = SHA-256(UTF-8(canonicalSeed))
```

- Dart의 `String.hashCode`는 사용하지 않는다.
- `Random`, `DateTime.now`, UUID 생성값을 계산 중간에 섞지 않는다.
- SHA-256 결과 32 bytes를 unsigned byte로 읽는다.
- 여러 결과가 필요하면 purpose를 분리해 상관관계를 줄인다.

```text
owner-profile
owner-seat
relationship
seat-order
character
fun-metrics
```

## 생성자 계산

### 자리 성향

입력:

```text
ownerBirthDate
algorithmVersion
```

```text
bucket = firstUint32(hash("owner-profile", ownerBirthDate)) mod 4

0 -> window: 창가 감성러
1 -> center: 은근한 핵심 인물
2 -> back: 자유로운 영혼
3 -> front: 알게 모르게 모범생
```

### 생성자 좌석

성향별 후보를 먼저 정하고 별도 hash로 후보 순서를 회전한다.

| 성향 | 후보 순서 |
| --- | --- |
| window | `[3, 0, 6, 4]` |
| center | `[4, 1, 7, 3, 5]` |
| back | `[7, 6, 8, 4]` |
| front | `[1, 0, 2, 4]` |

MVP에서는 생성자 한 명만 있으므로 첫 번째 seed 선택을 그대로 확정한다. 모서리 좌석이 선택돼도 관계 후보 계산은 교실 경계를 반영한다.

## 참여자 관계 계산

입력:

```text
classroomShareCode
ownerBirthDate
normalizedMemberName
memberBirthDate
algorithmVersion
```

```text
digest = SHA-256(seed("relationship", inputs))
relationshipBucket = uint16(digest[0..1]) mod 100
relationshipType = relationshipDistribution[relationshipBucket]
```

생성자 이름은 관계 계산에 넣지 않는다. 표시 이름을 변경하더라도 기존 관계를 깨지 않기 위함이다. 참여자 이름은 동일 생일을 가진 두 친구에게 서로 다른 결과를 줄 수 있도록 포함한다.

## 선호 좌석 순서

1. 관계 타입의 점수 함수로 생성자 좌석을 제외한 8개 좌석에 점수를 준다.
2. 높은 점수를 먼저 정렬한다.
3. 동점 좌석마다 독립 tie-break hash를 계산한다.

```text
tieBreak(seatIndex)
  = firstUint32(
      SHA-256(seed("seat-order", relationshipInputs, seatIndex))
    )
```

4. 점수 내림차순, tie-break 오름차순, seat index 오름차순으로 정렬한다.
5. 이미 사용 중인 좌석을 제거하고 첫 번째를 선택한다.

마지막 seat index 비교는 hash 충돌이 발생해도 모든 플랫폼에서 정렬 순서를 같게 만드는 최종 기준이다.

## 공통 fallback

관계별 높은 점수 후보가 모두 사용 중이어도 전체 8개 좌석은 이미 seed 기반으로 정렬돼 있다. 따라서 별도의 random fallback이 필요하지 않다. 빈 좌석이 하나라도 있으면 정렬된 목록의 첫 빈 좌석을 선택한다.

DB RPC는 같은 선호 목록을 받고 교실 행을 잠근 뒤 실제 빈 좌석을 확정한다.

## 캐릭터 계산

캐릭터 seed는 교실과 무관하게 사용자를 기준으로 한다.

```text
characterSeed = SHA-256(
  seed("character", normalizedName, birthDate, algorithmVersion)
)
```

같은 별명과 생일은 다른 교실에서도 같은 캐릭터가 나온다. 구체적인 byte-to-part 매핑은 캐릭터 설계 문서에서 고정한다.

## 재미용 수치

관계 계산과 별도 purpose를 사용한다.

```text
metricDigest = SHA-256(seed("fun-metrics", relationshipInputs))

focus = mapByteToRange(metricDigest[0], relationship.focusRange)
joy = mapByteToRange(metricDigest[1], relationship.joyRange)
```

범위 매핑:

```text
min + floor(byte * (max - min + 1) / 256)
```

최댓값을 포함하면서 modulo 편향을 피한다.

## 중복 판정

같은 교실에서 아래 두 값이 모두 같으면 중복이다.

```text
normalizedName
birthDate
```

클라이언트는 빠르게 알려주고, DB unique 제약과 RPC가 최종적으로 막는다. 중복 응답에는 기존 member id와 seat index를 반환해 해당 책상으로 포커스를 이동한다.

## 결정론의 범위

- 관계 타입: 항상 동일
- 캐릭터 파츠: 항상 동일
- 전체 선호 좌석 순서: 항상 동일
- 실제 좌석: 참여 시점에 이미 찬 좌석에 따라 달라질 수 있음
- 동일한 교실 구성과 참여 순서: 항상 동일한 실제 좌석

사용자에게는 결과가 무작위로 다시 뽑히지 않는다는 의미만 전달하고 내부 hash 규칙은 UI에 노출하지 않는다.

## 테스트 벡터

구현 시 아래 입력의 digest와 결과를 golden fixture로 한 번 확정한다.

```text
version: 1
classroom: 8fj2kd9abc
ownerBirth: 1995-06-12
memberName: 민수
memberBirth: 1996-03-17
```

필수 테스트:

- 같은 입력을 100회 계산해 동일한 결과인지 확인
- 웹과 Dart VM에서 fixture 결과가 같은지 확인
- 한 필드가 달라질 때 canonical seed가 달라지는지 확인
- 사용 좌석 집합 순서가 달라도 같은 빈 좌석을 선택하는지 확인
- 시간대가 달라도 생년월일 seed가 달라지지 않는지 확인
- 알고리즘 v1 fixture가 향후 코드 변경 후에도 유지되는지 확인
