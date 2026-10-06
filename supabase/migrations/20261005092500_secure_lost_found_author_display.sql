grant select, insert, update on public.lost_found_posts to authenticated;
grant select, insert on public.lost_found_responses to authenticated;

create or replace function private.populate_lost_found_author()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if auth.uid() is null or auth.uid() <> new.author_id then
    raise exception 'Invalid author';
  end if;
  select p.full_name, p.student_id
    into new.author_name, new.author_student_id
  from public.campusmate_profiles p
  where p.user_id = new.author_id;
  if new.author_name is null or trim(new.author_name) = '' then
    new.author_name := 'UIU student';
  end if;
  if new.author_student_id is null then
    new.author_student_id := '';
  end if;
  if new.author_avatar_path is null
     or split_part(new.author_avatar_path, '/', 1) <> new.author_id::text
     or not exists (
       select 1 from storage.objects o
       where o.bucket_id = 'lost-found-images' and o.name = new.author_avatar_path
     ) then
    new.author_avatar_path := null;
  end if;
  return new;
end;
$$;

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
  new.author_name := old.author_name;
  new.author_student_id := old.author_student_id;
  new.author_avatar_path := old.author_avatar_path;
  return new;
end;
$$;
revoke all on function private.populate_lost_found_author() from public, anon, authenticated;
revoke all on function private.preserve_lost_found_author() from public, anon, authenticated;
create trigger preserve_lost_found_author_before_update
before update on public.lost_found_posts
for each row execute function private.preserve_lost_found_author();
