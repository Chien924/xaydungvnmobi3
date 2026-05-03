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
  String currentUrl = '';
  final attempted = <String>{};
  final queue = <String>[];

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

  Future<List<String>> _buildUrlQueue() async {
    final urls = <String>[];
    void add(String url) {
      if (url.trim().isNotEmpty && !urls.contains(url)) urls.add(url);
    }

    for (final path in AppConfig.fallbackPaths(widget.path)) {
      try {
        add(await AuthService.webUrlWithSession(path));
      } catch (_) {}
      add(AppConfig.withAppMode(path));
    }
    return urls;
  }

  Future<void> _initWebView() async {
    try {
      setState(() {
        error = null;
        progress = 0;
        attempted.clear();
        queue.clear();
      });

      queue.addAll(await _buildUrlQueue());
      if (queue.isEmpty) throw Exception('Không có đường dẫn để mở.');

      final webController = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(
          NavigationDelegate(
            onProgress: (value) {
              if (mounted) setState(() => progress = value);
            },
            onPageStarted: (url) {
              if (mounted) setState(() => currentUrl = url);
            },
            onPageFinished: (url) {
              if (mounted) setState(() => currentUrl = url);
            },
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
              // Không cho nhảy ra Chrome/trang ngoài.
              return NavigationDecision.prevent;
            },
            onWebResourceError: (e) async {
              if (e.isForMainFrame == true) {
                final loaded = await _loadNextFallback();
                if (!loaded && mounted) {
                  setState(() => error = 'Không tải được trang. Kiểm tra mạng hoặc đường dẫn web.');
                }
              }
            },
          ),
        );

      if (mounted) setState(() => controller = webController);
      await _loadNextFallback();
    } catch (e) {
      if (mounted) setState(() => error = e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<bool> _loadNextFallback() async {
    final c = controller;
    if (c == null) return false;

    while (queue.isNotEmpty) {
      final url = queue.removeAt(0);
      if (attempted.contains(url)) continue;
      attempted.add(url);
      if (mounted) {
        setState(() {
          error = null;
          currentUrl = url;
          progress = 0;
        });
      }
      await c.loadRequest(Uri.parse(url));
      return true;
    }
    return false;
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
            IconButton(tooltip: 'Tải lại', icon: const Icon(Icons.refresh_rounded), onPressed: _initWebView),
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
                      Text(error!, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w800)),
                      if (currentUrl.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        SelectableText(currentUrl, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, color: Color(0xff64748b))),
                      ],
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
