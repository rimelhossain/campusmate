alter table public.marketplace_posts
  add column is_sold_out boolean not null default false;

create index marketplace_posts_sold_status_created_at_idx
  on public.marketplace_posts (is_sold_out, created_at desc);
