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
  created_at
from public.classroom_members;

comment on view public.public_classrooms is
  'Public classroom fields. Birth dates and normalized names are intentionally omitted.';

comment on view public.public_classroom_members is
  'Public member fields. Birth dates and normalized names are intentionally omitted.';
