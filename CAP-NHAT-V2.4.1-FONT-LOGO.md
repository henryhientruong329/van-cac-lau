# Văn Các Lầu 2.4.1 — Font toàn ứng dụng, logo và favicon mới

## Nội dung
- Thống nhất font Arial/Helvetica/Liberation Sans cho toàn bộ trang, tiêu đề, biểu mẫu, bìa tạo tự động, trình đọc và quản trị. Gỡ font Google và font serif/italic cũ gây hình dáng dấu không đồng nhất giữa thiết bị.
- Tăng cỡ chữ phụ, bình luận, nút, thông tin đánh giá, chia sẻ, tài khoản và quản trị; tăng tương phản cộng đồng và khoảng cách dòng để dấu tiếng Việt không chạm dòng bên trên.
- Giữ nguyên nội dung tác phẩm; xử lý NFC tiếng Việt vốn có vẫn được giữ. Không tự sửa chính tả hoặc dấu tác giả đã nhập sai.
- Thay logo đầu trang/chân trang/Admin Portal bằng hình Văn Các Lầu anh cung cấp. Không chỉnh sửa hình gốc.
- Favicon mới lấy phần biểu tượng lầu/trăng/sách từ chính ảnh logo thông qua vùng hiển thị SVG, có nhúng ảnh nên không lệ thuộc đường dẫn bên ngoài. Thêm phiên bản favicon để giảm hiện tượng trình duyệt giữ icon cũ.
- Giữ các chức năng của bản 2.4, cộng đồng và quản trị.

## Cập nhật qua GitHub
1. Giải nén ZIP.
2. Upload thư mục `site` để GỘP/ghi đè các tệp tương ứng trên GitHub; đừng xóa toàn bộ site cũ.
3. Giữ nguyên `site/config.js` và `public/config.js` chứa Supabase, cùng `wrangler.jsonc` hiện có. ZIP không chứa các tệp cấu hình này.
4. Có thể upload thêm `src`, `public`, `tests`, `supabase` và các tệp source để đồng bộ mã nguồn.
5. Commit changes, chờ Cloudflare triển khai thành công. Không cần cài Node; giữ build command trống và cấu hình deploy hiện tại.
6. Nhấn Ctrl+F5 để tải CSS mới. Nếu favicon còn cũ, đóng tab rồi mở lại hoặc thử cửa sổ riêng tư.

Đang ở bản 2.3/2.4: KHÔNG cần SQL mới. Nếu chưa áp dụng migration 03/04/05, xem hướng dẫn 2.3 kèm theo. Không chạy lại SQL01 sau migration.

## Kiểm tra
Build TypeScript/Vite và 63 kiểm thử đều đạt. Đã xem logo và font cộng đồng trong trình duyệt; kiểm tra computed font của tiêu đề là Arial/local sans. Rà các khai báo font trong toàn bộ CSS và bổ sung cỡ chữ cho các bề mặt còn lại. Chưa đăng nhập Supabase thật để kiểm thử trực quan các trang tài khoản/admin và chưa triển khai lên website Cloudflare của anh.
