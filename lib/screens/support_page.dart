import 'package:flutter/material.dart';

import '../config/app_config.dart';
import '../services/support_bot_service.dart';
import 'web_page.dart';

class SupportPage extends StatefulWidget {
  const SupportPage({super.key});

  @override
  State<SupportPage> createState() => _SupportPageState();
}

class _SupportPageState extends State<SupportPage> {
  final inputController = TextEditingController();
  final scrollController = ScrollController();
  bool sending = false;

  final messages = <_ChatMessage>[];

  static const List<BotSuggestion> fixedQuickSuggestions = [
    BotSuggestion(title: 'Tài khoản', text: 'Tài khoản'),
    BotSuggestion(title: 'Nạp tiền', text: 'Nạp tiền'),
    BotSuggestion(title: 'Hồ sơ công ty', text: 'Hồ sơ công ty'),
    BotSuggestion(title: 'Gói thầu', text: 'Gói thầu'),
    BotSuggestion(title: 'Báo giá', text: 'Báo giá'),
    BotSuggestion(title: 'Nhu cầu vật tư', text: 'Nhu cầu vật tư'),
    BotSuggestion(title: 'Cửa hàng vật tư', text: 'Cửa hàng vật tư'),
    BotSuggestion(title: 'Cơ giới', text: 'Cơ giới'),
    BotSuggestion(title: 'Tổ đội', text: 'Tổ đội'),
    BotSuggestion(title: 'Liên hệ', text: 'Liên hệ'),
  ];

  @override
  void initState() {
    super.initState();
    _initBot();
  }

  @override
  void dispose() {
    inputController.dispose();
    scrollController.dispose();
    super.dispose();
  }

  Future<void> _initBot() async {
    final reply = await SupportBotService.init();
    if (!mounted) return;
    setState(() {
      messages.clear();
      messages.add(_ChatMessage(bot: true, text: reply.text, suggestions: reply.suggestions));
    });
    _scrollBottom();
  }

  Future<void> send([String? quick]) async {
    final text = (quick ?? inputController.text).trim();
    if (text.isEmpty || sending) return;

    inputController.clear();

    setState(() {
      sending = true;
      messages.add(_ChatMessage(bot: false, text: text));
    });

    _scrollBottom();

    try {
      final reply = await SupportBotService.ask(text);
      if (!mounted) return;
      setState(() {
        messages.add(_ChatMessage(bot: true, text: reply.text, suggestions: reply.suggestions));
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => messages.add(const _ChatMessage(bot: true, text: 'Chưa kết nối được hỗ trợ.')));
    } finally {
      if (mounted) setState(() => sending = false);
      _scrollBottom();
    }
  }

  Future<void> choose(BotSuggestion item) async {
    if (sending) return;
    setState(() {
      sending = true;
      messages.add(_ChatMessage(bot: false, text: item.title));
    });
    _scrollBottom();

    try {
      final reply = await SupportBotService.choose(item);
      if (!mounted) return;
      setState(() {
        messages.add(_ChatMessage(bot: true, text: reply.text, suggestions: reply.suggestions));
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => messages.add(const _ChatMessage(bot: true, text: 'Chưa mở được nội dung này.')));
    } finally {
      if (mounted) setState(() => sending = false);
      _scrollBottom();
    }
  }

  void _openUrl(String rawUrl) {
    final url = _normalizeUrl(rawUrl);
    if (url.isEmpty) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => WebPage(
          title: 'Liên kết',
          path: url,
        ),
      ),
    );
  }

  String _normalizeUrl(String rawUrl) {
    var url = rawUrl.trim();
    if (url.isEmpty) return '';

    if (url.startsWith('http://xaydungvn.com.vn')) {
      url = url.replaceFirst('http://xaydungvn.com.vn', AppConfig.baseUrl);
    }

    if (url.startsWith('/')) {
      url = '${AppConfig.baseUrl}$url';
    }

    if (url.startsWith('xaydungvn.com.vn')) {
      url = 'https://$url';
    }

    if (url.contains('xaydungvn.com.vn') && !url.contains('app=1')) {
      url += url.contains('?') ? '&app=1' : '?app=1';
    }

    return url;
  }

