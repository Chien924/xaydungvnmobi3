import 'package:flutter/material.dart';

import '../services/auth_service.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final usernameController = TextEditingController();
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmController = TextEditingController();
  bool loading = false;
  String error = '';

  @override
  void dispose() {
    usernameController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    confirmController.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    final username = usernameController.text.trim();
    final phone = phoneController.text.trim();
    final password = passwordController.text;
    final confirm = confirmController.text;

    if (username.isEmpty || password.isEmpty) {
      setState(() => error = 'Nhập tài khoản và mật khẩu.');
      return;
    }
    if (password.length < 6) {
      setState(() => error = 'Mật khẩu nên từ 6 ký tự trở lên.');
      return;
    }
    if (password != confirm) {
      setState(() => error = 'Nhập lại mật khẩu chưa khớp.');
      return;
    }

    setState(() {
      loading = true;
      error = '';
    });

    try {
      await AuthService.register(username: username, password: password, phone: phone);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) setState(() => error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff4f7fb),
      appBar: AppBar(title: const Text('Tạo tài khoản')),
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
                const Text('Tạo tài khoản Xây Dựng VN', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),

                const SizedBox(height: 18),
                TextField(
                  controller: usernameController,
                  decoration: const InputDecoration(labelText: 'Tên tài khoản', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Số điện thoại', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Mật khẩu', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: confirmController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Nhập lại mật khẩu', border: OutlineInputBorder()),
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
                        : const Text('Tạo tài khoản'),
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
