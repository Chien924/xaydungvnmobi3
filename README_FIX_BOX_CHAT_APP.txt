FIX BOX CHAT APP - lọc từ khóa mạnh hơn, không cần đăng nhập

File cần thay:

1) web_upload_to_public/bot-api-app.php
   Copy lên web:
   C:\Data\AppCore\public\bot-api-app.php

2) lib/services/support_bot_service.dart
   Thay đè trong project app Flutter.

Nội dung đã sửa:
- App hỏi bot không cần đăng nhập, không gửi token/session.
- bot-api-app.php dùng bộ lọc từ khóa mạnh giống box chat web:
  + bỏ dấu tiếng Việt
  + nhận không dấu
  + nhận gõ sai nhẹ
  + nhận viết tắt k/ko/dc/ck/sdt/mk/tk/ql/cv/app/pccc
  + nhận gõ dính như naptienchuacong, timungvien387678
  + chấm điểm theo từ khóa, tiêu đề, câu hỏi mẫu, mô tả ngắn
  + nếu chắc thì trả lời thẳng, nếu chưa chắc thì hiện vài gợi ý gần đúng
- Không sửa giao diện support_page.dart.

Sau khi copy file PHP lên web, có thể test nhanh:
https://xaydungvn.com.vn/bot-api-app.php?action=ping

Nếu trả JSON pong là API đã chạy.
