import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../models/app_notification.dart';
import 'auth_service.dart';

class NotificationService {
  static Map<String, dynamic> _decodeJson(String body) {
    final trimmed = body.trimLeft();
    if (trimmed.startsWith('<!DOCTYPE') || trimmed.startsWith('<html') || trimmed.startsWith('<HTML')) {
      return {
        'success': false,
        'message': 'API thông báo đang trả về HTML. Kiểm tra app-thong-bao-api.php trên public.',
      };
    }

    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
      return {'success': false, 'message': 'API thông báo không trả JSON object.'};
    } catch (_) {
      return {
        'success': false,
        'message': 'API thông báo không trả JSON hợp lệ: ${body.length > 180 ? body.substring(0, 180) : body}',
      };
    }
  }

  static bool _isSuccess(int statusCode, Map<String, dynamic> data) {
    return statusCode >= 200 && statusCode < 300 &&
        (data['success'] == true || data['ok'] == true || data['status'] == true || data['code'] == 200);
  }

  static String _message(Map<String, dynamic> data, [String fallback = 'Có lỗi xảy ra']) {
    return '${data['message'] ?? data['msg'] ?? data['error'] ?? fallback}';
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

  static Future<AppNotificationData> fetch() async {
    final token = await AuthService.getToken();
    if (token == null || token.trim().isEmpty) return AppNotificationData.empty();

    final uri = Uri.parse(AppConfig.notificationApiUrl).replace(queryParameters: {'action': 'list'});
    final res = await http.get(uri, headers: await _headers()).timeout(const Duration(seconds: 15));

    final data = _decodeJson(res.body);
    if (!_isSuccess(res.statusCode, data)) {
      if (res.statusCode == 401) await AuthService.logout();
      throw Exception(_message(data, 'Không lấy được thông báo.'));
    }

    return AppNotificationData.fromJson(data);
  }

  static Future<String> markOne(int id) async {
    if (id <= 0) return '';

    final res = await http
        .post(
          Uri.parse(AppConfig.notificationApiUrl),
          headers: await _headers(),
          body: jsonEncode({'action': 'read_one', 'id': id}),
        )
        .timeout(const Duration(seconds: 15));

    final data = _decodeJson(res.body);
    if (!_isSuccess(res.statusCode, data)) {
      if (res.statusCode == 401) await AuthService.logout();
      throw Exception(_message(data, 'Không mở được thông báo.'));
    }

    return '${data['link'] ?? data['url'] ?? ''}'.trim();
  }

  static Future<void> markAll() async {
    final res = await http
        .post(
          Uri.parse(AppConfig.notificationApiUrl),
          headers: await _headers(),
          body: jsonEncode({'action': 'read_all'}),
        )
        .timeout(const Duration(seconds: 15));

    final data = _decodeJson(res.body);
    if (!_isSuccess(res.statusCode, data)) {
      if (res.statusCode == 401) await AuthService.logout();
      throw Exception(_message(data, 'Không đọc tất cả được.'));
    }
  }
}
