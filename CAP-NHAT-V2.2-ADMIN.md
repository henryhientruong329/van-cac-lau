# Văn Các Lầu 2.2 — Admin Portal

Bản nâng cấp trên website hiện có: GitHub + Cloudflare + Supabase. Anh KHÔNG cần cài Node, Git hay chạy lệnh trên máy.

## Các quyền và chức năng mới

| Khu vực | Quyền quản trị thực hiện được |
|---|---|
| Tổng quan | Xem tổng thành viên, thành viên mới 7 ngày, đang khóa, số tác phẩm, nháp, công khai, lưu trữ và sách ghim |
| Thành viên | Tìm theo email/tên hiển thị; xem ngày đăng ký và đăng nhập cuối; khóa/mở khóa có lý do; thay đổi vai trò |
| Thư viện | Biên tập tác phẩm; ghim/bỏ ghim; đặt thứ tự; phân bộ sưu tập; xuất bản/chuyển nháp; lưu trữ/khôi phục |
| Nhật ký | Xem người thao tác, thời điểm, đối tượng và thay đổi; tìm lại lịch sử bằng phân trang; xuất JSON trang nhật ký |
| Thông báo & quyền | Đăng thông báo công khai trên thư viện, xem ma trận quyền |
| Xuất dữ liệu | Tải toàn bộ dữ liệu tác phẩm mà admin đang quản lý thành JSON |

### Ba vai trò

| Vai trò | Phạm vi |
|---|---|
| Thành viên | Đọc truyện công khai, quản lý hồ sơ và template của mình |
| Biên tập viên | Quyền thành viên + thêm/sửa/xuất bản nội dung trên TOÀN BỘ tác phẩm trong thư viện; tải ảnh. Không quản trị thành viên, ghim, sắp xếp, lưu trữ, xóa vĩnh viễn hay xem nhật ký |
| Quản trị viên | Toàn bộ quyền trên + quản trị thành viên/vai trò, thư viện, thông báo, nhật ký và xuất dữ liệu. Có thể xóa vĩnh viễn tác phẩm trong bàn viết như trước; nên lưu trữ nếu chỉ muốn ẩn |

Tài khoản đã có trong `vcl_admins` từ bản trước giữ nguyên quyền quản trị. Không tự cấp quyền cho thành viên mới qua email hoặc user_metadata. Chỉ admin đang hoạt động được cấp/thu hồi vai trò qua Portal.

## 1. Nâng cấp Supabase trước

1. Đăng nhập Supabase Dashboard, mở đúng project đang dùng cho Văn Các Lầu.
2. Nếu đã cài bản 2.1, mở SQL Editor → New query, sao chép toàn bộ `supabase/04-ADMIN-PORTAL.sql` và bấm Run.
3. Nếu chưa cài 2.1, chạy `supabase/03-MEMBERS-UPGRADE.sql` trước, rồi chạy 04.
4. Không chạy lại file 01 của bản cũ SAU khi chạy 04: file cũ có thể thay các chính sách quyền mới. Gói nâng cấp này không cần tạo lại database/bucket.

File 04 bổ sung các bảng vai trò biên tập, trạng thái thành viên, nhật ký, thông báo; thêm cột ghim/thứ tự/lưu trữ/bộ sưu tập cho tác phẩm; thay các policy để khóa được thi hành tại cơ sở dữ liệu. Không xóa truyện, ảnh, thành viên hay admin hiện có. Có thể chạy lại 04 mà không mất dữ liệu.

**Không cần service_role key, Worker Secret, API token quản trị hay Edge Function.** Các thao tác quản trị được thực hiện qua các hàm SQL có kiểm tra quyền của người đang đăng nhập. Key bí mật không được đưa lên GitHub/browser.

## 2. Cập nhật GitHub

1. Giải nén ZIP.
2. Mở repository đang kết nối với Cloudflare, tại cấp chứa `site` và `src`.
3. Chọn Add file → Upload files, tải các thư mục **site**, **src**, **supabase** trong gói này vào đúng vị trí. Có thể tải kèm **tests**, package.json/package-lock.json và các file mã nguồn cấp gốc để lưu đủ phiên bản.
4. Commit changes; chờ Cloudflare triển khai thành công.
5. Giữ Build command trống. Với Worker hiện tại, giữ `npx wrangler deploy` và `assets.directory: ./site` như đang dùng.
6. Mở website, Ctrl + F5, đăng nhập tài khoản tác giả/quản trị hiện có.

