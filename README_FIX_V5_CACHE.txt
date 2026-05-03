Bản V5 cache mạnh

Đã sửa:
- App preload sẵn nhiều trang web chính khi mở app.
- Giữ cache WebView tối đa 80 controller, quá thì tự bỏ controller cũ khỏi bộ nhớ.
- Không clearCache để không xoá cache HTML/CSS/JS/icon của WebView.
- Nếu trang đã tải rồi, bấm lại mở gần như ngay.
- Sau đăng nhập/đăng xuất sẽ reset controller và preload lại để web nhận đúng session.
- Các link quan trọng giữ đúng:
  + tim-goi-thau.php
  + tim-kiem-nhu-cau.php
  + thong-tin-ca-nhan.php
  + nap-tien.php
  + lich-su-cua-toi.php
- Tab Hỗ trợ mở app-ho-tro-test.php và trang này gọi bot API cũ tại /bot%20chat/bot-api.php.

Copy file web nếu cần:
- web_upload_to_public/app-ho-tro-test.php -> C:\Data\AppCore\public\app-ho-tro-test.php

Upload source lên GitHub repo xaydungvnmobi3 rồi chạy Actions build lại APK.
