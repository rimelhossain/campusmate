create table public.study_help_posts (
  id uuid primary key default gen_random_uuid(),
  author_id uuid not null references auth.users(id) on delete cascade,
  author_name text not null default 'UIU student',
  author_student_id text not null default '',
  author_avatar_path text,
  course_name text not null check (char_length(trim(course_name)) between 1 and 120),
  topic_name text not null check (char_length(trim(topic_name)) between 1 and 160),
  description text not null check (char_length(trim(description)) between 1 and 5000),
  image_paths text[] not null default '{}',
  is_solved boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index study_help_posts_feed_idx on public.study_help_posts (is_solved, created_at desc);
alter table public.study_help_posts enable row level security;
create policy "Authenticated students can view study help posts"
  on public.study_help_posts for select to authenticated using (true);
create policy "Authors can create their study help posts"
  on public.study_help_posts for insert to authenticated with check (auth.uid() = author_id);
create policy "Authors can solve their own study help posts"
  on public.study_help_posts for update to authenticated using (auth.uid() = author_id) with check (auth.uid() = author_id);
grant select, insert, update on public.study_help_posts to authenticated;

create or replace function private.populate_study_help_author()
returns trigger language plpgsql security definer set search_path = ''
as $$
begin
  if auth.uid() is null or auth.uid() <> new.author_id then
    raise exception 'Invalid author';
  end if;
  select p.full_name, p.student_id into new.author_name, new.author_student_id
  from public.campusmate_profiles p where p.user_id = new.author_id;
  if new.author_name is null or trim(new.author_name) = '' then new.author_name := 'UIU student'; end if;
  if new.author_student_id is null then new.author_student_id := ''; end if;
  if new.author_avatar_path is null
     or split_part(new.author_avatar_path, '/', 1) <> new.author_id::text
     or not exists (select 1 from storage.objects o where o.bucket_id = 'study-help-media' and o.name = new.author_avatar_path) then
    new.author_avatar_path := null;
  end if;
  return new;
end;
$$;
revoke all on function private.populate_study_help_author() from public, anon, authenticated;
create trigger populate_study_help_author_before_insert
  before insert on public.study_help_posts for each row execute function private.populate_study_help_author();

create or replace function private.protect_study_help_author()
returns trigger language plpgsql security definer set search_path = ''
as $$
begin
  if auth.uid() is null or auth.uid() <> old.author_id or new.author_id <> old.author_id then
    raise exception 'Invalid author';
  end if;
  if old.is_solved and not new.is_solved then
    raise exception 'Solved study help posts cannot be reopened';
  end if;
  new.author_name := old.author_name;
  new.author_student_id := old.author_student_id;
  new.author_avatar_path := old.author_avatar_path;
  return new;
end;
$$;
revoke all on function private.protect_study_help_author() from public, anon, authenticated;
create trigger protect_study_help_author_before_update
  before update on public.study_help_posts for each row execute function private.protect_study_help_author();

create table public.study_help_chats (
  id uuid primary key default gen_random_uuid(),
  post_id uuid not null references public.study_help_posts(id) on delete cascade,
  author_id uuid not null references auth.users(id) on delete cascade,
  responder_id uuid not null references auth.users(id) on delete cascade,
  author_name text not null,
  author_student_id text not null,
  author_avatar_path text,
  responder_name text not null,
  responder_student_id text not null,
  responder_avatar_path text,
  author_closed_at timestamptz,
  responder_closed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint study_help_chat_participants_differ check (author_id <> responder_id),
  constraint study_help_one_chat_per_post_pair unique (post_id, author_id, responder_id)
);
create index study_help_chats_author_idx on public.study_help_chats (author_id, updated_at desc);
create index study_help_chats_responder_idx on public.study_help_chats (responder_id, updated_at desc);
alter table public.study_help_chats enable row level security;
create policy "Participants can view their open side of study help chats"
  on public.study_help_chats for select to authenticated
  using (
    (auth.uid() = author_id and author_closed_at is null)
    or (auth.uid() = responder_id and responder_closed_at is null)
  );
grant select on public.study_help_chats to authenticated;

create table public.study_help_messages (
  id uuid primary key default gen_random_uuid(),
  chat_id uuid not null references public.study_help_chats(id) on delete cascade,
  sender_id uuid not null references auth.users(id) on delete cascade,
  message_kind text not null check (message_kind in ('text', 'image', 'post_preview')),
  body text,
  attachment_path text,
  preview_topic text,
  preview_course text,
  preview_image_path text,
  created_at timestamptz not null default now(),
  constraint study_help_message_content_valid check (
    (message_kind = 'text' and char_length(trim(coalesce(body, ''))) between 1 and 4000 and attachment_path is null and preview_topic is null)
    or (message_kind = 'image' and attachment_path is not null and (body is null or char_length(body) <= 1000) and preview_topic is null)
    or (message_kind = 'post_preview' and preview_topic is not null and preview_course is not null and attachment_path is null)
  )
);
create index study_help_messages_chat_created_idx on public.study_help_messages (chat_id, created_at);
alter table public.study_help_messages enable row level security;
create policy "Open chat participants can read messages"
  on public.study_help_messages for select to authenticated using (
    exists (
      select 1 from public.study_help_chats c where c.id = chat_id and (
        (c.author_id = auth.uid() and c.author_closed_at is null)
        or (c.responder_id = auth.uid() and c.responder_closed_at is null)
      )
    )
  );
create policy "Open chat participants can send messages"
  on public.study_help_messages for insert to authenticated with check (
    sender_id = auth.uid()
    and message_kind in ('text', 'image')
    and exists (
      select 1 from public.study_help_chats c where c.id = chat_id and (
        (c.author_id = auth.uid() and c.author_closed_at is null)
        or (c.responder_id = auth.uid() and c.responder_closed_at is null)
      )
    )
    and (
      attachment_path is null
      or (
        split_part(attachment_path, '/', 1) = auth.uid()::text
        and exists (select 1 from storage.objects o where o.bucket_id = 'study-help-media' and o.name = attachment_path)
      )
    )
  );
grant select, insert on public.study_help_messages to authenticated;

create or replace function private.bump_study_help_chat_updated_at()
returns trigger language plpgsql security definer set search_path = ''
as $$
begin
  update public.study_help_chats set updated_at = new.created_at where id = new.chat_id;
  return new;
end;
$$;
revoke all on function private.bump_study_help_chat_updated_at() from public, anon, authenticated;
create trigger bump_study_help_chat_updated_at_after_message
  after insert on public.study_help_messages for each row execute function private.bump_study_help_chat_updated_at();

create or replace function public.open_study_help_chat(post_id_input uuid, responder_avatar_path_input text default null)
returns uuid language plpgsql security definer set search_path = ''
as $$
declare
  current_user_id uuid := auth.uid();
  post_row public.study_help_posts%rowtype;
  profile_row public.campusmate_profiles%rowtype;
  chat_id uuid;
begin
  if current_user_id is null then raise exception 'Please sign in to respond.'; end if;
  select * into post_row from public.study_help_posts where id = post_id_input for update;
  if not found then raise exception 'This study help post could not be found.'; end if;
  if post_row.is_solved then raise exception 'This post is already solved.'; end if;
  if post_row.author_id = current_user_id then raise exception 'You cannot respond to your own post.'; end if;
  select * into profile_row from public.campusmate_profiles where user_id = current_user_id;
  if not found then raise exception 'A student profile is required to respond.'; end if;
  if responder_avatar_path_input is not null and (
    split_part(responder_avatar_path_input, '/', 1) <> current_user_id::text
    or not exists (select 1 from storage.objects o where o.bucket_id = 'study-help-media' and o.name = responder_avatar_path_input)
  ) then responder_avatar_path_input := null; end if;

  select id into chat_id from public.study_help_chats
    where post_id = post_id_input and author_id = post_row.author_id and responder_id = current_user_id;
  if chat_id is null then
    insert into public.study_help_chats (
      post_id, author_id, responder_id, author_name, author_student_id,
      author_avatar_path, responder_name, responder_student_id, responder_avatar_path
    ) values (
      post_row.id, post_row.author_id, current_user_id, post_row.author_name,
      post_row.author_student_id, post_row.author_avatar_path, profile_row.full_name,
      profile_row.student_id, responder_avatar_path_input
    ) on conflict (post_id, author_id, responder_id) do nothing returning id into chat_id;
    if chat_id is not null then
      insert into public.study_help_messages (
        chat_id, sender_id, message_kind, preview_topic, preview_course, preview_image_path
      ) values (
        chat_id, current_user_id, 'post_preview', post_row.topic_name,
        post_row.course_name, post_row.image_paths[1]
      );
    else
      select id into chat_id from public.study_help_chats
        where post_id = post_id_input and author_id = post_row.author_id and responder_id = current_user_id;
    end if;
  else
    update public.study_help_chats set responder_closed_at = null where id = chat_id and responder_closed_at is not null;
  end if;
  return chat_id;
end;
$$;
revoke all on function public.open_study_help_chat(uuid, text) from public, anon;
grant execute on function public.open_study_help_chat(uuid, text) to authenticated;

create or replace function public.close_study_help_chat(chat_id_input uuid)
returns boolean language plpgsql security definer set search_path = ''
as $$
declare
  current_user_id uuid := auth.uid();
  chat_row public.study_help_chats%rowtype;
begin
  if current_user_id is null then raise exception 'Please sign in to close this chat.'; end if;
  select * into chat_row from public.study_help_chats where id = chat_id_input for update;
  if not found or (chat_row.author_id <> current_user_id and chat_row.responder_id <> current_user_id) then raise exception 'Chat not found.'; end if;
  if current_user_id = chat_row.author_id then
    update public.study_help_chats set author_closed_at = coalesce(author_closed_at, now()) where id = chat_id_input;
  else
    update public.study_help_chats set responder_closed_at = coalesce(responder_closed_at, now()) where id = chat_id_input;
  end if;
  select * into chat_row from public.study_help_chats where id = chat_id_input;
  if chat_row.author_closed_at is not null and chat_row.responder_closed_at is not null then
    delete from public.study_help_chats where id = chat_id_input;
    return true;
  end if;
  return false;
end;
$$;
revoke all on function public.close_study_help_chat(uuid) from public, anon;
grant execute on function public.close_study_help_chat(uuid) to authenticated;

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('study-help-media', 'study-help-media', false, 10485760, array['image/jpeg','image/png','image/webp'])
on conflict (id) do update set public = false, file_size_limit = excluded.file_size_limit, allowed_mime_types = excluded.allowed_mime_types;
create policy "Users can upload their own study help media"
  on storage.objects for insert to authenticated
  with check (bucket_id = 'study-help-media' and (storage.foldername(name))[1] = auth.uid()::text);
create policy "Students can view study help post and open chat media"
  on storage.objects for select to authenticated using (
    bucket_id = 'study-help-media' and (
      exists (select 1 from public.study_help_posts p where storage.objects.name = any(p.image_paths) or p.author_avatar_path = storage.objects.name)
      or exists (
        select 1 from public.study_help_chats c where c.author_avatar_path = storage.objects.name
          and (c.author_id = auth.uid() or c.responder_id = auth.uid())
          and ((c.author_id = auth.uid() and c.author_closed_at is null) or (c.responder_id = auth.uid() and c.responder_closed_at is null))
      )
      or exists (
        select 1 from public.study_help_chats c where c.responder_avatar_path = storage.objects.name
          and (c.author_id = auth.uid() or c.responder_id = auth.uid())
          and ((c.author_id = auth.uid() and c.author_closed_at is null) or (c.responder_id = auth.uid() and c.responder_closed_at is null))
      )
      or exists (
        select 1 from public.study_help_messages m join public.study_help_chats c on c.id = m.chat_id
        where m.attachment_path = storage.objects.name
          and ((c.author_id = auth.uid() and c.author_closed_at is null) or (c.responder_id = auth.uid() and c.responder_closed_at is null))
      )
    )
  );

do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'study_help_messages'
  ) then
    alter publication supabase_realtime add table public.study_help_messages;
  end if;
end;
$$;
