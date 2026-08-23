# 11. 카카오톡/SNS Open Graph 처리

## 결론

MVP는 Flutter Web의 `web/index.html`에 정적 Open Graph 메타데이터와 정적 교실 이미지를 넣는다.

교실별 미리보기가 실제 공유 전환에 중요하다는 데이터가 확인되면 Cloudflare Worker를 앞단에 추가해 `/class/:shareCode`의 HTML 응답에 동적 title/description/image URL을 주입한다.

Flutter가 실행된 뒤 브라우저에서 meta tag를 바꾸는 방식은 링크 크롤러가 JavaScript 실행 결과를 기다린다고 보장할 수 없으므로 사용하지 않는다.

## MVP: 정적 Open Graph

`web/index.html`의 `<head>`에 배포 시점의 절대 URL을 넣는다.

```html
<title>내 반에 앉아봐</title>
<meta
  name="description"
  content="내 반에서 너는 어디에 앉을까? 친구들과 우리만의 교실을 채워보세요."
>

<meta property="og:type" content="website">
<meta property="og:site_name" content="내 반에 앉아봐">
<meta property="og:title" content="내 반에 앉아봐">
<meta
  property="og:description"
  content="내 반에서 너는 어디에 앉을까?"
>
<meta property="og:url" content="https://seat-mate.example.com/">
<meta
  property="og:image"
  content="https://seat-mate.example.com/assets/assets/images/og-classroom.png"
>
<meta property="og:image:width" content="1200">
<meta property="og:image:height" content="630">
<meta property="og:image:alt" content="도트 캐릭터들이 앉아 있는 따뜻한 교실">

<meta name="twitter:card" content="summary_large_image">
<meta name="twitter:title" content="내 반에 앉아봐">
<meta name="twitter:description" content="내 반에서 너는 어디에 앉을까?">
<meta
  name="twitter:image"
  content="https://seat-mate.example.com/assets/assets/images/og-classroom.png"
>
```

실제 Flutter asset 배포 경로는 build 결과에서 확인해 URL을 확정한다. 파일 경로가 바뀌면 HTML의 URL과 배포 검증 테스트를 함께 수정한다.

## 정적 OG 이미지 사양

```text
크기: 1200 x 630 px
형식: JPEG 또는 최적화 PNG
목표 용량: 300KB 이하
핵심 안전 영역: 중앙 960 x 500 px
```

구성:

```text
내 반에 앉아봐
생일로 정해지는 우리들의 자리

[실제 제품과 같은 3x3 도트 교실]

내 반에서 너는 어디에 앉을까?
```

- 실제 교실 결과 화면의 색, 책상, 캐릭터를 사용한다.
- URL을 크게 표시하지 않는다.
- 작은 미리보기에서도 서비스명과 3x3 교실이 식별돼야 한다.
- 특정 실명이나 생년월일을 넣지 않는다.
- 투명 배경을 사용하지 않는다.

## 공유 URL

Flutter가 만드는 공유 URL은 hash route가 아닌 path route를 사용한다.

```text
https://seat-mate.example.com/class/8fj2kd9abc
```

호스팅은 알 수 없는 navigation 요청에 `index.html`을 반환하도록 SPA fallback을 설정한다. query parameter는 캠페인 측정이 필요할 때만 사용하며 share code의 의미를 복제하지 않는다.

## 2단계: Cloudflare Worker 동적 메타데이터

Cloudflare Workers는 static assets와 Worker routing을 함께 구성할 수 있고, `HTMLRewriter`로 HTML 응답을 변환할 수 있다.

공식 문서:

- <https://developers.cloudflare.com/workers/static-assets/>
- <https://developers.cloudflare.com/workers/static-assets/routing/>
- <https://developers.cloudflare.com/workers/runtime-apis/html-rewriter/>

요청 흐름:

```text
GET /class/:shareCode
  -> Worker가 shareCode 형식 검증
  -> Supabase public classroom endpoint 조회
  -> 존재하면 Flutter index.html asset 조회
  -> title, description, canonical, og:url, og:image 주입
  -> 브라우저와 크롤러에 같은 HTML 반환
  -> Flutter가 시작돼 정상 교실 화면 렌더
```

교실이 없거나 Supabase 조회가 실패하면 정적 기본 metadata와 `index.html`을 반환한다. OG 실패가 실제 앱 진입을 막지 않게 한다.

동적 예시:

