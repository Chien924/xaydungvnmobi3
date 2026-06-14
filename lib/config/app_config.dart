class AppConfig {
  static const String baseUrl = 'https://xaydungvn.com.vn';
  static const String apiBaseUrl = '$baseUrl/api/v1';

  static const List<String> loginEndpoints = [
    '$apiBaseUrl/auth/login.php',
    '$apiBaseUrl/app/login.php',
  ];

  static const List<String> registerEndpoints = [
    '$baseUrl/app-dang-ky-api.php',
    '$apiBaseUrl/auth/register.php',
    '$apiBaseUrl/app/register.php',
  ];

  static const List<String> meEndpoints = [
    '$apiBaseUrl/account/me.php',
    '$apiBaseUrl/app/me.php',
  ];

  // Endpoint đăng nhập Google cho app (native). App gửi id_token, nhận app_token.
  static const String googleLoginAppEndpoint = '$baseUrl/google-login-app.php';

  // Web Client ID của Google (giống trong google-callback.php).
  // Dùng cho serverClientId của google_sign_in để Google trả idToken đúng audience.
  static const String googleWebClientId =
      '692778120034-no4ilrgeb0soa892odju3jq9a3n8ctq1.apps.googleusercontent.com';

  // ===== Các trang xác thực mở bằng WebView (dùng trang web sẵn có) =====
  // Đăng nhập Google: nút Google nằm trên trang đăng nhập của web (dang-nhap.php).
  // Người dùng bấm nút Google -> Google xác thực -> google-callback.php set
  // session -> web chuyển về index.php. App nhận biết thành công khi về index.php.
  // Lưu ý: luồng này chỉ tạo SESSION COOKIE (không có token API).
  static const String googleLoginPath = '/dang-nhap.php';
  static const String forgotPasswordPath = '/quen-mat-khau.php';
  static const String changePasswordPath = '/doi-mat-khau.php';

  // Khi WebView về một trong các URL này nghĩa là đã đăng nhập thành công.
  static const List<String> loginSuccessMarkers = [
    '/index.php',
    '/trang-chu',
  ];

  // Bot API cũ của bạn đang nằm trong thư mục "bot chat".
  // Encode dấu cách thành %20 để WebView/fetch gọi ổn định.
  static const String botApiUrl = '$baseUrl/bot-api-app.php';
  static const String supportWebPath = '/app-ho-tro-test.php';
  static const String notificationApiUrl = '$baseUrl/app-thong-bao-api.php';

  // Chỉ tải nền vài trang người dùng hay mở nhất.
  // Preload quá nhiều WebView cùng lúc tốn RAM và dễ làm máy yếu bị giật/kill app.
  // Các trang khác vẫn mở nhanh nhờ WebView tự cache HTML/CSS/JS sau lần đầu.
  static const List<String> preloadWebPaths = [
    '/tim-xe',
    '/tim-vat-tu',
    '/tim-to-doi',
    '/ban-do-osm-vietnam.php',
    '/viec-lam.php',
    '/tao-cv.php',
  ];

  static String webPath(String path) {
    final trimmed = path.trim();

    // Bắt buộc toàn bộ web nội bộ chạy HTTPS để Android WebView không báo
    // net::ERR_CLEARTEXT_NOT_PERMITTED.
    if (trimmed.startsWith('http://xaydungvn.com.vn')) {
      return trimmed.replaceFirst('http://xaydungvn.com.vn', 'https://xaydungvn.com.vn');
    }
    if (trimmed.startsWith('http://www.xaydungvn.com.vn')) {
      return trimmed.replaceFirst('http://www.xaydungvn.com.vn', 'https://xaydungvn.com.vn');
    }
    if (trimmed.startsWith('https://www.xaydungvn.com.vn')) {
      return trimmed.replaceFirst('https://www.xaydungvn.com.vn', 'https://xaydungvn.com.vn');
    }

    // Link đầy đủ thì giữ nguyên, kể cả link ngoài.
    if (trimmed.startsWith('https://') || trimmed.startsWith('http://')) return trimmed;

    // Các scheme ngoài web như tel:, mailto:, sms:, intent:, zalo: không được ghép vào domain nội bộ.
    if (RegExp(r'^[a-zA-Z][a-zA-Z0-9+.-]*:').hasMatch(trimmed)) return trimmed;

    if (!trimmed.startsWith('/')) return '$baseUrl/$trimmed';
    return '$baseUrl$trimmed';
  }

  static bool isInternalWebUrl(String pathOrUrl) {
    final uri = Uri.tryParse(webPath(pathOrUrl));
    if (uri == null) return false;
    final host = uri.host.toLowerCase();
    return host == 'xaydungvn.com.vn' || host == 'www.xaydungvn.com.vn';
  }

  static String withAppMode(String path) {
    final rawUrl = webPath(path);
    if (!isInternalWebUrl(rawUrl)) return rawUrl;

    final uri = Uri.parse(rawUrl);
    final params = Map<String, String>.from(uri.queryParameters);
    params['app'] = '1';
    return uri.replace(
      scheme: 'https',
      host: 'xaydungvn.com.vn',
      queryParameters: params,
    ).toString();
  }

  // Không dò nhiều đường dẫn nữa. Trang nào chỉ định thì mở đúng trang đó.
  static List<String> fallbackPaths(String path) => [path];

  // Các trang web cho biết người dùng đang ở trạng thái CHƯA đăng nhập.
  // Khi WebView bị web đẩy về một trong các trang này, app sẽ tự mở
  // màn hình đăng nhập của app thay vì để người dùng thấy form login của web.
  static const List<String> loginRedirectPaths = [
    '/dang-nhap',
    '/dang-nhap.php',
    '/login',
    '/login.php',
    '/dangnhap.php',
    '/tai-khoan/dang-nhap',
  ];

  static bool looksLikeLoginPage(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return false;
    if (!isInternalWebUrl(url)) return false;

    final path = uri.path.toLowerCase();
    for (final p in loginRedirectPaths) {
      if (path == p || path.endsWith(p)) return true;
    }

    // Một số web đẩy về trang chủ kèm tham số yêu cầu đăng nhập.
    final query = uri.query.toLowerCase();
    if (query.contains('require_login=1') ||
        query.contains('need_login=1') ||
        query.contains('redirect_login=1')) {
      return true;
    }
    return false;
  }
}
