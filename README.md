# seat-mate

`내 반에 앉아봐`는 친구들이 공유 링크로 참여해 3x3 도트 교실을 채우는 Flutter Web 관계 콘텐츠다.

## 주요 기능

- 별명과 생년월일 기반의 결정론적 생성자 자리
- 관계 유형 10종과 충돌 없는 3x3 좌석 배치
- stable hash로 만드는 성별 구분 없는 도트 캐릭터
- 링크를 받은 친구의 로그인 없는 참여
- 중복 참여, 정원 9명, 잘못된 링크 처리
- 문에서 확정 좌석까지 이동하는 짧은 애니메이션
- 관계 결과 BottomSheet, 링크 공유, 클립보드 fallback
- 교실 PNG 저장과 정적 Open Graph 미리보기
- Supabase RPC 기반 원자적 생성/참여

## 로컬 실행

요구 환경:

- Flutter 3.41.9 이상
- Dart 3.11.5 이상
- Chrome 또는 Edge

```bash
flutter pub get
flutter run -d chrome
```

Supabase 값이 없으면 메모리 기반 demo repository가 사용된다. 샘플 교실은 아래 경로에서 확인할 수 있다.

```text
http://localhost:<port>/class/preview
```

## Supabase 연결

`.env.example`은 필요한 키 이름을 설명하기 위한 파일이며 Flutter가 자동으로 읽지 않는다. 실제 값은 빌드 시 `--dart-define`으로 전달한다.

```bash
flutter run -d chrome \
  --dart-define=APP_BASE_URL=http://localhost:8080 \
  --dart-define=SUPABASE_URL=https://your-project.supabase.co \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=sb_publishable_your_key
```

`service_role` 키는 Flutter 빌드에 절대 포함하지 않는다.

Supabase CLI가 준비된 환경에서는 다음 순서로 migration과 SQL 테스트를 실행한다.

```bash
supabase start
supabase db reset
supabase test db
```

Migration은 `supabase/migrations`, pgTAP 테스트는 `supabase/tests`에 있다.

## 검증

```bash
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build web --release
```

GitHub Actions는 `main` push와 pull request에서 위 검증을 수행한다. `main`은 `/seat-mate/` base path로 빌드돼 GitHub Pages에 배포되며 `404.html`이 SPA 직접 진입을 처리한다.

GitHub 저장소 설정의 Pages source는 `GitHub Actions`로 선택해야 한다. 실제 Supabase를 연결하려면 Actions secrets에 아래 값을 추가한다.

```text
SUPABASE_URL
SUPABASE_PUBLISHABLE_KEY
```

## 구조

```text
lib/app              앱 설정, router, theme
lib/core             날짜, 별명, stable hash
lib/features         classroom, character, sharing
lib/shared           공용 presentation 컴포넌트
supabase/migrations  테이블, view, RPC, RLS
supabase/tests       데이터베이스 테스트
docs/design          1~12 설계 문서
```

설계의 구현 순서와 완료 기준은 [MVP 개발 순서](docs/design/12-mvp-development-order.md), 개인정보 최소화 원칙은 [개인정보 처리 원칙](docs/privacy.md)에서 확인할 수 있다.
