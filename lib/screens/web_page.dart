import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../config/app_config.dart';
import '../services/auth_service.dart';

class WebPage extends StatefulWidget {
  final String title;
  final String path;
  final bool embedded;

  const WebPage({super.key, required this.title, required this.path, this.embedded = false});

  // Gọi hàm này khi mở app để tải sẵn nhiều trang.
  static Future<void> preloadAll() => _WebPageState.preloadPaths(AppConfig.preloadWebPaths);

  // Gọi khi đăng nhập/đăng xuất để các trang web dùng đúng session mới.
  static void resetCachedControllers() => _WebPageState.resetCachedControllers();

  @override
  State<WebPage> createState() => _WebPageState();
}

class _CachedWebController {
  final WebViewController controller;
  DateTime lastUsed;
  String url;
  bool isLoading;

  _CachedWebController({required this.controller, required this.url, this.isLoading = false}) : lastUsed = DateTime.now();
}

class _WebPageState extends State<WebPage> with AutomaticKeepAliveClientMixin {
  // Cache mạnh: giữ nhiều WebView controller. Web bạn ít ảnh nên có thể để thoải mái.
  // Khi vượt quá số này app chỉ bỏ controller cũ khỏi bộ nhớ, KHÔNG xoá cache WebView toàn cục.
  static const int maxCachedControllers = 80;
  static final Map<String, _CachedWebController> _cache = {};
  static bool _isPreloading = false;

