# 03. Supabase 데이터베이스 구조

## 설계 원칙

- 교실 식별용 UUID와 공유용 코드를 분리한다.
- 생년월일은 계산과 중복 확인에만 사용하고 공개 조회 결과에서 제외한다.
- 좌석 유일성, 중복 참여, 정원 제한은 클라이언트가 아니라 DB가 최종 보장한다.
- 쓰기 작업은 RPC 트랜잭션으로만 수행한다.
- 알고리즘 버전을 저장해 기존 결과를 재현한다.

## 확장 기능

```sql
create extension if not exists pgcrypto;
create extension if not exists citext;
```

## 타입

```sql
create type public.relationship_type as enum (
  'owner',
  'buddy',
  'chatter',
  'leader',
  'rival',
  'emergency',
  'accomplice',
  'quiet_bestie',
  'mood_maker',
  'caretaker',
  'transfer'
);
```

## classrooms

```sql
create table public.classrooms (
  id uuid primary key default gen_random_uuid(),
  share_code text not null unique,
  owner_name text not null,
  owner_name_normalized text not null,
  owner_birth_date date not null,
  owner_seat smallint not null,
  owner_profile text not null,
  owner_character_seed text not null,
  algorithm_version smallint not null default 1,
  member_count smallint not null default 1,
  created_at timestamptz not null default now(),
  expires_at timestamptz,

  constraint classrooms_share_code_format
    check (share_code ~ '^[a-z0-9]{8,12}$'),
  constraint classrooms_owner_name_length
    check (char_length(owner_name) between 1 and 12),
  constraint classrooms_owner_seat_range
    check (owner_seat between 0 and 8),
  constraint classrooms_member_count_range
    check (member_count between 1 and 9),
  constraint classrooms_birth_date_range
    check (owner_birth_date between date '1900-01-01' and current_date)
);
```

`member_count`는 빠른 표시와 원자적 정원 검사에 사용한다. 실제 행 수와 불일치하지 않도록 쓰기를 RPC로 제한한다.

## classroom_members

생성자도 구성원 테이블에 한 행으로 저장한다. 교실 렌더링 시 별도 분기 없이 9개 좌석을 동일하게 처리할 수 있다.

```sql
create table public.classroom_members (
  id uuid primary key default gen_random_uuid(),
  classroom_id uuid not null
    references public.classrooms(id) on delete cascade,
  name text not null,
  name_normalized text not null,
  birth_date date not null,
  birth_date_fingerprint text not null,
  is_owner boolean not null default false,
  seat_index smallint not null,
  relationship_type public.relationship_type not null,
  character_seed text not null,
  fun_focus_delta smallint not null,
  fun_joy_delta smallint not null,
  algorithm_version smallint not null default 1,
  created_at timestamptz not null default now(),

  constraint classroom_members_name_length
    check (char_length(name) between 1 and 12),
  constraint classroom_members_seat_range
    check (seat_index between 0 and 8),
  constraint classroom_members_birth_date_range
    check (birth_date between date '1900-01-01' and current_date),
  constraint classroom_members_metric_range
    check (
      fun_focus_delta between -99 and 99
      and fun_joy_delta between -99 and 99
    ),
  constraint classroom_members_owner_relationship
    check (
      (is_owner and relationship_type = 'owner')
      or (not is_owner and relationship_type <> 'owner')
    ),

  unique (classroom_id, seat_index),
  unique (classroom_id, name_normalized, birth_date_fingerprint)
);
```

`birth_date_fingerprint`는 서버 비밀 salt를 사용하는 HMAC 결과로 저장할 수 있다. MVP에서 원본 날짜가 알고리즘 재현에 필요하므로 `birth_date`도 저장하지만, 공개 view에서는 제외한다.

## 인덱스

```sql
create index classrooms_created_at_idx
  on public.classrooms (created_at desc);

create index classroom_members_classroom_created_idx
  on public.classroom_members (classroom_id, created_at);
```

`share_code`와 `(classroom_id, seat_index)`는 unique 제약이 자동으로 인덱스를 만든다.

## 공개 조회 View

