# Văn Các Lầu — GitHub + Supabase, KHÔNG CẦN NODE TRÊN MÁY

Bản 2.0, thay thế gói Workers + D1 + R2 trước đây. Tên mới: **Văn Các Lầu**.

**Anh chỉ cần trình duyệt, tải/giải nén ZIP và sao chép văn bản. Không cần cài Node, Git, npm, Wrangler; không cần mở terminal.** Giao diện đã được biên dịch sẵn trong thư mục `site`.

Cách dùng chính: **GitHub giữ mã nguồn → Cloudflare Pages hiển thị web → Supabase lưu sách, ảnh và quản lý đăng nhập**. Người đọc không cần tài khoản.

## A. Tạo Supabase (thực hiện một lần)

### A1. Tạo project mới

1. Đăng nhập https://supabase.com/dashboard
2. Chọn **New project**, đặt tên `van-cac-lau`.
3. Đặt database password riêng, lưu lại. Đây KHÔNG phải mật khẩu đăng nhập tác giả.
4. Chờ project sẵn sàng.

### A2. Tạo bảng và kho ảnh

1. Trong project, mở **SQL Editor → New query**.
2. Mở file `supabase/01-SETUP.sql` trong gói ZIP bằng Notepad hoặc trình soạn thảo văn bản.
3. Sao chép TOÀN BỘ vào SQL Editor và bấm **Run**.
4. Thành công khi không có lỗi. File tạo `vcl_books`, `vcl_admins`, bucket `vcl-images` và các chính sách bảo vệ dữ liệu.

Chỉ chạy trên project dành cho webapp này. Không tắt Row Level Security (RLS).

### A3. Tạo tài khoản tác giả

1. Mở **Authentication → Users → Add user → Create new user** (tên mục có thể thay đổi nhẹ).
2. Nhập email của anh và mật khẩu tác giả riêng. Nếu có tùy chọn **Auto Confirm User**, bật tùy chọn này.
3. Sau khi tạo, sao chép **User UID** của tài khoản.
4. Mở file `supabase/02-GRANT-AUTHOR.sql`, thay `THAY_BANG_USER_UID` bằng UID thật.
5. Dán đoạn SQL đã sửa vào một query mới và bấm **Run**.
6. Trong phần cấu hình Authentication/Sign Up, tắt đăng ký người dùng mới nếu chỉ có anh quản trị. Webapp không cung cấp nút tự đăng ký.

Chỉ có email/mật khẩu chưa đủ quyền sửa sách: tài khoản phải có UID trong bảng `vcl_admins`.

### A4. Lấy hai thông tin kết nối

Mở **Connect** hoặc **Project Settings → API / API Keys**, lấy:

| Cần lấy | Ví dụ minh họa | Ghi chú |
|---|---|---|
| Project URL | `https://abcdefgh.supabase.co` | Địa chỉ API của project |
| Publishable key | `sb_publishable_...` | Key công khai dành cho website |

Có thể dùng **anon public key** dạng JWT của project cũ nếu không có Publishable key. TUYỆT ĐỐI không dùng `service_role`, `sb_secret_...`, database password hay mật khẩu tác giả trong file cấu hình.

## B. Đưa gói mới lên GitHub — không dùng dòng lệnh

1. Đăng nhập https://github.com và tạo repository mới tên `van-cac-lau`.
2. Giải nén ZIP trên máy tính.
3. Mở thư mục bên trong `Van-Cac-Lau`. Anh phải nhìn thấy `site`, `src`, `supabase`, `package.json`, v.v.
4. Trên GitHub chọn **Add file → Upload files**; kéo các FILE VÀ THƯ MỤC BÊN TRONG thư mục này lên. Không kéo nguyên file ZIP; không để thêm một lớp thư mục `Van-Cac-Lau` bên ngoài.
5. Bấm **Commit changes**. Khi mở repository phải nhìn thấy ngay thư mục `site` ở cấp ngoài cùng.
6. Mở `site/config.js`, bấm biểu tượng bút chì để sửa. Điền hai giá trị ở bước A4, giữ nguyên dấu nháy và dấu phẩy:

```js
window.VAN_CAC_LAU_CONFIG = {
  supabaseUrl: "https://PROJECT_REF_CUA_ANH.supabase.co",
  supabasePublishableKey: "sb_publishable_KEY_CUA_ANH"
};
```

