# Văn Các Lầu 2.3 — Cộng đồng, đánh giá sao và chia sẻ truyện

Bản nâng cấp trên webapp hiện tại: GitHub + Cloudflare + Supabase. Không cần cài Node hoặc chạy lệnh trên máy của anh.

## 1. Những chức năng mới

### Trang Cộng đồng
- Có mục Cộng đồng trên thanh điều hướng máy tính và thanh Thư viện / Cộng đồng trên điện thoại.
- Có thể mở trực tiếp bằng URL website cộng `?page=community`.
- Thành viên đang hoạt động có thể đăng chủ đề, bình luận và trả lời.
- Chuyên mục: Cảm nhận, Thảo luận, Gợi ý truyện.
- Khách vẫn được đọc nhưng cần đăng nhập để tương tác.
- Có tên hiển thị, thời điểm đăng, đánh dấu spoiler, xóa nội dung của mình và báo cáo vi phạm.
- Hỗ trợ một tầng trả lời trong mỗi cuộc trò chuyện; không tạo chuỗi trả lời lồng vô hạn.
- Giới hạn 3–3000 ký tự/nội dung, tiêu đề tối đa 120 ký tự; tối thiểu 15 giây giữa các lần đăng. Giới hạn được kiểm tra trong Supabase.

### Bình luận và đánh giá từng truyện
- Mở trang chi tiết cuốn truyện: dưới phần tóm tắt và nút Đọc sách có phần Cảm nhận của độc giả.
- Mỗi thành viên được chọn 1–5 sao cho mỗi truyện. Bấm số sao mới để sửa; số lượt không bị tăng khi cùng một thành viên đổi điểm.
- Có thể gỡ đánh giá của mình.
- Hiển thị điểm trung bình, số lượt và phân bố 1–5 sao từ dữ liệu thật. Không có đánh giá mẫu giả.
- Thẻ sách trong thư viện hiển thị điểm trung bình và số lượt khi tải được dữ liệu.
- Bình luận của từng truyện tách riêng với Cộng đồng chung.

### Chia sẻ qua Zalo, Messenger và email
- Có nút Chia sẻ truyện trên trang chi tiết và biểu tượng chia sẻ trong trình đọc.
- Mỗi cuốn công khai có URL riêng dạng `https://TEN-WEBSITE/?book=UUID`.
- Người nhận mở link sẽ thấy đúng trang chi tiết tác phẩm; không cần đăng nhập để đọc truyện công khai.
- Link được tạo từ địa chỉ website đang chạy; giữ đường dẫn repository nếu dùng GitHub Pages và không mang theo query/fragment đăng nhập.
- Trên thiết bị hỗ trợ Web Share, các nút Zalo/Messenger mở hộp chọn chia sẻ của thiết bị: người đọc chọn ứng dụng, người nhận và tự xác nhận gửi.
- Website không thể ép hệ điều hành hiển thị ứng dụng chưa cài hoặc trình duyệt không hỗ trợ. Nếu không có Web Share, website sao chép link và đưa lựa chọn mở Zalo Web / Messenger để người đọc dán link vào cuộc trò chuyện.
- Nếu Clipboard bị chặn, có ô link để chọn và sao chép thủ công.
- Nút Email mở bản nháp qua ứng dụng email mặc định bằng mailto, có tên truyện và link; người đọc tự chọn người nhận và gửi. Chia sẻ email này không dùng SMTP của Supabase.
- Không tự gửi tin nhắn, không đăng thay người dùng, không lấy danh bạ và không cần Meta App ID/Zalo app credentials cho cơ chế chia sẻ này.
- Chỉ chia sẻ tác phẩm công khai, không lưu trữ. Truyện rút khỏi công khai sau đó sẽ không mở được từ link cũ.
- Website hiện là bản tĩnh: ảnh/bìa và tiêu đề xem trước khi dán vào ứng dụng chat có thể là thông tin chung của website; chưa có Open Graph được tạo phía máy chủ riêng cho từng cuốn. Việc mở đúng truyện không phụ thuộc khung xem trước này.

