BẢN FIX THÔNG BÁO APP

Copy đúng đường dẫn:

1) web_upload_to_public/app-thong-bao-api.php
   -> copy lên web: C:\Data\AppCore\public\app-thong-bao-api.php

2) lib/config/app_config.dart
3) lib/models/app_notification.dart
4) lib/services/notification_service.dart
5) lib/screens/home_page.dart

Sau đó push GitHub và build APK.

Chức năng:
- App gọi API lấy thông báo từ notification_unread + notification_templates.
- Badge tab Thông báo dùng tổng thông báo thật, không còn số giả.
- Tab Của tôi lấy thông báo cá nhân.
- Tab Hệ thống lấy users.ban/ban_at và bảng thong_bao_he_thong.
- Bấm thông báo cá nhân: API xóa dòng notification_unread, trừ users.thong_bao_chua_xem, rồi mở link liên quan trong app.
- Đọc tất cả: xóa toàn bộ notification_unread của user và reset users.thong_bao_chua_xem = 0.

Nếu app hiện lỗi “Vui lòng đăng nhập lại để xem thông báo” dù đã đăng nhập:
- gửi lại file api/v1/_token.php cho ChatGPT kiểm tra tên hàm xác thực token.
