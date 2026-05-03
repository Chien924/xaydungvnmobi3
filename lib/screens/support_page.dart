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
  List<BotSuggestion> suggestions = const [];

  final messages = <_ChatMessage>[];

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
      messages.add(_ChatMessage(bot: true, text: reply.text));
      suggestions = reply.suggestions;
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
        messages.add(_ChatMessage(bot: true, text: reply.text));
        if (reply.suggestions.isNotEmpty) suggestions = reply.suggestions;
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
        messages.add(_ChatMessage(bot: true, text: reply.text));
        if (reply.suggestions.isNotEmpty) suggestions = reply.suggestions;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => messages.add(const _ChatMessage(bot: true, text: 'Chưa mở được nội dung này.')));
    } finally {
      if (mounted) setState(() => sending = false);
      _scrollBottom();
    }
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
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
            itemCount: messages.length + (sending ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == messages.length) return const _Bubble(bot: true, text: 'Đang trả lời...');
              final msg = messages[index];
              return _Bubble(bot: msg.bot, text: msg.text);
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 12),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Color(0xffe5e7eb))),
          ),
          child: Column(
            children: [
              if (suggestions.isNotEmpty)
                SizedBox(
                  height: 38,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: suggestions.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 7),
                    itemBuilder: (context, index) {
                      final item = suggestions[index];
                      return ActionChip(
                        label: Text(item.title),
                        onPressed: () => choose(item),
                        side: const BorderSide(color: Color(0xffbbf7d0)),
                        backgroundColor: const Color(0xffecfdf5),
                        labelStyle: const TextStyle(color: Color(0xff166534), fontWeight: FontWeight.w800),
                      );
                    },
                  ),
                ),
              if (suggestions.isNotEmpty) const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: inputController,
                      minLines: 1,
                      maxLines: 5,
                      decoration: InputDecoration(
                        hintText: 'Nhập nội dung...',
                        filled: true,
                        fillColor: const Color(0xfff8fafc),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
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
                    width: 52,
                    height: 52,
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
    final maxWidth = MediaQuery.sizeOf(context).width * .84;

    return Align(
      alignment: bot ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        constraints: BoxConstraints(maxWidth: maxWidth),
        margin: const EdgeInsets.only(bottom: 8),
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
        child: Text(
          text,
          style: TextStyle(
            color: bot ? const Color(0xff0f172a) : Colors.white,
            fontWeight: FontWeight.w700,
            height: 1.35,
          ),
        ),
      ),
    );
  }
}

class _ChatMessage {
  final bool bot;
  final String text;

  const _ChatMessage({required this.bot, required this.text});
}
