FIX TRANG CHỦ APP - THÊM BẢN ĐỒ + 4 ICON/HÀNG

File cần thay:
- lib/screens/home_page.dart

Đã sửa:
1. Thêm nút "Bản đồ xây dựng VN" trong khu "Tìm kiếm dịch vụ xây dựng".
   Link mở trong app:
   https://xaydungvn.com.vn/ban-do-osm-vietnam.php

2. Dùng icon:
   assets/icons/ban-do.png

3. Khu "Tìm kiếm dịch vụ xây dựng" và "Đăng tin nhanh" đổi sang 4 nút / 1 hàng cho gọn hơn trên mobile.

4. Giữ lại các sửa trước đó trong home_page.dart:
   - Thông báo API
   - Tab quản lí đã chia nhóm
   - Nút Xác minh xe

Lưu ý:
- Vì pubspec.yaml đã khai báo assets/icons/ nên không cần sửa pubspec nếu file ban-do.png đã nằm đúng trong assets/icons/.
