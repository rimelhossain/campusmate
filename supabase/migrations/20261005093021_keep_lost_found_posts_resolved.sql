create or replace function private.preserve_lost_found_author()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if auth.uid() is null or auth.uid() <> old.author_id or new.author_id <> old.author_id then
    raise exception 'Invalid author';
  end if;
  if old.is_resolved and not new.is_resolved then
    raise exception 'Resolved posts cannot be reopened';
  end if;
  new.author_name := old.author_name;
  new.author_student_id := old.author_student_id;
  new.author_avatar_path := old.author_avatar_path;
  return new;
end;
$$;
revoke all on function private.preserve_lost_found_author() from public, anon, authenticated;
