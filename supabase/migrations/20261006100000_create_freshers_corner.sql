create table public.freshers_faqs (
  id uuid primary key default gen_random_uuid(),
  question text not null unique check (char_length(trim(question)) between 1 and 500),
  answer text not null check (char_length(trim(answer)) between 1 and 10000),
  display_order integer not null default 0,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.freshers_faqs enable row level security;
create policy "Authenticated students can read active freshers FAQs"
  on public.freshers_faqs for select to authenticated
  using (is_active or (select auth.jwt() -> 'app_metadata' ->> 'role') = 'admin');
create policy "Admins can add freshers FAQs"
  on public.freshers_faqs for insert to authenticated
  with check ((select auth.jwt() -> 'app_metadata' ->> 'role') = 'admin');
create policy "Admins can update freshers FAQs"
  on public.freshers_faqs for update to authenticated
  using ((select auth.jwt() -> 'app_metadata' ->> 'role') = 'admin')
  with check ((select auth.jwt() -> 'app_metadata' ->> 'role') = 'admin');
create policy "Admins can delete freshers FAQs"
  on public.freshers_faqs for delete to authenticated
  using ((select auth.jwt() -> 'app_metadata' ->> 'role') = 'admin');
grant select, insert, update, delete on public.freshers_faqs to authenticated;

insert into public.freshers_faqs (question, answer, display_order)
values (
  'What is Waiver and what is scholarship?',
  'Waiver is a discount applied on the tuition fees which is given based on the HSC result. 25% waiver is given if you have GPA 5 with the optional subjects and 50% waiver is given if you have GPA 5 without the optional subject. You have to keep holding CGPA 3.5+ to continue getting this discount every trimester. On the other hand, Scholarship is a discount applied on the tuition fees which is given based on the trimester results. If you can rank within top 2% of the students in the university, you will get 100% scholarship. Top 3% to top 5% gets 50% scholarship and top 6% to top 10% will get 25% scholarship. This discount applies as long as you keep ranking in the top positions.',
  1
)
on conflict (question) do nothing;

create table public.freshers_questions (
  id uuid primary key default gen_random_uuid(),
  author_id uuid not null references auth.users(id) on delete cascade,
  author_name text not null default 'UIU student',
  author_student_id text not null default '',
  author_avatar_path text,
  question text not null check (char_length(trim(question)) between 1 and 5000),
  image_paths text[] not null default '{}',
  best_answer_id uuid,
  is_resolved boolean generated always as (best_answer_id is not null) stored,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index freshers_questions_feed_idx
  on public.freshers_questions (is_resolved, created_at desc);
create index freshers_questions_author_idx
  on public.freshers_questions (author_id, created_at desc);

alter table public.freshers_questions enable row level security;
create policy "Authenticated students can read freshers questions"
  on public.freshers_questions for select to authenticated using (true);
create policy "Students can create their own freshers questions"
  on public.freshers_questions for insert to authenticated
  with check ((select auth.uid()) = author_id);
grant select, insert on public.freshers_questions to authenticated;

create table public.freshers_answers (
  id uuid primary key default gen_random_uuid(),
  question_id uuid not null references public.freshers_questions(id) on delete cascade,
  author_id uuid not null references auth.users(id) on delete cascade,
  author_name text not null default 'UIU student',
  author_student_id text not null default '',
  author_avatar_path text,
  body text not null check (char_length(trim(body)) between 1 and 5000),
  created_at timestamptz not null default now(),
  constraint freshers_answers_id_question_unique unique (id, question_id)
);

create index freshers_answers_question_created_idx
  on public.freshers_answers (question_id, created_at);

alter table public.freshers_questions
  add constraint freshers_questions_best_answer_same_question_fk
  foreign key (best_answer_id, id)
  references public.freshers_answers (id, question_id);

alter table public.freshers_answers enable row level security;
create policy "Authenticated students can read freshers answers"
  on public.freshers_answers for select to authenticated using (true);
create policy "Students can answer freshers questions"
  on public.freshers_answers for insert to authenticated
  with check ((select auth.uid()) = author_id);
grant select, insert on public.freshers_answers to authenticated;

create or replace function private.populate_freshers_question_author()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if auth.uid() is null or auth.uid() <> new.author_id then
    raise exception 'Invalid question author';
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
       where o.bucket_id = 'freshers-media' and o.name = new.author_avatar_path
     ) then
    new.author_avatar_path := null;
  end if;

  if exists (
    select 1 from unnest(new.image_paths) as path
    where split_part(path, '/', 1) <> new.author_id::text
       or not exists (
         select 1 from storage.objects o
         where o.bucket_id = 'freshers-media' and o.name = path
       )
  ) then
    raise exception 'Invalid question image';
  end if;
  return new;
end;
$$;
revoke all on function private.populate_freshers_question_author() from public, anon, authenticated;
create trigger populate_freshers_question_author_before_insert
  before insert on public.freshers_questions
  for each row execute function private.populate_freshers_question_author();

create or replace function private.populate_freshers_answer_author()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if auth.uid() is null or auth.uid() <> new.author_id then
    raise exception 'Invalid answer author';
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
       where o.bucket_id = 'freshers-media' and o.name = new.author_avatar_path
     ) then
    new.author_avatar_path := null;
  end if;
  return new;
end;
$$;
revoke all on function private.populate_freshers_answer_author() from public, anon, authenticated;
create trigger populate_freshers_answer_author_before_insert
  before insert on public.freshers_answers
  for each row execute function private.populate_freshers_answer_author();

create or replace function public.set_freshers_best_answer(
  question_id_input uuid,
  answer_id_input uuid default null
)
returns public.freshers_questions
language plpgsql
security definer
set search_path = ''
as $$
declare
  updated_question public.freshers_questions%rowtype;
begin
  if auth.uid() is null then
    raise exception 'Please sign in to manage the best answer.';
  end if;

  if answer_id_input is not null and not exists (
    select 1 from public.freshers_answers a
    where a.id = answer_id_input and a.question_id = question_id_input
  ) then
    raise exception 'That answer does not belong to this question.';
  end if;

  update public.freshers_questions q
  set best_answer_id = answer_id_input, updated_at = now()
  where q.id = question_id_input and q.author_id = auth.uid()
  returning q.* into updated_question;

  if not found then
    raise exception 'Only the question author can choose its best answer.';
  end if;

  return updated_question;
end;
$$;
revoke all on function public.set_freshers_best_answer(uuid, uuid) from public, anon;
grant execute on function public.set_freshers_best_answer(uuid, uuid) to authenticated;

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('freshers-media', 'freshers-media', false, 10485760, array['image/jpeg','image/png','image/webp'])
on conflict (id) do update
set public = false, file_size_limit = excluded.file_size_limit,
    allowed_mime_types = excluded.allowed_mime_types;

create policy "Students can upload their own freshers images"
  on storage.objects for insert to authenticated
  with check (
    bucket_id = 'freshers-media'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );
create policy "Students can read images attached to freshers content"
  on storage.objects for select to authenticated
  using (
    bucket_id = 'freshers-media'
    and (
      exists (
        select 1 from public.freshers_questions q
        where storage.objects.name = any(q.image_paths)
           or storage.objects.name = q.author_avatar_path
      )
      or exists (
        select 1 from public.freshers_answers a
        where storage.objects.name = a.author_avatar_path
      )
    )
  );
create policy "Students can delete their own freshers images"
  on storage.objects for delete to authenticated
  using (
    bucket_id = 'freshers-media'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );
