-- VĂN CÁC LẦU — chạy trong SQL Editor của project Supabase MỚI.
-- Không cần thay email hay mật khẩu trong file này.
begin;
create table if not exists public.vcl_admins (
 user_id uuid primary key references auth.users(id) on delete cascade,
 created_at timestamptz not null default now()
);
alter table public.vcl_admins enable row level security;
revoke all on public.vcl_admins from anon,authenticated;
grant select on public.vcl_admins to authenticated;
drop policy if exists vcl_admin_self on public.vcl_admins;
create policy vcl_admin_self on public.vcl_admins for select to authenticated using (user_id=(select auth.uid()));

create table if not exists public.vcl_books (
 id uuid primary key default gen_random_uuid(),
 data jsonb not null,
 published boolean generated always as ((data->>'published')::boolean) stored,
 updated_at timestamptz not null default now(),
 constraint vcl_book_shape check (coalesce((
  jsonb_typeof(data)='object' and jsonb_typeof(data->'title')='string' and length(trim(data->>'title')) between 1 and 300
  and jsonb_typeof(data->'summary')='string' and jsonb_typeof(data->'published')='boolean'
  and case when jsonb_typeof(data->'chapters')='array' then jsonb_array_length(data->'chapters') between 1 and 300 else false end
  and octet_length(data::text)<=1500000
 ),false))
);
create index if not exists vcl_books_updated_idx on public.vcl_books(updated_at desc,id);
alter table public.vcl_books enable row level security;
revoke all on public.vcl_books from anon,authenticated;
grant select on public.vcl_books to anon,authenticated;
grant insert,update,delete on public.vcl_books to authenticated;

drop policy if exists vcl_public_read on public.vcl_books;
create policy vcl_public_read on public.vcl_books for select to anon,authenticated using (published=true);
drop policy if exists vcl_author_read on public.vcl_books;
create policy vcl_author_read on public.vcl_books for select to authenticated using (exists(select 1 from public.vcl_admins where user_id=(select auth.uid())));
drop policy if exists vcl_author_insert on public.vcl_books;
create policy vcl_author_insert on public.vcl_books for insert to authenticated with check (exists(select 1 from public.vcl_admins where user_id=(select auth.uid())));
drop policy if exists vcl_author_update on public.vcl_books;
create policy vcl_author_update on public.vcl_books for update to authenticated using (exists(select 1 from public.vcl_admins where user_id=(select auth.uid()))) with check (exists(select 1 from public.vcl_admins where user_id=(select auth.uid())));
drop policy if exists vcl_author_delete on public.vcl_books;
create policy vcl_author_delete on public.vcl_books for delete to authenticated using (exists(select 1 from public.vcl_admins where user_id=(select auth.uid())));

-- Ảnh trong bucket này có URL công khai, kể cả ảnh gắn vào bản nháp.
insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types)
values ('vcl-images','vcl-images',true,8388608,array['image/jpeg','image/png','image/webp','image/gif'])
on conflict(id) do update set public=excluded.public,file_size_limit=excluded.file_size_limit,allowed_mime_types=excluded.allowed_mime_types;

drop policy if exists vcl_image_insert on storage.objects;
create policy vcl_image_insert on storage.objects for insert to authenticated with check (bucket_id='vcl-images' and (storage.foldername(name))[1]=(select auth.uid())::text and exists(select 1 from public.vcl_admins where user_id=(select auth.uid())));
drop policy if exists vcl_image_select on storage.objects;
create policy vcl_image_select on storage.objects for select to authenticated using (bucket_id='vcl-images' and exists(select 1 from public.vcl_admins where user_id=(select auth.uid())));
drop policy if exists vcl_image_delete on storage.objects;
create policy vcl_image_delete on storage.objects for delete to authenticated using (bucket_id='vcl-images' and exists(select 1 from public.vcl_admins where user_id=(select auth.uid())));
commit;
