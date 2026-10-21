-- Văn Các Lầu 2.3 — chạy sau 04-ADMIN-PORTAL.sql; giữ toàn bộ dữ liệu hiện có.
begin;
create table if not exists public.vcl_comments(
 id uuid primary key default gen_random_uuid(),user_id uuid not null references auth.users(id) on delete cascade,
 book_id uuid references public.vcl_books(id) on delete cascade,parent_id uuid references public.vcl_comments(id) on delete cascade,
 title text not null default '' check(char_length(title)<=120),body text not null check(char_length(body) between 3 and 3000),
 category text not null default 'Cảm nhận' check(category in ('Cảm nhận','Thảo luận','Gợi ý truyện')),
 spoiler boolean not null default false,status text not null default 'visible' check(status in ('visible','hidden','deleted')),
 created_at timestamptz not null default now()
);
create index if not exists vcl_comments_scope_idx on public.vcl_comments(book_id,parent_id,created_at desc);
create index if not exists vcl_comments_user_idx on public.vcl_comments(user_id,created_at desc);
create table if not exists public.vcl_comment_reports(
 id uuid primary key default gen_random_uuid(),comment_id uuid not null references public.vcl_comments(id) on delete cascade,
 user_id uuid not null references auth.users(id) on delete cascade,reason text not null check(char_length(reason) between 5 and 500),
 resolved boolean not null default false,created_at timestamptz not null default now(),unique(comment_id,user_id)
);
create table if not exists public.vcl_ratings(
 book_id uuid not null references public.vcl_books(id) on delete cascade,user_id uuid not null references auth.users(id) on delete cascade,
 stars smallint not null check(stars between 1 and 5),updated_at timestamptz not null default now(),primary key(book_id,user_id)
);
alter table public.vcl_comments enable row level security;
alter table public.vcl_comment_reports enable row level security;
alter table public.vcl_ratings enable row level security;
revoke all on public.vcl_comments,public.vcl_comment_reports,public.vcl_ratings from anon,authenticated;
-- No direct client CRUD: tightly scoped RPCs below control ownership, public visibility, limits and moderation.
create or replace function public.vcl_scope_public(p_book uuid) returns boolean language sql stable security definer set search_path=pg_catalog,public as $$
 select p_book is null or exists(select 1 from public.vcl_books where id=p_book and published and not archived)
$$;
revoke all on function public.vcl_scope_public(uuid) from public,anon,authenticated;

create or replace function public.vcl_comment_list(p_book uuid default null,p_parent uuid default null,p_offset integer default 0,p_category text default '') returns jsonb language plpgsql stable security definer set search_path=pg_catalog,public as $$
declare result jsonb; total bigint;
begin
 if not public.vcl_scope_public(p_book) then return jsonb_build_object('items','[]'::jsonb,'total',0);end if;
 if p_parent is not null and not exists(select 1 from public.vcl_comments where id=p_parent and book_id is not distinct from p_book and parent_id is null and status in ('visible','deleted')) then return jsonb_build_object('items','[]'::jsonb,'total',0);end if;
 select count(*) into total from public.vcl_comments c
 where c.book_id is not distinct from p_book and c.parent_id is not distinct from p_parent
 and (coalesce(p_category,'')='' or c.category=p_category)
 and (c.status='visible' or (c.status='deleted' and exists(select 1 from public.vcl_comments r where r.parent_id=c.id and r.status='visible')) or (c.status='hidden' and c.user_id=auth.uid() and public.vcl_active()));
 select coalesce(jsonb_agg(to_jsonb(t)),'[]'::jsonb) into result from (
 select c.id,case when c.status='deleted' then '' else c.title end as title,case when c.status='deleted' then '' else c.body end as body,c.category,c.spoiler,c.status,c.created_at,
 coalesce(nullif(p.display_name,''),nullif(u.raw_user_meta_data->>'display_name',''),'Độc giả') as display_name,
 (c.user_id=auth.uid() and public.vcl_active()) as is_mine,
 (select count(*) from public.vcl_comments r where r.parent_id=c.id and r.status='visible') as replies,
 exists(select 1 from public.vcl_comment_reports r where r.comment_id=c.id and r.user_id=auth.uid()) as reported
 from public.vcl_comments c left join public.vcl_profiles p on p.user_id=c.user_id left join auth.users u on u.id=c.user_id
 where c.book_id is not distinct from p_book and c.parent_id is not distinct from p_parent
 and (coalesce(p_category,'')='' or c.category=p_category)
 and (c.status='visible' or (c.status='deleted' and exists(select 1 from public.vcl_comments r where r.parent_id=c.id and r.status='visible')) or (c.status='hidden' and c.user_id=auth.uid() and public.vcl_active()))
 order by c.created_at desc,c.id limit 20 offset greatest(0,coalesce(p_offset,0))
 ) t;
 return jsonb_build_object('items',result,'total',total);
end $$;

