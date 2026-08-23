# 09. Flutter 패키지와 선택 이유

## 선택 원칙

- 핵심 스택인 Riverpod, GoRouter, Supabase는 공식 또는 널리 유지되는 패키지를 사용한다.
- Flutter/Dart SDK에 이미 있는 기능을 위해 별도 패키지를 추가하지 않는다.
- 초기 Web 번들 크기와 브라우저 호환성에 직접 도움이 되는 의존성만 넣는다.
- 버전은 문서에 고정하지 않고 구현 시작 시 현재 Flutter SDK와 호환되는 최신 안정 버전을 lockfile에 기록한다.
- 패키지를 추가할 때 라이선스, Web 지원, 최소 Flutter/Dart 버전을 확인한다.

## 필수 런타임 패키지

### `flutter_riverpod`

용도:

- Repository와 서비스 의존성 주입
- 교실 조회의 loading/error/data 상태 표현
- 반 생성과 친구 참여 controller 구성
- share code별 provider family 관리

선택 이유:

- BuildContext 없이 기능별 상태를 조합할 수 있다.
- UI와 application 상태를 분리하기 쉽다.
- fake repository로 provider 단위 테스트가 가능하다.

초기 MVP에서는 code generation을 도입하지 않고 명시적인 Provider와 AsyncNotifier만 사용한다. 보일러플레이트가 실제로 문제가 될 때 `riverpod_annotation`, `riverpod_generator`, `build_runner`를 추가한다.

공식 문서: <https://riverpod.dev/>

### `go_router`

용도:

- `/`, `/create`, `/class/:shareCode` 선언
- 공유 링크 직접 진입과 브라우저 새로고침
- not-found 및 오류 화면
- 생성 성공 후 replace navigation

선택 이유:

- Flutter 팀이 게시하는 URL 기반 declarative router다.
- Web deep link와 path parameter를 직접 지원한다.
- MVP 라우트 수가 적어 typed route code generation은 아직 필요하지 않다.

패키지: <https://pub.dev/packages/go_router>

### `supabase_flutter`

용도:

- Supabase client 초기화
- 공개 교실 조회
- `create_classroom`, `join_classroom` RPC 호출
- 향후 선택적인 Realtime 구독

선택 이유:

- Supabase가 제공하는 Flutter SDK이며 Web을 지원한다.
- PostgREST, RPC, Realtime 접근을 하나의 client 경계로 관리한다.
- Flutter 앱에는 publishable/anon key만 `--dart-define`으로 주입한다.

공식 Flutter 안내: <https://supabase.com/docs/guides/getting-started/quickstarts/flutter>

### `crypto`

용도:

- SHA-256 stable hash
- 관계, 좌석 순서, 캐릭터 파츠, 재미용 지표의 결정론적 seed 처리

선택 이유:

- Dart의 플랫폼별 `hashCode` 대신 명시적인 SHA-256 결과를 얻는다.
- Web과 Dart VM에서 동일한 fixture를 검증할 수 있다.

주의:

- 이는 암호 저장 라이브러리가 아니다.
- DB의 HMAC fingerprint는 서버 측 Postgres 함수가 처리한다.

패키지: <https://pub.dev/packages/crypto>

### `intl`

용도:

- 사용자에게 보이는 날짜 형식
- 한국어 날짜 및 숫자 formatting

선택 이유:

- 저장 seed의 ISO 날짜와 표시용 날짜를 분리할 수 있다.
- 브라우저 locale 차이로 표시 형식이 달라지는 것을 제어한다.

날짜 계산 자체에는 시간대가 있는 `DateTime` 변환을 사용하지 않고 날짜 값 객체를 둔다.

패키지: <https://pub.dev/packages/intl>

### `characters`

용도:

- 별명 1~12자 제한을 Unicode grapheme 기준으로 계산
- 한글, 결합 문자, emoji가 중간에서 잘리는 문제 방지

선택 이유:

- UTF-16 code unit 길이가 아니라 사용자가 보는 문자 단위로 검증한다.
- Flutter가 내부적으로 사용하더라도 앱 코드에서 직접 import하므로 direct dependency로 선언한다.

패키지: <https://pub.dev/packages/characters>

### `share_plus`

용도:

- 지원 플랫폼의 시스템 공유 UI 호출
- Web에서 텍스트, URL, 결과 이미지 파일 공유 시도
- 플랫폼별 공유 구현 차이 흡수

