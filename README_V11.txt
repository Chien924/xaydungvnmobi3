BẢN V11 - sửa chat cố định + nút Mobi/PC

1. Tab Hỗ trợ:
- Thanh gợi ý + ô nhập cố định ở dưới, không đổi theo từng đoạn chat.
- Gợi ý trong bong bóng bot vẫn bấm được.
- Link trong câu trả lời bị ẩn URL, đổi thành nút "Mở liên kết".
- Bấm link mở trong app WebView.

2. WebView:
- Tất cả trang web có nút chuyển Mobi/PC ở thanh trên.
- Trang tạo CV mặc định mở dạng PC.
- PC mode ép viewport rộng 1200px và user-agent desktop.
- Vẫn tự thêm app=1 và ép HTTPS.

3. Web PHP:
Copy các file trong web_upload_to_public vào C:\Data\AppCore\public\
