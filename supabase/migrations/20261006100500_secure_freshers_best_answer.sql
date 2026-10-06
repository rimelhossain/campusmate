drop policy "Authenticated students can read active freshers FAQs"
  on public.freshers_faqs;
create policy "Authenticated students can read active freshers FAQs"
  on public.freshers_faqs for select to authenticated
  using (
    is_active
    or ((select auth.jwt()) -> 'app_metadata' ->> 'role') = 'admin'
  );

drop policy "Admins can add freshers FAQs" on public.freshers_faqs;
create policy "Admins can add freshers FAQs"
  on public.freshers_faqs for insert to authenticated
  with check (((select auth.jwt()) -> 'app_metadata' ->> 'role') = 'admin');

drop policy "Admins can update freshers FAQs" on public.freshers_faqs;
create policy "Admins can update freshers FAQs"
  on public.freshers_faqs for update to authenticated
  using (((select auth.jwt()) -> 'app_metadata' ->> 'role') = 'admin')
  with check (((select auth.jwt()) -> 'app_metadata' ->> 'role') = 'admin');

drop policy "Admins can delete freshers FAQs" on public.freshers_faqs;
create policy "Admins can delete freshers FAQs"
  on public.freshers_faqs for delete to authenticated
  using (((select auth.jwt()) -> 'app_metadata' ->> 'role') = 'admin');

create policy "Question authors can update their best answer"
  on public.freshers_questions for update to authenticated
  using ((select auth.uid()) = author_id)
  with check ((select auth.uid()) = author_id);
grant update (best_answer_id) on public.freshers_questions to authenticated;

create index if not exists freshers_questions_best_answer_fk_idx
  on public.freshers_questions (best_answer_id, id);
create index if not exists freshers_answers_author_idx
  on public.freshers_answers (author_id);

create or replace function public.set_freshers_best_answer(
  question_id_input uuid,
  answer_id_input uuid default null
)
returns public.freshers_questions
language plpgsql
security invoker
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
  set best_answer_id = answer_id_input
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
