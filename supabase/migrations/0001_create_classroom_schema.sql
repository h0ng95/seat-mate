create extension if not exists pgcrypto with schema extensions;

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

create table public.classrooms (
  id uuid primary key default extensions.gen_random_uuid(),
  share_code text not null unique,
  owner_name text not null,
  owner_name_normalized text not null,
  owner_birth_date date not null,
  owner_algorithm_seed text not null,
  owner_seat smallint not null,
  owner_profile text not null,
  owner_character_seed text not null,
  algorithm_version smallint not null default 1,
  member_count smallint not null default 1,
  created_at timestamptz not null default now(),
  expires_at timestamptz,

  constraint classrooms_share_code_format
    check (share_code ~ '^[a-z0-9]{10}$'),
  constraint classrooms_owner_name_length
    check (char_length(owner_name) between 1 and 12),
  constraint classrooms_owner_seat_range
    check (owner_seat between 0 and 8),
  constraint classrooms_member_count_range
    check (member_count between 1 and 9),
  constraint classrooms_birth_date_minimum
    check (owner_birth_date >= date '1900-01-01'),
  constraint classrooms_profile_value
    check (owner_profile in ('window', 'center', 'back', 'front'))
);

create table public.classroom_members (
  id uuid primary key default extensions.gen_random_uuid(),
  classroom_id uuid not null references public.classrooms(id) on delete cascade,
  name text not null,
  name_normalized text not null,
  birth_date date not null,
  is_owner boolean not null default false,
  seat_index smallint not null,
  relationship_type public.relationship_type not null,
  character_seed text not null,
  fun_focus_delta smallint not null default 0,
  fun_joy_delta smallint not null default 0,
  algorithm_version smallint not null default 1,
  created_at timestamptz not null default now(),

  constraint classroom_members_name_length
    check (char_length(name) between 1 and 12),
  constraint classroom_members_seat_range
    check (seat_index between 0 and 8),
  constraint classroom_members_birth_date_minimum
    check (birth_date >= date '1900-01-01'),
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
  unique (classroom_id, name_normalized, birth_date)
);

create index classrooms_created_at_idx
  on public.classrooms (created_at desc);

create index classroom_members_classroom_created_idx
  on public.classroom_members (classroom_id, created_at);