선택 이유:

- Flutter Community가 관리하며 Web 공유를 지원한다.
- 직접 브라우저 API를 감싼 코드의 범위를 줄인다.

공유 API 미지원 또는 실패 시 Flutter `Clipboard`와 Web download fallback을 별도로 제공한다.

패키지: <https://pub.dev/packages/share_plus>

## SDK 기능으로 해결할 항목

다음 기능은 추가 패키지 없이 구현한다.

| 기능 | 구현 |
| --- | --- |
| 폼과 입력 검증 | Flutter `Form`, `TextFormField` |
| 링크 복사 | Flutter `Clipboard` |
| 교실 이미지 렌더 | `RepaintBoundary`, `RenderRepaintBoundary.toImage` |
| PNG 인코딩 | `ui.Image.toByteData` |
| 애니메이션 | `AnimationController`, implicit animation |
| 접근성 | `Semantics`, `MediaQuery.disableAnimations` |
| JSON 변환 | 수동 DTO factory, `dart:convert` |
| 불변 Domain 모델 | `final` 필드와 value equality 직접 구현 |

MVP 규모에서는 `freezed`, `json_serializable`, `equatable`, `screenshot`, 범용 animation 패키지를 추가하지 않는다.

## 조건부 패키지

### `web`

`share_plus`와 Flutter Clipboard로 해결되지 않는 Web 전용 download 또는 feature detection이 필요할 때만 추가한다. `dart:html` 직접 의존 대신 현재 Dart Web interop 방식을 따른다.

패키지: <https://pub.dev/packages/web>

### `flutter_svg`

관계 아이콘을 SVG asset으로 확정할 때만 추가한다. 초기 아이콘이 작은 PNG sprite 또는 Flutter icon이면 제외한다.

### `path_provider`

Web-only MVP에서는 우선 제외한다. 향후 모바일 앱 빌드에서 결과 파일을 임시 디렉터리에 써야 할 때 추가한다.

## 개발 의존성

### SDK 기본

```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  integration_test:
    sdk: flutter
  flutter_lints: any
```

실제 `pubspec.yaml`에는 `any`를 쓰지 않고 `flutter create`가 생성한 SDK 호환 constraint를 유지한다.

### 선택적 테스트 도구

`mocktail`은 Supabase client 자체를 mock하지 않고 interface repository의 복잡한 상호작용 검증이 필요할 때만 추가한다. 기본 테스트는 작은 fake repository로 충분하다.

Golden test는 우선 Flutter의 `matchesGoldenFile`을 사용한다. 여러 기기 preset과 font loading 관리가 반복되면 그때 golden helper 도입을 검토한다.

## 권장 초기 의존성 명령

Flutter 프로젝트 생성 후 현재 SDK에 맞는 안정 버전을 resolver가 선택하도록 실행한다.

```bash
flutter pub add flutter_riverpod go_router supabase_flutter crypto intl characters share_plus
```

이후:

```bash
flutter pub get
flutter pub outdated
flutter analyze
```

`pubspec.lock`은 애플리케이션 저장소에 커밋해 CI와 로컬 빌드가 같은 버전을 사용하게 한다.

## 도입하지 않는 패키지

| 종류 | 이유 |
| --- | --- |
| Firebase SDK | 기술 요구사항과 맞지 않음 |
| 로그인/인증 UI | MVP에 계정 기능이 없음 |
| 범용 상태 관리 추가 패키지 | Riverpod과 역할 중복 |
| 별도 router | GoRouter와 역할 중복 |
| 무거운 chart/3D/game engine | 제품 UI에 필요 없음 |
| 범용 confetti | 작은 분필 효과는 직접 구현 가능 |
| Google Fonts runtime loader | 첫 로드와 외부 요청을 줄이고 로컬 subset font 사용 |
| 랜덤 avatar 생성기 | 캐릭터 세계관과 stable 파츠 규칙을 통제하기 어려움 |

## 패키지 검수 체크리스트

- Web 지원이 명시돼 있는가?
- 현재 Flutter stable 및 Dart SDK와 호환되는가?
- tree shaking 후에도 초기 번들 비용이 합리적인가?
- 유지보수 주체와 최근 release가 신뢰 가능한가?
- 기존 SDK 기능으로 대체할 수 없는가?
- 라이선스 고지 파일에 포함해야 하는가?
- 모바일 Safari와 Android Chrome에서 핵심 기능이 동작하는가?
