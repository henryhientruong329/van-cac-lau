-- Văn Các Lầu 2.2 — chạy SAU 01-SETUP và 03-MEMBERS-UPGRADE.
-- Bổ sung Admin Portal; không xóa truyện, ảnh, thành viên hay admin hiện có.
begin;
create table if not exists public.vcl_editors(user_id uuid primary key references auth.users(id) on delete cascade, created_at timestamptz not null default now());
create table if not exists public.vcl_member_status(user_id uuid primary key references auth.users(id) on delete cascade, locked boolean not null default false, reason text not null default '', updated_at timestamptz not null default now(), updated_by uuid);
create table if not exists public.vcl_audit(id bigint generated always as identity primary key, actor_id uuid, action text not null, target_id text, details jsonb not null default '{}'::jsonb, created_at timestamptz not null default now());
create table if not exists public.vcl_site_settings(id boolean primary key default true check(id=true), announcement text not null default '' check(char_length(announcement)<=500), updated_at timestamptz not null default now());
insert into public.vcl_site_settings(id) values(true) on conflict do nothing;
alter table public.vcl_books add column if not exists featured boolean not null default false;
alter table public.vcl_books add column if not exists sort_order integer not null default 1000;
alter table public.vcl_books add column if not exists archived boolean not null default false;
alter table public.vcl_books add column if not exists shelf text not null default '';
create index if not exists vcl_audit_created_idx on public.vcl_audit(created_at desc);

-- Helpers inspect the current authenticated identity only; never trust browser-supplied roles.
create or replace function public.vcl_active() returns boolean language sql stable security definer set search_path=pg_catalog,public as $$
 select auth.uid() is not null and not exists(select 1 from public.vcl_member_status where user_id=auth.uid() and locked)
$$;
create or replace function public.vcl_is_admin() returns boolean language sql stable security definer set search_path=pg_catalog,public as $$
 select public.vcl_active() and exists(select 1 from public.vcl_admins where user_id=auth.uid())
$$;
create or replace function public.vcl_can_edit() returns boolean language sql stable security definer set search_path=pg_catalog,public as $$
 select public.vcl_active() and (exists(select 1 from public.vcl_admins where user_id=auth.uid()) or exists(select 1 from public.vcl_editors where user_id=auth.uid()))
$$;
revoke all on function public.vcl_active(),public.vcl_is_admin(),public.vcl_can_edit() from public,anon;
grant execute on function public.vcl_active(),public.vcl_is_admin(),public.vcl_can_edit() to authenticated;

alter table public.vcl_editors enable row level security;
alter table public.vcl_member_status enable row level security;
alter table public.vcl_audit enable row level security;
alter table public.vcl_site_settings enable row level security;
revoke all on public.vcl_editors,public.vcl_member_status,public.vcl_audit,public.vcl_site_settings from anon,authenticated;
grant select on public.vcl_editors,public.vcl_member_status,public.vcl_audit to authenticated;
grant select on public.vcl_site_settings to anon,authenticated;
drop policy if exists vcl_editor_read on public.vcl_editors;
create policy vcl_editor_read on public.vcl_editors for select to authenticated using(user_id=auth.uid() or public.vcl_is_admin());
drop policy if exists vcl_status_read on public.vcl_member_status;
create policy vcl_status_read on public.vcl_member_status for select to authenticated using(user_id=auth.uid() or public.vcl_is_admin());
drop policy if exists vcl_audit_read on public.vcl_audit;
create policy vcl_audit_read on public.vcl_audit for select to authenticated using(public.vcl_is_admin());
drop policy if exists vcl_settings_read on public.vcl_site_settings;
create policy vcl_settings_read on public.vcl_site_settings for select to anon,authenticated using(true);

-- Existing users may still read public stories; protected account operations require an active membership.
drop policy if exists vcl_profile_self_read on public.vcl_profiles;
create policy vcl_profile_self_read on public.vcl_profiles for select to authenticated using(user_id=auth.uid() and public.vcl_active());
drop policy if exists vcl_profile_self_insert on public.vcl_profiles;
create policy vcl_profile_self_insert on public.vcl_profiles for insert to authenticated with check(user_id=auth.uid() and public.vcl_active());
drop policy if exists vcl_profile_self_update on public.vcl_profiles;
create policy vcl_profile_self_update on public.vcl_profiles for update to authenticated using(user_id=auth.uid() and public.vcl_active()) with check(user_id=auth.uid() and public.vcl_active());

