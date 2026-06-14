import 'package:flutter/material.dart';

import '../services/app_prefs.dart';
import 'home_page.dart';
import 'login_page.dart';
import 'register_page.dart';

class IntroPage extends StatefulWidget {
  const IntroPage({super.key});

  @override
  State<IntroPage> createState() => _IntroPageState();
}

class _IntroPageState extends State<IntroPage> {
  final controller = PageController();
  int page = 0;

  Future<void> _enterGuest() async {
    await AppPrefs.setIntroSeen(true);
    if (!mounted) return;
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomePage()));
  }

  Future<void> _openLogin() async {
    final ok = await Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginPage()));
    if (ok == true) {
      await AppPrefs.setIntroSeen(true);
      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomePage()));
    }
  }

  Future<void> _openRegister() async {
    final ok = await Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterPage()));
    if (ok == true) {
      await AppPrefs.setIntroSeen(true);
      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomePage()));
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pages = const [
      _IntroSlide(
        icon: Icons.search_rounded,
        title: 'Tìm nhanh',
        text: 'Cơ giới, vật tư, tổ đội, gói thầu, nhu cầu và việc làm xây dựng.',
        color: Color(0xff16a34a),
      ),
      _IntroSlide(
        icon: Icons.add_business_rounded,
        title: 'Đăng tin',
        text: 'Đăng xe, vật tư, tổ đội, gói thầu, nhu cầu, đối tác và việc làm.',
        color: Color(0xffff8a00),
      ),
      _IntroSlide(
        icon: Icons.folder_rounded,
        title: 'Quản lí dễ',
        text: 'Quản lí tin, tài khoản, nạp tiền, lịch sử và hỗ trợ ngay trong app.',
        color: Color(0xff7c3aed),
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xfff4f7fb),
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _enterGuest,
                child: const Text('Bỏ qua'),
              ),
            ),
            Expanded(
              child: PageView(
                controller: controller,
                onPageChanged: (i) => setState(() => page = i),
                children: pages,
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                pages.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: i == page ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: i == page ? const Color(0xff16a34a) : const Color(0xffcbd5e1),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 52,
                          child: FilledButton(
                            onPressed: _openLogin,
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xff2f7d43),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                            ),
                            child: const Text('Đăng nhập'),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: SizedBox(
                          height: 52,
                          child: OutlinedButton(
                            onPressed: _enterGuest,
                            style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                              side: const BorderSide(color: Color(0xff2f7d43)),
                            ),
                            child: const Text('Khách vào luôn'),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: _openRegister,
                    child: const Text('Tạo tài khoản mới'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IntroSlide extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;
  final Color color;

  const _IntroSlide({
    required this.icon,
    required this.title,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 10, 22, 0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 138,
            height: 138,
            decoration: BoxDecoration(
              color: color.withOpacity(.12),
              borderRadius: BorderRadius.circular(38),
            ),
            child: Icon(icon, size: 76, color: color),
          ),
          const SizedBox(height: 32),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xff06122a),
              fontSize: 34,
              fontWeight: FontWeight.w900,
              height: 1.05,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xff64748b),
              fontSize: 16,
              height: 1.45,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
