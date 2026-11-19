import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/widgets/app_confirmation_dialog.dart';
import '../../auth/presentation/login_screen.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/profile_provider.dart';

/// Màn hình Chỉnh sửa & Quản lý Thông tin cá nhân (Personal Info Screen)
/// Cho phép người dùng chỉnh sửa Tên hiển thị, Số điện thoại, Giới thiệu (Bio),
/// và lựa chọn Avatar đại diện yêu thích. Lưu bền vững vào hệ thống & SharedPreferences.
class PersonalInfoScreen extends StatefulWidget {
  const PersonalInfoScreen({super.key});

  @override
  State<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends State<PersonalInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _bioController;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    _nameController = TextEditingController(text: auth.displayName);
    _phoneController = TextEditingController(text: auth.phoneNumber);
    _bioController = TextEditingController(text: auth.bio);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ProfileProvider>().initAvatar(auth.photoUrl);
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final profile = context.read<ProfileProvider>();
    final success = await profile.saveProfile(
      authProvider: auth,
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      bio: _bioController.text.trim(),
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              success ? Icons.check_circle_rounded : Icons.error_rounded,
              color: Colors.white,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                success
                    ? 'Đã cập nhật thông tin cá nhân thành công!'
                    : ((profile.errorMessage != null &&
                            profile.errorMessage!.isNotEmpty)
                        ? profile.errorMessage!
                        : (auth.errorMessage.isNotEmpty
                            ? auth.errorMessage
                            : 'Không thể cập nhật thông tin.')),
              ),
            ),
          ],
        ),
        backgroundColor: success ? const Color(0xFF16A34A) : Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );

    if (success) {
      Navigator.pop(context);
    }
  }

  Future<void> _confirmDeleteAccount(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    if (auth.isAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Tài khoản quản trị viên hệ sinh thái không thể bị xóa.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final confirmed = await showAppConfirmationDialog(
      context: context,
      type: AppConfirmationType.danger,
      icon: Icons.delete_forever_rounded,
      title: 'Xóa tài khoản vĩnh viễn?',
      description:
          'Hành động này là vĩnh viễn và không thể khôi phục. Toàn bộ thông tin cá nhân và dữ liệu liên kết của bạn sẽ bị xóa hoàn toàn khỏi hệ thống.',
      confirmText: 'Xác nhận',
      cancelText: 'Huỷ',
      extraContent: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFEF4444).withOpacity(0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.18)),
        ),
        child: Column(
          children: [
            _buildDeleteBullet(
                'Toàn bộ Tên, Số điện thoại và Avatar sẽ bị xóa sạch.', isDark),
            const SizedBox(height: 7),
            _buildDeleteBullet(
                'Hủy liên kết bài viết yêu thích và lịch sử đọc tin tức.',
                isDark),
            const SizedBox(height: 7),
            _buildDeleteBullet(
                'Toàn bộ phiên hoạt động và lịch sử sẽ được thu hồi an toàn.',
                isDark),
          ],
        ),
      ),
    );

    if (confirmed == true && context.mounted) {
      final success = await auth.deleteAccount();
      if (!context.mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                      'Tài khoản và toàn bộ dữ liệu của bạn đã được xóa thành công.'),
                ),
              ],
            ),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        Navigator.of(context).popUntil((route) => route.isFirst);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(auth.errorMessage.isNotEmpty
                ? auth.errorMessage
                : 'Không thể xóa tài khoản. Vui lòng thử lại.'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Widget _buildDeleteBullet(String text, bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 2),
          child: Icon(Icons.remove_circle_outline_rounded,
              size: 14, color: Color(0xFFEF4444)),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12.5,
              height: 1.4,
              color: isDark ? Colors.white70 : const Color(0xFF334155),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final profile = context.watch<ProfileProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;

    final bgColor = isDark ? const Color(0xFF090D1A) : const Color(0xFFF1F5F9);
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor =
        isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
    final subTextColor =
        isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final borderColor =
        isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    if (!auth.isAuthenticated) {
      return Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_rounded, color: textColor),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Thông tin cá nhân',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: textColor,
            ),
          ),
          centerTitle: true,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.account_circle_outlined,
                    size: 58,
                    color: Color(0xFF2563EB),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Chưa có thông tin cá nhân',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Bạn đang sử dụng ứng dụng dưới tư cách Khách. Khách chưa có thông tin nào để xem hay chỉnh sửa, vui lòng đăng nhập để tạo và quản lý hồ sơ cá nhân của bạn.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13.5,
                    color: subTextColor,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Đăng nhập ngay',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: textColor),
          tooltip: 'Quay lại',
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Thông tin cá nhân',
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w800,
            color: textColor,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // 1. HEADER AVATAR CHÍNH & HUY HIỆU VAI TRÒ
              Center(
                child: Column(
                  children: [
                    Stack(
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [Color(0xFF2563EB), Color(0xFF38BDF8)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    const Color(0xFF2563EB).withOpacity(0.35),
                                blurRadius: 18,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(3),
                          child: ClipOval(
                            child: profile.selectedAvatar.isNotEmpty
                                ? CachedNetworkImage(
                                    imageUrl: profile.selectedAvatar,
                                    memCacheWidth: 300,
                                    fit: BoxFit.cover,
                                    errorWidget: (_, __, ___) =>
                                        _buildFallbackAvatar(cs),
                                  )
                                : _buildFallbackAvatar(cs),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(7),
                            decoration: const BoxDecoration(
                              color: Color(0xFF2563EB),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.camera_alt_rounded,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      auth.displayName,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: textColor,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      auth.email.isNotEmpty
                          ? auth.email
                          : 'Chưa liên kết email',
                      style: TextStyle(
                        fontSize: 13,
                        color: subTextColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: auth.isAdmin
                            ? const Color(0xFFDC2626).withOpacity(0.12)
                            : const Color(0xFF2563EB).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        auth.isAdmin ? '👑 QUẢN TRỊ VIÊN' : '⭐ THÀNH VIÊN',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: auth.isAdmin
                              ? const Color(0xFFDC2626)
                              : const Color(0xFF2563EB),
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 2. CHỌN AVATAR NHANH (AVATAR PRESETS)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: borderColor),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Chọn ảnh đại diện mẫu',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 54,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: profile.avatarPresets.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 12),
                        itemBuilder: (context, index) {
                          final url = profile.avatarPresets[index];
                          final isSelected = profile.selectedAvatar == url;

                          return GestureDetector(
                            onTap: () {
                              context.read<ProfileProvider>().selectAvatar(url);
                            },
                            child: Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFF2563EB)
                                      : Colors.transparent,
                                  width: 2.5,
                                ),
                              ),
                              padding: const EdgeInsets.all(2),
                              child: ClipOval(
                                child: CachedNetworkImage(
                                  imageUrl: url,
                                  memCacheWidth: 160,
                                  fit: BoxFit.cover,
                                  errorWidget: (_, __, ___) =>
                                      const Icon(Icons.person),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // 3. FORM NHẬP THÔNG TIN CÁ NHÂN
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: borderColor),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Chỉnh sửa thông tin',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Tên hiển thị
                    _buildTextField(
                      controller: _nameController,
                      label: 'Tên hiển thị',
                      icon: Icons.person_outline_rounded,
                      textColor: textColor,
                      subTextColor: subTextColor,
                      borderColor: borderColor,
                      validator: (val) => val == null || val.trim().isEmpty
                          ? 'Vui lòng nhập họ và tên'
                          : null,
                    ),
                    const SizedBox(height: 14),

                    // Số điện thoại
                    _buildTextField(
                      controller: _phoneController,
                      label: 'Số điện thoại',
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      textColor: textColor,
                      subTextColor: subTextColor,
                      borderColor: borderColor,
                    ),
                    const SizedBox(height: 14),

                    // Giới thiệu ngắn
                    _buildTextField(
                      controller: _bioController,
                      label: 'Giới thiệu bản thân (Bio)',
                      icon: Icons.edit_note_rounded,
                      maxLines: 2,
                      textColor: textColor,
                      subTextColor: subTextColor,
                      borderColor: borderColor,
                    ),
                    const SizedBox(height: 14),

                    // Email (Chỉ đọc)
                    TextFormField(
                      initialValue: auth.email.isNotEmpty
                          ? auth.email
                          : 'Chưa liên kết email',
                      enabled: false,
                      style: TextStyle(color: subTextColor),
                      decoration: InputDecoration(
                        labelText: 'Email tài khoản',
                        labelStyle:
                            TextStyle(color: subTextColor, fontSize: 13),
                        prefixIcon: Icon(
                          auth.email.isNotEmpty
                              ? Icons.email_outlined
                              : Icons.account_circle_outlined,
                          color: subTextColor,
                        ),
                        suffixIcon: Icon(Icons.lock_outline_rounded,
                            size: 18, color: subTextColor),
                        filled: true,
                        fillColor: isDark
                            ? Colors.black.withOpacity(0.2)
                            : Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: borderColor),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: borderColor),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 4. NÚT LƯU THAY ĐỔI (SAVE BUTTON)
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: profile.isSaving ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    elevation: 4,
                    shadowColor: const Color(0xFF2563EB).withOpacity(0.4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: profile.isSaving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.save_rounded, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Lưu thay đổi',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 24),

              // 5. VÙNG XÓA TÀI KHOẢN (ACCOUNT DELETION - GOOGLE PLAY REQUIREMENT)
              if (!auth.isAdmin) ...[
                Divider(color: borderColor),
                const SizedBox(height: 12),
                Center(
                  child: TextButton.icon(
                    onPressed: () => _confirmDeleteAccount(context),
                    icon: const Icon(Icons.delete_outline_rounded,
                        color: Colors.redAccent, size: 20),
                    label: const Text(
                      'Xóa tài khoản & Dữ liệu người dùng',
                      style: TextStyle(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFallbackAvatar(ColorScheme cs) {
    return Container(
      color: Colors.white,
      child: const Center(
        child: Icon(Icons.person_rounded, size: 54, color: Color(0xFF2563EB)),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required Color textColor,
    required Color subTextColor,
    required Color borderColor,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: TextStyle(
          color: textColor, fontWeight: FontWeight.w600, fontSize: 14.5),
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: subTextColor, fontSize: 13.5),
        prefixIcon: Icon(icon, color: const Color(0xFF2563EB)),
        filled: true,
        fillColor: Colors.transparent,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.8),
        ),
      ),
    );
  }
}
