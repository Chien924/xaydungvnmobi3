FIX đăng nhập + thông báo sau khi gộp các bản sửa trang chủ/quản lí/bản đồ.

Thay đè trong app:
- lib/screens/home_page.dart
- lib/services/auth_service.dart
- lib/services/notification_service.dart
- lib/config/app_config.dart
- lib/models/app_notification.dart

Copy lên web:
- web_upload_to_public/app-thong-bao-api.php
  => C:\Data\AppCore\public\app-thong-bao-api.php

Nội dung sửa:
1. Không tự logout khi API /me hoặc API thông báo trả 401/lỗi tạm thời.
2. Trang chủ/Tài khoản ưu tiên dùng user cache, tránh hiện out giả khi WebView vẫn còn đăng nhập.
3. Tab Quản lí không hiện khung "Bạn chưa đăng nhập" nữa vì từng trang web đã tự kiểm tra phiên đăng nhập.
4. Giữ lại các sửa giao diện mới: quản lí chia nhóm, xác minh xe, bản đồ xây dựng VN, 4 icon/hàng.
5. Giữ API thông báo cho app.

Nếu sau khi thay vẫn chưa có thông báo: kiểm tra trực tiếp URL
https://xaydungvn.com.vn/app-thong-bao-api.php?action=list&token=TOKEN_APP
Nếu trả 401 thì cần gửi lại file api/v1/_token.php ở dạng .zip hoặc .php rời để khớp chính xác hàm xác thực token.
