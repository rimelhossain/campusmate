create table public.marketplace_posts (
  id uuid primary key default gen_random_uuid(),
  seller_id uuid not null references auth.users(id) on delete cascade,
  seller_name text not null,
  title text not null check (char_length(trim(title)) between 3 and 100),
  category text not null check (category in ('Food', 'Robotics Components', 'Study materials', 'Others')),
  description text not null check (char_length(trim(description)) between 10 and 2000),
  price_bdt numeric(12, 2) not null check (price_bdt >= 0),
  is_price_fixed boolean not null default false,
  image_paths text[] not null default '{}'::text[],
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index marketplace_posts_created_at_idx
  on public.marketplace_posts (created_at desc);
create index marketplace_posts_seller_id_idx
  on public.marketplace_posts (seller_id);

alter table public.marketplace_posts enable row level security;

create policy "Authenticated users can browse marketplace posts"
  on public.marketplace_posts for select to authenticated using (true);
create policy "Users can create their own marketplace posts"
  on public.marketplace_posts for insert to authenticated
  with check ((select auth.uid()) = seller_id);
create policy "Users can update their own marketplace posts"
  on public.marketplace_posts for update to authenticated
  using ((select auth.uid()) = seller_id)
  with check ((select auth.uid()) = seller_id);
create policy "Users can delete their own marketplace posts"
  on public.marketplace_posts for delete to authenticated
  using ((select auth.uid()) = seller_id);

grant select, insert, update, delete on public.marketplace_posts to authenticated;

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'marketplace-images',
  'marketplace-images',
  false,
  10485760,
  array['image/jpeg', 'image/png', 'image/webp']
)
on conflict (id) do update set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

create policy "Users can upload their own marketplace images"
  on storage.objects for insert to authenticated
  with check (
    bucket_id = 'marketplace-images'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );
create policy "Authenticated users can view marketplace images"
  on storage.objects for select to authenticated
  using (bucket_id = 'marketplace-images');
create policy "Users can delete their own marketplace images"
  on storage.objects for delete to authenticated
  using (
    bucket_id = 'marketplace-images'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );
