FIX upload ảnh WebView Android:

Lỗi cũ: bấm chọn ảnh được nhưng khi bấm Lưu, ảnh không upload lên web.
Nguyên nhân thường gặp: WebView nhận đường dẫn thô /storage/... từ file_picker, nhưng Android WebView cần URI hợp lệ dạng file:// hoặc content:// để đính kèm vào input type=file.

Đã sửa file:
- lib/screens/web_page.dart

Thay đổi chính:
- Sau khi chọn file, đổi đường dẫn ảnh thành Uri.file(path).toString()
- Nếu file_picker đã trả content:// hoặc file:// thì giữ nguyên

Cách cập nhật:
- Thay đè lib/screens/web_page.dart trong project app
- Push GitHub build lại APK
- Test đăng xe và tạo CV: chọn ảnh -> bấm lưu -> kiểm tra ảnh lên web
