BẢN V10 - sửa bot nhận đăng nhập app

Lỗi cũ:
- App đã đăng nhập bằng token native.
- Bot PHP cũ kiểm tra PHP session nên vẫn báo chưa đăng nhập.

Đã sửa:
1. App gửi token khi gọi bot.
2. Thêm file bot-api-app.php để nhận token, set $_SESSION, rồi gọi bot cũ trong /bot chat/bot-api.php.
3. Bot API trong app đổi sang /bot-api-app.php.

Cần copy lên web:
Copy toàn bộ file trong web_upload_to_public vào C:\Data\AppCore\public\
Quan trọng nhất:
- bot-api-app.php

Test:
https://xaydungvn.com.vn/bot-api-app.php?action=ping

Sau đó upload source lên GitHub và build APK lại.