7. Bấm **Commit changes** để lưu.

Hai giá trị này được phép xuất hiện trong trình duyệt. Quyền bảo vệ dữ liệu đến từ Supabase Auth và SQL/RLS, không đến từ việc giấu Publishable key. Không đưa bất cứ mật khẩu nào lên GitHub.

**Chỉ cần sửa `site/config.js` cho luồng không build.** File `public/config.js` dành cho trường hợp lập trình viên biên dịch lại mã nguồn; chưa cần dùng.

## C. Đưa lên Cloudflare Pages bằng trình duyệt

1. Mở https://dash.cloudflare.com
2. Vào **Workers & Pages → Create application → Pages → Connect to Git / Import a Git repository**. Chọn nhánh tạo **Pages**, không tạo Worker có deploy command.
3. Kết nối GitHub và chọn repository `van-cac-lau`.
4. Điền:

| Ô trên Cloudflare Pages | Giá trị |
|---|---|
| Project name | `van-cac-lau` (hoặc tên chưa được dùng) |
| Production branch | `main` |
| Framework preset | **None** |
| Build command | **ĐỂ TRỐNG** |
| Build output directory | **site** |
| Root directory | Để trống, hoặc `/` khi repository đúng cấu trúc trên |
| Environment variables | Không cần cho bản này |

5. Chọn **Save and Deploy**.
6. Cloudflare trả về đường link dạng `https://van-cac-lau.pages.dev` (tên thực tế phụ thuộc project name và khả dụng).
7. Mở link đó để kiểm tra. Trong Supabase Authentication → URL Configuration, đặt **Site URL** bằng địa chỉ vừa nhận. Đăng nhập bằng email/mật khẩu không cần OAuth redirect.

**Không nhập `npm run build`. Không nhập `npm run deploy`. Không cần D1, R2, AUTHOR_KEY hoặc database_id của gói cũ.** Cloudflare chỉ phát hành thư mục `site`; Supabase thực hiện phần dữ liệu.

## D. Kiểm tra trước khi chia sẻ

1. Mở website: tên phải là **Văn Các Lầu**. Nếu báo chưa kết nối Supabase, sửa `site/config.js` trên GitHub rồi đợi Cloudflare tự triển khai commit mới.
2. Chọn **Góc tác giả**, nhập email/mật khẩu đã tạo ở A3.
3. Tạo một truyện ngắn, điền bìa, tóm tắt và nội dung chương. Thử tải một ảnh từ thiết bị.
4. Bỏ chọn **Xuất bản** và lưu. Mở cửa sổ ẩn danh: bản nháp không được xuất hiện.
5. Quay lại tác giả, bật **Xuất bản**, lưu. Tải lại cửa sổ ẩn danh: truyện phải xuất hiện và đọc được.
6. Thử lật trang, vuốt trên điện thoại, phóng to/thu nhỏ, đánh dấu, đóng/mở lại sách.
7. Gửi đường link Pages cho người đọc.

Ba sách mẫu giúp thử giao diện khi chưa có sáng tác. Khi có một sáng tác xuất bản, các sách mẫu tự ẩn. Các sách mẫu không phải tác phẩm của Henry.

## E. Thêm truyện hằng ngày

Vào **Góc tác giả → Tác phẩm mới**, thêm nội dung, chương, ảnh và lưu. Không cần vào GitHub hoặc triển khai lại khi đăng/sửa truyện: dữ liệu được lưu trực tiếp trên Supabase.

- Hỗ trợ truyện ngắn, truyện dài, tản văn.
- Ảnh bìa và ảnh đầu chương: dùng đường dẫn HTTPS hoặc tải JPG/PNG/WebP/GIF, tối đa 8 MB/ảnh.
- Người đọc có mục lục, hiệu ứng lật trang, zoom, chế độ tối và bookmark.
- Vị trí đọc/bookmark lưu trên thiết bị/trình duyệt hiện tại; chưa đồng bộ nhiều thiết bị. Xóa dữ liệu trình duyệt sẽ mất vị trí đọc.
- Ảnh tải lên bucket `vcl-images` có URL công khai, KỂ CẢ ảnh gắn với bản nháp. Nội dung chữ bản nháp được RLS bảo vệ. Không tải ảnh cần giữ bí mật vào bucket này.
- Xóa truyện có xác nhận và không tự xóa ảnh cũ trong Storage để tránh mất ảnh dùng chung. Có thể dọn ảnh không dùng trong Supabase Storage.
- Quên mật khẩu: dùng phần quản trị người dùng trong Supabase để đặt lại cho tài khoản tác giả. Webapp hiện chưa có màn hình tự khôi phục mật khẩu.
- Dữ liệu và ảnh của project cũ không tự chuyển sang Supabase.

