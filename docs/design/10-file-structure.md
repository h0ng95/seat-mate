# 10. 구현 파일 목록과 폴더 구조

## 구조 원칙

- 화면 기능은 `features` 아래에 모으고 공용 코드만 `core`와 `shared`로 올린다.
- Domain은 Flutter와 Supabase를 import하지 않는다.
- Repository interface는 Domain/Application 쪽에, 구현은 Data 쪽에 둔다.
- 한 기능의 화면, controller, repository 구현을 찾기 위해 저장소 전체를 돌아다니지 않게 한다.
- 파일이 하나뿐인 계층을 위한 빈 추상화는 만들지 않는다.

## 저장소 구조

```text
seat-mate/
├─ README.md
├─ pubspec.yaml
├─ analysis_options.yaml
├─ web/
│  ├─ index.html
│  ├─ manifest.json
│  ├─ favicon.png
│  └─ icons/
├─ assets/
│  ├─ fonts/
│  │  └─ pretendard-subset.woff2
│  ├─ images/
│  │  ├─ og-classroom.png
│  │  └─ empty-classroom.png
│  └─ sprites/
│     ├─ characters.png
│     └─ classroom.png
├─ lib/
│  ├─ main.dart
│  ├─ bootstrap.dart
│  ├─ app/
│  │  ├─ seat_mate_app.dart
│  │  ├─ app_config.dart
│  │  ├─ app_constants.dart
│  │  ├─ app_router.dart
│  │  └─ app_theme.dart
│  ├─ core/
│  │  ├─ errors/
│  │  │  ├─ app_exception.dart
│  │  │  └─ error_mapper.dart
│  │  ├─ hashing/
│  │  │  ├─ canonical_seed.dart
│  │  │  └─ stable_hash.dart
│  │  └─ values/
│  │     ├─ local_date.dart
│  │     └─ nickname.dart
│  ├─ features/
│  │  ├─ landing/
│  │  │  └─ presentation/
│  │  │     └─ landing_page.dart
│  │  ├─ classroom/
│  │  │  ├─ domain/
│  │  │  │  ├─ classroom.dart
│  │  │  │  ├─ classroom_member.dart
│  │  │  │  ├─ classroom_repository.dart
│  │  │  │  ├─ owner_profile.dart
│  │  │  │  ├─ relationship.dart
│  │  │  │  ├─ seat.dart
│  │  │  │  └─ seat_mate_algorithm.dart
│  │  │  ├─ application/
│  │  │  │  ├─ create_classroom_controller.dart
│  │  │  │  ├─ join_classroom_controller.dart
│  │  │  │  ├─ classroom_provider.dart
│  │  │  │  └─ selected_member_provider.dart
│  │  │  ├─ data/
│  │  │  │  ├─ classroom_dto.dart
│  │  │  │  ├─ classroom_member_dto.dart
│  │  │  │  └─ supabase_classroom_repository.dart
│  │  │  └─ presentation/
│  │  │     ├─ create_classroom_page.dart
│  │  │     ├─ classroom_page.dart
│  │  │     └─ widgets/
│  │  │        ├─ classroom_scene.dart
│  │  │        ├─ classroom_seat.dart
│  │  │        ├─ join_classroom_form.dart
│  │  │        ├─ member_result_sheet.dart
│  │  │        ├─ owner_result_panel.dart
│  │  │        └─ seat_assignment_animation.dart
│  │  ├─ character/
│  │  │  ├─ domain/
│  │  │  │  ├─ character_parts.dart
│  │  │  │  └─ character_generator.dart
│  │  │  └─ presentation/
│  │  │     ├─ character_sprite.dart
│  │  │     └─ sprite_atlas.dart
│  │  └─ sharing/
│  │     ├─ application/
│  │     │  ├─ share_service.dart
│  │     │  └─ share_service_provider.dart
│  │     └─ presentation/
│  │        ├─ classroom_capture.dart
│  │        └─ capture_layout.dart
│  └─ shared/
│     └─ presentation/
│        ├─ app_scaffold.dart
│        ├─ chalk_loading.dart
│        ├─ empty_state.dart
│        ├─ error_state.dart
│        └─ primary_button.dart
├─ test/
│  ├─ core/
│  │  ├─ canonical_seed_test.dart
│  │  └─ local_date_test.dart
│  ├─ features/
│  │  ├─ classroom/
│  │  │  ├─ deterministic_algorithm_test.dart
│  │  │  ├─ seat_assignment_test.dart
│  │  │  ├─ classroom_capacity_test.dart
│  │  │  ├─ duplicate_member_test.dart
│  │  │  └─ classroom_page_test.dart
│  │  ├─ character/
│  │  │  └─ character_generator_test.dart
│  │  └─ sharing/
│  │     └─ share_service_test.dart
│  ├─ golden/
│  │  ├─ classroom_360_test.dart
│  │  ├─ classroom_390_test.dart
│  │  └─ classroom_430_test.dart
│  └─ fixtures/
│     ├─ classrooms.dart
│     └─ algorithm_v1.json
├─ integration_test/
│  ├─ create_and_share_flow_test.dart
│  └─ join_classroom_flow_test.dart
├─ supabase/
│  ├─ config.toml
│  ├─ migrations/
│  │  ├─ 0001_create_schema.sql
│  │  ├─ 0002_create_public_views.sql
│  │  ├─ 0003_create_classroom_rpc.sql
│  │  ├─ 0004_join_classroom_rpc.sql
│  │  └─ 0005_enable_rls.sql
│  ├─ seed.sql
│  └─ tests/
│     ├─ create_classroom_test.sql
│     ├─ join_classroom_test.sql
│     └─ concurrent_last_seat_test.sql
├─ docs/
│  └─ design/
└─ .github/
   └─ workflows/
      └─ ci.yml
```

