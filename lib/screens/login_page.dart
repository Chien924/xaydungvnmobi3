import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../config/app_config.dart';
import '../services/auth_service.dart';
import 'auth_web_page.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  final String? prefillUsername;
  final String? infoMessage;
  const LoginPage({super.key, this.prefillUsername, this.infoMessage});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  bool loading = false;
  bool hidePassword = true;
  String error = '';

  @override
  void initState() {
    super.initState();
    if (widget.prefillUsername != null && widget.prefillUsername!.isNotEmpty) {
      usernameController.text = widget.prefillUsername!;
    }
  }

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

  Future<void> openRegister() async {
    final ok = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RegisterPage()),
    );
    if (ok == true && mounted) Navigator.pop(context, true);
  }

  Future<void> loginWithGoogle() async {
    setState(() {
      loading = true;
      error = '';
    });
    try {
      final googleSignIn = GoogleSignIn(
        scopes: const ['email', 'profile', 'openid'],
        // serverClientId là Web Client ID để Google trả idToken đúng audience
        // mà server (google-login-app.php) xác minh được.
        serverClientId: AppConfig.googleWebClientId,
      );

      // Đăng xuất phiên Google cũ để người dùng chọn lại tài khoản.
      await googleSignIn.signOut();
      final account = await googleSignIn.signIn();
      if (account == null) {
        // Người dùng hủy.
        if (mounted) setState(() => loading = false);
        return;
      }
      final auth = await account.authentication;
      final idToken = auth.idToken;
      if (idToken == null || idToken.isEmpty) {
        throw Exception('Không lấy được idToken từ Google.');
      }

      await AuthService.loginWithGoogleIdToken(idToken);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() => error = 'Đăng nhập Google lỗi: ${e.toString().replaceFirst('Exception: ', '')}');
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> openForgotPassword() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const AuthWebPage(
          path: AppConfig.forgotPasswordPath,
          title: 'Quên mật khẩu',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffeef6f0),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text('Đăng nhập'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xff2f7d43), Color(0xff77a759)],
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
                  child: Text('XD', style: TextStyle(color: Color(0xff166534), fontWeight: FontWeight.w900, fontSize: 20)),
                ),
                SizedBox(width: 13),
                Expanded(
                  child: Text(
                    'Xây Dựng VN',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 24),
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
                const Text('Vào tài khoản', style: TextStyle(fontSize: 23, fontWeight: FontWeight.w900, color: Color(0xff111827))),
                if (widget.infoMessage != null && widget.infoMessage!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(11),
                    decoration: BoxDecoration(color: const Color(0xffecfdf5), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xffbbf7d0))),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_rounded, color: Color(0xff16a34a), size: 20),
                        const SizedBox(width: 8),
                        Expanded(child: Text(widget.infoMessage!, style: const TextStyle(color: Color(0xff047857), fontWeight: FontWeight.w800))),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                _InputBox(
                  controller: usernameController,
                  label: 'Tài khoản / số điện thoại',
                  icon: Icons.person_rounded,
                ),
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
                        : const Text('Đăng nhập', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xff2f7d43)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: loading ? null : openRegister,
                    child: const Text('Tạo tài khoản mới', style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xff2f7d43))),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: const [
                    Expanded(child: Divider(color: Color(0xffd1d5db))),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      child: Text('hoặc', style: TextStyle(color: Color(0xff6b7280), fontWeight: FontWeight.w700)),
                    ),
                    Expanded(child: Divider(color: Color(0xffd1d5db))),
                  ],
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xffd1d5db)),
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: loading ? null : loginWithGoogle,
                    icon: const Icon(Icons.g_mobiledata_rounded, color: Color(0xffdb4437), size: 30),
                    label: const Text('Đăng nhập bằng Google', style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xff374151))),
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: TextButton(
                    onPressed: loading ? null : openForgotPassword,
                    child: const Text('Quên mật khẩu?', style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xff2f7d43))),
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
