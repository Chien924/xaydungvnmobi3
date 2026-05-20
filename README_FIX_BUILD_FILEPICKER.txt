Fix lỗi build Flutter:

lib/screens/web_page.dart: Error: Member not found: platform

Nguyên nhân: bản file_picker mới đã bỏ cách gọi FilePicker.platform.pickFiles().
Đã sửa sang FilePicker.pickFiles().

Cách dùng:
- Thay đè file lib/screens/web_page.dart vào project.
- Giữ nguyên pubspec.yaml hiện tại đã có file_picker.
- Push GitHub và build lại APK.