## 앱 진입 파일

### `lib/main.dart`

- `WidgetsFlutterBinding.ensureInitialized()` 호출
- `bootstrap()` 실행
- 다른 비즈니스 로직을 포함하지 않음

### `lib/bootstrap.dart`

- `--dart-define` 환경값 검증
- Supabase 초기화
- 최상위 `ProviderScope` 구성
- 초기화 실패 시 진단 가능한 앱 오류 화면 실행

### `lib/app/seat_mate_app.dart`

- `MaterialApp.router` 구성
- theme, router, locale 적용
- 앱 title과 service name은 상수에서 읽음

### `lib/app/app_constants.dart`

```text
serviceName
serviceTagline
defaultShareText
classroomCapacity
algorithmVersion
```

서비스명을 화면별로 하드코딩하지 않는다.

## Core 파일 책임

### `canonical_seed.dart`

길이 prefix가 있는 seed 문자열을 한 방식으로 생성한다. 관계와 캐릭터 코드가 각자 문자열을 이어 붙이지 않게 한다.

### `stable_hash.dart`

SHA-256 digest와 byte-to-range helper만 제공한다. 관계 의미나 좌석 규칙은 포함하지 않는다.

### `local_date.dart`

연/월/일 검증, ISO 직렬화, 표시 변환을 담당한다. 시간대가 있는 시각 연산은 제공하지 않는다.

### `nickname.dart`

표시 이름과 normalized 이름을 함께 보관하고 grapheme 길이를 검증한다.

## Classroom Domain 파일 책임

### `seat_mate_algorithm.dart`

알고리즘 interface와 v1 구현을 둔다. 커지면 아래로 분리한다.

```text
owner_profile_calculator.dart
relationship_calculator.dart
seat_ranker.dart
fun_metrics_calculator.dart
```

처음부터 작은 파일로 과도하게 분리하지 않고 v1 구현이 읽기 어려워지는 시점에 나눈다.

### `relationship.dart`

10개 enum, 표시 제목, 설명, 아이콘 key, metric range를 정의한다. UI가 enum switch를 여러 곳에서 반복하지 않게 한다.

### `classroom_repository.dart`

UI와 Supabase 사이의 interface다. 생성, 조회, 참여 메서드와 명시적 command/result 타입을 둔다.

## Application 파일 책임

Controller는 다음만 수행한다.

- command 생성과 use case 호출
- 중복 submit 방지
- Async 상태 전환
- 성공 후 provider invalidation
- 앱 오류를 presentation이 처리할 형태로 전달

Widget, BuildContext, toast 호출은 controller에 넣지 않는다.

## Data 파일 책임

- JSON key와 nullable 처리
- RPC payload 구성
- 공개 view 응답을 Domain 모델로 변환
- `PostgrestException` code를 `AppException`으로 변환

Domain 객체를 `toJson()`으로 Supabase에 직접 보내지 않는다. DB 계약은 DTO가 소유한다.

## Presentation 파일 책임

- page는 레이아웃과 상태 분기를 조합한다.
- 작은 widget은 한 화면에서 두 번 이상 쓰이거나 독립 테스트 가치가 있을 때 분리한다.
- 모든 좌석은 동일한 `ClassroomSeat`을 사용한다.
- 결과 sheet와 캡처 layout은 시각 언어를 공유하되 캡처 전용 고정 비율을 유지한다.

## 테스트 배치

소스 경로와 유사한 구조를 사용해 대상 파일을 빠르게 찾는다.

```text
lib/features/classroom/domain/seat_mate_algorithm.dart
test/features/classroom/deterministic_algorithm_test.dart
```

Supabase SQL은 Flutter 단위 테스트로 흉내 내지 않고 `supabase/tests`에서 실제 constraint와 transaction을 검증한다.

## 파일 생성 순서

1. Flutter scaffold 및 app 진입
2. app config, theme, router
3. core value/hash
4. classroom domain과 테스트
5. character domain과 테스트
6. classroom presentation mock data 버전
7. Supabase migration/RPC
8. data repository와 controller
9. 실제 create/join 연결
10. sharing/capture
11. integration/golden/CI

## 구조 확장 기준

- 4x4, 5x5는 `SeatLayout` domain 타입으로 확장한다.
- 테마는 `ClassroomThemeDefinition`과 sprite atlas를 추가한다.
- 인증이 생겨도 기존 public classroom repository 계약은 유지하고 별도 identity feature를 추가한다.
- Realtime은 repository의 watch 메서드로 추가하며 presentation에서 Supabase channel을 직접 열지 않는다.