drop policy if exists vcl_public_read on public.vcl_books;
create policy vcl_public_read on public.vcl_books for select to anon,authenticated using(published=true and archived=false);
drop policy if exists vcl_author_read on public.vcl_books;
create policy vcl_author_read on public.vcl_books for select to authenticated using(public.vcl_can_edit());
drop policy if exists vcl_author_insert on public.vcl_books;
create policy vcl_author_insert on public.vcl_books for insert to authenticated with check(public.vcl_can_edit());
drop policy if exists vcl_author_update on public.vcl_books;
create policy vcl_author_update on public.vcl_books for update to authenticated using(public.vcl_can_edit()) with check(public.vcl_can_edit());
drop policy if exists vcl_author_delete on public.vcl_books;
create policy vcl_author_delete on public.vcl_books for delete to authenticated using(public.vcl_is_admin());

drop policy if exists vcl_image_insert on storage.objects;
create policy vcl_image_insert on storage.objects for insert to authenticated with check(bucket_id='vcl-images' and (storage.foldername(name))[1]=auth.uid()::text and public.vcl_can_edit());
drop policy if exists vcl_image_select on storage.objects;
create policy vcl_image_select on storage.objects for select to authenticated using(bucket_id='vcl-images' and public.vcl_can_edit());
drop policy if exists vcl_image_delete on storage.objects;
create policy vcl_image_delete on storage.objects for delete to authenticated using(bucket_id='vcl-images' and public.vcl_is_admin());

-- Editors edit story text, but cannot bypass the portal to change curation/archive controls.
create or replace function public.vcl_book_guard() returns trigger language plpgsql set search_path=pg_catalog,public as $$
begin
 if auth.uid() is null and current_user in ('postgres','supabase_admin') then return new; end if;
 if not public.vcl_is_admin() then
  if TG_OP='INSERT' and (new.featured or new.archived or new.sort_order<>1000 or new.shelf<>'') then raise exception 'Only admins can curate the library' using errcode='42501'; end if;
  if TG_OP='UPDATE' and (new.featured is distinct from old.featured or new.archived is distinct from old.archived or new.sort_order is distinct from old.sort_order or new.shelf is distinct from old.shelf) then raise exception 'Only admins can curate the library' using errcode='42501'; end if;
 end if;
 return new;
end $$;
drop trigger if exists vcl_book_guard_trigger on public.vcl_books;
create trigger vcl_book_guard_trigger before insert or update on public.vcl_books for each row execute function public.vcl_book_guard();
create or replace function public.vcl_book_audit() returns trigger language plpgsql security definer set search_path=pg_catalog,public as $$
declare b public.vcl_books; previous jsonb;
begin
 if TG_OP='DELETE' then b:=old; else b:=new; end if;
 if TG_OP='UPDATE' then previous:=jsonb_build_object('published',old.published,'featured',old.featured,'sort_order',old.sort_order,'archived',old.archived,'shelf',old.shelf);end if;
 insert into public.vcl_audit(actor_id,action,target_id,details) values(auth.uid(),'book.'||lower(TG_OP),b.id::text,jsonb_build_object('title',b.data->>'title','published',b.published,'featured',b.featured,'sort_order',b.sort_order,'archived',b.archived,'shelf',b.shelf,'previous',previous));
 if TG_OP='DELETE' then return old; else return new; end if;
end $$;
drop trigger if exists vcl_book_audit_trigger on public.vcl_books;
create trigger vcl_book_audit_trigger after insert or update or delete on public.vcl_books for each row execute function public.vcl_book_audit();
revoke all on function public.vcl_book_guard(),public.vcl_book_audit() from public,anon,authenticated;

create or replace function public.vcl_access() returns jsonb language sql stable security definer set search_path=pg_catalog,public as $$
 select jsonb_build_object('locked',not public.vcl_active(),'reason',coalesce((select reason from public.vcl_member_status where user_id=auth.uid()),''),'role',case when public.vcl_is_admin() then 'admin' when public.vcl_can_edit() then 'editor' else 'member' end)
$$;