```html
<title>재홍이네 반 | 내 반에 앉아봐</title>
<meta property="og:title" content="재홍이네 반에 앉아봐">
<meta property="og:description" content="현재 4명이 앉아 있어요. 너는 어디 자리일까?">
<meta
  property="og:url"
  content="https://seat-mate.example.com/class/8fj2kd9abc"
>
<link
  rel="canonical"
  href="https://seat-mate.example.com/class/8fj2kd9abc"
>
```

초기 동적 단계에서도 이미지는 정적 교실 이미지를 재사용할 수 있다. title과 인원수만 달라져도 링크 맥락은 충분히 좋아진다.

## 3단계: 교실별 동적 OG 이미지

동적 이미지가 필요해지면 Supabase Edge Function을 사용한다. Supabase는 Edge Functions의 Open Graph 이미지 생성 사용 사례를 공식 문서에서 제공한다.

공식 문서: <https://supabase.com/docs/guides/functions>

권장 흐름:

```text
교실 생성 또는 구성원 참여 성공
  -> 이미지 version 증가
  -> Edge Function이 public classroom data 조회
  -> 1200x630 이미지 생성
  -> Storage public bucket에 저장
  -> /og/class/:shareCode?v=<version>으로 제공
  -> Worker가 해당 URL을 og:image에 주입
```

요청마다 이미지를 즉석 생성하면 공유 크롤러 재시도와 비용 변동이 커질 수 있으므로, 구성 변경 시 생성하고 versioned URL을 캐시하는 방식을 우선한다.

## 캐시 전략

### HTML

- `/`와 `/create`: 정적 asset 캐시
- `/class/:shareCode`: 짧은 edge cache 또는 캐시 미사용으로 인원수 stale 최소화
- Supabase 장애 시 기본 metadata를 가진 HTML fallback

### 이미지

- 정적 OG: 긴 `Cache-Control`, 파일명에 content hash
- 동적 OG: version query 또는 versioned pathname
- 교실 업데이트 시 기존 URL을 덮어쓰지 않고 새 version 발급

카카오톡과 SNS는 각자 링크 미리보기 캐시를 가질 수 있다. 그래서 동일 URL의 이미지를 덮어쓰는 것보다 version이 바뀌는 URL이 예측 가능하다.

## 개인정보와 보안

- OG에는 owner 별명, 현재 인원수, 공개 관계 요약만 사용한다.
- 생년월일, normalized name, 내부 UUID를 포함하지 않는다.
- share code 형식이 맞지 않으면 DB 요청을 보내지 않는다.
- Worker의 Supabase key는 환경 binding으로 관리하고 저장소에 커밋하지 않는다.
- service role key는 공개 교실 조회에 사용하지 않는다.
- 동일 IP/코드의 과도한 OG 요청은 edge rate limit 대상으로 둔다.
- 사용자 입력은 HTML attribute에 넣기 전에 escape한다.

## SEO 보조 항목

- `lang="ko"`
- mobile viewport
- theme color
- canonical URL
- robots 정책
- `sitemap.xml`에는 개인 교실 URL을 나열하지 않음
- 존재하지 않는 교실은 앱 UX와 별개로 Worker 단계에서 404 metadata 검토

공개 교실은 검색 엔진 노출이 핵심 목적이 아니므로 기본적으로 교실 경로의 index 정책을 신중히 설정한다. 링크 미리보기 크롤링과 검색 색인은 별도 요구다.

## 검증 체크리스트

- `curl`로 받은 최초 HTML에 OG 태그가 실제 존재함
- `og:image`가 인증 없이 200으로 응답함
- image content type과 1200x630 크기가 정확함
- `/class/:shareCode` 직접 진입과 브라우저 새로고침 정상
- 한글 별명과 특수문자가 metadata를 깨지 않음
- 존재하지 않는 share code가 앱 shell 진입을 막지 않음
- 카카오톡, 메시지, X, Facebook 계열 debugger에서 실제 카드 확인
- 캐시 갱신 후 versioned image가 새 결과를 표시함

## 구현 우선순위

1. 출시용 도메인 확정
2. 정적 OG 이미지 제작
3. `web/index.html` 기본 metadata 적용
4. 실제 배포 URL에서 링크 카드 검증
5. 공유 전환 데이터 수집
6. 필요 시 Cloudflare Worker로 title/description 동적화
7. 필요 시 Supabase Edge Function으로 교실별 이미지 생성