**Không xóa thư mục site cũ trước khi upload.** ZIP không kèm site/config.js, public/config.js hoặc wrangler.jsonc; vì vậy không ghi đè thông tin Supabase hay cấu hình Cloudflare của anh.

## 3. Mở Admin Portal

- Khi đăng nhập bằng tài khoản quản trị đang hoạt động, đầu trang xuất hiện nút **Quản trị** (trên màn hình nhỏ hiện biểu tượng bánh răng).
- Hoặc mở **Tài khoản → Admin Portal**.
- Thành viên và biên tập viên không được vào Portal. Nếu tự gọi RPC từ trình duyệt, Supabase cũng từ chối.

Nếu không thấy nút Quản trị:
1. Xác nhận file SQL 04 đã Run thành công.
2. Kiểm tra đang đăng nhập đúng email có UID trong `vcl_admins`.
3. Nếu tài khoản chưa được cấp quyền từ bản trước, dùng Supabase SQL Editor chạy file 02-GRANT-AUTHOR của gói cũ với UID thật. Quyền quản trị đầu tiên phải được chủ project cấp trong SQL Editor, không có chức năng tự nhận admin.
4. Đăng xuất và đăng nhập lại.

## 4. Quản lý thành viên

1. Chọn **Thành viên**, nhập email/tên hiển thị rồi bấm Tìm kiếm.
2. Bấm **Khóa**, nhập lý do tối thiểu 3 ký tự, xác nhận tài khoản và lưu.
3. Bấm **Mở khóa** để khôi phục quyền. Hồ sơ và dữ liệu vẫn được giữ.
4. Bấm **Đổi quyền**, chọn Thành viên / Biên tập viên / Quản trị viên, đọc phạm vi và xác nhận.

Danh sách lấy tài khoản trong project Supabase đang kết nối, kể cả người chưa lưu hồ sơ. Chỉ admin nhìn thấy email và danh sách quản trị này. Đây là website sử dụng project Supabase riêng cho Văn Các Lầu như hướng dẫn tạo ban đầu.

### Khóa có nghĩa gì?

- Đây là **khóa quyền dùng tài khoản trong Văn Các Lầu**, không phải ban tài khoản Supabase Auth cấp nền tảng.
- Đăng nhập qua website sẽ kiểm tra trạng thái và đăng xuất ngay nếu đã khóa.
- RLS chặn ngay các thao tác được bảo vệ với JWT còn hiệu lực: ghi/đọc hồ sơ riêng, thêm/sửa truyện, tải ảnh, quản trị.
- Phiên đang mở sẽ được kiểm tra lại khi lấy focus và định kỳ khoảng 60 giây; giao diện quản trị/biên tập đóng lại nếu mất quyền hoặc bị khóa. Dữ liệu đã được tải xuống trước đó không thể thu hồi khỏi thiết bị.
- Truyện công khai vẫn đọc được như khách. Khóa không thể ngăn một người mở trình duyệt ẩn danh để xem nội dung công khai.
- Không thể tự khóa hoặc đổi vai trò của chính admin đang thao tác. Thay đổi trạng thái/quyền được tuần tự hóa để admin đã bị khóa không khóa ngược người còn lại.

Nếu cần ban ở Supabase Auth, thu hồi phiên cấp nền tảng, xóa tài khoản hoặc đặt lại mật khẩu cho người khác, thực hiện trong Supabase Dashboard. Portal này không giả lập các chức năng đó và không ghi trực tiếp vào bảng auth.users.

## 5. Sắp xếp và quản lý thư viện

### Ghim
Bấm **Ghim** trên tác phẩm muốn đề cử. Tác phẩm ghim đứng trước tác phẩm không ghim trong thư viện công khai; có nhãn Đề cử.

### Vị trí
Bấm **Vị trí & bộ sưu tập**. Nhập số vị trí hoặc dùng nút đưa lên/xuống 10 bậc:
- Số nhỏ đứng trước: 10, 20, 30...
- Mặc định tác phẩm có vị trí 1000.
- Sắp theo: ghim trước → vị trí tăng dần → cập nhật mới trước → ID để ổn định khi trùng.
- Một tác phẩm không ghim không vượt tác phẩm đã ghim dù số vị trí nhỏ hơn. Nếu muốn vượt, ghim tác phẩm đó hoặc bỏ ghim tác phẩm trước.

