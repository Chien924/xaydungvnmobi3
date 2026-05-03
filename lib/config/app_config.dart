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

  // Bot API cũ của bạn đang nằm trong thư mục "bot chat".
  // Encode dấu cách thành %20 để WebView/fetch gọi ổn định.
  static const String botApiUrl = '$baseUrl/bot%20chat/bot-api.php';
  static const String supportWebPath = '/app-ho-tro-test.php';

  // Các trang web chính cần preload/cache sẵn để bấm vào mở nhanh.
  // WebView vẫn tự quản lý cache HTML/CSS/JS/icon; app chỉ giữ controller để không phải tải lại từ đầu.
  static const List<String> preloadWebPaths = [
    // Tìm kiếm
    '/tim-xe',
    '/tim-vat-tu',
    '/tim-to-doi',
    '/tim-goi-thau.php',
    '/tim-kiem-nhu-cau.php',
    '/viec-lam.php',
    '/tao-cv.php',

    // Đăng tin
    '/xe-cua-toi?tab=dang',
    '/vat-tu-cua-toi?tab=form',
    '/to-doi-cua-toi?tab=form',
    '/goi-thau-cua-toi?tab=form',
    '/nhu-cau-cua-toi?tab=form',
    '/doi-tac-cua-toi?tab=form',
    '/viec-lam-cua-toi.php?tab=dang',

    // Quản lí
    '/xe-cua-toi?tab=quanly',
    '/vat-tu-cua-toi?tab=quanly',
    '/to-doi-cua-toi?tab=quanly',
    '/goi-thau-cua-toi?tab=quanly',
    '/nhu-cau-cua-toi?tab=list',
    '/doi-tac-cua-toi?tab=list_xe',
    '/doi-tac-cua-toi?tab=list_vattu',
    '/viec-lam-cua-toi.php?tab=quanly',

    // Tài khoản
    '/thong-tin-ca-nhan.php',
    '/nap-tien.php',
    '/lich-su-cua-toi.php',

    // Hỗ trợ + thông tin khác
    '/app-ho-tro-test.php',
    '/huong-dan-su-dung.php',
    '/chinh-sach-quy-dinh.php',
    '/lien-he-ho-tro.php',
    '/thong-bao-he-thong.php',
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
    if (trimmed.startsWith('https://')) return trimmed;
    if (!trimmed.startsWith('/')) return '$baseUrl/$trimmed';
    return '$baseUrl$trimmed';
  }

  static String withAppMode(String path) {
    final rawUrl = webPath(path);
    final uri = Uri.parse(rawUrl);
    final params = Map<String, String>.from(uri.queryParameters);
    params['app'] = '1';
    return uri.replace(queryParameters: params).toString();
  }

  // Không dò nhiều đường dẫn nữa. Trang nào chỉ định thì mở đúng trang đó.
  static List<String> fallbackPaths(String path) => [path];
}
