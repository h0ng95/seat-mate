begin;

select plan(10);

select has_table('public', 'classrooms', 'classrooms table exists');
select has_table('public', 'classroom_members', 'classroom_members table exists');
select has_function('public', 'create_classroom', 'create_classroom RPC exists');
select has_function('public', 'join_classroom', 'join_classroom RPC exists');

create temporary table created_classroom as
select * from public.create_classroom(
  '재홍',
  date '1995-06-12',
  null::smallint,
  null::smallint,
  '{"engine_version":"saju-0.1.1"}'::jsonb,
  4::smallint,
  'center',
  'owner-seed',
  'owner-algorithm-seed',
  2::smallint
);

select is(
  (select member_count from public.classrooms where id = (select classroom_id from created_classroom)),
  1::smallint,
  'classroom starts with one member'
);

select is(
  (select count(*)::integer from public.classroom_members where classroom_id = (select classroom_id from created_classroom)),
  1,
  'owner member is inserted'
);

create temporary table first_join as
select * from public.join_classroom(
  (select share_code from created_classroom),
  '민수',
  date '1996-03-17',
  null::smallint,
  null::smallint,
  '{"engine_version":"saju-0.1.1"}'::jsonb,
  '{"heart_score":82,"rules_version":"compatibility-1"}'::jsonb,
  'buddy',
  array[]::uuid[],
  array[]::smallint[],
  5::smallint,
  'member-seed',
  (-8)::smallint,
  92::smallint,
  2::smallint
);

select is((select result_status from first_join), 'created', 'new member is created');

select is(
  (
    select result_status from public.join_classroom(
      (select share_code from created_classroom),
      '민수',
      date '1996-03-17',
      null::smallint,
      null::smallint,
      '{"engine_version":"saju-0.1.1"}'::jsonb,
      '{"heart_score":82,"rules_version":"compatibility-1"}'::jsonb,
      'buddy',
      array[]::uuid[],
      array[]::smallint[],
      5::smallint,
      'member-seed',
      (-8)::smallint,
      92::smallint,
      2::smallint
    )
  ),
  'duplicate',
  'duplicate member returns the existing seat'
);

create temporary table second_join as
select * from public.join_classroom(
  (select share_code from created_classroom),
  '소라',
  date '1998-02-21',
  null::smallint,
  null::smallint,
  '{"engine_version":"saju-0.1.1"}'::jsonb,
  '{"heart_score":94,"rules_version":"compatibility-1"}'::jsonb,
  'caretaker',
  array[(select member_id from first_join)]::uuid[],
  array[6]::smallint[],
  5::smallint,
  'second-member-seed',
  10::smallint,
  94::smallint,
  4::smallint
);

select is(
  (
    select seat_index
    from public.classroom_members
    where id = (select member_id from first_join)
  ),
  6::smallint,
  'existing member is reseated when a new member joins'
);

select is(
  (select seat_index from second_join),
  5::smallint,
  'new member receives the recalculated seat'
);

select * from finish();
rollback;
