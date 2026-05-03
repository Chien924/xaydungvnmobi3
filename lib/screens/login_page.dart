import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import 'web_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  bool loading = false;
  String error = '';

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    final username = usernameController.text.trim();
    final password = passwordController.text;
    if (username.isEmpty || password.isEmpty) {
      setState(() => error = 'Nhập tài khoản và mật khẩu.');
      return;
    }

    setState(() {
      loading = true;
      error = '';
    });

    try {
      await AuthService.login(username, password);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) setState(() => error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void openRegister() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const WebPage(title: 'Tạo tài khoản', path: '/dang-ky.php')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff4f7fb),
      appBar: AppBar(title: const Text('Đăng nhập')),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xffe5e7eb)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Đăng nhập Xây Dựng VN', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                const SizedBox(height: 6),
                const Text('Đăng nhập 1 lần, app sẽ tự lưu cho lần sau.', style: TextStyle(color: Color(0xff64748b), fontWeight: FontWeight.w600)),
                const SizedBox(height: 18),
                TextField(
                  controller: usernameController,
                  decoration: const InputDecoration(labelText: 'Tài khoản / số điện thoại', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Mật khẩu', border: OutlineInputBorder()),
                  onSubmitted: (_) => submit(),
                ),
                if (error.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(error, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w700)),
                ],
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: FilledButton(
                    onPressed: loading ? null : submit,
                    child: loading
                        ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Đăng nhập'),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton(
                    onPressed: openRegister,
                    child: const Text('Tạo tài khoản'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
