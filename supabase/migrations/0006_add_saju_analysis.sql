alter table public.classrooms
  add column owner_birth_hour smallint,
  add column owner_birth_minute smallint;

alter table public.classroom_members
  add column birth_hour smallint,
  add column birth_minute smallint,
  add column saju_chart jsonb,
  add column compatibility jsonb;

alter table public.classrooms
  add constraint classrooms_birth_time_pair check (
    (owner_birth_hour is null and owner_birth_minute is null)
    or (
      owner_birth_hour between 0 and 23
      and owner_birth_minute between 0 and 59
    )
  );

alter table public.classroom_members
  add constraint classroom_members_birth_time_pair check (
    (birth_hour is null and birth_minute is null)
    or (birth_hour between 0 and 23 and birth_minute between 0 and 59)
  ),
  add constraint classroom_members_saju_chart_object check (
    saju_chart is null or jsonb_typeof(saju_chart) = 'object'
  ),
  add constraint classroom_members_compatibility_object check (
    compatibility is null or jsonb_typeof(compatibility) = 'object'
  );

drop view public.public_classroom_members;
drop view public.public_classrooms;

create view public.public_classrooms
with (security_barrier = true) as
select
  id,
  share_code,
  owner_name,
  owner_seat,
  owner_algorithm_seed,
  owner_profile,
  owner_character_seed,
  algorithm_version,
  member_count,
  created_at
from public.classrooms
where expires_at is null or expires_at > now();

create view public.public_classroom_members
with (security_barrier = true) as
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
  saju_chart,
  compatibility,
  created_at
from public.classroom_members;

comment on view public.public_classrooms is
  'Public classroom fields. Raw birth data and normalized names are intentionally omitted.';

comment on view public.public_classroom_members is
  'Public member fields expose derived Saju evidence, never raw birth date or time.';

grant select on public.public_classrooms to anon, authenticated;
grant select on public.public_classroom_members to anon, authenticated;

drop function if exists public.create_classroom(
  text, date, smallint, text, text, text, smallint
);

create function public.create_classroom(
  p_owner_name text,
  p_owner_birth_date date,
  p_owner_birth_hour smallint,
  p_owner_birth_minute smallint,
  p_owner_saju_chart jsonb,
  p_owner_seat smallint,
  p_owner_profile text,
  p_owner_character_seed text,
  p_owner_algorithm_seed text,
  p_algorithm_version smallint default 2
)
returns table (classroom_id uuid, share_code text, owner_member_id uuid)
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_classroom_id uuid;
  v_owner_member_id uuid;
  v_share_code text;
  v_attempt smallint := 0;
  v_owner_name text := trim(regexp_replace(p_owner_name, '\s+', ' ', 'g'));
begin
  if char_length(v_owner_name) not between 1 and 12 then
    raise exception using errcode = '22023', message = 'INVALID_NAME';
  end if;
  if p_owner_birth_date < date '1900-01-01' or p_owner_birth_date > current_date then
    raise exception using errcode = '22023', message = 'INVALID_BIRTH_DATE';
  end if;
  if (p_owner_birth_hour is null) <> (p_owner_birth_minute is null)
     or p_owner_birth_hour not between 0 and 23
     or p_owner_birth_minute not between 0 and 59 then
    raise exception using errcode = '22023', message = 'INVALID_BIRTH_TIME';
  end if;
  if p_owner_saju_chart is null or jsonb_typeof(p_owner_saju_chart) <> 'object' then
    raise exception using errcode = '22023', message = 'INVALID_SAJU_CHART';
  end if;
  if p_owner_seat not between 0 and 8 then
    raise exception using errcode = '22023', message = 'INVALID_SEAT';
  end if;
  if p_owner_profile not in ('window', 'center', 'back', 'front') then
    raise exception using errcode = '22023', message = 'INVALID_OWNER_PROFILE';
  end if;

  loop
    v_attempt := v_attempt + 1;
    v_share_code := public.generate_classroom_share_code();
    begin
      insert into public.classrooms (
        share_code,
        owner_name,
        owner_name_normalized,
        owner_birth_date,
        owner_birth_hour,
        owner_birth_minute,
        owner_seat,
        owner_profile,
        owner_character_seed,
        owner_algorithm_seed,
        algorithm_version
      ) values (
        v_share_code,
        v_owner_name,
        public.normalize_nickname(v_owner_name),
        p_owner_birth_date,
        p_owner_birth_hour,
        p_owner_birth_minute,
        p_owner_seat,
        p_owner_profile,
        p_owner_character_seed,
        p_owner_algorithm_seed,
        p_algorithm_version
      ) returning id into v_classroom_id;
      exit;
    exception when unique_violation then
      if v_attempt >= 5 then
        raise;
      end if;
    end;
  end loop;

  insert into public.classroom_members (
    classroom_id,
    name,
    name_normalized,
    birth_date,
    birth_hour,
    birth_minute,
    is_owner,
    seat_index,
    relationship_type,
    character_seed,
    saju_chart,
    algorithm_version
  ) values (
    v_classroom_id,
    v_owner_name,
    public.normalize_nickname(v_owner_name),
    p_owner_birth_date,
    p_owner_birth_hour,
    p_owner_birth_minute,
    true,
    p_owner_seat,
    'owner',
    p_owner_character_seed,
    p_owner_saju_chart,
    p_algorithm_version
  ) returning id into v_owner_member_id;

  return query select v_classroom_id, v_share_code, v_owner_member_id;