### Bộ sưu tập
Trong cùng hộp thoại, đặt tên kệ như “Tuyển tập kiếm hiệp”, “Những chuyện tình”, “Hành trình tương lai”. Bộ sưu tập có tác phẩm đang công khai sẽ hiện ở bộ lọc trên thư viện. Đổi vị trí và bộ sưu tập được lưu cùng một giao dịch để không xảy ra lưu một nửa.

### Xuất bản và lưu trữ
- **Chuyển về nháp**: giữ nội dung, bỏ trạng thái công khai.
- **Xuất bản**: đưa tác phẩm không lưu trữ lên thư viện công khai.
- **Lưu trữ**: ẩn cả tác phẩm đang công khai tại RLS nhưng vẫn giữ toàn bộ dữ liệu.
- **Khôi phục**: bỏ cờ lưu trữ. Nếu tác phẩm vẫn có trạng thái xuất bản, nó công khai trở lại; hộp xác nhận có nhắc điều này.
- Sách đã lưu trữ cần khôi phục trước khi đổi trạng thái xuất bản tại Portal.
- Nên dùng Lưu trữ thay cho Xóa vĩnh viễn khi chỉ muốn ẩn.

Từ bản 2.2, các cuốn minh họa không được trộn vào thư viện dữ liệu thật. Khi chưa có sách công khai, thư viện sẽ hiện trạng thái trống. Khung hero dùng cuốn đầu tiên đang công khai hoặc một bìa minh họa nếu thư viện trống.

## 6. Nhật ký và xuất dữ liệu

- Nhật ký bắt đầu từ lúc cài file 04; không dựng lại các thao tác đã xảy ra trước đó.
- Ghi thêm/sửa/xóa tác phẩm; thay đổi ghim, vị trí, kệ, lưu trữ, xuất bản; khóa/mở khóa; đổi vai trò; thay thông báo.
- Có người thực hiện, thời điểm, đối tượng, lý do/giá trị thay đổi và metadata trước/sau khi chỉnh sách.
- Người dùng ứng dụng, kể cả admin, không được sửa/xóa trực tiếp nhật ký qua API. Chủ project vẫn có quyền quản trị database trong Supabase.
- Đây không phải lịch sử phiên bản toàn bộ nội dung chương; không có chức năng tự phục hồi bản văn cũ từ log.
- **Xuất JSON thư viện** tải dữ liệu tác phẩm, bao gồm nháp/lưu trữ mà admin được phép xem. Không xuất mật khẩu, khóa API hay file ảnh. Ảnh chỉ được tham chiếu qua URL.
- **Xuất trang nhật ký** chỉ xuất trang đang xem (30 sự kiện), không giả định là toàn bộ log.
- Không có thống kê lượt xem giả lập; dashboard chỉ dùng số liệu tài khoản và tác phẩm thật.

## 7. Kiểm tra sau cập nhật

1. Đăng nhập admin, mở Quản trị, đối chiếu số liệu với project Supabase.
2. Tạo thành viên thử: họ không thấy Portal, không gọi được API quản trị.
3. Khóa thành viên thử, kiểm tra đăng nhập bị từ chối; mở khóa và đăng nhập lại.
4. Cấp vai trò Biên tập viên cho tài khoản thử: được thêm/sửa nội dung nhưng không quản lý thành viên, ghim hay lưu trữ.
5. Ghim tác phẩm, đặt vị trí/kệ và kiểm tra thứ tự trong cửa sổ ẩn danh.
6. Lưu trữ tác phẩm thử, xác nhận không còn đọc được qua thư viện công khai; khôi phục và kiểm tra lại.
7. Xem nhật ký và đăng một thông báo thử.

## Kiểm chứng bàn giao

48 kiểm thử đã đạt, gồm SQL/RLS chạy trên PostgreSQL WASM/PGlite, khóa bằng JWT còn hiệu lực, khóa/mở khóa, phân quyền, bảo vệ tự khóa, lưu trữ, sắp xếp, audit, auth dùng mạng mô phỏng, template và Unicode. TypeScript/Vite đã biên dịch thành công.

Chưa cài SQL hoặc thử UI trực tiếp trên tài khoản Supabase/Cloudflare của anh. Hãy làm bước 1 trước khi cập nhật giao diện, vì các API/cột thư viện mới cần file SQL 04.

Tài liệu Supabase: https://supabase.com/docs/guides/database/postgres/row-level-security và https://supabase.com/docs/reference/javascript/auth-admin-updateuserbyid
