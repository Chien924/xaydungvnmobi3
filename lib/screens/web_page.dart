import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

import '../config/app_config.dart';
import '../services/auth_service.dart';

class WebPage extends StatefulWidget {
  final String title;
  final String path;
  final bool embedded;

  const WebPage({super.key, required this.title, required this.path, this.embedded = false});

  static Future<void> preloadAll() => _WebPageState.preloadPaths(AppConfig.preloadWebPaths);

  static void resetCachedControllers() => _WebPageState.resetCachedControllers();

  static Future<bool> openExternalIfNeeded(String url) => _WebPageState.openExternalIfNeeded(url);

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
          if (_shouldOpenExternally(url)) continue;

          final webController = _createControllerForPath(key);
          _cache[key] = _CachedWebController(controller: webController, url: url, isLoading: true);
          await _trimCache();
          await webController.loadRequest(Uri.parse(url));
          _cache[key]?.isLoading = false;
        } catch (_) {}

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

  static bool _isInternalHost(String host) {
    final fixed = host.toLowerCase();
    return fixed == 'xaydungvn.com.vn' || fixed == 'www.xaydungvn.com.vn';
  }

  static bool _isSafeWebViewScheme(String scheme) {
    final fixed = scheme.toLowerCase();
    return fixed == 'http' || fixed == 'https' || fixed == 'about' || fixed == 'data' || fixed == 'blob';
  }

  static String _safeDecodeLower(String value) {
    try {
      return Uri.decodeFull(value).toLowerCase();
    } catch (_) {
      return value.toLowerCase();
    }
  }

  static bool _looksLikeDownloadOrExternalPage(String url, Uri uri) {
    final decodedUrl = _safeDecodeLower(url);
    final path = _safeDecodeLower(uri.path);
    final query = _safeDecodeLower(uri.query);

    // Các link file/hồ sơ/báo giá đang lưu bằng link ngoài thì cho trình duyệt mặc định xử lý.
    // Nếu link Drive nằm trong tham số redirect/go thì vẫn bắt được qua decodedUrl/query.
    if (decodedUrl.contains('drive.google.com') || decodedUrl.contains('docs.google.com')) return true;

    // Trang tải CV nội bộ là ngoại lệ: vẫn thuộc xaydungvn.com.vn nhưng phải mở ngoài app.
    // Trường hợp đã đi qua app-session-login.php thì query sẽ chứa go=...tai-cv.php...
    if (path.contains('tai-cv') || query.contains('tai-cv')) return true;

    // Cờ mở ngoài dùng chung về sau cho nút tải CV/file hoặc link đặc biệt trên web.
    if (query.contains('app_open_external=1') || query.contains('open_external=1')) return true;

    const fileExtensions = [
      '.pdf',
      '.doc',
      '.docx',
      '.xls',
      '.xlsx',
      '.ppt',
      '.pptx',
      '.zip',
      '.rar',
      '.7z',
      '.dwg',
      '.dxf',
    ];
    if (fileExtensions.any(path.endsWith)) return true;

    const pathKeywords = [
      '/download',
      'download-',
      'download_',
      'download.php',
      'xuat-pdf',
      'xuat_pdf',
      'export',
      'generate-pdf',
      'pdf-download',
      'cv-pdf',
      'cv_pdf',
      'file-bao-gia',
      'bao-gia-file',
      'ho-so-nang-luc',
      'attachment',
    ];
    if (pathKeywords.any(path.contains)) return true;

    const queryKeywords = [
      'download=1',
      'action=download',
      'act=download',
      'export=pdf',
      'format=pdf',
      'type=pdf',
      'pdf=1',
      'drive=',
      'attachment=',
    ];
    if (queryKeywords.any(query.contains)) return true;

    return false;
  }

  static bool _shouldOpenExternally(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return false;

    final scheme = uri.scheme.toLowerCase();
    if (!_isSafeWebViewScheme(scheme)) return true;

    if (scheme == 'about' || scheme == 'data' || scheme == 'blob') return false;

    final host = uri.host.toLowerCase();

    // Link ngoài mở bằng trình duyệt/app mặc định của máy.
    if (!_isInternalHost(host)) return true;

    // Link nội bộ vẫn mở trong app, trừ tai-cv.php và các link tải/xuất file.
    return _looksLikeDownloadOrExternalPage(url, uri);
  }

  static Future<bool> _launchOutside(String url) async {
    var finalUrl = url;

    // Link tải CV nội bộ có thể cần session đăng nhập.
    // Nếu web có app-session-login.php thì mở ngoài vẫn giữ được đăng nhập trước khi chuyển tới tai-cv.php.
    if (AppConfig.isInternalWebUrl(url) && !url.contains('/app-session-login.php')) {
      try {
        finalUrl = await AuthService.webUrlWithSession(url);
      } catch (_) {}
    }

    final uri = Uri.tryParse(finalUrl);
    if (uri == null) return false;

    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      try {
        return await launchUrl(uri, mode: LaunchMode.platformDefault);
      } catch (_) {
        return false;
      }
    }
  }

  static Future<bool> openExternalIfNeeded(String url) async {
    if (!_shouldOpenExternally(url)) return false;
    return _launchOutside(url);
  }

  static String _forceAppModeStatic(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return url;
    final host = uri.host.toLowerCase();
    if (!_isInternalHost(host)) return url;

    final params = Map<String, String>.from(uri.queryParameters);
    params['app'] = '1';

    return uri.replace(
      scheme: 'https',
      host: 'xaydungvn.com.vn',
      queryParameters: params,
    ).toString();
  }

  static bool _acceptTypesPreferImage(List<String> acceptTypes) {
    final cleaned = acceptTypes
        .map((item) => item.trim().toLowerCase())
        .where((item) => item.isNotEmpty && item != '*/*')
        .toList();

    if (cleaned.isEmpty) return false;

    const imageExtensions = ['.jpg', '.jpeg', '.png', '.webp', '.gif', '.bmp', '.heic', '.heif'];
    return cleaned.every((item) {
      if (item.startsWith('image/')) return true;
      if (imageExtensions.any(item.contains)) return true;
      return false;
    });
  }

  static Future<List<String>> _pickFilesForAndroidWebView(FileSelectorParams params) async {
    try {
      final result = await FilePicker.pickFiles(
        allowMultiple: params.mode == FileSelectorMode.openMultiple,
        type: _acceptTypesPreferImage(params.acceptTypes) ? FileType.image : FileType.any,
      );

      if (result == null || result.files.isEmpty) return <String>[];

      return result.files
          .map((file) => file.path)
          .where((path) => path != null && path.trim().isNotEmpty)
          .cast<String>()
          .toList();
    } catch (_) {
      return <String>[];
    }
  }

  static void _enableAndroidFileUpload(WebViewController controller) {
    if (defaultTargetPlatform != TargetPlatform.android) return;
    final platformController = controller.platform;
    if (platformController is! AndroidWebViewController) return;

    // Cho input type="file" trên web mở bộ chọn ảnh/file native của Android.
    // Dùng cho đăng xe và tạo CV có ảnh trong WebView.
    platformController.setAllowFileAccess(true);
    platformController.setAllowContentAccess(true);
    platformController.setOnShowFileSelector(_pickFilesForAndroidWebView);
  }

  static WebViewController _createControllerForPath(String key) {
    late final WebViewController c;
    c = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xffffffff))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (value) {
            final cached = _cache[key];
            if (cached != null) cached.lastUsed = DateTime.now();
          },
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
          onNavigationRequest: (request) async {
            final uri = Uri.tryParse(request.url);
            if (uri == null) return NavigationDecision.prevent;

            if (_shouldOpenExternally(request.url)) {
              await _launchOutside(request.url);
              return NavigationDecision.prevent;
            }

            final host = uri.host.toLowerCase();
            if (_isInternalHost(host)) {
              final fixed = _forceAppModeStatic(request.url);
              if (fixed != request.url) {
                c.loadRequest(Uri.parse(fixed));
                return NavigationDecision.prevent;
              }
              return NavigationDecision.navigate;
            }
            return NavigationDecision.prevent;
          },
        ),
      );

    _enableAndroidFileUpload(c);

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
      var css = '.header,.head,.top-menu,.navbar,.menu-pc,.menu-mobile,.footer,.bottom-web,.banner-app,.mobile-bottom-nav,.app-download{display:none!important} body{padding-top:0!important;margin-top:0!important;} .container,.main-container,.wrapper{max-width:100%!important;width:100%!important;}';
      var s=document.getElementById('xaydungvn-app-hide-head');
      if(!s){s=document.createElement('style');s.id='xaydungvn-app-hide-head';document.head.appendChild(s);} s.innerHTML=css;

      // Ép link target=_blank về cùng cửa sổ để Flutter bắt được NavigationRequest.
      function fixLinks(){
        var links=document.querySelectorAll('a[href]');
        for(var i=0;i<links.length;i++){
          links[i].removeAttribute('target');
          links[i].rel='noopener noreferrer';
        }
      }
      fixLinks();
      document.addEventListener('click', function(e){
        var a=e.target.closest && e.target.closest('a[href]');
        if(a){a.removeAttribute('target'); a.rel='noopener noreferrer';}
      }, true);
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

      final firstUrl = await _buildFirstUrlForPath(widget.path);
      if (_shouldOpenExternally(firstUrl)) {
        final opened = await _launchOutside(firstUrl);
        if (!mounted) return;
        setState(() {
          progress = 100;
          currentUrl = firstUrl;
          error = opened ? 'Đã mở liên kết bằng trình duyệt mặc định của máy.' : 'Chưa mở được liên kết ngoài.';
        });
        if (opened && !widget.embedded) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && Navigator.of(context).canPop()) Navigator.of(context).pop();
          });
        }
        return;
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
      queue.removeWhere(_shouldOpenExternally);
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
              const Icon(Icons.open_in_browser_rounded, size: 56, color: Colors.grey),
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
