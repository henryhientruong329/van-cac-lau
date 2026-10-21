-- VĂN CÁC LẦU 2.1 — dùng được trên project hiện có, KHÔNG xóa truyện hay quyền tác giả.
begin;
create table if not exists public.vcl_profiles (
 user_id uuid primary key references auth.users(id) on delete cascade,
 display_name text not null default '' check (char_length(display_name)<=60),
 reading_theme text not null default 'auto' check (reading_theme in ('auto','romance','wuxia','scifi')),
 updated_at timestamptz not null default now()
);
alter table public.vcl_profiles enable row level security;
revoke all on public.vcl_profiles from anon,authenticated;
grant select,insert,update on public.vcl_profiles to authenticated;
drop policy if exists vcl_profile_self_read on public.vcl_profiles;
create policy vcl_profile_self_read on public.vcl_profiles for select to authenticated using (user_id=(select auth.uid()));
drop policy if exists vcl_profile_self_insert on public.vcl_profiles;
create policy vcl_profile_self_insert on public.vcl_profiles for insert to authenticated with check (user_id=(select auth.uid()));
drop policy if exists vcl_profile_self_update on public.vcl_profiles;
create policy vcl_profile_self_update on public.vcl_profiles for update to authenticated using (user_id=(select auth.uid())) with check (user_id=(select auth.uid()));
commit;
-- Đăng ký phải được bật trong Supabase Authentication → Sign In / Providers → Email.
-- Đặt Site URL và Redirect URLs bằng URL website thật, giữ Confirm email bật.
-- Thành viên KHÔNG được tự thêm vào vcl_admins và KHÔNG được quyền ghi vcl_books.
