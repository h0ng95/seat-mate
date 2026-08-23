begin;

select plan(8);

select has_table('public', 'classrooms', 'classrooms table exists');
select has_table('public', 'classroom_members', 'classroom_members table exists');
select has_function('public', 'create_classroom', 'create_classroom RPC exists');
select has_function('public', 'join_classroom', 'join_classroom RPC exists');

create temporary table created_classroom as
select * from public.create_classroom(
  '재홍',
  date '1995-06-12',
  4::smallint,
  'center',
  'owner-seed',
  1::smallint
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
  'buddy',
  array[5, 3, 2, 8, 0, 6, 1, 7]::smallint[],
  'member-seed',
  (-8)::smallint,
  92::smallint,
  1::smallint
);

select is((select result_status from first_join), 'created', 'new member is created');

select is(
  (
    select result_status from public.join_classroom(
      (select share_code from created_classroom),
      '민수',
      date '1996-03-17',
      'buddy',
      array[5, 3, 2, 8, 0, 6, 1, 7]::smallint[],
      'member-seed',
      (-8)::smallint,
      92::smallint,
      1::smallint
    )
  ),
  'duplicate',
  'duplicate member returns the existing seat'
);

select * from finish();
rollback;
