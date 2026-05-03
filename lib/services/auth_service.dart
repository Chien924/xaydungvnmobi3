import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';
import '../models/app_user.dart';

class AuthService {
  static const String _tokenKey = 'xaydungvn_app_token';
  static const String _userCacheKey = 'xaydungvn_app_user_cache';

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    if (token == null || token.trim().isEmpty) return null;
    return token;
  }

  static Future<void> saveToken(String token) async {
    if (token.trim().isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token.trim());
  }

  static Future<void> _saveUserCache(AppUser user) async {
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
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_userCacheKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final data = jsonDecode(raw);
      if (data is Map) return AppUser.fromJson(Map<String, dynamic>.from(data));
    } catch (_) {}
    return null;
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userCacheKey);
  }

  static Map<String, dynamic> _decodeJson(String body) {
    final trimmed = body.trimLeft();
    if (trimmed.startsWith('<!DOCTYPE') || trimmed.startsWith('<html') || trimmed.startsWith('<HTML')) {
      return {
        'success': false,
        'message': 'API đang trả về HTML. Kiểm tra lại file PHP trên public.',
      };
    }
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
      return {'success': false, 'message': 'API không trả JSON object'};
    } catch (_) {
      return {
        'success': false,
        'message': 'API không trả JSON hợp lệ: ${body.length > 180 ? body.substring(0, 180) : body}',
      };
    }
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
        if (res.statusCode == 401) await logout();
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
        lastError = _extractMessage(data, 'Tạo tài khoản thất bại');
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
