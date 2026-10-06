create table public.marketplace_comments (
  id uuid primary key default gen_random_uuid(),
  post_id uuid not null references public.marketplace_posts(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  user_name text not null,
  body text not null check (char_length(trim(body)) between 1 and 1000),
  created_at timestamptz not null default now()
);

create index marketplace_comments_post_created_at_idx
  on public.marketplace_comments (post_id, created_at asc);

alter table public.marketplace_comments enable row level security;

create policy "Authenticated users can read marketplace responses"
  on public.marketplace_comments for select to authenticated using (true);
create policy "Users can add their own marketplace responses"
  on public.marketplace_comments for insert to authenticated with check (
    (select auth.uid()) = user_id
    and exists (
      select 1 from public.marketplace_posts p where p.id = post_id
    )
  );

grant select, insert on public.marketplace_comments to authenticated;
