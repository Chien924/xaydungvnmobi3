import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';
import '../models/app_user.dart';

class AuthService {
  static const String _tokenKey = 'xaydungvn_app_token';

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    if (token == null || token.trim().isEmpty) return null;
    return token;
  }

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  static Map<String, dynamic> _decodeJson(String body) {
    final decoded = jsonDecode(body);
    if (decoded is Map<String, dynamic>) return decoded;
    if (decoded is Map) return Map<String, dynamic>.from(decoded);
    return {'success': false, 'message': 'API không trả JSON object'};
  }

  static Map<String, dynamic>? _extractUser(Map<String, dynamic> data) {
    final candidates = [data['user'], data['data'], data['account'], data];
    for (final item in candidates) {
      if (item is Map<String, dynamic>) return item;
      if (item is Map) return Map<String, dynamic>.from(item);
    }
    return null;
  }

  static String _extractMessage(Map<String, dynamic> data, [String fallback = 'Có lỗi xảy ra']) {
    return '${data['message'] ?? data['msg'] ?? data['error'] ?? fallback}';
  }

  static bool _isSuccess(int statusCode, Map<String, dynamic> data) {
    return statusCode >= 200 && statusCode < 300 &&
        (data['success'] == true || data['status'] == true || data['ok'] == true || data['code'] == 200 || data.containsKey('token'));
  }

  static Future<AppUser?> currentUser() async {
    final token = await getToken();
    if (token == null) return null;

    for (final endpoint in AppConfig.meEndpoints) {
      try {
        final res = await http.get(
          Uri.parse(endpoint),
          headers: {'Authorization': 'Bearer $token'},
        ).timeout(const Duration(seconds: 12));

        final data = _decodeJson(res.body);
        if (_isSuccess(res.statusCode, data)) {
          final userMap = _extractUser(data);
          if (userMap != null) return AppUser.fromJson(userMap);
        }
        if (res.statusCode == 401) await logout();
      } catch (_) {
        // Thử endpoint tiếp theo.
      }
    }
    return null;
  }

  static Future<AppUser> login(String username, String password) async {
    Object? lastError;
    for (final endpoint in AppConfig.loginEndpoints) {
      try {
        final res = await http
            .post(
              Uri.parse(endpoint),
              headers: {'Content-Type': 'application/json; charset=utf-8'},
              body: jsonEncode({'username': username, 'password': password}),
            )
            .timeout(const Duration(seconds: 15));

        final data = _decodeJson(res.body);
        if (_isSuccess(res.statusCode, data)) {
          final token = '${data['token'] ?? data['access_token'] ?? data['data']?['token'] ?? ''}';
          if (token.isEmpty) throw Exception('API đăng nhập chưa trả token.');
          await saveToken(token);
          final userMap = _extractUser(data) ?? {'username': username};
          return AppUser.fromJson(userMap);
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
      'password': password,
      'confirm_password': password,
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
              headers: {'Content-Type': 'application/json; charset=utf-8'},
              body: jsonEncode(payload),
            )
            .timeout(const Duration(seconds: 15));

        final data = _decodeJson(res.body);
        if (_isSuccess(res.statusCode, data)) {
          final token = '${data['token'] ?? data['access_token'] ?? data['data']?['token'] ?? ''}';
          if (token.isNotEmpty) await saveToken(token);
          final userMap = _extractUser(data) ?? {'username': username, 'phone': phone};
          return AppUser.fromJson(userMap);
        }
        lastError = _extractMessage(data, 'Tạo tài khoản không thành công');
      } catch (e) {
        lastError = e;
      }
    }
    throw Exception('$lastError'.replaceFirst('Exception: ', ''));
  }

  static Future<String> webUrlWithSession(String path, {bool useSessionBridge = true}) async {
    final token = await getToken();
    final appUrl = AppConfig.withAppMode(path);

    if (!useSessionBridge || token == null) return appUrl;

    final go = Uri.encodeComponent(appUrl);
    final tk = Uri.encodeComponent(token);
    return '${AppConfig.baseUrl}/app-session-login.php?token=$tk&go=$go';
  }
}
