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

  static Future<AppUser?> currentUser() async {
    final token = await getToken();
    if (token == null) return null;

    final res = await http.get(
      Uri.parse('${AppConfig.apiBaseUrl}/me.php'),
      headers: {'Authorization': 'Bearer $token'},
    ).timeout(const Duration(seconds: 12));

    final data = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode == 200 && data['success'] == true && data['user'] is Map) {
      return AppUser.fromJson(Map<String, dynamic>.from(data['user']));
    }

    if (res.statusCode == 401) await logout();
    return null;
  }

  static Future<AppUser> login(String username, String password) async {
    final res = await http
        .post(
          Uri.parse('${AppConfig.apiBaseUrl}/login.php'),
          headers: {'Content-Type': 'application/json; charset=utf-8'},
          body: jsonEncode({'username': username, 'password': password}),
        )
        .timeout(const Duration(seconds: 15));

    final data = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode == 200 && data['success'] == true) {
      final token = '${data['token'] ?? ''}';
      if (token.isEmpty) throw Exception('API chưa trả token.');
      await saveToken(token);
      return AppUser.fromJson(Map<String, dynamic>.from(data['user']));
    }

    throw Exception('${data['message'] ?? 'Đăng nhập không thành công'}');
  }

  static Future<String> webUrlWithSession(String path) async {
    final token = await getToken();
    final appUrl = AppConfig.withAppMode(path);

    if (token == null) return appUrl;

    final go = Uri.encodeComponent(appUrl);
    final tk = Uri.encodeComponent(token);
    return '${AppConfig.baseUrl}/app-session-login.php?token=$tk&go=$go';
  }
}
