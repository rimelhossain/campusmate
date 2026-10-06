create schema if not exists private;
revoke all on schema private from public, anon, authenticated;

create table if not exists public.lost_found_posts (
  id uuid primary key default gen_random_uuid(),
  author_id uuid not null references auth.users(id) on delete cascade,
  author_name text not null default 'UIU student',
  author_student_id text not null default '',
  author_avatar_path text,
  title text not null check (char_length(trim(title)) between 1 and 120),
  post_type text not null check (post_type in ('lost', 'found')),
  description text not null check (char_length(trim(description)) between 1 and 5000),
  location text not null check (char_length(trim(location)) between 1 and 300),
  occurred_at timestamptz not null default now(),
  image_paths text[] not null default '{}',
  is_resolved boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.lost_found_responses (
  id uuid primary key default gen_random_uuid(),
  post_id uuid not null references public.lost_found_posts(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  user_name text not null default 'UIU student',
  body text not null check (char_length(trim(body)) between 1 and 2000),
  created_at timestamptz not null default now()
);

create index if not exists lost_found_posts_feed_idx on public.lost_found_posts (is_resolved, created_at desc);
create index if not exists lost_found_responses_post_idx on public.lost_found_responses (post_id, created_at);

alter table public.lost_found_posts enable row level security;
alter table public.lost_found_responses enable row level security;

create policy "Signed in users can view lost and found posts"
on public.lost_found_posts for select to authenticated using (true);
create policy "Users can create their own lost and found posts"
on public.lost_found_posts for insert to authenticated with check (auth.uid() = author_id);
create policy "Authors can update their own lost and found posts"
on public.lost_found_posts for update to authenticated using (auth.uid() = author_id) with check (auth.uid() = author_id);

create policy "Signed in users can view lost and found responses"
on public.lost_found_responses for select to authenticated using (true);
create policy "Users can respond to unresolved posts"
on public.lost_found_responses for insert to authenticated
with check (
  auth.uid() = user_id
  and exists (
    select 1 from public.lost_found_posts p
    where p.id = post_id and p.is_resolved = false
  )
);

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
revoke all on function private.populate_lost_found_author() from public, anon, authenticated;
create trigger populate_lost_found_author_before_insert
before insert on public.lost_found_posts
for each row execute function private.populate_lost_found_author();

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('lost-found-images', 'lost-found-images', false, 10485760, array['image/jpeg','image/png','image/webp'])
on conflict (id) do update set public = false, file_size_limit = excluded.file_size_limit, allowed_mime_types = excluded.allowed_mime_types;

create policy "Signed in users can view lost and found images"
on storage.objects for select to authenticated
using (bucket_id = 'lost-found-images');
create policy "Users can upload their own lost and found images"
on storage.objects for insert to authenticated
with check (bucket_id = 'lost-found-images' and (storage.foldername(name))[1] = auth.uid()::text);
create policy "Users can delete their own lost and found images"
on storage.objects for delete to authenticated
using (bucket_id = 'lost-found-images' and (storage.foldername(name))[1] = auth.uid()::text);
