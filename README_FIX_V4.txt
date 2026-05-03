BẢN FIX V4

1) APP FLUTTER
- Tìm gói thầu mở đúng: /tim-goi-thau.php
- Tìm nhu cầu mở đúng: /tim-kiem-nhu-cau.php
- Thông tin cá nhân mở đúng: /thong-tin-ca-nhan.php
- Nạp tiền mở đúng: /nap-tien.php
- Không dò nhiều link fallback nữa.
- WebView cache mạnh hơn: giữ tối đa 8 WebView đã mở, mở lại nhanh; quá 8 tự xoá cache cũ.
- WebView tự thêm app=1 và ép ẩn head/menu thêm bằng JavaScript nếu web còn sót.
- Hỗ trợ chuyển sang trang web test app-ho-tro-test.php nhúng trong app.

2) FILE PHP CẦN UP LÊN WEB
Copy 3 file trong thư mục web_upload_to_public vào:
C:\Data\AppCore\public\

Gồm:
- app-ho-tro-test.php
- app-dang-ky-api.php
- app-dang-ky-test.php

Test nhanh:
https://xaydungvn.com.vn/app-ho-tro-test.php?app=1
https://xaydungvn.com.vn/app-dang-ky-test.php

3) LƯU Ý ĐĂNG KÝ
app-dang-ky-api.php dùng bảng users và password_hash().
Nếu login API cũ của bạn chưa hỗ trợ password_hash/password_verify thì đăng ký tạo được nhưng đăng nhập có thể chưa vào được. Khi đó sửa login API để dùng password_verify.
