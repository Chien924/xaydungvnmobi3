Bản fix này xử lý:

1. Tối ưu mượt app
- Tắt preload WebView hàng loạt.
- Giảm cache WebView còn 6 controller.
- Chèn CSS app=1 để tắt animation/transition/smooth-scroll nặng trong WebView.
- Giữ upload ảnh/file, link ngoài và tai-cv.php như bản trước.

2. Thông báo
- Không hiện câu “Vui lòng đăng nhập...” trong app.
- Gửi thêm app_user_id/app_username để API thông báo lấy đúng dữ liệu khi token API chưa khớp.
- Chuông thông báo lấy lại unread_count thật từ notification_unread.

3. Màn hình lỗi mạng/web lỗi
- Nếu không có mạng hoặc web không mở được, hiện màn hình gọn: Không mở được trang / Thử lại / Mở trình duyệt.

Cách dùng:
- Thay đè toàn bộ file trong ZIP vào app.
- Copy web_upload_to_public/app-thong-bao-api.php lên public web:
  C:\Data\AppCore\public\app-thong-bao-api.php
- Push GitHub build APK lại.
