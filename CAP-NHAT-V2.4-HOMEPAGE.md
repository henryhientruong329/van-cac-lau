# Văn Các Lầu 2.4 — Homepage mới & chữ dễ đọc

## Những thay đổi
- Banner xanh đậm/vàng kem, minh họa sách mở và núi non/trăng sao dạng vector sắc nét.
- Chữ nội dung Arial 15–17 px, tăng độ tương phản; tiêu đề Georgia đậm. Dấu tiếng Việt giữ nguyên; không dùng hiệu ứng làm mờ chữ.
- Nút Đọc ngay mở truyện được đề cử, hoặc tác phẩm công khai đầu tiên. Không có truyện thì dẫn đến thư viện.
- Khối đề cử dùng bìa, tóm tắt, tác giả, thể loại và số chương thật từ Supabase. Admin chọn đề cử trong thư viện như bản 2.2.
- Khối Đọc tiếp hiện khi có vị trí đọc đã lưu trên thiết bị. Chọn tác phẩm đang đọc đầu tiên trong thứ tự thư viện, không khẳng định đây là cuốn mở gần nhất.
- Thư viện nằm trước phần chọn giao diện đọc; lọc thể loại tự lấy từ các truyện công khai, kết hợp loại truyện/tìm kiếm/bộ sưu tập. Có nút xóa bộ lọc.
- Thiết kế co giãn, nút lớn hơn, có lối vào cộng đồng. Giữ các chức năng thành viên/admin/bình luận/đánh giá/chia sẻ.

## Cập nhật bằng trình duyệt — không cài Node
1. Giải nén ZIP.
2. Vào repository GitHub đang liên kết với Cloudflare. Chọn Add file → Upload files.
3. Đưa thư mục `site` lên ĐÈ/GỘP với thư mục `site` hiện tại. Không xóa thư mục cũ: phải giữ `site/config.js` chứa kết nối Supabase của anh. ZIP không chứa tệp này để tránh ghi đè.
4. Cập nhật thêm `src`, `public` và các tệp mã nguồn ở gốc nếu muốn lưu đầy đủ source. Đừng thay `public/config.js` hoặc `wrangler.jsonc` cũ của anh.
5. Commit changes. Đợi Cloudflare triển khai thành công, rồi mở website và nhấn Ctrl+F5. Cloudflare vẫn dùng assets.directory = ./site; build command để trống và deploy command giữ như cấu hình hiện có.

Nếu website đang ở bản 2.3: KHÔNG cần chạy SQL mới. Bản 2.4 chỉ thay giao diện.
Nếu website chưa lên 2.3: xem hướng dẫn 2.3 đi kèm và chạy SQL 03 → 04 → 05 còn thiếu theo đúng thứ tự. Không chạy lại SQL01 sau các migration.

## Kiểm tra sau cập nhật
- Banner/ảnh minh họa xuất hiện, chữ có dấu rõ; thử trên điện thoại.
- Truyện đề cử xuất hiện nếu có tác phẩm công khai; bấm Đọc ngay.
- Thử chọn thể loại, tìm tên sách, xóa bộ lọc.
- Đọc vài trang, trở về trang chủ, chọn Đọc tiếp.
- Thử vào cộng đồng, tài khoản và Admin Portal.

## Xác minh
Build TypeScript/Vite thành công; 63 kiểm thử sẵn có đều đạt. Đã xem homepage và kiểm tra bộ lọc loại truyện/điều hướng cộng đồng trong trình duyệt preview. Preview không có cấu hình Supabase thật nên chưa kiểm tra dữ liệu thật, bìa thật hoặc các thao tác tài khoản trên website của anh. Chưa triển khai trực tiếp lên Cloudflare của anh. Việc phù hợp nội dung theo độ tuổi tùy thuộc tác phẩm anh đăng; bản này không thêm hệ thống phân loại độ tuổi.
