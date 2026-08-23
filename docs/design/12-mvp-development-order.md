# 12. MVP 개발 순서

## 진행 원칙

- 결과 교실 화면을 가장 먼저 눈에 보이는 수준으로 만든다.
- Domain 규칙은 Supabase 연결 전에 테스트로 고정한다.
- 외부 서비스 연결 전 fake repository로 전체 UX를 완주한다.
- 각 단계는 실행 가능한 상태, 테스트, 한 개의 목적이 분명한 커밋으로 끝낸다.
- 모바일 360px, 390px, 430px을 매 UI 단계에서 확인한다.

## 1. Flutter Web 프로젝트 기반

산출물:

- Flutter Web scaffold
- 서비스명 상수, app config, 기본 theme
- Riverpod `ProviderScope`
- GoRouter의 `/`, `/create`, `/class/:shareCode`
- 앱 전용 not-found 화면

검증:

```text
flutter pub get
flutter analyze
flutter test
flutter run -d chrome
```

완료 기준:

- 세 경로를 직접 열고 새로고침할 수 있다.
- 서비스명이 한 상수에서 관리된다.
- 기본 Flutter 오류 화면이 노출되지 않는다.

권장 커밋:

```text
feat: scaffold Flutter web app
```

## 2. 디자인 토큰과 공용 UI

산출물:

- 따뜻한 중립 배경, 초록 칠판, 원목 책상, 코랄/연두/하늘색 accent
- 본문용 한국어 subset font
- 버튼, 입력, scaffold, loading, error 상태
- 고정된 spacing, radius, typography token

검증:

- text scale 200%에서 버튼/입력 text가 잘리지 않는다.
- contrast와 44x44 tap target을 확인한다.
- 네온, 과한 gradient, card 안의 card가 없다.

권장 커밋:

```text
feat: establish classroom visual system
```

## 3. 3x3 교실 결과 화면

산출물:

- mock classroom data
- 칠판, 창문, 문, 9개 책상
- 생성자와 3명의 샘플 구성원
- 좌석 선택과 결과 BottomSheet
- 360/390/430px responsive layout

검증:

- 9개 좌석 크기가 동적 text로 흔들리지 않는다.
- 긴 별명과 관계 아이콘이 겹치지 않는다.
- 교실이 화면의 주인공이고 다음 CTA 힌트가 보인다.
- golden screenshot을 저장한다.

권장 커밋:

```text
feat: build responsive classroom result
```

## 4. 도트 캐릭터 시스템

산출물:

- 캐릭터 sprite atlas 또는 임시 pixel painter
- 헤어, 상의, 표정, 액세서리, 피부 팔레트
- stable seed-to-parts generator
- 앉기, 선택, 신규 참여 상태

검증:

- 같은 seed에서 같은 캐릭터가 나온다.
- 모든 byte 입력이 유효한 파츠 index를 만든다.
- 9명 캐릭터가 서로 식별되고 이름표를 가리지 않는다.

권장 커밋:

```text
feat: add deterministic pixel characters
```

## 5. 결정론적 Domain 알고리즘

산출물:

- `LocalDate`, `Nickname`, canonical seed
- SHA-256 helper
- 생성자 자리 성향 4종
- 관계 타입 10종과 metric range
- 관계별 좌석 점수와 collision fallback
- algorithm v1 fixture

검증:

- 동일 입력 반복 결과가 같다.
- 사용 좌석이 중복 배정되지 않는다.
- 사용 좌석 set 입력 순서가 결과를 바꾸지 않는다.
- Web과 Dart VM fixture가 같다.

권장 커밋:

```text
feat: implement deterministic seat algorithm
```

## 6. 랜딩과 반 생성 UX

산출물:

- 5초 안에 이해되는 랜딩
- 별명/생년월일 생성 폼
- 자리 배치 loading 문구
- 생성자 성향과 좌석 미리보기
- fake repository로 교실 화면 이동

검증:

- 잘못된 날짜와 빈 이름을 필드에서 안내한다.
- submit 중 layout shift와 중복 submit이 없다.
- mobile keyboard에서 CTA까지 접근 가능하다.

권장 커밋:

```text
feat: create classroom onboarding flow
```

## 7. 친구 참여와 자리 이동

산출물:

- 교실 아래 참여 폼
- fake repository 기반 참여 성공/중복/만석 상태
- 문에서 책상까지 1.8초 이내 이동
- 참여 성공 결과 BottomSheet
- reduced motion 대체

검증:

- 서버 응답 seat를 받은 뒤 애니메이션을 시작한다.
- 중복이면 기존 좌석으로 이동한다.
- 만석이면 교실은 볼 수 있고 내 반 만들기 CTA가 나온다.

권장 커밋:

```text
feat: add classroom join experience
```

## 8. Supabase 스키마와 RPC

산출물:

- classrooms, classroom_members migration
- 공개 read view
- create_classroom RPC
- join_classroom RPC
- RLS 정책
- local seed 및 SQL tests

검증:

