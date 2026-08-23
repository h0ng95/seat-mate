update public.classroom_members
set
  relationship_type = 'mood_maker'::public.relationship_type,
  compatibility = case
    when compatibility is null then null
    else jsonb_set(
      compatibility,
      '{relationship_type}',
      '"mood_maker"'::jsonb,
      true
    )
  end
where relationship_type = 'emergency'::public.relationship_type;

alter table public.classroom_members
  drop constraint if exists classroom_members_classroom_id_seat_index_key;

alter table public.classroom_members
  add constraint classroom_members_classroom_id_seat_index_key
  unique (classroom_id, seat_index)
  deferrable initially deferred;

drop function if exists public.join_classroom(
  text, text, date, smallint, smallint, jsonb, jsonb, public.relationship_type,
  smallint[], text, smallint, smallint, smallint
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
  p_existing_member_ids uuid[],
  p_existing_member_seats smallint[],
  p_new_seat smallint,
  p_character_seed text,
  p_fun_focus_delta smallint,
  p_fun_joy_delta smallint,
  p_algorithm_version smallint default 4
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
  v_member_id uuid;
  v_member_count smallint;
  v_existing_member_count integer;
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
  if coalesce(cardinality(p_existing_member_ids), 0)
       <> coalesce(cardinality(p_existing_member_seats), 0)
     or exists (
       select 1
       from unnest(p_existing_member_ids, p_existing_member_seats)
         as assigned(member_id, assigned_seat)
       where assigned.member_id is null or assigned.assigned_seat is null
     ) then
    raise exception using errcode = '22023', message = 'INVALID_SEAT_ASSIGNMENTS';
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

  if v_classroom.member_count >= 12 then
    raise exception using errcode = 'P0001', message = 'CLASSROOM_FULL';
  end if;

  select count(*)::integer into v_existing_member_count
  from public.classroom_members
  where classroom_id = v_classroom.id
    and not is_owner;

  if coalesce(cardinality(p_existing_member_ids), 0) <> v_existing_member_count
     or exists (
       select 1
       from public.classroom_members member
       where member.classroom_id = v_classroom.id
         and not member.is_owner
         and not (member.id = any(p_existing_member_ids))
     )
     or exists (
       select 1
       from unnest(p_existing_member_ids) as supplied(member_id)
       where not exists (
         select 1
         from public.classroom_members member
         where member.classroom_id = v_classroom.id
           and not member.is_owner
           and member.id = supplied.member_id
       )
     ) then
    raise exception using errcode = 'P0001', message = 'CLASSROOM_CHANGED';
  end if;

  if p_new_seat is null
     or p_new_seat not between 0 and 11
     or p_new_seat = v_classroom.owner_seat
     or exists (
       select 1
       from unnest(p_existing_member_seats) as supplied(assigned_seat)
       where supplied.assigned_seat not between 0 and 11
         or supplied.assigned_seat = v_classroom.owner_seat
         or supplied.assigned_seat = p_new_seat
     )
     or (
       select count(distinct supplied.assigned_seat)
       from unnest(p_existing_member_seats) as supplied(assigned_seat)
     ) <> coalesce(cardinality(p_existing_member_seats), 0) then
    raise exception using errcode = '22023', message = 'INVALID_SEAT_ASSIGNMENTS';
  end if;

  update public.classroom_members member
  set
    seat_index = assigned.assigned_seat,
    algorithm_version = p_algorithm_version
  from unnest(p_existing_member_ids, p_existing_member_seats)
    as assigned(member_id, assigned_seat)
  where member.classroom_id = v_classroom.id
    and member.id = assigned.member_id;

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
    p_new_seat,
    p_relationship_type,
    p_character_seed,
    p_fun_focus_delta,
    p_fun_joy_delta,
    p_saju_chart,
    p_compatibility,
    p_algorithm_version
  ) returning id into v_member_id;

  update public.classrooms
  set
    member_count = member_count + 1,
    algorithm_version = p_algorithm_version
  where id = v_classroom.id
  returning public.classrooms.member_count into v_member_count;

  return query select
    'created'::text,
    v_classroom.id,
    v_member_id,
    p_new_seat,
    v_member_count;
end;
$$;

revoke all on function public.join_classroom(
  text, text, date, smallint, smallint, jsonb, jsonb, public.relationship_type,
  uuid[], smallint[], smallint, text, smallint, smallint, smallint
) from public;

grant execute on function public.join_classroom(
  text, text, date, smallint, smallint, jsonb, jsonb, public.relationship_type,
  uuid[], smallint[], smallint, text, smallint, smallint, smallint
) to anon, authenticated;