```sql
create view public.public_classrooms
with (security_invoker = true) as
select
  id,
  share_code,
  owner_name,
  owner_seat,
  owner_profile,
  owner_character_seed,
  algorithm_version,
  member_count,
  created_at
from public.classrooms;

create view public.public_classroom_members
with (security_invoker = true) as
select
  id,
  classroom_id,
  name,
  is_owner,
  seat_index,
  relationship_type,
  character_seed,
  fun_focus_delta,
  fun_joy_delta,
  algorithm_version,
  created_at
from public.classroom_members;
```

클라이언트 조회 응답에는 생년월일과 정규화 이름을 포함하지 않는다.

## 공유 코드

- 소문자 영문과 숫자로 10자를 생성한다.
- 혼동하기 쉬운 `0`, `o`, `1`, `l`은 제외할 수 있다.
- `gen_random_bytes`에서 생성하고 unique 충돌 시 제한 횟수만 재시도한다.
- UUID 일부나 시간값을 그대로 노출하지 않는다.

## create_classroom RPC

입력:

```text
owner_name
owner_birth_date
owner_seat
owner_profile
owner_character_seed
algorithm_version
```

트랜잭션:

1. 입력을 trim하고 이름 비교용 값을 정규화한다.
2. 날짜, 이름 길이, 좌석 범위를 검증한다.
3. 충돌 없는 공유 코드를 생성한다.
4. `classrooms`를 삽입한다.
5. 같은 트랜잭션에서 생성자를 `classroom_members`에 삽입한다.
6. 공개 조회에 필요한 데이터만 반환한다.

## join_classroom RPC

입력:

```text
share_code
name
birth_date
relationship_type
existing_member_ids uuid[]
existing_member_seats smallint[]
new_seat smallint
character_seed
fun_focus_delta
fun_joy_delta
algorithm_version
```

트랜잭션:

1. `share_code`로 교실을 조회하고 `for update`로 잠근다.
2. 없으면 `CLASSROOM_NOT_FOUND`를 반환한다.
3. 정규화 이름과 날짜 fingerprint로 기존 참여를 찾는다.
4. 중복이면 `DUPLICATE_MEMBER`와 기존 member id를 반환한다.
5. `member_count >= 12`이면 `CLASSROOM_FULL`을 반환한다.
6. 전달받은 기존 member id가 현재 비방장 명단과 정확히 일치하는지 검증한다.
7. 방장 좌석을 제외한 전체 배치에 중복이나 범위 오류가 없는지 검증한다.
8. 기존 구성원 좌석을 한 번에 갱신하고 새 구성원을 최종 좌석에 삽입한다.
9. `member_count`를 1 증가시키고 `algorithm_version`을 갱신한다.
10. 새 구성원과 갱신된 인원수를 반환한다.

교실 행 잠금으로 동시에 두 명이 참여해도 같은 마지막 좌석을 배정받지 않는다. 클라이언트가 읽은 뒤 다른 참여자가 먼저 저장되었다면 `CLASSROOM_CHANGED`를 반환해 최신 명단 기준 재계산을 유도한다.

## RLS 정책

```text
classrooms
  select: public view에 필요한 행만 허용
  insert/update/delete: 직접 접근 차단

classroom_members
  select: public view에 필요한 행만 허용
  insert/update/delete: 직접 접근 차단

RPC
  anon 실행 허용
  security definer 사용 시 search_path 고정
  내부에서 모든 입력 재검증
```

공개 조회가 제품상 필요하므로 share code는 비밀번호가 아니다. 민감 필드를 view에서 제거하고, 대량 열거 방지를 위해 API rate limit과 만료 정책을 운영 단계에서 추가한다.

## 데이터 수명

MVP에서는 `expires_at`을 nullable로 두되, 출시 전 개인정보 보유 정책을 정한다. 예를 들어 마지막 활동 후 90일이 지난 교실을 배치 작업으로 삭제할 수 있다. 삭제 시 외래 키 cascade로 구성원도 함께 삭제된다.

## 마이그레이션 순서

1. 확장과 enum 생성
2. 테이블과 제약 생성
3. 인덱스와 공개 view 생성
4. 공유 코드 함수 생성
5. 생성/참여 RPC 생성
6. RLS 활성화 및 정책 적용
7. 정원, 중복, 동시 참여 통합 테스트
