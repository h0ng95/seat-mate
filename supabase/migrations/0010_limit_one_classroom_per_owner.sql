begin;

create or replace function public.create_classroom(
  p_owner_name text,
  p_owner_birth_date date,
  p_owner_birth_hour smallint,
  p_owner_birth_minute smallint,
  p_owner_saju_chart jsonb,
  p_owner_seat smallint,
  p_owner_profile text,
  p_owner_character_seed text,
  p_owner_algorithm_seed text,
  p_algorithm_version smallint default 4
)
returns table (classroom_id uuid, share_code text, owner_member_id uuid)
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_classroom_id uuid;
  v_owner_member_id uuid;
  v_owner_user_id uuid := auth.uid();
  v_existing_share_code text;
  v_share_code text;
  v_attempt smallint := 0;
  v_owner_name text := trim(regexp_replace(p_owner_name, '\s+', ' ', 'g'));
begin
  if v_owner_user_id is null then
    raise exception using errcode = '42501', message = 'AUTH_REQUIRED';
  end if;

  perform pg_advisory_xact_lock(hashtextextended(v_owner_user_id::text, 0));
  select classroom.share_code
    into v_existing_share_code
  from public.classrooms classroom
  where classroom.owner_user_id = v_owner_user_id
    and (classroom.expires_at is null or classroom.expires_at > now())
  order by classroom.created_at desc
  limit 1;

  if v_existing_share_code is not null then
    raise exception using
      errcode = 'P0001',
      message = 'CLASSROOM_ALREADY_EXISTS',
      detail = v_existing_share_code;
  end if;

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
  if p_owner_seat not between 0 and 11 then
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
        owner_user_id,
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
        v_owner_user_id,
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

revoke all on function public.create_classroom(
  text, date, smallint, smallint, jsonb, smallint, text, text, text, smallint
) from public, anon;
grant execute on function public.create_classroom(
  text, date, smallint, smallint, jsonb, smallint, text, text, text, smallint
) to authenticated;

commit;