  WebViewController? controller;
  int progress = 0;
  String? error;
  String currentUrl = '';
  final queue = <String>[];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) _initWebView();
  }

  String get _cacheKey => widget.path;

  static void resetCachedControllers() {
    // Không gọi clearCache để không xoá cache WebView hệ thống.
    _cache.clear();
  }

  static Future<void> preloadPaths(List<String> paths) async {
    if (kIsWeb || _isPreloading) return;
    _isPreloading = true;

    try {
      for (final path in paths) {
        final key = path;
        if (_cache.containsKey(key)) {
          _cache[key]!.lastUsed = DateTime.now();
          continue;
        }

        try {
          final url = await _buildFirstUrlForPath(path);
          final webController = _createControllerForPath(key);
          _cache[key] = _CachedWebController(controller: webController, url: url, isLoading: true);
          await _trimCache();
          await webController.loadRequest(Uri.parse(url));
          _cache[key]?.isLoading = false;
        } catch (_) {
          // Preload lỗi thì bỏ qua, khi người dùng bấm sẽ tải lại thật.
        }

        // Nghỉ rất ngắn để tránh dồn quá nhiều request cùng lúc.
        await Future<void>.delayed(const Duration(milliseconds: 80));
      }
    } finally {
      _isPreloading = false;
    }
  }

  static Future<String> _buildFirstUrlForPath(String path) async {
    try {
      return await AuthService.webUrlWithSession(path);
    } catch (_) {
      return AppConfig.withAppMode(path);
    }
  }

  static String _forceAppModeStatic(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return url;
    final host = uri.host.toLowerCase();
    if (host != 'xaydungvn.com.vn' && host != 'www.xaydungvn.com.vn') return url;

    final params = Map<String, String>.from(uri.queryParameters);
    params['app'] = '1';

    // Luôn ép HTTPS và chuẩn hoá host về xaydungvn.com.vn.
    return uri.replace(
      scheme: 'https',
      host: 'xaydungvn.com.vn',
      queryParameters: params,
    ).toString();
  }

  static WebViewController _createControllerForPath(String key) {
    late final WebViewController c;
    c = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xffffffff))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            final cached = _cache[key];
            if (cached != null) {
              cached.url = url;
              cached.lastUsed = DateTime.now();
              cached.isLoading = true;
            }
          },
          onPageFinished: (url) async {
            final cached = _cache[key];
            if (cached != null) {
              cached.url = url;
              cached.lastUsed = DateTime.now();
              cached.isLoading = false;
            }
            try {
              await c.runJavaScript(_hideHeadJs);
            } catch (_) {}
          },
          onNavigationRequest: (request) {
            final uri = Uri.tryParse(request.url);
            if (uri == null) return NavigationDecision.prevent;
            final host = uri.host.toLowerCase();
            if (host == 'xaydungvn.com.vn' || host == 'www.xaydungvn.com.vn') {
              final fixed = _forceAppModeStatic(request.url);
              if (fixed != request.url) {
                c.loadRequest(Uri.parse(fixed));
                return NavigationDecision.prevent;
              }
              return NavigationDecision.navigate;
            }
            // Không mở link ngoài app.
            return NavigationDecision.prevent;
          },
        ),
      );
    return c;
  }

  static Future<void> _trimCache() async {
    if (_cache.length <= maxCachedControllers) return;
    final entries = _cache.entries.toList()..sort((a, b) => a.value.lastUsed.compareTo(b.value.lastUsed));
    while (_cache.length > maxCachedControllers && entries.isNotEmpty) {
      final old = entries.removeAt(0);
      _cache.remove(old.key);
    }
  }

  static const String _hideHeadJs = r'''
    (function(){
      var css = '.header,.head,.top-menu,.navbar,.menu-pc,.menu-mobile,.footer,.bottom-web,.banner-app,.mobile-bottom-nav,.app-download{display:none!important} body{padding-top:0!important;margin-top:0!important;}';
      var s=document.getElementById('xaydungvn-app-hide-head');
      if(!s){s=document.createElement('style');s.id='xaydungvn-app-hide-head';document.head.appendChild(s);} s.innerHTML=css;
    })();
  ''';

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

  Future<void> _initWebView({bool forceReload = false}) async {
    try {
      if (mounted) {
        setState(() {
          error = null;
          progress = 0;
          queue.clear();
        });
      }

      if (!forceReload && _cache.containsKey(_cacheKey)) {
        final cached = _cache[_cacheKey]!;
        cached.lastUsed = DateTime.now();
        if (mounted) {
          setState(() {
            controller = cached.controller;
            currentUrl = cached.url;
            progress = 100;
          });
        }
        return;
      }

      queue.addAll(await _buildUrlQueue());
      if (queue.isEmpty) throw Exception('Không có đường dẫn để mở.');

      final webController = _createControllerForPath(_cacheKey);
      if (mounted) setState(() => controller = webController);
      _cache[_cacheKey] = _CachedWebController(controller: webController, url: '');
      await _trimCache();
      await _loadExactUrl();
    } catch (e) {
      if (mounted) setState(() => error = e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<bool> _loadExactUrl() async {
    final c = controller;
    if (c == null || queue.isEmpty) return false;
    final url = queue.removeAt(0);
    if (mounted) {
      setState(() {
        error = null;
        currentUrl = url;
        progress = 0;
      });
    }
    _cache[_cacheKey]?.isLoading = true;
    await c.loadRequest(Uri.parse(url));
    return true;
  }

  Future<bool> _handleBack() async {
    final c = controller;
    if (c != null && await c.canGoBack()) {
      await c.goBack();
      return false;
    }
    return true;
  }

  Widget _webBody() {
    if (kIsWeb) {
      final previewUrl = AppConfig.withAppMode(widget.path);
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'WebView không chạy trên Chrome web.\nHãy build APK hoặc chạy Android.\n\nLink sẽ mở trong app:\n$previewUrl',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
        ),
      );
    }

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
              FilledButton(onPressed: () => _initWebView(forceReload: true), child: const Text('Thử lại')),
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
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (widget.embedded) return _webBody();
    return WillPopScope(
      onWillPop: _handleBack,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
          actions: [
            IconButton(tooltip: 'Tải lại', icon: const Icon(Icons.refresh_rounded), onPressed: () => _initWebView(forceReload: true)),
            IconButton(tooltip: 'Trang chủ', icon: const Icon(Icons.home_rounded), onPressed: () => Navigator.popUntil(context, (route) => route.isFirst)),
          ],
        ),
        body: _webBody(),
      ),
    );
  }
}
