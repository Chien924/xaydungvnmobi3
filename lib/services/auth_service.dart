import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';
import '../models/app_user.dart';

class AuthService {
  static const String _tokenKey = 'xaydungvn_app_token';
  static const String _userCacheKey = 'xaydungvn_app_user_cache';

  // Cache trong RAM để không phải đọc disk mỗi lần build URL/preload.
  // Trong vòng preload ~30 trang, hàm này được gọi rất nhiều lần.
  static String? _tokenMem;
  static bool _tokenLoaded = false;

  static Future<String?> getToken() async {
    if (_tokenLoaded) return _tokenMem;
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    _tokenMem = (token == null || token.trim().isEmpty) ? null : token.trim();
    _tokenLoaded = true;
    return _tokenMem;
  }

  static Future<void> saveToken(String token) async {
    if (token.trim().isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token.trim());
    _tokenMem = token.trim();
    _tokenLoaded = true;
  }

  static AppUser? _userMem;

  static Future<void> _saveUserCache(AppUser user) async {
    _userMem = user;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userCacheKey, jsonEncode({
      'id': user.id,
      'username': user.username,
      'display_name': user.displayName,
      'balance': user.balance,
      'phone': user.phone,
    }));
  }

  static Future<AppUser?> cachedUser() async {
    if (_userMem != null) return _userMem;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_userCacheKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final data = jsonDecode(raw);
      if (data is Map) {
        _userMem = AppUser.fromJson(Map<String, dynamic>.from(data));
        return _userMem;
      }
    } catch (_) {}
    return null;
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userCacheKey);
    _tokenMem = null;
    _tokenLoaded = true;
    _userMem = null;
  }

  static Map<String, dynamic> _decodeJson(String body) {
    final trimmed = body.trimLeft();
    if (trimmed.startsWith('<!DOCTYPE') || trimmed.startsWith('<html') || trimmed.startsWith('<HTML')) {
      // Server trả HTML (thường là trang báo lỗi). Cố bóc câu thông báo
      // dễ hiểu cho người dùng thay vì hiện thông báo kỹ thuật.
      final friendly = _extractMessageFromHtml(body);
      return {
        'success': false,
        'message': friendly ?? 'Không thực hiện được. Vui lòng thử lại.',
      };
    }
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
      return {'success': false, 'message': 'Không thực hiện được. Vui lòng thử lại.'};
    } catch (_) {
      return {
        'success': false,
        'message': 'Không thực hiện được. Vui lòng thử lại.',
      };
    }
  }

  // Tìm câu thông báo lỗi tiếng Việt thường gặp bên trong trang HTML.
  static String? _extractMessageFromHtml(String html) {
    final text = html
        .replaceAll(RegExp(r'<script[^>]*>[\s\S]*?</script>', caseSensitive: false), ' ')
        .replaceAll(RegExp(r'<style[^>]*>[\s\S]*?</style>', caseSensitive: false), ' ')
        .replaceAll(RegExp(r'<[^>]+>'), ' ')
        .replaceAll('&nbsp;', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    if (text.isEmpty) return null;

    final lower = text.toLowerCase();
    // Các cụm lỗi hay gặp khi đăng ký trùng dữ liệu.
    const knownPhrases = [
      'số điện thoại đã',
      'sđt đã',
      'sdt đã',
      'tài khoản đã tồn tại',
      'tên đăng nhập đã',
      'tài khoản đã được',
      'đã được sử dụng',
      'đã tồn tại',
      'đã đăng ký',
      'mật khẩu',
      'không hợp lệ',
      'sai',
    ];

    for (final p in knownPhrases) {
      final idx = lower.indexOf(p);
      if (idx >= 0) {
        // Lấy câu chứa cụm lỗi (cắt theo dấu chấm gần nhất).
        final start = text.lastIndexOf('.', idx) + 1;
        var end = text.indexOf('.', idx);
        if (end < 0) end = (idx + 120).clamp(0, text.length);
        final sentence = text.substring(start, end).trim();
        if (sentence.length >= 4 && sentence.length <= 160) return sentence;
      }
    }
    return null;
  }

  static Map<String, dynamic>? _extractUser(Map<String, dynamic> data) {
    final candidates = [data['user'], data['account'], data['profile'], data['data'], data];
    for (final item in candidates) {
      if (item is Map<String, dynamic>) return item;
      if (item is Map) return Map<String, dynamic>.from(item);
    }
    return null;
  }

  static String _extractMessage(Map<String, dynamic> data, [String fallback = 'Có lỗi xảy ra']) {
    return '${data['message'] ?? data['msg'] ?? data['error'] ?? fallback}';
  }

  static String _extractToken(Map<String, dynamic> data) {
    final direct = data['token'] ?? data['access_token'];
    if (direct != null && '$direct'.trim().isNotEmpty) return '$direct'.trim();
    final inner = data['data'];
    if (inner is Map) {
      final token = inner['token'] ?? inner['access_token'];
      if (token != null && '$token'.trim().isNotEmpty) return '$token'.trim();
    }
    return '';
  }

  static bool _isSuccess(int statusCode, Map<String, dynamic> data) {
    return statusCode >= 200 && statusCode < 300 &&
        (data['success'] == true || data['status'] == true || data['ok'] == true || data['code'] == 200 || _extractToken(data).isNotEmpty);
  }

  static Future<AppUser?> currentUser() async {
    final token = await getToken();
    final cache = await cachedUser();
    if (token == null) return cache;

    for (final endpoint in AppConfig.meEndpoints) {
      try {
        final res = await http.get(
          Uri.parse(endpoint),
          headers: {'Authorization': 'Bearer $token'},
        ).timeout(const Duration(seconds: 12));

        final data = _decodeJson(res.body);
        if (_isSuccess(res.statusCode, data)) {
          final userMap = _extractUser(data);
          if (userMap != null) {
            final user = AppUser.fromJson(userMap);
            await _saveUserCache(user);
            return user;
          }
        }
        // Không tự logout khi endpoint /me trả 401.
        // Một số server/API app có thể chưa đồng bộ token nhưng WebView vẫn còn phiên đăng nhập.
        // Nếu xóa token ở đây, trang chủ/tài khoản sẽ hiện sai là chưa đăng nhập.
        // Người dùng chỉ đăng xuất khi bấm nút Thoát.
        if (res.statusCode == 401) continue;
      } catch (_) {}
    }
    return cache;
  }

  static Future<AppUser> login(String username, String password) async {
    Object? lastError;
    for (final endpoint in AppConfig.loginEndpoints) {
      try {
        final res = await http
            .post(
              Uri.parse(endpoint),
              headers: {'Content-Type': 'application/json; charset=utf-8', 'Accept': 'application/json'},
              body: jsonEncode({'username': username, 'password': password}),
            )
            .timeout(const Duration(seconds: 15));

        final data = _decodeJson(res.body);
        if (_isSuccess(res.statusCode, data)) {
          final token = _extractToken(data);
          if (token.isEmpty) throw Exception('API đăng nhập chưa trả token.');
          await saveToken(token);
          final userMap = _extractUser(data) ?? {'username': username};
          final user = AppUser.fromJson(userMap);
          await _saveUserCache(user);
          return user;
        }
        lastError = _extractMessage(data, 'Đăng nhập không thành công');
      } catch (e) {
        lastError = e;
      }
    }
    throw Exception('$lastError'.replaceFirst('Exception: ', ''));
  }

  static Future<AppUser> register({
    required String username,
    required String password,
    required String phone,
    String? displayName,
  }) async {
    Object? lastError;
    final payload = {
      'username': username,
      'usersname': username,
      'password': password,
      'password2': password,
      'confirm_password': password,
      'password_confirmation': password,
      'phone': phone,
      'sdt': phone,
      'display_name': displayName ?? username,
      'name': displayName ?? username,
    };

    for (final endpoint in AppConfig.registerEndpoints) {
      try {
        final res = await http
            .post(
              Uri.parse(endpoint),
              headers: {'Content-Type': 'application/json; charset=utf-8', 'Accept': 'application/json'},
              body: jsonEncode(payload),
            )
            .timeout(const Duration(seconds: 15));

        final data = _decodeJson(res.body);
        if (_isSuccess(res.statusCode, data)) {
          final token = _extractToken(data);
          if (token.isNotEmpty) {
            await saveToken(token);
            final userMap = _extractUser(data) ?? {'username': username, 'phone': phone, 'sdt': phone};
            final user = AppUser.fromJson(userMap);
            await _saveUserCache(user);
            return user;
          }

          // Nếu API đăng ký thành công nhưng không trả token thì tự đăng nhập ngay.
          return await login(username, password);
        }

        // Nếu server trả về lỗi NGHIỆP VỤ rõ ràng (vd: trùng SĐT, trùng tài khoản)
        // thì báo ngay cho người dùng, KHÔNG thử endpoint khác.
        // Chỉ thử endpoint kế tiếp khi endpoint này thật sự không tồn tại (404/405).
        final msg = _extractMessage(data, '');
        final isServerHandled = res.statusCode == 200 ||
            res.statusCode == 400 ||
            res.statusCode == 409 ||
            res.statusCode == 422;
        if (isServerHandled && msg.trim().isNotEmpty) {
          throw Exception(msg);
        }
        lastError = msg.trim().isNotEmpty ? msg : 'Tạo tài khoản thất bại';
      } catch (e) {
        // Lỗi nghiệp vụ đã ném ra ở trên -> dừng luôn, không thử endpoint khác.
        final s = e.toString();
        if (s.startsWith('Exception:') && !s.contains('SocketException') && !s.contains('TimeoutException')) {
          rethrow;
        }
        lastError = e;
      }
    }
    throw Exception('$lastError'.replaceFirst('Exception: ', ''));
  }

  static Future<String> webUrlWithSession(String path, {bool useSessionBridge = true}) async {
    final token = await getToken();
    final appUrl = AppConfig.withAppMode(path);

    // Link ngoài như Google Drive, Google Docs, Facebook... không đi qua WebView/session bridge.
    // Những link này sẽ được app mở bằng trình duyệt/app mặc định của máy.
    if (!AppConfig.isInternalWebUrl(appUrl)) return appUrl;

    if (!useSessionBridge || token == null) return appUrl;

    final go = Uri.encodeComponent(appUrl);
    final tk = Uri.encodeComponent(token);
    return '${AppConfig.baseUrl}/app-session-login.php?token=$tk&go=$go';
  }
}
