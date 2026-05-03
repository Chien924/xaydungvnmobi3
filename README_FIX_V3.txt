BẢN SỬA XAYDUNGVNMOBI3

Đã sửa:
- Tìm gói thầu / Đơn hàng vật tư có fallback: .php, không .php, trang thay thế.
- Tạo tài khoản chuyển sang màn native, gọi API auth/register.php trước, app/register.php sau.
- Đăng nhập/me chuyển sang ưu tiên API cũ: /api/v1/auth/login.php, /api/v1/account/me.php.
- Tài khoản/nạp tiền/lịch sử/thông tin cá nhân vẫn mở web trong app, có app=1 và fallback.
- Hỗ trợ bot chat là app cứng, gọi /bot-api.php của web, nếu API không khớp thì dùng trả lời dự phòng.
- WebView không mở Chrome ngoài app, tự thêm app=1 để bỏ head.

Lưu ý web:
- Nếu dùng API cũ, upload thư mục v1 lên: C:\Data\AppCore\public\api\v1\
- Các head vẫn cần xử lý ?app=1 để ẩn menu web.

Upload GitHub:
- Upload toàn bộ nội dung thư mục này, để pubspec.yaml nằm ngoài cùng repo.
- Actions -> Build Android APK -> Run workflow.