create or replace function public.vcl_comment_post(p_body text,p_book uuid default null,p_parent uuid default null,p_title text default '',p_category text default 'Cảm nhận',p_spoiler boolean default false) returns uuid language plpgsql security definer set search_path=pg_catalog,public as $$
declare result uuid;
begin
 if not public.vcl_active() then raise exception 'Vui lòng đăng nhập bằng tài khoản đang hoạt động.' using errcode='42501';end if;
 if not public.vcl_scope_public(p_book) then raise exception 'Truyện chưa công khai hoặc đã được lưu trữ.';end if;
 if p_body is null or char_length(trim(p_body)) not between 3 and 3000 or p_title is null or char_length(p_title)>120 or p_category is null or p_category not in ('Cảm nhận','Thảo luận','Gợi ý truyện') then raise exception 'Nội dung hoặc chủ đề không hợp lệ.';end if;
 if p_parent is not null and not exists(select 1 from public.vcl_comments where id=p_parent and parent_id is null and book_id is not distinct from p_book and status='visible') then raise exception 'Không thể trả lời chủ đề này.';end if;
 perform pg_advisory_xact_lock(hashtextextended(auth.uid()::text,8383));
 if exists(select 1 from public.vcl_comments where user_id=auth.uid() and created_at>now()-interval '15 seconds') then raise exception 'Vui lòng đợi 15 giây giữa các lần đăng bình luận.';end if;
 insert into public.vcl_comments(user_id,book_id,parent_id,title,body,category,spoiler) values(auth.uid(),p_book,p_parent,trim(p_title),trim(p_body),p_category,coalesce(p_spoiler,false)) returning id into result;
 return result;
end $$;

create or replace function public.vcl_comment_delete(p_id uuid) returns void language plpgsql security definer set search_path=pg_catalog,public as $$
begin
 if not public.vcl_active() then raise exception 'Tài khoản không hoạt động.' using errcode='42501';end if;
 update public.vcl_comments set status='deleted' where id=p_id and user_id=auth.uid() and status='visible';
 if not found then raise exception 'Không có quyền xóa bình luận này.' using errcode='42501';end if;
end $$;

create or replace function public.vcl_comment_report(p_id uuid,p_reason text) returns void language plpgsql security definer set search_path=pg_catalog,public as $$
begin
 if not public.vcl_active() then raise exception 'Vui lòng đăng nhập bằng tài khoản đang hoạt động.' using errcode='42501';end if;
 if p_reason is null or char_length(trim(p_reason)) not between 5 and 500 then raise exception 'Lý do báo cáo cần từ 5 đến 500 ký tự.';end if;
 if not exists(select 1 from public.vcl_comments c where c.id=p_id and c.user_id<>auth.uid() and c.status='visible' and public.vcl_scope_public(c.book_id) and (c.parent_id is null or exists(select 1 from public.vcl_comments p where p.id=c.parent_id and p.status in ('visible','deleted')))) then raise exception 'Không thể báo cáo bình luận này.';end if;
 insert into public.vcl_comment_reports(comment_id,user_id,reason) values(p_id,auth.uid(),trim(p_reason)) on conflict(comment_id,user_id) do nothing;
end $$;

create or replace function public.vcl_rate_book(p_book uuid,p_stars integer) returns void language plpgsql security definer set search_path=pg_catalog,public as $$
begin
 if not public.vcl_active() then raise exception 'Vui lòng đăng nhập bằng tài khoản đang hoạt động.' using errcode='42501';end if;
 if p_book is null or not public.vcl_scope_public(p_book) then raise exception 'Truyện chưa công khai hoặc đã lưu trữ.';end if;
 if p_stars is null or p_stars not between 1 and 5 then raise exception 'Chỉ chấp nhận từ 1 đến 5 sao.';end if;
 insert into public.vcl_ratings(book_id,user_id,stars) values(p_book,auth.uid(),p_stars) on conflict(book_id,user_id) do update set stars=excluded.stars,updated_at=now();
end $$;
create or replace function public.vcl_rating_remove(p_book uuid) returns void language plpgsql security definer set search_path=pg_catalog,public as $$
begin
 if not public.vcl_active() then raise exception 'Tài khoản không hoạt động.' using errcode='42501';end if;
 delete from public.vcl_ratings where book_id=p_book and user_id=auth.uid();
end $$;
create or replace function public.vcl_book_ratings(p_book uuid) returns jsonb language plpgsql stable security definer set search_path=pg_catalog,public as $$
begin
 if p_book is null or not public.vcl_scope_public(p_book) then return jsonb_build_object('average',null,'count',0,'mine',null,'histogram','{}'::jsonb);end if;
 return jsonb_build_object('average',(select round(avg(stars)::numeric,1) from public.vcl_ratings where book_id=p_book),'count',(select count(*) from public.vcl_ratings where book_id=p_book),'mine',case when public.vcl_active() then (select stars from public.vcl_ratings where book_id=p_book and user_id=auth.uid()) else null end,'histogram',(select jsonb_object_agg(n,(select count(*) from public.vcl_ratings where book_id=p_book and stars=n)) from generate_series(1,5) n));
