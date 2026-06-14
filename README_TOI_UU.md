# Bản tối ưu app Xây Dựng VN

Các thay đổi trong bản này:

## Đăng nhập
- Khi WebView bị web đẩy về trang đăng nhập (phát hiện qua `AppConfig.looksLikeLoginPage`),
  app tự đóng trang web và mở màn hình đăng nhập của app (`LoginPage`).
- Sau khi đăng nhập xong, app làm mới user, thông báo và preload lại web.
- Có cờ `_loginSheetOpen` để không mở màn đăng nhập nhiều lần chồng nhau.
- Nếu chỉnh tên đường dẫn trang login của web, sửa trong
  `lib/config/app_config.dart` -> `loginRedirectPaths`.

## Màn hình lỗi / không có mạng
- `web_page.dart`: thay màn lỗi cũ bằng màn "Không có kết nối" đẹp hơn,
  có minh hoạ, nút "Thử lại" và "Mở bằng trình duyệt".

## Tải CV (tai-cv.php)
- Trước đây ép mở trình duyệt ngoài nên dễ mất session -> không vào được.
- Giờ `tai-cv.php` mở TRONG app (giữ session đăng nhập).
- Chỉ link file thật (kết thúc .pdf/.docx...) mới mở ngoài để máy tải về.

## Hiệu năng
- Giảm số WebView giữ trong RAM: `maxCachedControllers` 24 -> 8.
- Giảm danh sách preload từ ~30 trang xuống 6 trang hay dùng nhất.
- Cache token và user trong RAM (`AuthService`) để không đọc disk lặp lại.

## Build / bảo mật
- `WillPopScope` (đã deprecated) -> `PopScope`.
- Manifest: thêm `android:usesCleartextTraffic="false"` (chỉ chạy HTTPS).
- `build.gradle.kts`: `minSdk` tối thiểu 23 cho WebView + chọn file.
- `codemagic.yaml`: build `--split-per-abi` để APK nhẹ hơn.

## Tải CV (tai-cv.php) - CẬP NHẬT
- tai-cv.php là TRANG HTML có nút "Tải PDF/Tải ảnh" (tạo file bằng JS trong
  trình duyệt), không phải link tải trực tiếp.
- WebView Android không tự lưu được file blob -> bấm tải không có gì xảy ra.
- Trang này dùng ?id= và CV công khai (cong_khai=1) nên KHÔNG cần đăng nhập.
- Giải pháp: tai-cv.php mở bằng TRÌNH DUYỆT NGOÀI, mở thẳng URL gốc (kèm app=1),
  KHÔNG bọc qua app-session-login.php. Nút tải PDF/ảnh chạy tốt trên trình
  duyệt thật. Web chỉ cần đảm bảo nút "Tải CV" trỏ tới tai-cv.php?id=<id CV>.

## Sửa lỗi đăng ký & đăng nhập (bản này)
- Lỗi trùng SĐT / trùng tài khoản: trước báo "API trả về HTML" khó hiểu.
  Giờ app bóc đúng câu lỗi tiếng Việt từ server và hiện lên màn hình.
- Khi server báo lỗi nghiệp vụ rõ ràng (trùng dữ liệu...), app dừng và
  báo ngay, không thử endpoint khác làm mất thông báo gốc.
- Lỗi "đăng ký/đăng nhập xong nhưng web không nhận đã đăng nhập":
  nguyên nhân là WebView chưa có session cookie của website (app chỉ lưu
  token API). Đã thêm `WebPage.warmUpWebSession()` mồi session một lần qua
  app-session-login.php sau khi đăng nhập/đăng ký và khi mở app nếu còn
  token -> các trang web nhận đăng nhập ngay, không phải đăng xuất rồi vào lại.

## Web mượt + đẹp hơn
- Chèn CSS ẩn header NGAY khi trang bắt đầu (onPageStarted) thay vì đợi
  tải xong -> hết cảnh header web nhấp nháy hiện rồi biến mất.
- CSS bổ sung: chống overscroll (kéo giãn mép), khử text-size-adjust,
  ép ảnh không tràn khung.
- Tắt zoom (`enableZoom(false)`) để layout web không nhảy khi pinch.
- Thanh tiến trình đổi sang xanh lá khớp app, mảnh hơn.
- Box chat hỗ trợ: thay chữ "Đang trả lời..." bằng 3 chấm động.

## CẦN LÀM TRƯỚC KHI LÊN STORE
- Tạo keystore riêng và thay `signingConfig = signingConfigs.getByName("debug")`
  trong `android/app/build.gradle.kts` bằng khoá release của bạn.
  APK hiện vẫn ký bằng khoá debug, KHÔNG cập nhật lên CH Play được.
