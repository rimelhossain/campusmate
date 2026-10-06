create schema if not exists private;
revoke all on schema private from public, anon, authenticated;

alter table public.notifications
  add column if not exists dedupe_key text unique;

revoke update on public.notifications from authenticated;
grant update (read_at) on public.notifications to authenticated;

create or replace function private.notify_marketplace_response()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  post_row public.marketplace_posts%rowtype;
  profile_row public.campusmate_profiles%rowtype;
begin
  select * into post_row
  from public.marketplace_posts
  where id = new.post_id;
  if not found or post_row.seller_id = new.user_id then
    return new;
  end if;

  select * into profile_row
  from public.campusmate_profiles
  where user_id = new.user_id;

  insert into public.notifications (user_id, title, body, data)
  values (
    post_row.seller_id,
    'Marketplace',
    coalesce(nullif(trim(profile_row.full_name), ''), 'A student') ||
      '(' || coalesce(profile_row.student_id, '') ||
      ') has responded to your marketplace post.',
    jsonb_build_object('type', 'marketplace_response', 'post_id', post_row.id)
  );
  return new;
end;
$$;
revoke all on function private.notify_marketplace_response() from public, anon, authenticated;
create trigger notify_marketplace_response_after_insert
  after insert on public.marketplace_comments
  for each row execute function private.notify_marketplace_response();

create or replace function private.notify_lost_found_response()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  post_row public.lost_found_posts%rowtype;
  profile_row public.campusmate_profiles%rowtype;
begin
  select * into post_row
  from public.lost_found_posts
  where id = new.post_id;
  if not found or post_row.author_id = new.user_id then
    return new;
  end if;

  select * into profile_row
  from public.campusmate_profiles
  where user_id = new.user_id;

  insert into public.notifications (user_id, title, body, data)
  values (
    post_row.author_id,
    'Lost and Found',
    coalesce(nullif(trim(profile_row.full_name), ''), 'A student') ||
      '(' || coalesce(profile_row.student_id, '') ||
      ') has responded to your Lost and Found post.',
    jsonb_build_object('type', 'lost_found_response', 'post_id', post_row.id)
  );
  return new;
end;
$$;
revoke all on function private.notify_lost_found_response() from public, anon, authenticated;
create trigger notify_lost_found_response_after_insert
  after insert on public.lost_found_responses
  for each row execute function private.notify_lost_found_response();

create or replace function private.notify_freshers_answer()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  question_row public.freshers_questions%rowtype;
begin
  select * into question_row
  from public.freshers_questions
  where id = new.question_id;
  if not found or question_row.author_id = new.author_id then
    return new;
  end if;

  insert into public.notifications (user_id, title, body, data)
  values (
    question_row.author_id,
    'Freshers'' Corner',
    coalesce(nullif(trim(new.author_name), ''), 'A student') ||
      '(' || coalesce(new.author_student_id, '') ||
      ') has answered your question in the Freshers'' Corner. Click to view their response.',
    jsonb_build_object('type', 'freshers_answer', 'question_id', question_row.id)
  );
  return new;
end;
$$;
revoke all on function private.notify_freshers_answer() from public, anon, authenticated;
create trigger notify_freshers_answer_after_insert
  after insert on public.freshers_answers
  for each row execute function private.notify_freshers_answer();

create or replace function private.send_tuition_reminders()
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  local_today date := (now() at time zone 'Asia/Dhaka')::date;
  installment_row record;
  profile_row record;
  days_remaining integer;
  message_body text;
begin
  for installment_row in
    select id, label, due_on
    from public.tuition_installments
    where due_on is not null
      and due_on in (local_today, local_today + 3)
  loop
    days_remaining := installment_row.due_on - local_today;
    if days_remaining = 3 then
      message_body := '3 days remaining before the upcoming deadline. Click to view the deadlines and calculate fee amounts.';
    else
      message_body := 'Today is the last day of the current installment for paying the tuition fees. Failing to pay the required amount today will add BDT 500 as a late fine.';
    end if;

    for profile_row in
      select user_id from public.campusmate_profiles
    loop
      insert into public.notifications
        (user_id, title, body, data, dedupe_key)
      values (
        profile_row.user_id,
        'Tuition fee reminder',
        message_body,
        jsonb_build_object(
          'type', 'tuition_reminder',
          'installment_id', installment_row.id,
          'days_remaining', days_remaining
        ),
        'tuition:' || installment_row.id || ':' || installment_row.due_on || ':' || days_remaining || ':' || profile_row.user_id
      )
      on conflict (dedupe_key) do nothing;
    end loop;
  end loop;
