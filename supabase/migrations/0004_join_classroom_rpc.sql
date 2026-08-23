create or replace function public.join_classroom(
  p_share_code text,
  p_name text,
  p_birth_date date,
  p_relationship_type public.relationship_type,
  p_preferred_seats smallint[],
  p_character_seed text,
  p_fun_focus_delta smallint,
  p_fun_joy_delta smallint,
  p_algorithm_version smallint default 1
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
    seat_index,
    relationship_type,
    character_seed,
    fun_focus_delta,
    fun_joy_delta,
    algorithm_version
  ) values (
    v_classroom.id,
    v_name,
    public.normalize_nickname(v_name),
    p_birth_date,
    v_seat,
    p_relationship_type,
    p_character_seed,
    p_fun_focus_delta,
    p_fun_joy_delta,
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
