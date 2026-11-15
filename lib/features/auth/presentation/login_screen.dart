import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../navigation/presentation/main_nav_screen.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _isRegister = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _rememberMe = true;
  bool _agreeTerms = true;
  bool _loading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_isRegister && !_agreeTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Vui lòng đồng ý với Điều khoản sử dụng và Chính sách quyền riêng tư.'),
        ),
      );
      return;
    }

    if (_isRegister &&
        _passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mật khẩu nhập lại không khớp.')),
      );
      return;
    }

    setState(() => _loading = true);
    final auth = context.read<AuthProvider>();
    bool success;

    if (_isRegister) {
      success = await auth.register(
        _emailController.text,
        _passwordController.text,
        name: _nameController.text,
      );
    } else {
      success = await auth.signIn(
        _emailController.text,
        _passwordController.text,
      );
    }

    if (!mounted) return;
    setState(() => _loading = false);

    if (success) {
      _navigateAfterAuth(
          _isRegister ? 'Đăng ký thành công!' : 'Đăng nhập thành công!');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage.isNotEmpty
              ? auth.errorMessage
              : 'Thao tác thất bại. Vui lòng thử lại.'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  void _signInWithGoogle() async {
    setState(() => _loading = true);
    final auth = context.read<AuthProvider>();
    final success = await auth.signInWithGoogle();
    if (!mounted) return;
    setState(() => _loading = false);
    if (success) {
      _navigateAfterAuth('Đăng nhập Google thành công!');
    } else if (auth.errorMessage.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.errorMessage)),
      );
    }
  }

  void _signInWithFacebook() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
            'Facebook — chưa cấu hình App ID (Meta for Developers).'),
      ),
    );
  }

  void _signInWithApple() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content:
            Text('Apple Sign In — chỉ khả dụng trên thiết bị iOS/macOS.'),
      ),
    );
  }

  void _forgotPassword() {
    final resetCtrl =
        TextEditingController(text: _emailController.text.trim());
    final formKey = GlobalKey<FormState>();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Đặt lại mật khẩu'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Nhập email để nhận liên kết đặt lại:',
                  style: TextStyle(fontSize: 14)),
              const SizedBox(height: 12),
              TextFormField(
                controller: resetCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Vui lòng nhập email';
                  if (!v.contains('@')) return 'Email không hợp lệ';
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final auth = context.read<AuthProvider>();
              final ok = await auth.sendPasswordReset(resetCtrl.text);
              if (!ctx.mounted) return;
              Navigator.pop(ctx);
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(ok
                    ? 'Đã gửi email khôi phục!'
                    : (auth.errorMessage.isNotEmpty
                        ? auth.errorMessage
                        : 'Không gửi được email.')),
              ));
            },
            child: const Text('Gửi email'),
          ),
        ],
      ),
    );
  }

  void _navigateAfterAuth(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)));
    if (Navigator.canPop(context)) {
      Navigator.pop(context, true);
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainNavScreen()),
      );
    }
  }

  void _skipToHome() {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainNavScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        leading: _isRegister
            ? BackButton(
                onPressed: () => setState(() => _isRegister = false))
            : Navigator.canPop(context)
                ? const BackButton()
                : null,
        actions: [
          TextButton(
            onPressed: _skipToHome,
            child: const Text('Bỏ qua'),
          ),
          const SizedBox(width: 8),
        ],
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Logo & tiêu đề ────────────────────────────────
                    Center(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.asset(
                          'assets/images/app_icon.jpg',
                          height: _isRegister ? 64 : 80,
                          width: _isRegister ? 64 : 80,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            height: _isRegister ? 64 : 80,
                            width: _isRegister ? 64 : 80,
                            decoration: BoxDecoration(
                              color: cs.primaryContainer,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Icon(Icons.newspaper_rounded,
                                color: cs.primary, size: 36),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _isRegister ? 'Tạo tài khoản' : 'Đăng nhập',
                      textAlign: TextAlign.center,
                      style: tt.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _isRegister
                          ? 'Điền thông tin để bắt đầu'
                          : 'Daily News & Weather Portal',
                      textAlign: TextAlign.center,
                      style: tt.bodyMedium
                          ?.copyWith(color: cs.onSurfaceVariant),
                    ),
                    const SizedBox(height: 32),

                    // ── Fields ────────────────────────────────────────
                    if (_isRegister) ...[
                      TextFormField(
                        controller: _nameController,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Họ và tên',
                          prefixIcon: Icon(Icons.person_outline_rounded),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Vui lòng nhập họ tên'
                            : null,
                      ),
                      const SizedBox(height: 12),
                    ],

                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Vui lòng nhập email';
                        }
                        if (!v.contains('@')) {
                          return 'Email không hợp lệ';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      textInputAction: _isRegister
                          ? TextInputAction.next
                          : TextInputAction.done,
                      decoration: InputDecoration(
                        labelText: 'Mật khẩu',
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined),
                          onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                      validator: (v) => (v == null || v.length < 6)
                          ? 'Mật khẩu tối thiểu 6 ký tự'
                          : null,
                    ),

                    if (_isRegister) ...[
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: _obscureConfirmPassword,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          labelText: 'Nhập lại mật khẩu',
                          prefixIcon:
                              const Icon(Icons.lock_outline_rounded),
                          suffixIcon: IconButton(
                            icon: Icon(_obscureConfirmPassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined),
                            onPressed: () => setState(() =>
                                _obscureConfirmPassword =
                                    !_obscureConfirmPassword),
                          ),
                        ),
                        validator: (v) =>
                            (v != _passwordController.text)
                                ? 'Mật khẩu nhập lại không khớp'
                                : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.done,
                        decoration: const InputDecoration(
                          labelText: 'Số điện thoại (tùy chọn)',
                          prefixIcon: Icon(Icons.phone_outlined),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Terms
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Checkbox(
                            value: _agreeTerms,
                            visualDensity: VisualDensity.compact,
                            onChanged: (v) =>
                                setState(() => _agreeTerms = v ?? true),
                          ),
                          Expanded(
                            child: Padding(
                              padding:
                                  const EdgeInsets.only(top: 11),
                              child: Text.rich(
                                TextSpan(
                                  text: 'Tôi đồng ý với ',
                                  style: TextStyle(
                                      fontSize: 13,
                                      color: cs.onSurfaceVariant),
                                  children: [
                                    TextSpan(
                                      text: 'Điều khoản sử dụng',
                                      style:
                                          TextStyle(color: cs.primary),
                                    ),
                                    const TextSpan(text: ' và '),
                                    TextSpan(
                                      text:
                                          'Chính sách quyền riêng tư',
                                      style:
                                          TextStyle(color: cs.primary),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],

                    // Remember me & Forgot (login only)
                    if (!_isRegister) ...[
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Checkbox(
                                value: _rememberMe,
                                visualDensity: VisualDensity.compact,
                                onChanged: (v) => setState(
                                    () => _rememberMe = v ?? true),
                              ),
                              const Text('Ghi nhớ',
                                  style: TextStyle(fontSize: 13)),
                            ],
                          ),
                          TextButton(
                            onPressed: _forgotPassword,
                            style: TextButton.styleFrom(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 4),
                            ),
                            child: const Text('Quên mật khẩu?',
                                style: TextStyle(fontSize: 13)),
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 24),

                    // ── Nút submit ────────────────────────────────────
                    FilledButton(
                      onPressed: _loading ? null : _submit,
                      child: _loading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : Text(_isRegister ? 'Đăng ký' : 'Đăng nhập'),
                    ),

                    const SizedBox(height: 20),

                    // ── Divider ───────────────────────────────────────
                    Row(
                      children: [
                        Expanded(child: Divider(color: cs.outlineVariant)),
                        Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            'hoặc',
                            style: TextStyle(
                                fontSize: 12, color: cs.onSurfaceVariant),
                          ),
                        ),
                        Expanded(child: Divider(color: cs.outlineVariant)),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // ── Social buttons ────────────────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _SocialButton(
                          tooltip: 'Google',
                          onTap: _loading ? null : _signInWithGoogle,
                          child: _GoogleLogo(),
                        ),
                        const SizedBox(width: 16),
                        _SocialButton(
                          tooltip: 'Facebook (chưa cấu hình)',
                          onTap: _signInWithFacebook,
                          child: const Text('f',
                              style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF1877F2))),
                        ),
                        const SizedBox(width: 16),
                        _SocialButton(
                          tooltip: 'Apple (iOS only)',
                          onTap: _signInWithApple,
                          child: Icon(Icons.apple,
                              size: 24, color: cs.onSurface),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // ── Switch login / register ────────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _isRegister
                              ? 'Đã có tài khoản? '
                              : 'Chưa có tài khoản? ',
                          style: TextStyle(
                              fontSize: 13, color: cs.onSurfaceVariant),
                        ),
                        GestureDetector(
                          onTap: () =>
                              setState(() => _isRegister = !_isRegister),
                          child: Text(
                            _isRegister ? 'Đăng nhập' : 'Đăng ký',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: cs.primary,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PRIVATE HELPERS
// ─────────────────────────────────────────────────────────────────────────────

class _SocialButton extends StatelessWidget {
  final String tooltip;
  final VoidCallback? onTap;
  final Widget child;

  const _SocialButton(
      {required this.tooltip, this.onTap, required this.child});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            border:
                Border.all(color: cs.outlineVariant),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Center(child: child),
        ),
      ),
    );
  }
}

class _GoogleLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 22,
      height: 22,
      child: CustomPaint(painter: _GooglePainter()),
    );
  }
}

class _GooglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final c = Offset(w / 2, h / 2);
    final r = w / 2 - 1;
    const sw = 3.5;
    final rect = Rect.fromCircle(center: c, radius: r);

    canvas.drawArc(rect, -0.3, 1.2, false,
        Paint()
          ..color = const Color(0xFF4285F4)
          ..style = PaintingStyle.stroke
          ..strokeWidth = sw);
    canvas.drawLine(c, Offset(w - 1, c.dy),
        Paint()
          ..color = const Color(0xFF4285F4)
          ..strokeWidth = sw
          ..strokeCap = StrokeCap.round);
    canvas.drawArc(rect, 0.9, 1.2, false,
        Paint()
          ..color = const Color(0xFF34A853)
          ..style = PaintingStyle.stroke
          ..strokeWidth = sw);
    canvas.drawArc(rect, 2.1, 1.2, false,
        Paint()
          ..color = const Color(0xFFFBBC05)
          ..style = PaintingStyle.stroke
          ..strokeWidth = sw);
    canvas.drawArc(rect, 3.3, 1.6, false,
        Paint()
          ..color = const Color(0xFFEA4335)
          ..style = PaintingStyle.stroke
          ..strokeWidth = sw);
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}