end;
$$;
revoke all on function private.send_tuition_reminders() from public, anon, authenticated;

create or replace function public.open_study_help_chat(
  post_id_input uuid,
  responder_avatar_path_input text default null
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  current_user_id uuid := auth.uid();
  post_row public.study_help_posts%rowtype;
  profile_row public.campusmate_profiles%rowtype;
  chat_id uuid;
begin
  if current_user_id is null then
    raise exception 'Please sign in to respond.';
  end if;
  select * into post_row
  from public.study_help_posts
  where id = post_id_input
  for update;
  if not found then
    raise exception 'This study help post could not be found.';
  end if;
  if post_row.is_solved then
    raise exception 'This post is already solved.';
  end if;
  if post_row.author_id = current_user_id then
    raise exception 'You cannot respond to your own post.';
  end if;
  select * into profile_row
  from public.campusmate_profiles
  where user_id = current_user_id;
  if not found then
    raise exception 'A student profile is required to respond.';
  end if;
  if responder_avatar_path_input is not null and (
    split_part(responder_avatar_path_input, '/', 1) <> current_user_id::text
    or not exists (
      select 1 from storage.objects o
      where o.bucket_id = 'study-help-media'
        and o.name = responder_avatar_path_input
    )
  ) then
    responder_avatar_path_input := null;
  end if;

  select id into chat_id
  from public.study_help_chats
  where post_id = post_id_input
    and author_id = post_row.author_id
    and responder_id = current_user_id;

  if chat_id is null then
    insert into public.study_help_chats (
      post_id, author_id, responder_id, author_name, author_student_id,
      author_avatar_path, responder_name, responder_student_id,
      responder_avatar_path
    ) values (
      post_row.id, post_row.author_id, current_user_id, post_row.author_name,
      post_row.author_student_id, post_row.author_avatar_path,
      profile_row.full_name, profile_row.student_id,
      responder_avatar_path_input
    )
    on conflict (post_id, author_id, responder_id) do nothing
    returning id into chat_id;

    if chat_id is not null then
      insert into public.study_help_messages (
        chat_id, sender_id, message_kind, preview_topic,
        preview_course, preview_image_path
      ) values (
        chat_id, current_user_id, 'post_preview', post_row.topic_name,
        post_row.course_name, post_row.image_paths[1]
      );
    else
      select id into chat_id
      from public.study_help_chats
      where post_id = post_id_input
        and author_id = post_row.author_id
        and responder_id = current_user_id;
    end if;
  else
    update public.study_help_chats
    set responder_closed_at = null
    where id = chat_id and responder_closed_at is not null;
  end if;

  insert into public.notifications (user_id, title, body, data)
  values (
    post_row.author_id,
    'Study Help',
    profile_row.full_name || '(' || profile_row.student_id ||
      ') has responded to your Study help post.',
    jsonb_build_object('type', 'study_help_response', 'post_id', post_row.id)
  );
  return chat_id;
end;
$$;
revoke all on function public.open_study_help_chat(uuid, text) from public, anon;
grant execute on function public.open_study_help_chat(uuid, text) to authenticated;

create extension if not exists pg_cron with schema pg_catalog;
do $$
begin
  if exists (select 1 from cron.job where jobname = 'campusmate-tuition-reminders') then
    perform cron.unschedule(jobid)
    from cron.job
    where jobname = 'campusmate-tuition-reminders';
  end if;
  perform cron.schedule(
    'campusmate-tuition-reminders',
    '5 18 * * *',
    'select private.send_tuition_reminders();'
  );
end;
$$;

do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'notifications'
  ) then
    alter publication supabase_realtime add table public.notifications;
  end if;
end;
$$;
