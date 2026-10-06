create or replace function private.notify_marketplace_author_reply()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  post_row public.marketplace_posts%rowtype;
  recipient_id uuid;
begin
  select * into post_row
  from public.marketplace_posts
  where id = new.post_id;
  if not found or new.user_id <> post_row.seller_id then
    return new;
  end if;

  select user_id into recipient_id
  from public.marketplace_comments
  where post_id = new.post_id
    and id <> new.id
    and user_id <> post_row.seller_id
  order by created_at desc, id desc
  limit 1;

  if recipient_id is not null then
    insert into public.notifications (user_id, title, body, data)
    values (
      recipient_id,
      'Marketplace',
      post_row.seller_name || ' added a response after you. Click to view the post.',
      jsonb_build_object('type', 'marketplace_response', 'post_id', post_row.id)
    );
  end if;
  return new;
end;
$$;
revoke all on function private.notify_marketplace_author_reply() from public, anon, authenticated;
create trigger notify_marketplace_author_reply_after_insert
  after insert on public.marketplace_comments
  for each row execute function private.notify_marketplace_author_reply();

create or replace function private.notify_lost_found_author_reply()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  post_row public.lost_found_posts%rowtype;
  recipient_id uuid;
begin
  select * into post_row
  from public.lost_found_posts
  where id = new.post_id;
  if not found or new.user_id <> post_row.author_id then
    return new;
  end if;

  select user_id into recipient_id
  from public.lost_found_responses
  where post_id = new.post_id
    and id <> new.id
    and user_id <> post_row.author_id
  order by created_at desc, id desc
  limit 1;

  if recipient_id is not null then
    insert into public.notifications (user_id, title, body, data)
    values (
      recipient_id,
      'Lost and Found',
      post_row.author_name || ' added a response after you. Click to view the post.',
      jsonb_build_object('type', 'lost_found_response', 'post_id', post_row.id)
    );
  end if;
  return new;
end;
$$;
revoke all on function private.notify_lost_found_author_reply() from public, anon, authenticated;
create trigger notify_lost_found_author_reply_after_insert
  after insert on public.lost_found_responses
  for each row execute function private.notify_lost_found_author_reply();

create or replace function private.notify_freshers_author_reply()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  question_row public.freshers_questions%rowtype;
  recipient_id uuid;
begin
  select * into question_row
  from public.freshers_questions
  where id = new.question_id;
  if not found or new.author_id <> question_row.author_id then
    return new;
  end if;

  select author_id into recipient_id
  from public.freshers_answers
  where question_id = new.question_id
    and id <> new.id
    and author_id <> question_row.author_id
  order by created_at desc, id desc
  limit 1;

  if recipient_id is not null then
    insert into public.notifications (user_id, title, body, data)
    values (
      recipient_id,
      'Freshers'' Corner',
      question_row.author_name || ' added a response after you. Click to view the post.',
      jsonb_build_object('type', 'freshers_answer', 'question_id', question_row.id)
    );
  end if;
  return new;
end;
$$;
revoke all on function private.notify_freshers_author_reply() from public, anon, authenticated;
create trigger notify_freshers_author_reply_after_insert
  after insert on public.freshers_answers
  for each row execute function private.notify_freshers_author_reply();

create or replace function private.notify_study_help_author_reply()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  chat_row public.study_help_chats%rowtype;
  previous_sender_id uuid;
begin
  if new.message_kind = 'post_preview' then
    return new;
  end if;

  select * into chat_row
  from public.study_help_chats
  where id = new.chat_id;
  if not found or new.sender_id <> chat_row.author_id then
    return new;
  end if;

  select sender_id into previous_sender_id
  from public.study_help_messages
  where chat_id = new.chat_id
    and id <> new.id
  order by created_at desc, id desc
  limit 1;

  if previous_sender_id = chat_row.responder_id then
    insert into public.notifications (user_id, title, body, data)
    values (
      chat_row.responder_id,
      'Study Help',
      chat_row.author_name || ' added a response after you. Click to view the post.',
      jsonb_build_object('type', 'study_help_response', 'post_id', chat_row.post_id)
    );
  end if;
  return new;
end;
$$;
revoke all on function private.notify_study_help_author_reply() from public, anon, authenticated;
create trigger notify_study_help_author_reply_after_insert
  after insert on public.study_help_messages
  for each row execute function private.notify_study_help_author_reply();
