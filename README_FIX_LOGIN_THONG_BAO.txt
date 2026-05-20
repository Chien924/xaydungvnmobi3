FIX đăng nhập bị mất trạng thái + thông báo

Cách thay file:
1) Thay đè trong app Flutter:
   - lib/config/app_config.dart
   - lib/models/app_notification.dart
   - lib/services/auth_service.dart
   - lib/services/notification_service.dart
   - lib/screens/home_page.dart

2) Copy lên web public:
   - web_upload_to_public/app-thong-bao-api.php
   đến:
   C:\Data\AppCore\public\app-thong-bao-api.php

Nội dung đã sửa:
- Không tự logout app khi API /me hoặc API thông báo trả 401.
- Trang chủ/Tài khoản ưu tiên giữ user cache, tránh hiện sai "chưa đăng nhập".
- Tab Quản lí bỏ khung "Bạn chưa đăng nhập" vì các trang quản lí WebView đã tự kiểm tra session.
- API thông báo nhận token cả qua Authorization header và query/body token để tránh Apache/PHP làm mất header.
- API thông báo dò thêm nhiều tên hàm xác thực token và vài bảng token phổ biến nếu có.

Nếu sau bản này Trang chủ/Tài khoản ổn nhưng Thông báo vẫn chưa hiện, gửi thêm file:
- C:\Data\AppCore\public\api\v1\_token.php
- API login đang dùng nếu có: api/v1/auth/login.php hoặc api/v1/app/login.php
để khớp chính xác hàm xác thực token.
