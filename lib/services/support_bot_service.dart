import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';

class BotReply {
  final String text;
  final List<String> suggestions;

  const BotReply({required this.text, this.suggestions = const []});
}

class SupportBotService {
  static Future<BotReply> ask(String message) async {
    final payload = {
      'message': message,
      'text': message,
      'question': message,
      'query': message,
      'app': '1',
    };

    // Thử API bot chat web cũ bằng POST JSON.
    try {
      final res = await http
          .post(
            Uri.parse(AppConfig.botApiUrl),
            headers: {'Content-Type': 'application/json; charset=utf-8'},
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 12));
      final reply = _parseReply(res.body);
      if (reply != null) return reply;
    } catch (_) {}

    // Thử dạng form POST.
    try {
      final res = await http
          .post(
            Uri.parse(AppConfig.botApiUrl),
            body: {'message': message, 'text': message, 'q': message, 'app': '1'},
          )
          .timeout(const Duration(seconds: 12));
      final reply = _parseReply(res.body);
      if (reply != null) return reply;
    } catch (_) {}

    // Thử dạng GET.
    try {
      final uri = Uri.parse(AppConfig.botApiUrl).replace(queryParameters: {'q': message, 'message': message, 'app': '1'});
      final res = await http.get(uri).timeout(const Duration(seconds: 12));
      final reply = _parseReply(res.body);
      if (reply != null) return reply;
    } catch (_) {}

    return BotReply(text: _localReply(message), suggestions: const ['Tài khoản', 'Nạp tiền', 'Đăng tin', 'Quản lí', 'Báo giá']);
  }

  static BotReply? _parseReply(String body) {
    if (body.trim().isEmpty) return null;
    dynamic data;
    try {
      data = jsonDecode(body);
    } catch (_) {
      // Nếu API cũ trả text/html ngắn, vẫn hiển thị được nhưng tránh cả trang HTML dài.
      final text = body.replaceAll(RegExp(r'<[^>]+>'), ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
      if (text.isNotEmpty && text.length < 600) return BotReply(text: text);
      return null;
    }

    if (data is List && data.isNotEmpty) data = data.first;
    if (data is! Map) return null;
    final map = Map<String, dynamic>.from(data as Map);
    final inner = map['data'] is Map ? Map<String, dynamic>.from(map['data'] as Map) : map;
    final text = '${inner['answer'] ?? inner['reply'] ?? inner['message'] ?? inner['content'] ?? inner['text'] ?? ''}'.trim();
    if (text.isEmpty) return null;

    final rawSuggestions = inner['suggestions'] ?? inner['goi_y'] ?? inner['buttons'] ?? inner['items'];
    final suggestions = <String>[];
    if (rawSuggestions is List) {
      for (final item in rawSuggestions) {
        if (item is String && item.trim().isNotEmpty) suggestions.add(item.trim());
        if (item is Map) {
          final t = '${item['title'] ?? item['text'] ?? item['label'] ?? item['nut_hien_thi'] ?? ''}'.trim();
          if (t.isNotEmpty) suggestions.add(t);
        }
      }
    }

    return BotReply(text: text, suggestions: suggestions.take(8).toList());
  }

  static String _localReply(String key) {
    final k = key.toLowerCase();
    if (k.contains('tài khoản') || k.contains('dang nhap') || k.contains('đăng nhập')) {
      return 'Bạn vào tab Tài khoản để đăng nhập, đăng xuất, tạo tài khoản, nạp tiền và xem lịch sử.';
    }
    if (k.contains('nạp') || k.contains('tiền')) {
      return 'Bạn vào tab Tài khoản → Nạp tiền. Trang nạp tiền sẽ mở trong app.';
    }
    if (k.contains('đăng') || k.contains('dang')) {
      return 'Trang chủ có mục Đăng tin nhanh: đăng xe, vật tư, tổ đội, gói thầu, nhu cầu, đối tác và việc làm.';
    }
    if (k.contains('quản') || k.contains('quan')) {
      return 'Bạn vào tab Quản lí để chọn từng mục quản lí riêng: xe, vật tư, tổ đội, gói thầu, nhu cầu, đối tác và việc làm.';
    }
    if (k.contains('báo giá') || k.contains('bao gia')) {
      return 'Các chức năng báo giá vẫn chạy bằng web trong app để giữ đúng hệ thống hiện tại.';
    }
    return 'Tôi đã nhận câu hỏi. API bot chat web cũ chưa trả dữ liệu phù hợp, app đang dùng trả lời dự phòng.';
  }
}
