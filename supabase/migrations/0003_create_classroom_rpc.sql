create or replace function public.normalize_nickname(value text)
returns text
language sql
immutable
strict
set search_path = ''
as $$
  select lower(regexp_replace(trim(value), '\s+', ' ', 'g'));
$$;

revoke all on function public.normalize_nickname(text) from public;

create or replace function public.generate_classroom_share_code()
returns text
language sql
volatile
set search_path = ''
as $$
  select substr(encode(extensions.gen_random_bytes(8), 'hex'), 1, 10);
$$;

revoke all on function public.generate_classroom_share_code() from public;

create or replace function public.create_classroom(
  p_owner_name text,
  p_owner_birth_date date,
  p_owner_seat smallint,
  p_owner_profile text,
  p_owner_character_seed text,
  p_algorithm_version smallint default 1
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
        owner_seat,
        owner_profile,
        owner_character_seed,
        algorithm_version
      ) values (
        v_share_code,
        v_owner_name,
        public.normalize_nickname(v_owner_name),
        p_owner_birth_date,
        p_owner_seat,
        p_owner_profile,
        p_owner_character_seed,
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
    is_owner,
    seat_index,
    relationship_type,
    character_seed,
    algorithm_version
  ) values (
    v_classroom_id,
    v_owner_name,
    public.normalize_nickname(v_owner_name),
    p_owner_birth_date,
    true,
    p_owner_seat,
    'owner',
    p_owner_character_seed,
    p_algorithm_version
  ) returning id into v_owner_member_id;

  return query select v_classroom_id, v_share_code, v_owner_member_id;
end;
$$;
