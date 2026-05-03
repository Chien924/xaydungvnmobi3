class AppConfig {
  static const String baseUrl = 'https://xaydungvn.com.vn';
  static const String apiBaseUrl = '$baseUrl/api/v1/app';

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

  // Nếu sau này có trang web riêng cho hỗ trợ thì thay tại đây.
  // Hiện tại tab Hỗ trợ trong app là màn app cứng, không mở web.
  static const String supportPath = '/ho-tro.php';
}