  void _scrollBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!scrollController.hasClients) return;
      scrollController.animateTo(
        scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Column(
      children: [
        Container(
          color: const Color(0xfff4f7fb),
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xffdcfce7),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(Icons.support_agent_rounded, color: Color(0xff15803d)),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Hỗ trợ',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xff06122a)),
                ),
              ),
              IconButton(
                onPressed: _initBot,
                icon: const Icon(Icons.refresh_rounded),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 12),
            itemCount: messages.length + (sending ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == messages.length) {
                return const _TypingBubble();
              }
              final msg = messages[index];
              return _Bubble(
                bot: msg.bot,
                text: msg.text,
                suggestions: msg.suggestions,
                onOpenUrl: _openUrl,
                onChoose: choose,
              );
            },
          ),
        ),
        AnimatedPadding(
          duration: const Duration(milliseconds: 160),
          padding: EdgeInsets.only(bottom: bottomInset > 0 ? bottomInset : 0),
          child: Container(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 12),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xffe5e7eb))),
              boxShadow: [BoxShadow(color: Color(0x10000000), blurRadius: 12, offset: Offset(0, -4))],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 39,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: fixedQuickSuggestions.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 7),
                    itemBuilder: (context, index) {
                      final item = fixedQuickSuggestions[index];
                      return ActionChip(
                        label: Text(item.title),
                        onPressed: () => choose(item),
                        side: const BorderSide(color: Color(0xffbbf7d0)),
                        backgroundColor: const Color(0xffecfdf5),
                        labelStyle: const TextStyle(color: Color(0xff166534), fontWeight: FontWeight.w900),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: inputController,
                        minLines: 1,
                        maxLines: 4,
                        decoration: InputDecoration(
                          hintText: 'Nhập nội dung...',
                          filled: true,
                          fillColor: const Color(0xfff8fafc),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 13),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(17),
                            borderSide: const BorderSide(color: Color(0xffe5e7eb)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(17),
                            borderSide: const BorderSide(color: Color(0xffe5e7eb)),
                          ),
                        ),
                        onSubmitted: (_) => send(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 54,
                      height: 54,
                      child: IconButton.filled(
                        onPressed: sending ? null : () => send(),
                        icon: const Icon(Icons.send_rounded),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ChatMessage {
  final bool bot;
  final String text;
  final List<BotSuggestion> suggestions;

  const _ChatMessage({
    required this.bot,
    required this.text,
    this.suggestions = const [],
  });
}

class _Bubble extends StatelessWidget {
  final bool bot;
  final String text;
  final List<BotSuggestion> suggestions;
  final ValueChanged<String> onOpenUrl;
  final ValueChanged<BotSuggestion> onChoose;

  const _Bubble({
    required this.bot,
    required this.text,
    this.suggestions = const [],
    required this.onOpenUrl,
    required this.onChoose,
  });

  @override
  Widget build(BuildContext context) {
    final maxWidth = MediaQuery.sizeOf(context).width * .84;
    final parsed = _parseText(text);

    return Align(
      alignment: bot ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        constraints: BoxConstraints(maxWidth: maxWidth),
        margin: const EdgeInsets.only(bottom: 9),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
        decoration: BoxDecoration(
          color: bot ? Colors.white : const Color(0xff16a34a),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(17),
            topRight: const Radius.circular(17),
            bottomLeft: Radius.circular(bot ? 5 : 17),
            bottomRight: Radius.circular(bot ? 17 : 5),
          ),
          border: bot ? Border.all(color: const Color(0xffe5e7eb)) : null,
          boxShadow: bot ? const [BoxShadow(color: Color(0x08000000), blurRadius: 8, offset: Offset(0, 3))] : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (parsed.cleanText.isNotEmpty)
              Text(
                parsed.cleanText,
                style: TextStyle(
                  color: bot ? const Color(0xff0f172a) : Colors.white,
                  fontWeight: FontWeight.w800,
                  height: 1.35,
                ),
              ),
            if (bot && parsed.urls.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 7,
                runSpacing: 7,
                children: parsed.urls
                    .map(
                      (url) => ActionChip(
                        label: const Text('Mở liên kết'),
                        avatar: const Icon(Icons.link_rounded, size: 18, color: Color(0xff166534)),
                        onPressed: () => onOpenUrl(url),
                        side: const BorderSide(color: Color(0xffbbf7d0)),
                        backgroundColor: const Color(0xffecfdf5),
                        labelStyle: const TextStyle(color: Color(0xff166534), fontWeight: FontWeight.w900),
                      ),
                    )
                    .toList(),
              ),
            ],
            if (bot && suggestions.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 7,
                runSpacing: 7,
                children: suggestions
                    .take(10)
                    .map(
                      (s) => ActionChip(
                        label: Text(s.title),
                        onPressed: () => onChoose(s),
                        side: const BorderSide(color: Color(0xffbbf7d0)),
                        backgroundColor: const Color(0xffecfdf5),
                        labelStyle: const TextStyle(color: Color(0xff166534), fontWeight: FontWeight.w900),
                      ),
                    )
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  _ParsedBubble _parseText(String raw) {
    final urlReg = RegExp(r'''https?:\/\/[^\s<>"']+''', caseSensitive: false);
    final urls = <String>[];

    var clean = raw.replaceAllMapped(urlReg, (match) {
      final u = match.group(0) ?? '';
      final fixed = u.replaceAll(RegExp(r'[.,;]+$'), '');
      if (fixed.isNotEmpty) urls.add(fixed);
      return '';
    });

    clean = clean
        .replaceAll(RegExp(r'Link\s*:\s*', caseSensitive: false), '')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();

    return _ParsedBubble(cleanText: clean, urls: urls);
  }
}

class _ParsedBubble {
  final String cleanText;
  final List<String> urls;

  const _ParsedBubble({required this.cleanText, required this.urls});
}

class _TypingBubble extends StatefulWidget {
  const _TypingBubble();

  @override
  State<_TypingBubble> createState() => _TypingBubbleState();
}

class _TypingBubbleState extends State<_TypingBubble> with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 9),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(17),
            topRight: Radius.circular(17),
            bottomLeft: Radius.circular(5),
            bottomRight: Radius.circular(17),
          ),
          border: Border.all(color: const Color(0xffe5e7eb)),
          boxShadow: const [BoxShadow(color: Color(0x08000000), blurRadius: 8, offset: Offset(0, 3))],
        ),
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) {
                final t = (_c.value + i * 0.2) % 1.0;
                final scale = 0.6 + 0.4 * (1 - (t - 0.5).abs() * 2).clamp(0.0, 1.0);
                return Padding(
                  padding: EdgeInsets.only(right: i < 2 ? 5 : 0),
                  child: Transform.scale(
                    scale: scale,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(color: Color(0xff16a34a), shape: BoxShape.circle),
                    ),
                  ),
                );
              }),
            );
          },
        ),
      ),
    );
  }
}
