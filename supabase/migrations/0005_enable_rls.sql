alter table public.classrooms enable row level security;
alter table public.classroom_members enable row level security;

revoke all on table public.classrooms from anon, authenticated;
revoke all on table public.classroom_members from anon, authenticated;

grant select on public.public_classrooms to anon, authenticated;
grant select on public.public_classroom_members to anon, authenticated;

revoke all on function public.create_classroom(
  text, date, smallint, text, text, smallint
) from public;
revoke all on function public.join_classroom(
  text, text, date, public.relationship_type, smallint[], text, smallint, smallint, smallint
) from public;

grant execute on function public.create_classroom(
  text, date, smallint, text, text, smallint
) to anon, authenticated;
grant execute on function public.join_classroom(
  text, text, date, public.relationship_type, smallint[], text, smallint, smallint, smallint
) to anon, authenticated;
