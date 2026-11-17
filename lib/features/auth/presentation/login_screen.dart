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
  bool _agreeTerms = false; // Không tick sẵn: người dùng phải tự đồng ý điều khoản
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
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_isRegister &&
        _passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mật khẩu nhập lại không khớp.'),
          backgroundColor: Colors.red,
        ),
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
      _navigateAfterAuth(_isRegister
          ? 'Đăng ký tài khoản thành công!'
          : 'Đăng nhập thành công!');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage.isNotEmpty
              ? auth.errorMessage
              : 'Thao tác thất bại. Vui lòng thử lại.'),
          backgroundColor: Colors.red,
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
        SnackBar(
          content: Text(auth.errorMessage),
          backgroundColor: Colors.red.shade700,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  void _signInWithFacebook() async {
    setState(() => _loading = true);
    final auth = context.read<AuthProvider>();
    final success = await auth.signInWithFacebook();
    if (!mounted) return;
    setState(() => _loading = false);

    if (success) {
      _navigateAfterAuth('Đăng nhập Facebook thành công!');
    } else if (auth.errorMessage.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage),
          backgroundColor: Colors.red.shade700,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  void _loginQuickAdmin() async {
    setState(() => _loading = true);
    final auth = context.read<AuthProvider>();
    final success = await auth.signInAsAdmin();
    if (!mounted) return;
    setState(() => _loading = false);
    if (success) {
      _navigateAfterAuth('Đăng nhập Quản trị viên (Admin) thành công!');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage.isNotEmpty
              ? auth.errorMessage
              : 'Không thể đăng nhập tài khoản Admin.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _forgotPassword() {
    final resetEmailController =
        TextEditingController(text: _emailController.text.trim());
    final formKey = GlobalKey<FormState>();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Quên mật khẩu',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                  'Nhập địa chỉ email để nhận liên kết đặt lại mật khẩu:',
                  style: TextStyle(fontSize: 14)),
              const SizedBox(height: 14),
              TextFormField(
                controller: resetEmailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email',
                  prefixIcon: const Icon(Icons.email_outlined,
                      color: Color(0xFF1E60F2)),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Vui lòng nhập email';
                  }
                  if (!val.contains('@')) return 'Email không hợp lệ';
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E60F2),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final auth = context.read<AuthProvider>();
              final success =
                  await auth.sendPasswordReset(resetEmailController.text);
              if (!ctx.mounted) return;
              Navigator.pop(ctx);
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(success
                    ? 'Đã gửi email khôi phục! Kiểm tra hộp thư của bạn.'
                    : (auth.errorMessage.isNotEmpty
                        ? auth.errorMessage
                        : 'Không gửi được email.')),
                backgroundColor: success ? Colors.green : Colors.red,
              ));
            },
            child: const Text('Gửi email', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _navigateAfterAuth(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
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
    // Màn Login trước đây ghim cứng nền xanh sáng kể cả khi app ở Dark mode.
    // Nay nền / chữ / nút đổi theo theme chung của app.
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? Colors.white : const Color(0xFF082875);
    final subColor = isDark
        ? Colors.white.withOpacity(0.75)
        : const Color(0xFF082875).withOpacity(0.75);
    final chipBg = isDark ? const Color(0xFF1C2541) : Colors.white;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Container(
        // Gradient nền: xanh trời (Light) / xanh đêm cùng tông AppTheme (Dark)
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? const [
                    Color(0xFF0B132B),
                    Color(0xFF14264C),
                    Color(0xFF1C2541),
                    Color(0xFF0B132B)
                  ]
                : const [
                    Color(0xFF5BB8FA),
                    Color(0xFF90D0FF),
                    Color(0xFFC5E9FF),
                    Color(0xFFEDF6FF)
                  ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: const [0.0, 0.25, 0.55, 1.0],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                physics: const BouncingScrollPhysics(),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 18),

                      // ── Top Bar: Back button & Bỏ qua ──
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (_isRegister)
                            GestureDetector(
                              onTap: () => setState(() => _isRegister = false),
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: chipBg.withOpacity(0.9),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.08),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Icon(Icons.arrow_back_rounded,
                                    color: titleColor, size: 20),
                              ),
                            )
                          else if (Navigator.canPop(context))
                            GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: chipBg.withOpacity(0.9),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.08),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Icon(Icons.arrow_back_rounded,
                                    color: titleColor, size: 20),
                              ),
                            )
                          else
                            const SizedBox(width: 40),

                          GestureDetector(
                            onTap: _skipToHome,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: chipBg.withOpacity(0.9),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.06),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Text(
                                    'Bỏ qua',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF1E60F2),
                                    ),
                                  ),
                                  SizedBox(width: 4),
                                  Icon(Icons.arrow_forward_ios_rounded,
                                      color: Color(0xFF1E60F2), size: 12),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // ── App Icon 3D ──
                      Center(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(22),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    const Color(0xFF1E60F2).withOpacity(0.25),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(22),
                            child: Image.asset(
                              'assets/images/app_icon.jpg',
                              height: _isRegister ? 68 : 84,
                              width: _isRegister ? 68 : 84,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // ── App Title ──
                      Center(
                        child: Text(
                          'Tin tức\n& Thời tiết',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.w900,
                            color: titleColor,
                            height: 1.25,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),

                      // ── Slogan ──
                      Center(
                        child: Text(
                          'Đọc báo • Cập nhật thời tiết • Kết nối thông tin',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: subColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ── Form Title ──
                      if (_isRegister) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.person_add_alt_1_rounded,
                                color: Color(0xFF1E60F2), size: 22),
                            SizedBox(width: 8),
                            Text(
                              'Đăng ký tài khoản',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: titleColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Center(
                          child: Text(
                            'Tham gia ngay để trải nghiệm đầy đủ tính năng',
                            style: TextStyle(
                                fontSize: 12, color: isDark ? Colors.grey.shade400 : Colors.grey.shade700),
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],

                      // ══════════ INPUT FIELDS ══════════
                      if (!_isRegister) ...[
                        // ── LOGIN: 2 fields ──
                        _buildField(
                          controller: _emailController,
                          hint: 'Email hoặc số điện thoại',
                          icon: Icons.person_rounded,
                          keyboard: TextInputType.emailAddress,
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Vui lòng nhập email hoặc SĐT'
                              : null,
                        ),
                        const SizedBox(height: 12),

                        _buildField(
                          controller: _passwordController,
                          hint: 'Mật khẩu',
                          icon: Icons.lock_rounded,
                          obscure: _obscurePassword,
                          suffixIcon: _eyeButton(
                            _obscurePassword,
                            () => setState(
                                () => _obscurePassword = !_obscurePassword),
                          ),
                          validator: (v) => (v == null || v.length < 6)
                              ? 'Mật khẩu tối thiểu 6 ký tự'
                              : null,
                        ),
                        const SizedBox(height: 10),

                        // Remember + Forgot
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: Checkbox(
                                    value: _rememberMe,
                                    activeColor: const Color(0xFF1E60F2),
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(4)),
                                    onChanged: (v) =>
                                        setState(() => _rememberMe = v ?? true),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Ghi nhớ đăng nhập',
                                  style: TextStyle(
                                      fontSize: 12.5,
                                      color: cs.onSurface,
                                      fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                            GestureDetector(
                              onTap: _forgotPassword,
                              child: const Text(
                                'Quên mật khẩu?',
                                style: TextStyle(
                                    fontSize: 12.5,
                                    color: Color(0xFF1E60F2),
                                    fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ] else ...[
                        // ── REGISTER: 5 fields ──
                        _buildField(
                          controller: _nameController,
                          hint: 'Họ và tên đầy đủ',
                          icon: Icons.person_rounded,
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Vui lòng nhập họ tên'
                              : null,
                        ),
                        const SizedBox(height: 11),

                        _buildField(
                          controller: _emailController,
                          hint: 'Email của bạn',
                          icon: Icons.mail_rounded,
                          keyboard: TextInputType.emailAddress,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Vui lòng nhập email';
                            }
                            if (!v.contains('@')) return 'Email không hợp lệ';
                            return null;
                          },
                        ),
                        const SizedBox(height: 11),

                        _buildField(
                          controller: _passwordController,
                          hint: 'Mật khẩu',
                          icon: Icons.lock_rounded,
                          obscure: _obscurePassword,
                          suffixIcon: _eyeButton(
                            _obscurePassword,
                            () => setState(
                                () => _obscurePassword = !_obscurePassword),
                          ),
                          validator: (v) => (v == null || v.length < 6)
                              ? 'Mật khẩu tối thiểu 6 ký tự'
                              : null,
                        ),
                        const SizedBox(height: 11),

                        _buildField(
                          controller: _confirmPasswordController,
                          hint: 'Nhập lại mật khẩu',
                          icon: Icons.lock_rounded,
                          obscure: _obscureConfirmPassword,
                          suffixIcon: _eyeButton(
                            _obscureConfirmPassword,
                            () => setState(() => _obscureConfirmPassword =
                                !_obscureConfirmPassword),
                          ),
                          validator: (v) => (v != _passwordController.text)
                              ? 'Mật khẩu nhập lại không khớp'
                              : null,
                        ),
                        const SizedBox(height: 11),

                        _buildField(
                          controller: _phoneController,
                          hint: 'Số điện thoại (tùy chọn)',
                          icon: Icons.phone_rounded,
                          keyboard: TextInputType.phone,
                        ),
                        const SizedBox(height: 10),

                        // Terms checkbox
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 22,
                              height: 22,
                              child: Checkbox(
                                value: _agreeTerms,
                                activeColor: const Color(0xFF1E60F2),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4)),
                                onChanged: (v) =>
                                    setState(() => _agreeTerms = v ?? true),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text.rich(
                                TextSpan(
                                  text: 'Tôi đồng ý với ',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade700),
                                  children: const [
                                    TextSpan(
                                      text: 'Điều khoản sử dụng',
                                      style: TextStyle(
                                          color: Color(0xFF1E60F2),
                                          fontWeight: FontWeight.w600),
                                    ),
                                    TextSpan(text: ' và '),
                                    TextSpan(
                                      text: 'Chính sách quyền riêng tư',
                                      style: TextStyle(
                                          color: Color(0xFF1E60F2),
                                          fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],

                      const SizedBox(height: 20),

                      // ══════════ SUBMIT BUTTON ══════════
                      GestureDetector(
                        onTap: _loading ? null : _submit,
                        child: Container(
                          height: 50,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF1654F0), Color(0xFF2574FF)],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    const Color(0xFF1E60F2).withOpacity(0.35),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Center(
                            child: _loading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                        color: Colors.white, strokeWidth: 2.2),
                                  )
                                : Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        _isRegister ? 'Đăng ký' : 'Đăng nhập',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const Icon(Icons.arrow_forward_rounded,
                                          color: Colors.white, size: 18),
                                    ],
                                  ),
                          ),
                        ),
                      ),

                      if (!_isRegister) ...[
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: _loading ? null : _loginQuickAdmin,
                          icon: const Icon(Icons.admin_panel_settings_rounded,
                              color: Color(0xFF0D9488), size: 20),
                          label: const Text(
                            '⚡ Đăng nhập nhanh với tài khoản Admin',
                            style: TextStyle(
                              color: Color(0xFF0D9488),
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                                color: Color(0xFF0D9488), width: 1.2),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24)),
                            padding: const EdgeInsets.symmetric(
                                vertical: 12, horizontal: 16),
                            backgroundColor: chipBg.withOpacity(0.85),
                          ),
                        ),
                      ],

                      const SizedBox(height: 18),

                      // ══════════ DIVIDER ══════════
                      Row(
                        children: [
                          Expanded(
                              child: Divider(
                                  color: isDark
                                      ? Colors.white24
                                      : const Color(0xFF082875)
                                          .withOpacity(0.2),
                                  thickness: 1)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              _isRegister
                                  ? 'Hoặc đăng ký bằng'
                                  : 'Hoặc đăng nhập bằng',
                              style: TextStyle(fontSize: 12, color: subColor),
                            ),
                          ),
                          Expanded(
                              child: Divider(
                                  color: isDark
                                      ? Colors.white24
                                      : const Color(0xFF082875)
                                          .withOpacity(0.2),
                                  thickness: 1)),
                        ],
                      ),

                      const SizedBox(height: 14),

                      // ══════════ SOCIAL BUTTONS ══════════
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildSocialBtn(
                            onTap: _loading ? null : _signInWithGoogle,
                            tooltip: 'Google',
                            child: _buildGoogleIcon(),
                          ),
                          const SizedBox(width: 20),
                          _buildSocialBtn(
                            onTap: _signInWithFacebook,
                            tooltip: 'Facebook',
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: const BoxDecoration(
                                  color: Color(0xFF1877F2),
                                  shape: BoxShape.circle),
                              child: const Center(
                                child: Text('f',
                                    style: TextStyle(
                                        fontSize: 21,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.white,
                                        height: 1.15)),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),
                      Text(
                        'Hỗ trợ đăng nhập nhanh bằng Google và Facebook.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 11, color: subColor),
                      ),
                      const SizedBox(height: 16),

                      // ══════════ SWITCH LOGIN / REGISTER ══════════
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _isRegister
                                ? 'Đã có tài khoản? '
                                : 'Chưa có tài khoản? ',
                            style: TextStyle(fontSize: 13, color: subColor),
                          ),
                          GestureDetector(
                            onTap: () =>
                                setState(() => _isRegister = !_isRegister),
                            child: Text(
                              _isRegister ? 'Đăng nhập ngay' : 'Đăng ký ngay',
                              style: const TextStyle(
                                  color: Color(0xFF1E60F2),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13.5),
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
      ),
    );
  }

  // ── Rounded white input field ──────────────────────────────────────
  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
    TextInputType keyboard = TextInputType.text,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E60F2).withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboard,
        style: TextStyle(
            fontSize: 14,
            color: cs.onSurface,
            fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: cs.onSurfaceVariant, fontSize: 13.5),
          prefixIcon: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Icon(icon, color: const Color(0xFF1E60F2), size: 20),
          ),
          prefixIconConstraints:
              const BoxConstraints(minWidth: 46, minHeight: 24),
          suffixIcon: suffixIcon,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        validator: validator,
      ),
    );
  }

  Widget _eyeButton(bool isObscure, VoidCallback onTap) {
    return IconButton(
      icon: Icon(
        isObscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        size: 20,
      ),
      onPressed: onTap,
    );
  }

  // ── Social button (white circle with border) ───────────────────────
  Widget _buildSocialBtn({
    required VoidCallback? onTap,
    required String tooltip,
    required Widget child,
  }) {
    final cs = Theme.of(context).colorScheme;
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: cs.surface,
            shape: BoxShape.circle,
            border: Border.all(color: cs.outlineVariant, width: 1.2),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2)),
            ],
          ),
          child: Center(child: child),
        ),
      ),
    );
  }

  Widget _buildGoogleIcon() {
    return SizedBox(
      width: 24,
      height: 24,
      child: CustomPaint(painter: _GoogleIconPainter()),
    );
  }
}

