# Văn Các Lầu 2.5 — Trang Giới thiệu

Thêm trang Giới thiệu với nguyên văn bài viết anh cung cấp, các đoạn tách rõ và phần in đậm giữ nguyên. Ảnh đính kèm đặt trước bài viết; tệp giữ nguyên 1672 × 941 px, không nén, không cắt, không kéo méo. Ảnh thu vừa khung trang khi màn hình nhỏ hơn, có đường dẫn mở kích thước gốc.

Menu Giới thiệu có trên máy tính, điện thoại và chân trang. Trang có đường dẫn `?page=about`, mở trực tiếp, tải lại và dùng Back/Forward được. Giữ tên thương hiệu Văn Các Lầu, logo/favicon mới và các chức năng trước đó.

## Cập nhật — không cần Node
1. Giải nén ZIP.
2. Upload thư mục `site` gộp/ghi đè các tệp tương ứng trên GitHub. KHÔNG xóa thư mục site cũ: giữ nguyên `site/config.js` chứa kết nối Supabase. ZIP không chứa tệp này.
3. Đồng bộ thêm `src`, `public` và các tệp mã nguồn nếu muốn lưu source. Giữ nguyên `public/config.js` và `wrangler.jsonc` hiện có.
4. Commit, chờ Cloudflare deploy thành công rồi Ctrl+F5. Giữ cấu hình assets ./site và build command trống như hiện tại.
5. Chọn Giới thiệu để xem bài viết, bấm ảnh để mở bản gốc và thử nút Khám phá thư viện cuối bài.

Bản 2.5 không thêm SQL. Nếu đã chạy migration 03/04/05 ở các bản trước thì không cần chạy lại. Nếu chưa, xem hướng dẫn 2.3 kèm theo.

Đã build TypeScript/Vite thành công và kiểm tra trực quan trang Giới thiệu qua browser preview, xác nhận ảnh tải đúng kích thước tự nhiên 1672 × 941. Không chỉnh logic tài khoản hoặc dữ liệu. Chưa triển khai lên website Cloudflare của anh.
