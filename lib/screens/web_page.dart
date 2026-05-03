import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../config/app_config.dart';
import '../services/auth_service.dart';

class WebPage extends StatefulWidget {
  final String title;
  final String path;

  const WebPage({super.key, required this.title, required this.path});

  @override
  State<WebPage> createState() => _WebPageState();
}

class _WebPageState extends State<WebPage> {
  WebViewController? controller;
  int progress = 0;
  String? error;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) _initWebView();
  }

  String _forceAppMode(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return url;
    final host = uri.host.toLowerCase();
    if (host != 'xaydungvn.com.vn' && host != 'www.xaydungvn.com.vn') return url;
    final params = Map<String, String>.from(uri.queryParameters);
    if (params['app'] == '1') return url;
    params['app'] = '1';
    return uri.replace(queryParameters: params).toString();
  }

  Future<void> _initWebView() async {
    try {
      setState(() => error = null);
      final url = await AuthService.webUrlWithSession(widget.path);
      final webController = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(
          NavigationDelegate(
            onProgress: (value) => setState(() => progress = value),
            onNavigationRequest: (request) {
              final uri = Uri.tryParse(request.url);
              if (uri == null) return NavigationDecision.prevent;
              final host = uri.host.toLowerCase();
              if (host == 'xaydungvn.com.vn' || host == 'www.xaydungvn.com.vn') {
                final fixed = _forceAppMode(request.url);
                if (fixed != request.url) {
                  controller?.loadRequest(Uri.parse(fixed));
                  return NavigationDecision.prevent;
                }
                return NavigationDecision.navigate;
              }
              return NavigationDecision.prevent;
            },
            onWebResourceError: (e) {
              if (e.isForMainFrame == true) {
                setState(() => error = 'Không tải được trang. Kiểm tra mạng rồi thử lại.');
              }
            },
          ),
        )
        ..loadRequest(Uri.parse(url));

      if (mounted) setState(() => controller = webController);
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    }
  }

  Future<bool> _handleBack() async {
    final c = controller;
    if (c != null && await c.canGoBack()) {
      await c.goBack();
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      final previewUrl = AppConfig.withAppMode(widget.path);
      return Scaffold(
        appBar: AppBar(title: Text(widget.title)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'WebView không chạy trên Chrome web.\nHãy build APK hoặc chạy Android.\n\nLink sẽ mở trong app:\n$previewUrl',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
          ),
        ),
      );
    }

    return WillPopScope(
      onWillPop: _handleBack,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
          actions: [
            IconButton(tooltip: 'Tải lại', icon: const Icon(Icons.refresh_rounded), onPressed: () => controller?.reload()),
            IconButton(tooltip: 'Trang chủ', icon: const Icon(Icons.home_rounded), onPressed: () => Navigator.popUntil(context, (route) => route.isFirst)),
          ],
        ),
        body: Builder(
          builder: (_) {
            if (error != null) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.wifi_off_rounded, size: 56, color: Colors.grey),
                      const SizedBox(height: 12),
                      Text(error!, textAlign: TextAlign.center),
                      const SizedBox(height: 14),
                      FilledButton(onPressed: _initWebView, child: const Text('Thử lại')),
                    ],
                  ),
                ),
              );
            }
            if (controller == null) return const Center(child: CircularProgressIndicator());
            return Column(
              children: [
                if (progress < 100) LinearProgressIndicator(value: progress / 100),
                Expanded(child: WebViewWidget(controller: controller!)),
              ],
            );
          },
        ),
      ),
    );
  }
}
