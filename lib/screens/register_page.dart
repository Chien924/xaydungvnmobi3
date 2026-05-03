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
  bool hidePassword = true;
  bool hideConfirm = true;
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

    if (username.isEmpty) {
      setState(() => error = 'Nhập tên tài khoản.');
      return;
    }
    if (phone.isEmpty) {
      setState(() => error = 'Nhập số điện thoại.');
      return;
    }
    if (password.isEmpty) {
      setState(() => error = 'Nhập mật khẩu.');
      return;
    }
    if (password.length < 4) {
      setState(() => error = 'Mật khẩu quá ngắn.');
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
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tạo tài khoản thành công')));
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        final msg = e.toString().replaceFirst('Exception: ', '');
        setState(() => error = msg.isEmpty ? 'Tạo tài khoản thất bại.' : msg);
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffeef6f0),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text('Tạo tài khoản'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xff2f7d43), Color(0xff83b765)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(28),
              boxShadow: const [BoxShadow(color: Color(0x22000000), blurRadius: 18, offset: Offset(0, 8))],
            ),
            child: const Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person_add_alt_1_rounded, color: Color(0xff166534), size: 30),
                ),
                SizedBox(width: 13),
                Expanded(
                  child: Text(
                    'Tạo tài khoản mới',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 23),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: const Color(0xffe5e7eb)),
              boxShadow: const [BoxShadow(color: Color(0x0d000000), blurRadius: 16, offset: Offset(0, 6))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Thông tin đăng ký', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xff111827))),
                const SizedBox(height: 18),
                _InputBox(controller: usernameController, label: 'Tên tài khoản', icon: Icons.person_rounded),
                const SizedBox(height: 12),
                _InputBox(controller: phoneController, label: 'Số điện thoại', icon: Icons.phone_rounded, keyboardType: TextInputType.phone),
                const SizedBox(height: 12),
                _InputBox(
                  controller: passwordController,
                  label: 'Mật khẩu',
                  icon: Icons.lock_rounded,
                  obscureText: hidePassword,
                  suffix: IconButton(
                    icon: Icon(hidePassword ? Icons.visibility_rounded : Icons.visibility_off_rounded),
                    onPressed: () => setState(() => hidePassword = !hidePassword),
                  ),
                ),
                const SizedBox(height: 12),
                _InputBox(
                  controller: confirmController,
                  label: 'Nhập lại mật khẩu',
                  icon: Icons.verified_user_rounded,
                  obscureText: hideConfirm,
                  suffix: IconButton(
                    icon: Icon(hideConfirm ? Icons.visibility_rounded : Icons.visibility_off_rounded),
                    onPressed: () => setState(() => hideConfirm = !hideConfirm),
                  ),
                  onSubmitted: (_) => submit(),
                ),
                if (error.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(11),
                    decoration: BoxDecoration(color: const Color(0xfffff1f2), borderRadius: BorderRadius.circular(14)),
                    child: Text(error, style: const TextStyle(color: Color(0xffbe123c), fontWeight: FontWeight.w800)),
                  ),
                ],
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xff2f7d43),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: loading ? null : submit,
                    child: loading
                        ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Tạo tài khoản', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
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

class _InputBox extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool obscureText;
  final Widget? suffix;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onSubmitted;

  const _InputBox({
    required this.controller,
    required this.label,
    required this.icon,
    this.obscureText = false,
    this.suffix,
    this.keyboardType,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      onSubmitted: onSubmitted,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        suffixIcon: suffix,
        filled: true,
        fillColor: const Color(0xfff8fafc),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xffe5e7eb))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xffe5e7eb))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xff2f7d43), width: 1.6)),
      ),
    );
  }
}
