BẢN APP V2 - XÂY DỰNG VN

Đã sửa theo yêu cầu:

1. Menu dưới app cứng:
   Trang chủ | Quản lí | Hỗ trợ | Thông báo | Tài khoản

2. Trang chủ app cứng:
   - Hiện tài khoản bằng username, không lấy tên công ty.
   - Hiện số dư.
   - Có chuông thông báo +10, bấm chuyển qua tab Thông báo.
   - Sửa link tìm kiếm:
     + Gói thầu: /tim-goi-thau.php
     + Đơn hàng vật tư: /tim-kiem-nhu-cau.php
   - Sửa link đăng:
     + Đăng xe: /xe-cua-toi?tab=dang
     + Đăng vật tư: /vat-tu-cua-toi?tab=form
     + Đăng tổ đội: /to-doi-cua-toi?tab=form
     + Đăng gói thầu: /goi-thau-cua-toi?tab=form
     + Đăng đơn hàng: /nhu-cau-cua-toi?tab=form
     + Đăng đối tác: /doi-tac-cua-toi?tab=form
     + Đăng việc làm: /viec-lam-cua-toi.php?tab=dang

3. Tab Quản lí app cứng:
   - Quản lí xe: /xe-cua-toi?tab=quanly
   - Quản lí vật tư: /vat-tu-cua-toi?tab=quanly
   - Quản lí tổ đội: /to-doi-cua-toi?tab=quanly
   - Quản lí gói thầu: /goi-thau-cua-toi?tab=quanly
   - Quản lí nhu cầu: /nhu-cau-cua-toi?tab=list
   - Đối tác xe: /doi-tac-cua-toi?tab=list_xe
   - Đối tác vật tư: /doi-tac-cua-toi?tab=list_vattu
   - Quản lí việc làm: /viec-lam-cua-toi.php?tab=quanly

4. Tab Hỗ trợ:
   - Là màn bot chat app cứng tạm thời.
   - Có gợi ý nhanh: Tài khoản, Nạp tiền, Đăng tin, Quản lí, Báo giá, Liên hệ.
   - Sau này có thể nối lại API bot chat cũ.

5. Tab Thông báo:
   - Là màn app cứng thiết kế sẵn.
   - Có 2 tab nhỏ: Của tôi và Hệ thống.
   - Mặc định mở Thông báo của tôi.

6. Tab Tài khoản:
   - Đăng nhập, đăng xuất, tạo tài khoản.
   - Nạp tiền: /nap-tien.php
   - Lịch sử: /lich-su-cua-toi.php
   - Thông tin cá nhân: /thong-tin-ca-nhan.php

7. WebView:
   - Tất cả link mở trong app.
   - Không mở Chrome ngoài.
   - Tự ép app=1 vào link để web bỏ head/menu.
   - Nếu đã đăng nhập app thì mở qua /app-session-login.php để đồng bộ session web.

CÁCH UP LÊN GITHUB:
- Upload toàn bộ file/thư mục bên trong thư mục này lên repo.
- Đảm bảo pubspec.yaml nằm ngoài cùng repo.
- Vào tab Actions → Build Android APK → Run workflow.
- Tải Artifacts: xaydungvn-apk.
