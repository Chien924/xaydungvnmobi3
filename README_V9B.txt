BẢN V9B - Xây Dựng VN Mobile

Đã kiểm tra lại file zip.

Cách dùng:
1. Giải nén zip.
2. Mở thư mục xaydungvnmobi3_fix_v9b_auth_chat_ok.
3. Upload TOÀN BỘ nội dung bên trong thư mục này lên GitHub repo xaydungvnmobi3.
   Lưu ý: pubspec.yaml phải nằm ngoài cùng repo, ngang hàng với android, lib, assets.
4. Copy 2 file PHP trong web_upload_to_public vào C:\Data\AppCore\public\:
   - app-dang-ky-api.php
   - app-dang-ky-test.php
5. GitHub Actions -> Build Android APK -> Run workflow.

Bản này gồm:
- Form đăng nhập app cứng
- Form đăng ký app cứng
- Đăng ký trùng tài khoản báo lỗi
- Đăng ký trùng số điện thoại báo lỗi
- Đăng ký thành công tự đăng nhập
- Chat hỗ trợ app cứng gọi bot API cũ
- Màn hình mở app + intro lần đầu
