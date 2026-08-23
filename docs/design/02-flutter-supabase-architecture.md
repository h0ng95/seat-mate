# 02. Flutter Web + Supabase 아키텍처

## 구성 개요

```text
Browser
  -> GoRouter
  -> Flutter Presentation
  -> Riverpod Application Controllers
  -> Domain Use Cases / Pure Rules
  -> Repository Interfaces
  -> Supabase Repository
  -> Supabase Postgres + RPC
```

의존성은 바깥 계층에서 안쪽 계층으로만 향한다. Domain은 Flutter, Riverpod, Supabase 패키지를 import하지 않는다.

## Flutter Web

Flutter Web은 다음 책임을 맡는다.

- 모바일 우선 UI와 교실 장면 렌더링
- 사용자 입력 검증의 빠른 피드백
- 결정론적 결과의 로컬 미리보기
- Web Share API 또는 클립보드 대체 처리
- 교실 캡처 이미지 생성

첫 화면 번들 부담을 줄이기 위해 캡처 및 공유 관련 구현은 실제 사용 시점까지 초기화하지 않는다. 교실 장면은 작은 에셋 여러 개보다 재사용 가능한 sprite 또는 CustomPainter 중심으로 구성한다.

## GoRouter

라우트 정의는 UI 파일과 분리한다.

```text
/
/create
/class/:shareCode
```

- 잘못된 `shareCode`는 앱 전용 not-found 화면으로 연결한다.
- 브라우저 새로고침과 직접 URL 진입을 지원한다.
- `/class/:shareCode`는 인증 redirect 없이 바로 조회한다.
- 향후 결과 전용 라우트는 중첩하지 않고 독립 경로로 추가한다.

## Riverpod

상태는 기능 단위로 나눈다.

| Provider | 역할 |
| --- | --- |
| `supabaseClientProvider` | 초기화된 클라이언트 제공 |
| `classroomRepositoryProvider` | 저장소 구현 주입 |
| `classroomProvider(shareCode)` | 교실과 구성원 조회 |
| `createClassroomControllerProvider` | 생성 입력, 계산, 저장 상태 관리 |
| `joinClassroomControllerProvider` | 참여 입력, 배치, 저장 상태 관리 |
| `selectedMemberProvider` | BottomSheet 대상 관리 |
| `shareServiceProvider` | 링크/이미지 공유 기능 제공 |

서버 상태는 `AsyncValue`로 표현하고 입력 폼의 일시적 값은 로컬 `Form` 상태로 둔다. 같은 값을 Riverpod과 위젯 양쪽에 중복 저장하지 않는다.

## Domain 경계

다음 로직은 pure function 또는 불변 객체로 구현한다.

- `normalizeNickname`
- `buildStableSeed`
- `deriveOwnerProfile`
- `deriveRelationship`
- `rankPreferredSeats`
- `assignFirstAvailableSeat`
- `deriveCharacterParts`
- `deriveFunMetrics`

날짜는 `DateTime` 대신 날짜 전용 값 객체를 사용해 시간대에 따른 하루 밀림을 방지한다.

## Repository 경계

Application 계층은 아래 인터페이스만 사용한다.

```dart
abstract interface class ClassroomRepository {
  Future<Classroom> createClassroom(CreateClassroomCommand command);
  Future<Classroom> getClassroom(String shareCode);
  Future<JoinClassroomResult> joinClassroom(JoinClassroomCommand command);
}
```

Supabase DTO, `PostgrestException`, JSON 키 이름은 Data 계층 밖으로 노출하지 않는다.

## Supabase 읽기

교실 조회는 공개 링크의 `share_code`를 기준으로 한다.

1. `classrooms` 한 건을 조회한다.
2. 연결된 `classroom_members`를 좌석 순서로 조회한다.
3. Repository에서 Domain `Classroom`으로 조립한다.

초기 MVP는 단순 조회 후 새로고침으로 갱신한다. 실시간 반영이 제품 지표에 중요해지면 해당 교실의 구성원 insert만 Realtime 구독한다.

## Supabase 쓰기

클라이언트에서 여러 insert를 순차 실행하지 않는다. 다음 RPC로 원자성을 확보한다.

- `create_classroom`: 공유 코드 생성, 생성자 좌석 확정, 교실과 생성자 구성원 저장
- `join_classroom`: 행 잠금, 중복/정원 검사, 사용 좌석 조회, 빈 좌석 확정, 구성원 저장

관계와 캐릭터 알고리즘은 앱과 DB 함수가 동일한 `algorithm_version`을 사용한다. 초기에는 클라이언트가 계산한 후보를 RPC에 전달하되, DB가 제약과 빈 좌석을 최종 검증한다.

## 보안과 접근

- 브라우저에는 Supabase anon key만 노출한다.
- service role key는 Flutter assets나 빌드 변수에 포함하지 않는다.
- 테이블 직접 insert/update/delete는 차단하고 쓰기는 제한된 RPC로만 허용한다.
- 공개 읽기에는 추측하기 어려운 share code가 필요하다.
- 요청당 이름 길이, 날짜 범위, 입력 형식을 DB에서도 검증한다.
- 생년월일은 제품 목적에 필요하지만 공개 응답에는 반환하지 않는다.

## 오류 모델

Data 오류를 다음 앱 오류로 변환한다.

| 오류 | 사용자 처리 |
| --- | --- |
| `ClassroomNotFound` | 링크 오류 화면과 반 만들기 CTA |
| `ClassroomFull` | 교실 유지, 참여 폼 대신 반 만들기 CTA |
| `DuplicateMember` | 기존 좌석 포커스 및 안내 |
| `InvalidInput` | 해당 입력 필드 오류 표시 |
| `NetworkUnavailable` | 현재 화면 유지, 재시도 제공 |
| `UnexpectedFailure` | 짧은 안내와 다시 시도 제공 |

## 환경 설정

Supabase URL과 anon key는 `--dart-define`으로 주입한다.

```text
SUPABASE_URL
SUPABASE_ANON_KEY
APP_BASE_URL
```

로컬, preview, production 값을 분리하고 비밀 키를 저장소에 커밋하지 않는다. 값이 없을 때는 앱 시작 단계에서 진단 가능한 설정 오류를 표시한다.

## 테스트 전략

- Domain: hash, 관계, 캐릭터, 좌석 충돌 단위 테스트
- Application: fake repository로 생성/참여 상태 전이 테스트
- Data: 로컬 Supabase에 RPC 정원/중복/동시성 통합 테스트
- Presentation: 360px, 390px, 430px golden 및 widget test
- Web: 공유 API 지원/미지원 브라우저 대체 동작 테스트