## F. Nếu muốn chỉ dùng GitHub Pages + Supabase (không dùng Cloudflare)

Giao diện đã dùng đường dẫn tương đối nên hỗ trợ GitHub Pages ở đường dẫn repository.

1. Hoàn thành A và B.
2. Trong repository, chọn **Settings → Pages → Build and deployment → Source: GitHub Actions**.
3. Mở `extras/github-pages-workflow.txt`, sao chép nội dung.
4. Trên GitHub chọn **Add file → Create new file**. Đặt tên `.github/workflows/pages.yml`, dán nội dung đã sao chép, Commit.
5. Mở tab **Actions**, đợi workflow hoàn tất; URL xuất hiện ở Settings → Pages. Có thể dùng Run workflow nếu cần.
6. Đặt Site URL trong Supabase bằng URL Pages vừa nhận.

Workflow chỉ phát hành `site`; anh không chạy Node trên máy. Khả năng dùng Pages với repository private phụ thuộc gói GitHub; có thể chọn repository public cho mã nguồn không chứa bí mật. Không cần đồng thời dùng cả GitHub Pages và Cloudflare Pages.

## G. Các lỗi thường gặp

| Thông báo/hiện tượng | Cách xử lý |
|---|---|
| Chưa kết nối Supabase | Điền URL và Publishable key đúng trong `site/config.js`, Commit, đợi deploy |
| `Invalid API key` | Dùng Publishable key hoặc anon public key của đúng project |
| `Invalid login credentials` | Kiểm tra email/mật khẩu và trạng thái xác nhận user trong Authentication |
| Tài khoản chưa có quyền tác giả | Chạy `02-GRANT-AUTHOR.sql` với User UID thật; đăng nhập lại |
| `relation vcl_books does not exist` | Chạy toàn bộ `01-SETUP.sql` trong đúng project |
| `row-level security policy` khi lưu/ảnh | Kiểm tra UID trong `vcl_admins`, phiên đăng nhập và các policy từ SQL; không tắt RLS |
| Ảnh không lên | Đúng bucket `vcl-images`, ảnh <=8 MB, định dạng được hỗ trợ |
| Cloudflare báo thiếu Worker entrypoint | Anh đang tạo Worker; tạo lại theo luồng **Pages**, framework None, build trống, output site |
| Cloudflare chạy npm dù hướng dẫn không yêu cầu | Xóa Build command, framework None; chỉ cần thư mục site. Nếu nền tảng tự cài dependency nhưng không chạy build, đó là xử lý trên cloud, không phải trên máy anh |
| Chỉ thấy README hoặc lỗi 404 | Output directory phải là `site` và repository phải có `site/index.html` |
| Sửa tên trong src mà web không đổi | Luồng không build dùng bản đã biên dịch trong site; sửa mã React cần biên dịch lại. Đăng/sửa truyện không cần biên dịch |

## H. Bàn giao và kiểm chứng

Gói gồm giao diện đã biên dịch `site`, mã nguồn React/TypeScript, cấu hình công khai mẫu, SQL tạo bảng/quyền/kho ảnh và bộ kiểm thử chính sách SQL. Không có mật khẩu hay tài khoản cloud được tạo sẵn.

Công việc này KHÔNG tự tạo project trong tài khoản GitHub/Supabase/Cloudflare của anh. Sau khi anh kết nối ba tài khoản theo hướng dẫn, website mới có dữ liệu vận hành thật. Link ChatGPT xem trước cũ không phải bản Supabase này.

Tài liệu chính thức:
- Supabase RLS: https://supabase.com/docs/guides/database/postgres/row-level-security
- Supabase Storage policies: https://supabase.com/docs/guides/storage/security/access-control
- Cloudflare Pages static: https://developers.cloudflare.com/pages/framework-guides/deploy-anything/
