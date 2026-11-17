import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../admin/presentation/admin_panel_screen.dart';
import '../../auth/presentation/login_screen.dart';
import '../../auth/providers/auth_provider.dart';
import '../../favorites/presentation/favorites_screen.dart';
import '../../notifications/presentation/notifications_screen.dart';
import 'personal_info_screen.dart';
import '../../search/presentation/search_screen.dart';
import '../../settings/presentation/settings_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final bool isLoggedIn = auth.isAuthenticated;

    final displayName = isLoggedIn ? auth.displayName : 'Khách';
    final email = isLoggedIn ? auth.email : 'Chưa đăng nhập tài khoản';

    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // Header Người dùng với Avatar tròn chuẩn Mockup
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: cs.outlineVariant),
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: cs.primary.withOpacity(0.12),
                  backgroundImage: auth.photoUrl.isNotEmpty
                      ? NetworkImage(auth.photoUrl)
                      : null,
                  child: auth.photoUrl.isEmpty
                      ? Icon(
                          Icons.person_rounded,
                          size: 46,
                          color: cs.primary,
                        )
                      : null,
                ),
                const SizedBox(height: 12),
                Text(
                  displayName,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: TextStyle(
                    fontSize: 13,
                    color: cs.onSurfaceVariant,
                  ),
                ),
                if (!isLoggedIn) ...[
                  const SizedBox(height: 14),
                  SizedBox(
                    width: 140,
                    height: 38,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const LoginScreen(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: cs.primary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: const Text(
                        'Đăng nhập',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Menu List chuẩn Mockup
          Container(
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: cs.outlineVariant),
            ),
            child: Column(
              children: [
                _buildMenuItem(
                  context: context,
                  icon: Icons.person_outline_rounded,
                  title: 'Thông tin cá nhân',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PersonalInfoScreen(),
                      ),
                    );
                  },
                ),
                _buildDivider(),
                _buildMenuItem(
                  context: context,
                  icon: Icons.bookmark_border_rounded,
                  title: 'Tin đã lưu',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const FavoritesScreen(),
                      ),
                    );
                  },
                ),
                _buildDivider(),
                _buildMenuItem(
                  context: context,
                  icon: Icons.history_rounded,
                  title: 'Lịch sử tìm kiếm',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SearchScreen(),
                      ),
                    );
                  },
                ),
                _buildDivider(),
                _buildMenuItem(
                  context: context,
                  icon: Icons.settings_outlined,
                  title: 'Cài đặt',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SettingsScreen(),
                      ),
                    );
                  },
                ),
                _buildDivider(),
                _buildMenuItem(
                  context: context,
                  icon: Icons.notifications_none_rounded,
                  title: 'Thông báo',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const NotificationsScreen(),
                      ),
                    );
                  },
                ),
                _buildDivider(),
                if (auth.isAdmin) ...[
                  _buildMenuItem(
                    context: context,
                    icon: Icons.admin_panel_settings_outlined,
                    title: 'Bảng quản trị viên (Admin Panel)',
                    iconColor: const Color(0xFF0D9488),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AdminPanelScreen(),
                        ),
                      );
                    },
                  ),
                  _buildDivider(),
                ],
                _buildMenuItem(
                  context: context,
                  icon: Icons.help_outline_rounded,
                  title: 'Trợ giúp & hỗ trợ',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Trung tâm hỗ trợ người dùng')),
                    );
                  },
                ),
                _buildDivider(),
                if (isLoggedIn)
                  _buildMenuItem(
                    context: context,
                    icon: Icons.logout_rounded,
                    title: 'Đăng xuất',
                    iconColor: const Color(0xFFEF4444),
                    textColor: const Color(0xFFEF4444),
                    showArrow: false,
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          title: const Text(
                            'Xác nhận đăng xuất',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          content: const Text(
                            'Bạn có chắc chắn muốn đăng xuất khỏi tài khoản không?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text('Hủy'),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFEF4444),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              onPressed: () async {
                                Navigator.pop(ctx);
                                await auth.signOut();
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Đã đăng xuất thành công'),
                                  ),
                                );
                              },
                              child: const Text(
                                'Đăng xuất',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  )
                else
                  _buildMenuItem(
                    context: context,
                    icon: Icons.login_rounded,
                    title: 'Đăng nhập / Đăng ký',
                    iconColor: const Color(0xFF1E60F2),
                    textColor: const Color(0xFF1E60F2),
                    showArrow: true,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const LoginScreen(),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Future<void> _showPersonalInfo(
    BuildContext context,
    AuthProvider auth,
  ) async {
    if (!auth.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Vui lòng đăng nhập để xem thông tin cá nhân.')),
      );
      return;
    }

    final nameController = TextEditingController(text: auth.displayName);
    final formKey = GlobalKey<FormState>();
    var saving = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text(
                'Thông tin cá nhân',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor:
                          Theme.of(context).colorScheme.primaryContainer,
                      child: Icon(
                        Icons.person_rounded,
                        size: 34,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: nameController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Tên hiển thị',
                        prefixIcon: Icon(Icons.badge_outlined),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Vui lòng nhập tên hiển thị';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      initialValue: auth.email,
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Mã tài khoản: ${auth.uid}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: saving ? null : () => Navigator.pop(dialogContext),
                  child: const Text('Hủy'),
                ),
                FilledButton(
                  onPressed: saving
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) return;
                          setState(() => saving = true);
                          final success = await auth.updateDisplayName(
                            nameController.text,
                          );
                          if (!context.mounted) return;
                          if (success) {
                            Navigator.pop(dialogContext);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Đã cập nhật thông tin cá nhân.'),
                              ),
                            );
                          } else {
                            setState(() => saving = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  auth.errorMessage.isNotEmpty
                                      ? auth.errorMessage
                                      : 'Không thể cập nhật thông tin.',
                                ),
                              ),
                            );
                          }
                        },
                  child: saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Lưu thay đổi'),
                ),
              ],
            );
          },
        );
      },
    );
    nameController.dispose();
  }

  Widget _buildMenuItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color iconColor = const Color(0xFF1E60F2),
    Color? textColor,
    bool showArrow = true,
  }) {
    return Material(
      color: Colors.transparent,
      child: ListTile(
        leading: Icon(icon, color: iconColor, size: 22),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.w600,
            color: textColor ?? Theme.of(context).colorScheme.onSurface,
          ),
        ),
        trailing: showArrow
            ? const Icon(Icons.chevron_right_rounded,
                color: Colors.grey, size: 20)
            : null,
        onTap: onTap,
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(height: 1, thickness: 1);
  }
}
