create table public.campusmate_profiles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  full_name text not null check (char_length(trim(full_name)) between 2 and 120),
  student_id text not null unique check (char_length(trim(student_id)) between 4 and 32),
  avatar_path text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
alter table public.campusmate_profiles enable row level security;
create policy "Profiles are readable by their owner" on public.campusmate_profiles
  for select to authenticated using ((select auth.uid()) = user_id);
create policy "Profiles are editable by their owner" on public.campusmate_profiles
  for update to authenticated using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);
grant select, update on public.campusmate_profiles to authenticated;

create or replace function public.handle_campusmate_user_signup()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  insert into public.campusmate_profiles (user_id, full_name, student_id, avatar_path)
  values (
    new.id,
    nullif(trim(new.raw_user_meta_data ->> 'full_name'), ''),
    nullif(trim(new.raw_user_meta_data ->> 'student_id'), ''),
    nullif(trim(new.raw_user_meta_data ->> 'avatar_path'), '')
  );
  return new;
end;
$$;
revoke all on function public.handle_campusmate_user_signup() from public, anon, authenticated;
create trigger on_campusmate_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_campusmate_user_signup();

create table public.tuition_installments (
  id smallint primary key check (id between 1 and 3),
  label text not null,
  due_on date,
  updated_at timestamptz not null default now()
);
insert into public.tuition_installments (id, label) values
  (1, 'Installment 1'), (2, 'Installment 2'), (3, 'Installment 3');
alter table public.tuition_installments enable row level security;
create policy "Authenticated users can read tuition deadlines" on public.tuition_installments
  for select to authenticated using (true);
grant select on public.tuition_installments to authenticated;

create table public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  title text not null,
  body text not null default '',
  data jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  read_at timestamptz
);
create index notifications_user_created_idx on public.notifications (user_id, created_at desc);
alter table public.notifications enable row level security;
create policy "Users can read their notifications" on public.notifications
  for select to authenticated using ((select auth.uid()) = user_id);
create policy "Users can mark their notifications read" on public.notifications
  for update to authenticated using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);
grant select, update on public.notifications to authenticated;

create table public.push_devices (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  fcm_token text not null unique,
  platform text not null check (platform in ('android', 'ios')),
  updated_at timestamptz not null default now()
);
create index push_devices_user_idx on public.push_devices (user_id);
alter table public.push_devices enable row level security;
create policy "Users manage their own push devices" on public.push_devices
  for all to authenticated using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);
grant select, insert, update, delete on public.push_devices to authenticated;

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('profile-avatars', 'profile-avatars', false, 5242880, array['image/jpeg','image/png','image/webp'])
on conflict (id) do update set public = false, file_size_limit = 5242880,
  allowed_mime_types = array['image/jpeg','image/png','image/webp'];
create policy "Users read their own avatar files" on storage.objects for select to authenticated
  using (bucket_id = 'profile-avatars' and (storage.foldername(name))[1] = (select auth.uid())::text);
create policy "Users upload their own avatar files" on storage.objects for insert to authenticated
  with check (bucket_id = 'profile-avatars' and (storage.foldername(name))[1] = (select auth.uid())::text);
create policy "Users update their own avatar files" on storage.objects for update to authenticated
  using (bucket_id = 'profile-avatars' and (storage.foldername(name))[1] = (select auth.uid())::text)
  with check (bucket_id = 'profile-avatars' and (storage.foldername(name))[1] = (select auth.uid())::text);
create policy "Users delete their own avatar files" on storage.objects for delete to authenticated
  using (bucket_id = 'profile-avatars' and (storage.foldername(name))[1] = (select auth.uid())::text);
