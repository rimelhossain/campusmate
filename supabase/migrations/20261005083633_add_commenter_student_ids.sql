alter table public.marketplace_comments
  add column student_id text;

create or replace function public.set_marketplace_comment_student_id()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  select p.student_id
    into new.student_id
  from public.campusmate_profiles p
  where p.user_id = new.user_id;

  if new.student_id is null then
    raise exception 'A student profile is required to respond.';
  end if;

  return new;
end;
$$;

revoke all on function public.set_marketplace_comment_student_id()
  from public, anon, authenticated;

create trigger set_marketplace_comment_student_id_before_insert
before insert on public.marketplace_comments
for each row execute function public.set_marketplace_comment_student_id();
