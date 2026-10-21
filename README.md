# Văn Các Lầu

**Dành cho Henry — không cần cài Node hay chạy lệnh trên máy.**

Mở **BAT-DAU-O-DAY.md** để làm từng bước bằng trình duyệt.

- GitHub: lưu và cập nhật mã website.
- Supabase: truyện, chương, ảnh và đăng nhập tác giả.
- Cloudflare Pages hoặc GitHub Pages: phát hành website.

## Cloudflare Pages

| Thiết lập | Giá trị |
|---|---|
| Framework | None |
| Build command | Để trống |
| Output directory | site |

Sửa `site/config.js` với Project URL và Publishable key của Supabase. Chạy hai file trong thư mục `supabase` qua SQL Editor theo hướng dẫn. Không đưa mật khẩu hoặc service_role key vào GitHub.

Thư mục `site` là bản hoàn chỉnh đã biên dịch để phát hành. `src` là mã nguồn dành cho lập trình viên. Không cần D1/R2, Worker Secret hay Wrangler của bản cũ.

## Dành riêng cho lập trình viên

Nếu sửa React rồi biên dịch lại, cập nhật `public/config.js` bằng các giá trị công khai trước khi build (Vite sao chép file này vào `site`). Build mới sẽ thay thế `site/config.js`.

- `npm ci` rồi `npm run build`: tạo bản site mới.
- `npm test`: kiểm tra các policy với PostgreSQL WASM (PGlite), không cần Supabase thật.

Kiểm thử không thay cho việc kiểm tra lại cấu hình và quyền trên project Supabase thật.
