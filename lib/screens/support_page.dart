import 'package:flutter/material.dart';

import '../services/support_bot_service.dart';

class SupportPage extends StatefulWidget {
  const SupportPage({super.key});

  @override
  State<SupportPage> createState() => _SupportPageState();
}

class _SupportPageState extends State<SupportPage> {
  final inputController = TextEditingController();
  final scrollController = ScrollController();
  bool sending = false;
  List<String> suggestions = const ['Tài khoản', 'Nạp tiền', 'Đăng tin', 'Quản lí', 'Báo giá', 'Liên hệ'];
  final messages = <_ChatMessage>[
    const _ChatMessage(bot: true, text: 'Xin chào! Tôi là bot hỗ trợ Xây Dựng VN. Bạn cần hỗ trợ mục nào?'),
  ];

  @override
  void dispose() {
    inputController.dispose();
    scrollController.dispose();
    super.dispose();
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
      if (mounted) {
        setState(() {
          messages.add(_ChatMessage(bot: true, text: reply.text));
          if (reply.suggestions.isNotEmpty) suggestions = reply.suggestions;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => messages.add(_ChatMessage(bot: true, text: 'Chưa kết nối được API hỗ trợ. Bạn thử lại sau.')));
      }
    } finally {
      if (mounted) setState(() => sending = false);
      _scrollBottom();
    }
  }

  void _scrollBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!scrollController.hasClients) return;
      scrollController.animateTo(scrollController.position.maxScrollExtent, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: const Color(0xffe5e7eb))),
            child: const Row(
              children: [
                CircleAvatar(backgroundColor: Color(0xffdcfce7), child: Icon(Icons.support_agent_rounded, color: Color(0xff15803d))),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Hỗ trợ bot chat', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                      SizedBox(height: 3),
                      Text('App gọi bot-api.php của web. Nếu API chưa khớp, app dùng trả lời dự phòng.', style: TextStyle(color: Color(0xff64748b), fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(14, 4, 14, 10),
            itemCount: messages.length + (sending ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == messages.length) return const _Bubble(bot: true, text: 'Đang trả lời...');
              final msg = messages[index];
              return _Bubble(bot: msg.bot, text: msg.text);
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Color(0xffe5e7eb)))),
          child: Column(
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: suggestions
                      .map((key) => Padding(padding: const EdgeInsets.only(right: 8), child: ActionChip(label: Text(key), onPressed: () => send(key))))
                      .toList(),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: inputController,
                      minLines: 1,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Nhập nội dung cần hỗ trợ...',
                        filled: true,
                        fillColor: const Color(0xfff8fafc),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xffe5e7eb))),
                      ),
                      onSubmitted: (_) => send(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(onPressed: sending ? null : () => send(), icon: const Icon(Icons.send_rounded)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Bubble extends StatelessWidget {
  final bool bot;
  final String text;

  const _Bubble({required this.bot, required this.text});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: bot ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 310),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bot ? Colors.white : const Color(0xff16a34a),
          borderRadius: BorderRadius.circular(16),
          border: bot ? Border.all(color: const Color(0xffe5e7eb)) : null,
        ),
        child: Text(text, style: TextStyle(color: bot ? const Color(0xff0f172a) : Colors.white, fontWeight: FontWeight.w700, height: 1.35)),
      ),
    );
  }
}

class _ChatMessage {
  final bool bot;
  final String text;

  const _ChatMessage({required this.bot, required this.text});
}