- 생성자 포함 9명만 저장된다.
- 동일 이름+생년월일 중복이 차단된다.
- 같은 좌석 insert가 차단된다.
- 동시에 마지막 좌석을 요청해도 한 명만 성공한다.
- 공개 응답에 생년월일이 없다.

권장 커밋:

```text
feat: add Supabase classroom schema
```

## 9. Flutter와 Supabase 연결

산출물:

- Supabase initialization via dart-define
- DTO와 repository 구현
- Riverpod create/join controllers
- share code 교실 조회
- 앱 오류 매핑과 재시도

검증:

- fake repository contract test를 실제 구현도 만족한다.
- create -> route -> join 전체 흐름이 실제 DB에서 동작한다.
- 네트워크 실패 후 입력이 유지된다.
- service role key가 빌드와 저장소에 없다.

권장 커밋:

```text
feat: connect classroom flows to Supabase
```

## 10. 공유 링크와 바이럴 CTA

산출물:

- 시스템 링크 공유
- clipboard fallback
- 참여 결과 공유 문구
- `나도 내 반 만들어보기` CTA
- 공유 취소/실패 처리

검증:

- 모바일 Safari와 Android Chrome에서 링크 공유 또는 복사가 된다.
- 공유 URL로 새 browser session에서 교실에 직접 진입한다.
- 사용자가 공유를 취소해도 오류로 표시하지 않는다.

권장 커밋:

```text
feat: add classroom link sharing
```

## 11. 결과 이미지와 Open Graph

산출물:

- 4:5 교실 캡처 layout
- PNG 저장 또는 파일 공유
- 1200x630 정적 OG 이미지
- `web/index.html` metadata
- SPA fallback 배포 설정

검증:

- 캡처에 입력 폼과 조작 버튼이 나오지 않는다.
- 9명과 핵심 관계 요약이 이미지 안에 들어온다.
- 배포 URL 최초 HTML에 OG 태그가 있다.
- 카카오톡과 주요 SNS preview를 실제 기기에서 확인한다.

권장 커밋:

```text
feat: add shareable classroom artwork
```

## 12. 출시 전 품질과 배포

산출물:

- deterministic/domain/widget/integration test 보강
- loading, not-found, network, duplicate, full 상태 최종 점검
- asset 압축과 font subset
- CI: format, analyze, test, web build
- production 환경값과 배포 문서
- 개인정보 보유/삭제 정책 문구

검증:

```text
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
flutter build web --release
```

브라우저/화면:

```text
iOS Safari: 360, 390, 430px 상당
Android Chrome: 360, 412px 상당
Desktop Chrome: 1280px 이상
reduced motion
text scale 200%
느린 네트워크와 offline 전환
```

완료 기준:

- 생성부터 친구 참여, 결과, 공유까지 막힘 없이 완주한다.
- 9번째 참여와 10번째 거절이 정확하다.
- build output에 비밀 키가 없다.
- 핵심 화면에 overflow, 겹침, 빈 canvas가 없다.
- README에 로컬 실행, Supabase migration, 배포 방법이 있다.

권장 커밋:

```text
chore: prepare MVP release
```

## 기능별 우선순위

```text
P0
  3x3 교실 결과
  도트 캐릭터
  결정론적 관계/좌석
  반 생성/참여
  Supabase 저장
  링크 공유

P1
  자리 이동 애니메이션
  관계 BottomSheet
  이미지 저장
  정적 Open Graph
  신규 참여 강조

P2
  Realtime
  동적 Open Graph title/image
  추가 교실 theme
  결과 전용 URL
```

P2는 초기 출시를 막지 않는다.

## 단계별 공통 Definition of Done

각 구현 단계는 아래를 모두 만족해야 완료다.

- 요청 범위의 UI 또는 로직이 실제 실행된다.
- 관련 테스트가 통과한다.
- `flutter analyze` 신규 경고가 없다.
- 사용자 입력과 오류 상태가 고려돼 있다.
- 모바일 최소 폭에서 overflow가 없다.
- 비밀값, 생성 산출물, 불필요한 asset이 커밋되지 않는다.
- 단계 하나의 목적을 설명하는 커밋으로 `main`에 푸시된다.

## 출시 판단

MVP 출시를 위해 반드시 필요한 것은 완벽한 캐릭터 파츠 수가 아니라 다음 감정이 실제 흐름에서 전달되는 것이다.

```text
"ㅋㅋ 너 내 옆자리로 나왔어"
```

생성자 한 명이 링크를 보내고 친구 한 명이 참여해 그 결과를 다시 공유하는 흐름이 빠르고 예쁘게 완주되면 첫 출시 조건을 만족한다.

## 설계 문서 색인

```text
01 전체 서비스 구조
02 Flutter Web + Supabase 아키텍처
03 Supabase 데이터베이스 구조
04 관계 유형과 좌석 매핑
05 결정론적 알고리즘
06 도트 캐릭터 생성 규칙
07 3x3 교실 와이어프레임
08 전체 사용자 흐름
09 Flutter 패키지
10 파일과 폴더 구조
11 Open Graph 처리
12 MVP 개발 순서
```