## 2. Nâng cấp Supabase trước khi tải giao diện mới

1. Mở project Supabase đang dùng cho Văn Các Lầu → SQL Editor → New query.
2. Nếu đang dùng bản 2.2 và đã cài file 04: chỉ cần chạy toàn bộ `supabase/05-COMMUNITY-RATINGS.sql`.
3. Nếu chưa cài 2.1/2.2: chạy `03-MEMBERS-UPGRADE.sql`, rồi `04-ADMIN-PORTAL.sql`, rồi `05-COMMUNITY-RATINGS.sql` theo thứ tự. Cả ba được kèm trong ZIP.
4. Không tạo lại database/bucket, không xóa bảng, không chạy lại file 01 cũ sau các bản nâng cấp vì có thể ghi đè policy mới.
5. File 05 tạo bảng bình luận, báo cáo và đánh giá; tạo các RPC đọc/ghi có kiểm soát. Có thể chạy lại mà không mất dữ liệu.

Không cần khóa bí mật, service_role key, Worker Secret, Edge Function hoặc công cụ Node trên máy.

Đăng ký/xác nhận email cho thành viên vẫn dùng Supabase Auth và SMTP đã cấu hình từ bản 2.1. Bản này không thay cấu hình SMTP. Nút chia sẻ Email là ứng dụng email của chính người đọc, không phải chức năng gửi email từ máy chủ.

## 3. Cập nhật GitHub và Cloudflare

1. Giải nén ZIP.
2. Tại thư mục gốc repository GitHub đang kết nối với Cloudflare, chọn Add file → Upload files.
3. Tải ba thư mục **site**, **src** và **supabase** vào đúng chỗ. Có thể lưu kèm tests và các file mã nguồn cấp gốc để quản lý đủ phiên bản.
4. Commit changes, chờ Cloudflare triển khai thành công.
5. Giữ Build command trống. Với Worker đang dùng, giữ `npx wrangler deploy` và cấu hình `assets.directory: ./site` hiện có.
6. Mở website, Ctrl + F5, đăng nhập và kiểm tra.

**Không xóa thư mục site cũ trước khi tải lên.** ZIP không kèm `site/config.js`, `public/config.js` hoặc `wrangler.jsonc`, nên không ghi đè khóa công khai Supabase hay cấu hình triển khai.

## 4. Kiểm duyệt trong Admin Portal

- Mở **Quản trị → Cộng đồng**.
- Các tab: Cần xem xét, Tất cả nội dung, Đang ẩn.
- Quản trị viên xem được lý do báo cáo; email người đăng chỉ hiện trong khu vực quản trị.
- Chọn Ẩn nội dung, Khôi phục hoặc Đã xem xét, giữ nguyên; nhập ghi chú khi công cụ hỏi.
- Ẩn chủ đề sẽ chặn việc đọc các trả lời trong cuộc trò chuyện ở API công khai. Người đăng vẫn có thể thấy nội dung đang ẩn của chính mình kèm nhãn trạng thái.
- Nội dung người đăng đã xóa không được khôi phục. Nếu chủ đề đã xóa nhưng còn trả lời, phần công khai chỉ giữ dòng thông báo đã xóa để bảo toàn mạch trao đổi; không hiện lại nội dung hoặc tiêu đề cũ.
- Không thể dùng thao tác tự xóa để làm hiện lại một chủ đề đang bị admin ẩn.
- Một người chỉ báo cáo một nội dung một lần; không báo cáo chính mình. Các báo cáo được đánh dấu đã xử lý khi admin quyết định.
- Các thao tác kiểm duyệt được ghi vào Nhật ký thao tác của bản 2.2.
- Chỉ quản trị viên được kiểm duyệt; biên tập viên không có quyền quản trị cộng đồng.

