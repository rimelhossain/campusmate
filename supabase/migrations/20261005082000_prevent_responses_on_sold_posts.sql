drop policy "Users can add their own marketplace responses"
  on public.marketplace_comments;

create policy "Users can respond to available marketplace posts"
  on public.marketplace_comments for insert to authenticated with check (
    (select auth.uid()) = user_id
    and exists (
      select 1
      from public.marketplace_posts p
      where p.id = post_id
        and p.is_sold_out = false
    )
  );
