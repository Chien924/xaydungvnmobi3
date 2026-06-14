import 'dart:async';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../config/app_config.dart';
import '../services/auth_service.dart';

/// Màn WebView dùng cho các luồng xác thực mở bằng trang web sẵn có:
/// đăng nhập Google, quên mật khẩu.
///
/// Cách nhận biết đăng nhập thành công:
/// 1) Nếu web chuyển hướng về URL chứa ?app_token=... (KHUYẾN NGHỊ) thì app
///    lấy token, lưu lại và đóng màn -> báo thành công.
/// 2) Nếu web chỉ set session cookie và chuyển về trang chủ kèm app=1 thì
///    app vẫn coi là thành công (nhưng app sẽ chưa có token API; phần lớn
///    chức năng web vẫn chạy nhờ cookie session).
class AuthWebPage extends StatefulWidget {
  final String path;
  final String title;

  /// true: đây là luồng đăng nhập (cần bắt token / nhận biết thành công).
  /// false: chỉ mở trang (vd quên mật khẩu) rồi người dùng tự quay lại.
  final bool expectLogin;

  const AuthWebPage({
    super.key,
    required this.path,
    required this.title,
    this.expectLogin = false,
  });

  @override
  State<AuthWebPage> createState() => _AuthWebPageState();
}

class _AuthWebPageState extends State<AuthWebPage> {
  late final WebViewController _controller;
  int _progress = 0;
  bool _done = false;
  bool _hasLeftLoginPage = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xffffffff))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (p) => mounted ? setState(() => _progress = p) : null,
          onNavigationRequest: (request) => _handleUrl(request.url),
          onPageStarted: (url) => _handleUrl(url),
          onPageFinished: (_) {
            if (mounted) setState(() => _progress = 100);
          },
        ),
      );
    _load();
  }

  Future<void> _load() async {
    // Đính kèm session hiện có (nếu đang đăng nhập) để đổi mật khẩu dùng được.
    String url;
    try {
      url = await AuthService.webUrlWithSession(widget.path);
    } catch (_) {
      url = AppConfig.withAppMode(widget.path);
    }
    await _controller.loadRequest(Uri.parse(url));
  }

  NavigationDecision _handleUrl(String url) {
    if (_done) return NavigationDecision.navigate;
    final uri = Uri.tryParse(url);
    if (uri == null) return NavigationDecision.navigate;

    final path = uri.path.toLowerCase();

    // Cách 1: web trả token qua app_token / token trên URL chuyển hướng (nếu sau
    // này web có hỗ trợ). Ưu tiên vì app sẽ có token API đầy đủ.
    final token = uri.queryParameters['app_token'] ?? uri.queryParameters['token'];
    if (widget.expectLogin && token != null && token.trim().isNotEmpty && token.contains('.')) {
      _finishWithToken(token.trim());
      return NavigationDecision.prevent;
    }

    // Cách 2: web báo đăng nhập thành công bằng cờ trên URL.
    final lower = url.toLowerCase();
    if (widget.expectLogin &&
        (lower.contains('app_login_success=1') || lower.contains('login_success=1'))) {
      _finishSuccess();
      return NavigationDecision.prevent;
    }

    // Cách 3 (Google qua web): đăng nhập Google set session rồi chuyển về
    // index.php. Khi rời trang đăng nhập và về trang chủ -> coi là thành công.
    if (widget.expectLogin && _hasLeftLoginPage) {
      for (final marker in AppConfig.loginSuccessMarkers) {
        if (path == marker || path.endsWith(marker)) {
          _finishSuccess();
          return NavigationDecision.prevent;
        }
      }
    }

    // Đánh dấu đã rời khỏi trang đăng nhập (để không nhầm lần tải đầu).
    if (!path.contains('dang-nhap') && !path.contains('dang-ky')) {
      _hasLeftLoginPage = true;
    }

    return NavigationDecision.navigate;
  }

  Future<void> _finishWithToken(String token) async {
    _done = true;
    await AuthService.saveToken(token);
    if (mounted) Navigator.pop(context, true);
  }

  void _finishSuccess() {
    _done = true;
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title, style: const TextStyle(fontWeight: FontWeight.w900)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xff0f172a),
        surfaceTintColor: Colors.transparent,
        elevation: 0.5,
        actions: [
          if (widget.expectLogin)
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Bỏ qua', style: TextStyle(fontWeight: FontWeight.w800)),
            ),
        ],
      ),
      body: Column(
        children: [
          if (_progress < 100)
            LinearProgressIndicator(
              value: _progress / 100,
              minHeight: 2.5,
              backgroundColor: const Color(0xffe8f5e9),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xff16a34a)),
            ),
          Expanded(child: WebViewWidget(controller: _controller)),
        ],
      ),
    );
  }
}