create or replace function public.vcl_admin_members(p_query text default '',p_offset integer default 0,p_limit integer default 30) returns jsonb language plpgsql stable security definer set search_path=pg_catalog,public as $$
declare result jsonb; total bigint;
begin
 if not public.vcl_is_admin() then raise exception 'Admin access required' using errcode='42501';end if;
 select count(*) into total from auth.users u left join public.vcl_profiles p on p.user_id=u.id where position(lower(coalesce(p_query,'')) in lower(coalesce(u.email,'')||' '||coalesce(p.display_name,'')))>0;
 select coalesce(jsonb_agg(to_jsonb(t)),'[]'::jsonb) into result from (
 select u.id,u.email,coalesce(nullif(p.display_name,''),u.raw_user_meta_data->>'display_name','Độc giả') as display_name,u.created_at,u.last_sign_in_at,coalesce(s.locked,false) as locked,coalesce(s.reason,'') as reason,
 case when exists(select 1 from public.vcl_admins a where a.user_id=u.id) then 'admin' when exists(select 1 from public.vcl_editors e where e.user_id=u.id) then 'editor' else 'member' end as role
 from auth.users u left join public.vcl_profiles p on p.user_id=u.id left join public.vcl_member_status s on s.user_id=u.id
 where position(lower(coalesce(p_query,'')) in lower(coalesce(u.email,'')||' '||coalesce(p.display_name,'')))>0
 order by u.created_at desc,u.id limit greatest(1,least(coalesce(p_limit,30),100)) offset greatest(0,coalesce(p_offset,0))
 ) t;
 return jsonb_build_object('items',result,'total',total);
end $$;

create or replace function public.vcl_admin_member(p_user uuid,p_action text,p_value text,p_reason text default '') returns void language plpgsql security definer set search_path=pg_catalog,public as $$
declare old_role text; was_locked boolean; desired boolean;
begin
 perform pg_advisory_xact_lock(77442211);
 if not public.vcl_is_admin() then raise exception 'Admin access required' using errcode='42501';end if;
 if p_user=auth.uid() then raise exception 'Không thể khóa hoặc đổi vai trò của chính mình.';end if;
 if not exists(select 1 from auth.users where id=p_user) then raise exception 'Không tìm thấy thành viên.';end if;
 if char_length(coalesce(p_reason,''))>500 then raise exception 'Lý do tối đa 500 ký tự.';end if;
 old_role:=case when exists(select 1 from public.vcl_admins where user_id=p_user) then 'admin' when exists(select 1 from public.vcl_editors where user_id=p_user) then 'editor' else 'member' end;
 was_locked:=coalesce((select locked from public.vcl_member_status where user_id=p_user),false);
 if p_action='lock' then
  if p_value is null or p_value not in ('true','false') then raise exception 'Invalid status';end if;
  desired:=p_value='true';
  if desired and length(trim(coalesce(p_reason,'')))<3 then raise exception 'Vui lòng nhập lý do khóa (ít nhất 3 ký tự).';end if;
  insert into public.vcl_member_status(user_id,locked,reason,updated_by) values(p_user,desired,coalesce(p_reason,''),auth.uid()) on conflict(user_id) do update set locked=excluded.locked,reason=excluded.reason,updated_by=excluded.updated_by,updated_at=now();
 elsif p_action='role' then
  if p_value is null or p_value not in ('admin','editor','member') then raise exception 'Invalid role';end if;
  delete from public.vcl_admins where user_id=p_user;
  delete from public.vcl_editors where user_id=p_user;
  if p_value='admin' then insert into public.vcl_admins(user_id) values(p_user);end if;
  if p_value='editor' then insert into public.vcl_editors(user_id) values(p_user);end if;
 else raise exception 'Invalid action';end if;
 insert into public.vcl_audit(actor_id,action,target_id,details) values(auth.uid(),'member.'||p_action,p_user::text,jsonb_build_object('value',p_value,'reason',coalesce(p_reason,''),'previous_role',old_role,'previous_locked',was_locked));
end $$;

