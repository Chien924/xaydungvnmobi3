import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import 'auth_service.dart';

class BotSuggestion {
  final String title;
  final String text;
  final int? id;

  const BotSuggestion({required this.title, required this.text, this.id});
}

class BotReply {
  final String text;
  final List<BotSuggestion> suggestions;

  const BotReply({required this.text, this.suggestions = const []});
}

class SupportBotService {
  static Future<BotReply> init() async {
    try {
      final data = await _post({'action': 'init', 'app': '1'});
      return _parseReply(data);
    } catch (_) {
      return const BotReply(
        text: 'Xin chào! Bạn cần hỗ trợ mục nào?',
        suggestions: [
          BotSuggestion(title: 'Tài khoản', text: 'Tài khoản'),
          BotSuggestion(title: 'Nạp tiền', text: 'Nạp tiền'),
          BotSuggestion(title: 'Đăng tin', text: 'Đăng tin'),
          BotSuggestion(title: 'Quản lí', text: 'Quản lí'),
          BotSuggestion(title: 'Báo giá', text: 'Báo giá'),
        ],
      );
    }
  }

  static Future<BotReply> ask(String message) async {
    try {
      final data = await _post({
        'action': 'ask',
        'message': message,
        'q': message,
        'text': message,
        'app': '1',
      });
      return _parseReply(data);
    } catch (_) {
      return BotReply(
        text: _localReply(message),
        suggestions: const [
          BotSuggestion(title: 'Tài khoản', text: 'Tài khoản'),
          BotSuggestion(title: 'Nạp tiền', text: 'Nạp tiền'),
          BotSuggestion(title: 'Đăng tin', text: 'Đăng tin'),
          BotSuggestion(title: 'Quản lí', text: 'Quản lí'),
          BotSuggestion(title: 'Báo giá', text: 'Báo giá'),
        ],
      );
    }
  }

  static Future<BotReply> choose(BotSuggestion suggestion) async {
    if (suggestion.id == null || suggestion.id! <= 0) {
      return ask(suggestion.text);
    }

    try {
      final data = await _post({
        'action': 'choose',
        'kich_ban_id': '${suggestion.id}',
        'id': '${suggestion.id}',
        'app': '1',
      });
      return _parseReply(data);
    } catch (_) {
      return ask(suggestion.text);
    }
  }

  static Future<Map<String, dynamic>> _post(Map<String, String> body) async {
    final token = await AuthService.getToken();
    final sendBody = Map<String, String>.from(body);

    // Quan trọng: app đăng nhập bằng token, còn bot PHP cũ kiểm tra session.
    // Gửi token cho bot-api-app.php để PHP set $_SESSION trước khi chạy bot cũ.
    if (token != null && token.trim().isNotEmpty) {
      sendBody['token'] = token.trim();
      sendBody['app_token'] = token.trim();
    }

    final headers = <String, String>{
      'Accept': 'application/json',
    };

    if (token != null && token.trim().isNotEmpty) {
      headers['Authorization'] = 'Bearer ${token.trim()}';
    }

    final res = await http
        .post(
          Uri.parse(AppConfig.botApiUrl),
          headers: headers,
          body: sendBody,
        )
        .timeout(const Duration(seconds: 15));

    final raw = res.body.trim();
    final decoded = jsonDecode(raw);
    if (decoded is! Map) throw Exception('Bot API không trả JSON object');

    final data = Map<String, dynamic>.from(decoded);

    if (res.statusCode < 200 ||
        res.statusCode >= 300 ||
        data['ok'] == false ||
        data['success'] == false) {
      throw Exception('${data['message'] ?? 'Bot API lỗi'}');
    }

    return data;
  }

  static BotReply _parseReply(Map<String, dynamic> data) {
    final html = '${data['message_html'] ?? ''}'.trim();
    final text = html.isNotEmpty
        ? _htmlToText(html)
        : '${data['message'] ?? data['reply'] ?? data['answer'] ?? data['content'] ?? ''}'.trim();

    return BotReply(
      text: text.isEmpty ? 'Bot chưa có phản hồi.' : text,
      suggestions: _parseSuggestions(data['suggestions'] ?? data['goi_y'] ?? data['buttons'] ?? data['items']),
    );
  }

  static List<BotSuggestion> _parseSuggestions(dynamic raw) {
    final result = <BotSuggestion>[];

    if (raw is List) {
      for (final item in raw) {
        if (item is String && item.trim().isNotEmpty) {
          result.add(BotSuggestion(title: item.trim(), text: item.trim()));
        } else if (item is Map) {
          final map = Map<String, dynamic>.from(item);
          final title =
              '${map['title'] ?? map['tieu_de'] ?? map['nut_hien_thi'] ?? map['label'] ?? map['text'] ?? ''}'.trim();
          final text = '${map['text'] ?? map['cau_hoi_mau'] ?? title}'.trim();
          final rawId = map['kich_ban_id'] ?? map['id'] ?? map['kichban_id'];
          final id = int.tryParse('$rawId');

          if (title.isNotEmpty) {
            result.add(BotSuggestion(title: title, text: text.isEmpty ? title : text, id: id));
          }
        }
      }
    }

    return result.take(12).toList();
  }

  static String _htmlToText(String html) {
    var s = html
        .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'</p>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'<[^>]+>'), ' ')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#039;', "'");

    s = s.replaceAll(RegExp(r'[ \t]+'), ' ').replaceAll(RegExp(r'\n\s+'), '\n').trim();
    return s;
  }

  static String _localReply(String key) {
    final k = key.toLowerCase();

    if (k.contains('tài khoản') || k.contains('dang nhap') || k.contains('đăng nhập')) {
      return 'Bạn vào tab Tài khoản để đăng nhập, đăng xuất, tạo tài khoản, nạp tiền và xem lịch sử.';
    }

    if (k.contains('nạp') || k.contains('tiền')) {
      return 'Bạn vào tab Tài khoản → Nạp tiền.';
    }

    if (k.contains('đăng') || k.contains('dang')) {
      return 'Trang chủ có mục Đăng tin nhanh: đăng xe, vật tư, tổ đội, gói thầu, nhu cầu, đối tác và việc làm.';
    }

    if (k.contains('quản') || k.contains('quan')) {
      return 'Bạn vào tab Quản lí để chọn từng mục quản lí riêng.';
    }

    if (k.contains('báo giá') || k.contains('bao gia')) {
      return 'Các chức năng báo giá chạy bằng web trong app để giữ đúng hệ thống hiện tại.';
    }

    return 'Tôi đã nhận câu hỏi. Bạn có thể hỏi về tài khoản, nạp tiền, đăng tin, quản lí, báo giá.';
  }
}
