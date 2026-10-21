-- BƯỚC 1: Tạo user trong Supabase Authentication → Users → Add user.
-- BƯỚC 2: Sao chép User UID của tài khoản tác giả.
-- BƯỚC 3: Thay THAY_BANG_USER_UID bằng UID thật bên dưới, rồi chạy SQL.
insert into public.vcl_admins(user_id)
values ('THAY_BANG_USER_UID'::uuid)
on conflict(user_id) do nothing;

-- Chỉ SQL Editor (quyền quản trị) cấp được vai trò này. Người đăng nhập thường không tự cấp quyền.