Bình luận mới của thành viên đang hoạt động xuất hiện ngay và có thể bị admin ẩn sau đó; đây không phải hàng chờ duyệt trước khi đăng. Không có bộ lọc AI tự động hay tự kiểm chứng nội dung.

## 5. Quyền riêng tư và dữ liệu

- Tên hiển thị được công khai khi đăng chủ đề/bình luận. Email, ID tài khoản và thông tin người báo cáo không được đưa ra feed công khai.
- Nội dung là văn bản thuần, được hiển thị an toàn bằng React; không cho chèn HTML/script, không hỗ trợ file đính kèm trong Cộng đồng ở bản này.
- Xóa bình luận là gỡ khỏi hiển thị công khai. Bản ghi gốc có thể được quản trị viên xem trong công cụ kiểm duyệt; không hứa xóa vật lý khỏi database.
- Một đánh giá gắn với tài khoản đã đăng nhập, không khẳng định danh tính thực của người đọc hoặc xác minh họ đã đọc hết truyện.
- Khóa tài khoản chặn đăng bình luận, trả lời, báo cáo, đánh giá và thao tác bảo vệ khác ngay tại RPC. Nội dung/đánh giá đã đăng không tự bị xóa khi khóa; quản trị viên xử lý bình luận vi phạm qua công cụ kiểm duyệt.
- Tác phẩm chuyển nháp/lưu trữ sẽ không trả về bình luận hoặc thống kê đánh giá ở API công khai. Dữ liệu được giữ để dùng lại nếu xuất bản trở lại.
- Xóa vĩnh viễn một tác phẩm sẽ xóa các bình luận/đánh giá liên quan theo quan hệ database; dùng lưu trữ nếu muốn giữ dữ liệu.
- Trang cộng đồng cần Làm mới/tải lại để thấy nội dung vừa được người khác đăng; bản này chưa dùng Supabase Realtime.

## 6. Kiểm tra sau triển khai

1. Mở Cộng đồng bằng cửa sổ ẩn danh: đọc được, muốn viết phải đăng nhập.
2. Đăng nhập thành viên thử, tạo chủ đề và trả lời bằng tài khoản khác.
3. Mở truyện, chọn 4 sao rồi đổi thành 5 sao: tổng lượt vẫn là một lượt của tài khoản đó.
4. Kiểm tra điểm trung bình và bình luận trong trang chi tiết, rồi kiểm tra thẻ thư viện.
5. Dùng một tài khoản khác báo cáo bình luận; admin vào Quản trị → Cộng đồng, ẩn nội dung và kiểm tra phía khách.
6. Thử chia sẻ trên điện thoại qua ứng dụng cài sẵn; trên máy tính, thử sao chép link rồi mở Zalo Web/Messenger.
7. Gửi link vào cửa sổ ẩn danh hoặc thiết bị khác để xác nhận mở đúng truyện. Thử chuyển truyện về nháp để xác nhận link cũ không mở nội dung riêng.

## Kiểm chứng bàn giao

63 kiểm thử đã đạt: quyền dữ liệu, phân quyền, moderation, bình luận, chống giả danh, đánh giá một lần/tài khoản, điểm trung bình, tài khoản khóa, truyện lưu trữ, không lộ email/ID tài khoản trong feed và URL chia sẻ không kèm token đăng nhập. Các policy/RPC chạy trên PostgreSQL WASM/PGlite; Auth có kiểm thử mạng mô phỏng. Đã biên dịch TypeScript/Vite thành công.

Chưa cài SQL hoặc thử trực tiếp trên tài khoản Supabase/Cloudflare của anh. Chưa xác minh Zalo/Messenger hoặc trình duyệt cụ thể trên thiết bị của anh. Luồng dự phòng sao chép link vẫn được cung cấp.

Tham khảo: https://www.w3.org/TR/web-share/ và https://developers.zalo.me/docs/social/share
