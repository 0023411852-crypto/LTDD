import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../admin/presentation/admin_panel_screen.dart';
import '../../auth/presentation/login_screen.dart';
import '../../auth/providers/auth_provider.dart';
import '../../favorites/presentation/favorites_screen.dart';
import '../../notifications/presentation/notifications_screen.dart';
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

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Hồ sơ cá nhân',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // Header Người dùng với Avatar tròn
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: const Color(0xFF1E60F2).withOpacity(0.15),
                  child: const Icon(
                    Icons.person_rounded,
                    size: 48,
                    color: Color(0xFF1E60F2),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  displayName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
                if (!isLoggedIn) ...[
                  const SizedBox(height: 14),
                  SizedBox(
                    width: 140,
                    height: 36,
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
                        backgroundColor: const Color(0xFF1E60F2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: const Text('Đăng nhập',
                          style: TextStyle(color: Colors.white, fontSize: 13)),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Menu List chuẩn Mockup Screen #10
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                _buildMenuItem(
                  icon: Icons.person_outline_rounded,
                  title: 'Thông tin cá nhân',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Tính năng chỉnh sửa hồ sơ')),
                    );
                  },
                ),
                _buildDivider(),
                _buildMenuItem(
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
                // Lối tắt truy cập Admin Panel
                _buildMenuItem(
                  icon: Icons.admin_panel_settings_outlined,
                  title: 'Bảng quản trị viên (Admin Panel)',
                  iconColor: const Color(0xFF059669),
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
                _buildMenuItem(
                  icon: Icons.help_outline_rounded,
                  title: 'Trợ giúp & hỗ trợ',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Trung tâm hỗ trợ người dùng')),
                    );
                  },
                ),
                _buildDivider(),
                if (isLoggedIn)
                  _buildMenuItem(
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
                                    backgroundColor: Colors.orange,
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

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color iconColor = const Color(0xFF1E60F2),
    Color textColor = const Color(0xFF0F172A),
    bool showArrow = true,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor, size: 22),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14.5,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
      trailing: showArrow
          ? const Icon(Icons.chevron_right_rounded,
              color: Colors.grey, size: 20)
          : null,
      onTap: onTap,
    );
  }

  Widget _buildDivider() {
    return const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9));
  }
}