end;
$$;

drop function if exists public.join_classroom(
  text, text, date, public.relationship_type, smallint[], text, smallint, smallint, smallint
);

create function public.join_classroom(
  p_share_code text,
  p_name text,
  p_birth_date date,
  p_birth_hour smallint,
  p_birth_minute smallint,
  p_saju_chart jsonb,
  p_compatibility jsonb,
  p_relationship_type public.relationship_type,
  p_preferred_seats smallint[],
  p_character_seed text,
  p_fun_focus_delta smallint,
  p_fun_joy_delta smallint,
  p_algorithm_version smallint default 2
)
returns table (
  result_status text,
  classroom_id uuid,
  member_id uuid,
  seat_index smallint,
  member_count smallint
)
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_classroom public.classrooms%rowtype;
  v_existing public.classroom_members%rowtype;
  v_name text := trim(regexp_replace(p_name, '\s+', ' ', 'g'));
  v_seat smallint;
  v_member_id uuid;
  v_member_count smallint;
begin
  if char_length(v_name) not between 1 and 12 then
    raise exception using errcode = '22023', message = 'INVALID_NAME';
  end if;
  if p_birth_date < date '1900-01-01' or p_birth_date > current_date then
    raise exception using errcode = '22023', message = 'INVALID_BIRTH_DATE';
  end if;
  if (p_birth_hour is null) <> (p_birth_minute is null)
     or p_birth_hour not between 0 and 23
     or p_birth_minute not between 0 and 59 then
    raise exception using errcode = '22023', message = 'INVALID_BIRTH_TIME';
  end if;
  if p_saju_chart is null or jsonb_typeof(p_saju_chart) <> 'object'
     or p_compatibility is null or jsonb_typeof(p_compatibility) <> 'object' then
    raise exception using errcode = '22023', message = 'INVALID_SAJU_RESULT';
  end if;
  if p_relationship_type = 'owner' then
    raise exception using errcode = '22023', message = 'INVALID_RELATIONSHIP';
  end if;
  if coalesce(cardinality(p_preferred_seats), 0) = 0
     or exists (
       select 1 from unnest(p_preferred_seats) as candidate
       where candidate not between 0 and 8
     ) then
    raise exception using errcode = '22023', message = 'INVALID_SEAT_PREFERENCES';
  end if;

  select * into v_classroom
  from public.classrooms
  where share_code = p_share_code
    and (expires_at is null or expires_at > now())
  for update;

  if not found then
    raise exception using errcode = 'P0002', message = 'CLASSROOM_NOT_FOUND';
  end if;

  select * into v_existing
  from public.classroom_members
  where classroom_id = v_classroom.id
    and name_normalized = public.normalize_nickname(v_name)
    and birth_date = p_birth_date;

  if found then
    return query select
      'duplicate'::text,
      v_classroom.id,
      v_existing.id,
      v_existing.seat_index,
      v_classroom.member_count;
    return;
  end if;

  if v_classroom.member_count >= 9 then
    raise exception using errcode = 'P0001', message = 'CLASSROOM_FULL';
  end if;

  select candidate into v_seat
  from unnest(p_preferred_seats) with ordinality as ranked(candidate, position)
  where not exists (
    select 1
    from public.classroom_members member
    where member.classroom_id = v_classroom.id
      and member.seat_index = ranked.candidate
  )
  order by position
  limit 1;

  if v_seat is null then
    raise exception using errcode = 'P0001', message = 'CLASSROOM_FULL';
  end if;

  insert into public.classroom_members (
    classroom_id,
    name,
    name_normalized,
    birth_date,
    birth_hour,
    birth_minute,
    seat_index,
    relationship_type,
    character_seed,
    fun_focus_delta,
    fun_joy_delta,
    saju_chart,
    compatibility,
    algorithm_version
  ) values (
    v_classroom.id,
    v_name,
    public.normalize_nickname(v_name),
    p_birth_date,
    p_birth_hour,
    p_birth_minute,
    v_seat,
    p_relationship_type,
    p_character_seed,
    p_fun_focus_delta,
    p_fun_joy_delta,
    p_saju_chart,
    p_compatibility,
    p_algorithm_version
  ) returning id into v_member_id;

  update public.classrooms
  set member_count = member_count + 1
  where id = v_classroom.id
  returning public.classrooms.member_count into v_member_count;

  return query select
    'created'::text,
    v_classroom.id,
    v_member_id,
    v_seat,
    v_member_count;
end;
$$;

revoke all on function public.create_classroom(
  text, date, smallint, smallint, jsonb, smallint, text, text, text, smallint
) from public;
revoke all on function public.join_classroom(
  text, text, date, smallint, smallint, jsonb, jsonb, public.relationship_type,
  smallint[], text, smallint, smallint, smallint
) from public;

grant execute on function public.create_classroom(
  text, date, smallint, smallint, jsonb, smallint, text, text, text, smallint
) to anon, authenticated;
grant execute on function public.join_classroom(
  text, text, date, smallint, smallint, jsonb, jsonb, public.relationship_type,
  smallint[], text, smallint, smallint, smallint
) to anon, authenticated;