end $$;
create or replace function public.vcl_rating_summary(p_ids uuid[]) returns jsonb language plpgsql stable security definer set search_path=pg_catalog,public as $$
declare result jsonb;
begin
 if coalesce(cardinality(p_ids),0)>100 then raise exception 'Tối đa 100 truyện mỗi lần.';end if;
 select coalesce(jsonb_agg(to_jsonb(t)),'[]'::jsonb) into result from (
 select b.id as book_id,round(avg(r.stars)::numeric,1) as average,count(r.stars) as count from public.vcl_books b left join public.vcl_ratings r on r.book_id=b.id
 where b.id=any(p_ids) and b.published and not b.archived group by b.id
 ) t;return result;
end $$;

create or replace function public.vcl_admin_community(p_filter text default 'reported',p_offset integer default 0) returns jsonb language plpgsql stable security definer set search_path=pg_catalog,public as $$
declare result jsonb; total bigint;
begin
 if not public.vcl_is_admin() then raise exception 'Admin access required' using errcode='42501';end if;
 if p_filter not in ('all','reported','hidden') then raise exception 'Invalid filter';end if;
 select count(*) into total from public.vcl_comments c where p_filter='all' or (p_filter='hidden' and c.status='hidden') or (p_filter='reported' and exists(select 1 from public.vcl_comment_reports r where r.comment_id=c.id and not r.resolved));
 select coalesce(jsonb_agg(to_jsonb(t)),'[]'::jsonb) into result from (
 select c.*,coalesce(nullif(p.display_name,''),u.raw_user_meta_data->>'display_name','Độc giả') as display_name,u.email as author_email,b.data->>'title' as book_title,
 (select count(*) from public.vcl_comment_reports r where r.comment_id=c.id and not r.resolved) as report_count,
 coalesce((select jsonb_agg(jsonb_build_object('reason',r.reason,'created_at',r.created_at)) from public.vcl_comment_reports r where r.comment_id=c.id and not r.resolved),'[]'::jsonb) as reports
 from public.vcl_comments c left join public.vcl_profiles p on p.user_id=c.user_id left join auth.users u on u.id=c.user_id left join public.vcl_books b on b.id=c.book_id
 where p_filter='all' or (p_filter='hidden' and c.status='hidden') or (p_filter='reported' and exists(select 1 from public.vcl_comment_reports r where r.comment_id=c.id and not r.resolved))
 order by c.created_at desc,c.id limit 30 offset greatest(0,coalesce(p_offset,0))
 ) t;return jsonb_build_object('items',result,'total',total);
end $$;
create or replace function public.vcl_admin_moderate(p_id uuid,p_action text,p_reason text default '') returns void language plpgsql security definer set search_path=pg_catalog,public as $$
declare c public.vcl_comments;
begin
 if not public.vcl_is_admin() then raise exception 'Admin access required' using errcode='42501';end if;
 select * into c from public.vcl_comments where id=p_id for update;
 if not found then raise exception 'Không tìm thấy bình luận.';end if;
 if char_length(coalesce(p_reason,''))>500 then raise exception 'Lý do tối đa 500 ký tự.';end if;
 if p_action='hide' then
  if c.status='deleted' then raise exception 'Nội dung đã xóa; hãy kiểm duyệt các trả lời riêng.';end if;
  update public.vcl_comments set status='hidden' where id=p_id;
 elsif p_action='restore' then
  if c.status='deleted' then raise exception 'Không khôi phục nội dung đã được tác giả xóa.';end if;
  update public.vcl_comments set status='visible' where id=p_id;
 elsif p_action<>'resolve' then raise exception 'Invalid action';end if;
 update public.vcl_comment_reports set resolved=true where comment_id=p_id;
 insert into public.vcl_audit(actor_id,action,target_id,details) values(auth.uid(),'community.'||p_action,p_id::text,jsonb_build_object('title',coalesce(nullif(c.title,''),left(c.body,100)),'previous_status',c.status,'reason',coalesce(p_reason,'')));
end $$;

revoke all on function public.vcl_comment_list(uuid,uuid,integer,text),public.vcl_book_ratings(uuid),public.vcl_rating_summary(uuid[]) from public;
grant execute on function public.vcl_comment_list(uuid,uuid,integer,text),public.vcl_book_ratings(uuid),public.vcl_rating_summary(uuid[]) to anon,authenticated;
revoke all on function public.vcl_comment_post(text,uuid,uuid,text,text,boolean),public.vcl_comment_delete(uuid),public.vcl_comment_report(uuid,text),public.vcl_rate_book(uuid,integer),public.vcl_rating_remove(uuid),public.vcl_admin_community(text,integer),public.vcl_admin_moderate(uuid,text,text) from public,anon;
grant execute on function public.vcl_comment_post(text,uuid,uuid,text,text,boolean),public.vcl_comment_delete(uuid),public.vcl_comment_report(uuid,text),public.vcl_rate_book(uuid,integer),public.vcl_rating_remove(uuid),public.vcl_admin_community(text,integer),public.vcl_admin_moderate(uuid,text,text) to authenticated;
commit;