class _GoogleIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w / 2, h / 2);
    final radius = w / 2;
    final rect = Rect.fromCircle(center: center, radius: radius - 2);
    const sw = 4.0;

    canvas.drawArc(
        rect,
        -0.3,
        1.2,
        false,
        Paint()
          ..color = const Color(0xFF4285F4)
          ..style = PaintingStyle.stroke
          ..strokeWidth = sw);
    canvas.drawLine(
        center,
        Offset(w - 2, center.dy),
        Paint()
          ..color = const Color(0xFF4285F4)
          ..strokeWidth = sw
          ..strokeCap = StrokeCap.round);
    canvas.drawArc(
        rect,
        0.9,
        1.2,
        false,
        Paint()
          ..color = const Color(0xFF34A853)
          ..style = PaintingStyle.stroke
          ..strokeWidth = sw);
    canvas.drawArc(
        rect,
        2.1,
        1.2,
        false,
        Paint()
          ..color = const Color(0xFFFBBC05)
          ..style = PaintingStyle.stroke
          ..strokeWidth = sw);
    canvas.drawArc(
        rect,
        3.3,
        1.6,
        false,
        Paint()
          ..color = const Color(0xFFEA4335)
          ..style = PaintingStyle.stroke
          ..strokeWidth = sw);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
