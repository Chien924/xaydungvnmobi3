import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../models/app_notification.dart';
import 'auth_service.dart';

class NotificationService {
  static Map<String, dynamic> _decodeJson(String body) {
    final trimmed = body.trimLeft();
    if (trimmed.startsWith('<!DOCTYPE') || trimmed.startsWith('<html') || trimmed.startsWith('<HTML')) {
      return {'success': false, 'message': 'html'};
    }

    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
      return {'success': false, 'message': 'json'};
    } catch (_) {
      return {'success': false, 'message': 'json'};
    }
  }

  static bool _isSuccess(int statusCode, Map<String, dynamic> data) {
    return statusCode >= 200 && statusCode < 300 &&
        (data['success'] == true || data['ok'] == true || data['status'] == true || data['code'] == 200);
  }

  static Future<Map<String, String>> _headers() async {
    final token = await AuthService.getToken();
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json; charset=utf-8',
    };

    if (token != null && token.trim().isNotEmpty) {
      headers['Authorization'] = 'Bearer ${token.trim()}';
    }

    return headers;
  }

  static Future<Map<String, String>> _authParams({String action = 'list'}) async {
    final token = await AuthService.getToken();
    final cached = await AuthService.cachedUser();

    final params = <String, String>{'action': action};
    if (token != null && token.trim().isNotEmpty) params['token'] = token.trim();
    if (cached != null && cached.id > 0) params['app_user_id'] = '${cached.id}';
    if (cached != null && cached.username.trim().isNotEmpty) params['app_username'] = cached.username.trim();
    return params;
  }

  static Future<AppNotificationData> fetch() async {
    final token = await AuthService.getToken();
    final cached = await AuthService.cachedUser();
    if ((token == null || token.trim().isEmpty) && (cached == null || cached.id <= 0)) {
      return AppNotificationData.empty();
    }

    final uri = Uri.parse(AppConfig.notificationApiUrl).replace(queryParameters: await _authParams());
    try {
      final res = await http.get(uri, headers: await _headers()).timeout(const Duration(seconds: 10));
      final data = _decodeJson(res.body);
      if (!_isSuccess(res.statusCode, data)) return AppNotificationData.empty();
      return AppNotificationData.fromJson(data);
    } catch (_) {
      return AppNotificationData.empty();
    }
  }

  static Future<String> markOne(int id) async {
    if (id <= 0) return '';
    final params = await _authParams(action: 'read_one');
    params['id'] = '$id';

    try {
      final res = await http
          .post(
            Uri.parse(AppConfig.notificationApiUrl),
            headers: await _headers(),
            body: jsonEncode(params),
          )
          .timeout(const Duration(seconds: 10));

      final data = _decodeJson(res.body);
      if (!_isSuccess(res.statusCode, data)) return '';
      return '${data['link'] ?? data['url'] ?? ''}'.trim();
    } catch (_) {
      return '';
    }
  }

  static Future<void> markAll() async {
    final params = await _authParams(action: 'read_all');

    try {
      await http
          .post(
            Uri.parse(AppConfig.notificationApiUrl),
            headers: await _headers(),
            body: jsonEncode(params),
          )
          .timeout(const Duration(seconds: 10));
    } catch (_) {}
  }
}