create or replace function public.vcl_admin_book(p_id uuid,p_action text,p_value text) returns void language plpgsql security definer set search_path=pg_catalog,public as $$
declare v jsonb;
begin
 if not public.vcl_is_admin() then raise exception 'Admin access required' using errcode='42501';end if;
 if not exists(select 1 from public.vcl_books where id=p_id) then raise exception 'Không tìm thấy tác phẩm.';end if;
 if p_action in ('featured','archive','publish') then
  if p_value is null or p_value not in ('true','false') then raise exception 'Invalid status';end if;
  if p_action='featured' then update public.vcl_books set featured=p_value::boolean,updated_at=now() where id=p_id;end if;
  if p_action='archive' then update public.vcl_books set archived=p_value::boolean,updated_at=now() where id=p_id;end if;
  if p_action='publish' then update public.vcl_books set data=jsonb_set(data,'{published}',to_jsonb(p_value::boolean)),updated_at=now() where id=p_id;end if;
 elsif p_action='curate' then
  if p_value is null then raise exception 'Thiếu dữ liệu sắp xếp.';end if;
  v:=p_value::jsonb;
  if jsonb_typeof(v)<>'object' or coalesce(v->>'order','') !~ '^[0-9]{1,6}$' or v->>'shelf' is null or char_length(v->>'shelf')>60 then raise exception 'Vị trí hoặc bộ sưu tập không hợp lệ.';end if;
  update public.vcl_books set sort_order=(v->>'order')::integer,shelf=trim(v->>'shelf'),updated_at=now() where id=p_id;
 elsif p_action='order' then
  if p_value is null or p_value !~ '^[0-9]{1,6}$' then raise exception 'Vị trí phải từ 0 đến 999999.';end if;
  update public.vcl_books set sort_order=p_value::integer,updated_at=now() where id=p_id;
 elsif p_action='shelf' then
  if p_value is null or char_length(p_value)>60 then raise exception 'Tên bộ sưu tập tối đa 60 ký tự.';end if;
  update public.vcl_books set shelf=trim(p_value),updated_at=now() where id=p_id;
 else raise exception 'Invalid action';end if;
end $$;

create or replace function public.vcl_admin_overview() returns jsonb language plpgsql stable security definer set search_path=pg_catalog,public as $$
begin
 if not public.vcl_is_admin() then raise exception 'Admin access required' using errcode='42501';end if;
 return jsonb_build_object('members',(select count(*) from auth.users),'locked',(select count(*) from public.vcl_member_status where locked),'new_members',(select count(*) from auth.users where created_at>=now()-interval '7 days'),'admins',(select count(*) from public.vcl_admins),'editors',(select count(*) from public.vcl_editors),'books',(select count(*) from public.vcl_books),'published',(select count(*) from public.vcl_books where published and not archived),'drafts',(select count(*) from public.vcl_books where not published and not archived),'archived',(select count(*) from public.vcl_books where archived),'featured',(select count(*) from public.vcl_books where featured and not archived));
end $$;

create or replace function public.vcl_admin_announcement(p_text text) returns void language plpgsql security definer set search_path=pg_catalog,public as $$
begin
 if not public.vcl_is_admin() then raise exception 'Admin access required' using errcode='42501';end if;
 if p_text is null or char_length(p_text)>500 then raise exception 'Thông báo tối đa 500 ký tự.';end if;
 update public.vcl_site_settings set announcement=trim(p_text),updated_at=now() where id=true;
 insert into public.vcl_audit(actor_id,action,target_id,details) values(auth.uid(),'site.announcement','site',jsonb_build_object('text',trim(p_text)));
end $$;

create or replace function public.vcl_admin_audit(p_offset integer default 0) returns jsonb language plpgsql stable security definer set search_path=pg_catalog,public as $$
declare result jsonb;
begin
 if not public.vcl_is_admin() then raise exception 'Admin access required' using errcode='42501';end if;
 select coalesce(jsonb_agg(to_jsonb(t)),'[]'::jsonb) into result from (
  select a.*,coalesce(nullif(p.display_name,''),u.email,a.actor_id::text,'Hệ thống / SQL Editor') as actor_name,coalesce(a.details->>'title',target_user.email,a.target_id) as target_name
  from public.vcl_audit a left join auth.users u on u.id=a.actor_id left join public.vcl_profiles p on p.user_id=a.actor_id left join auth.users target_user on target_user.id::text=a.target_id
  order by a.created_at desc,a.id desc limit 30 offset greatest(0,coalesce(p_offset,0))
 ) t;
 return result;
end $$;
revoke all on function public.vcl_admin_audit(integer) from public,anon;
grant execute on function public.vcl_admin_audit(integer) to authenticated;

revoke all on function public.vcl_access(),public.vcl_admin_members(text,integer,integer),public.vcl_admin_member(uuid,text,text,text),public.vcl_admin_book(uuid,text,text),public.vcl_admin_overview(),public.vcl_admin_announcement(text) from public,anon;
grant execute on function public.vcl_access(),public.vcl_admin_members(text,integer,integer),public.vcl_admin_member(uuid,text,text,text),public.vcl_admin_book(uuid,text,text),public.vcl_admin_overview(),public.vcl_admin_announcement(text) to authenticated;
commit;
