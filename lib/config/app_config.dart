class AppConfig {
  static const String baseUrl = 'https://xaydungvn.com.vn';
  static const String apiBaseUrl = '$baseUrl/api/v1';

  static const List<String> loginEndpoints = [
    '$apiBaseUrl/auth/login.php',
    '$apiBaseUrl/app/login.php',
  ];

  static const List<String> registerEndpoints = [
    '$apiBaseUrl/auth/register.php',
    '$apiBaseUrl/app/register.php',
  ];

  static const List<String> meEndpoints = [
    '$apiBaseUrl/account/me.php',
    '$apiBaseUrl/app/me.php',
  ];

  // Bot chat web cũ thường nằm ở file này. App sẽ gọi API này trước,
  // nếu API trả khác định dạng thì app vẫn có trả lời dự phòng.
  static const String botApiUrl = '$baseUrl/bot-api.php';

  static String webPath(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) return path;
    if (!path.startsWith('/')) return '$baseUrl/$path';
    return '$baseUrl$path';
  }

  static String withAppMode(String path) {
    final rawUrl = webPath(path);
    final uri = Uri.parse(rawUrl);
    final params = Map<String, String>.from(uri.queryParameters);
    params['app'] = '1';
    return uri.replace(queryParameters: params).toString();
  }

  static List<String> fallbackPaths(String path) {
    final uri = Uri.tryParse(webPath(path));
    final cleanPath = uri?.path ?? path;
    final query = uri?.query;
    String addQuery(String p) => (query == null || query.isEmpty) ? p : '$p?$query';

    final variants = <String>[];
    void add(String p) {
      if (!variants.contains(p)) variants.add(p);
    }

    // Bản gốc trước.
    add(path);

    // Nếu web rewrite bỏ .php thì thử bản không .php.
    if (cleanPath.endsWith('.php')) {
      add(addQuery(cleanPath.substring(0, cleanPath.length - 4)));
    }

    // Một số trang từng bị lỗi / đổi tên.
    switch (cleanPath) {
      case '/tim-goi-thau.php':
        add('/tim-goi-thau');
        add('/dau-thau.php');
        add('/dau-thau');
        break;
      case '/tim-kiem-nhu-cau.php':
        add('/tim-kiem-nhu-cau');
        add('/nhu-cau-vat-tu.php');
        add('/nhu-cau-vat-tu');
        break;
      case '/dang-ky.php':
        add('/dang-ky');
        add('/register.php');
        break;
      case '/nap-tien.php':
        add('/nap-tien');
        break;
      case '/lich-su-cua-toi.php':
        add('/lich-su-cua-toi');
        break;
      case '/thong-tin-ca-nhan.php':
        add('/thong-tin-ca-nhan');
        break;
    }

    return variants;
  }
}
