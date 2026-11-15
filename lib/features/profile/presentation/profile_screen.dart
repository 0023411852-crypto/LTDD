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
    final isLoggedIn = auth.isAuthenticated;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Tài khoản')),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // ── Avatar & info ─────────────────────────────────────────
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: cs.primaryContainer,
                    child: Text(
                      isLoggedIn
                          ? (auth.displayName.isNotEmpty
                              ? auth.displayName[0].toUpperCase()
                              : '?')
                          : '?',
                      style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: cs.primary),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isLoggedIn ? auth.displayName : 'Khách',
                          style: tt.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isLoggedIn ? auth.email : 'Chưa đăng nhập',
                          style: TextStyle(
                              fontSize: 13, color: cs.onSurfaceVariant),
                        ),
                        if (!isLoggedIn) ...[
                          const SizedBox(height: 10),
                          FilledButton.tonal(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const LoginScreen()),
                            ),
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text(
                              'Đăng nhập',
                              style: TextStyle(fontSize: 13),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // ── Menu ──────────────────────────────────────────────────
          _MenuSection(
            children: [
              _MenuItem(
                icon: Icons.bookmark_outline_rounded,
                label: 'Bài đã lưu',
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const FavoritesScreen())),
              ),
              _MenuItem(
                icon: Icons.search_rounded,
                label: 'Lịch sử tìm kiếm',
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const SearchScreen())),
              ),
              _MenuItem(
                icon: Icons.notifications_outlined,
                label: 'Thông báo',
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const NotificationsScreen())),
              ),
              _MenuItem(
                icon: Icons.settings_outlined,
                label: 'Cài đặt',
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const SettingsScreen())),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (auth.isAdmin) ...[
            _MenuSection(
              children: [
                _MenuItem(
                  icon: Icons.admin_panel_settings_outlined,
                  label: 'Bảng quản trị (Admin)',
                  iconColor: const Color(0xFF0D9488),
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const AdminPanelScreen())),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],

          _MenuSection(
            children: [
              _MenuItem(
                icon: Icons.help_outline_rounded,
                label: 'Trợ giúp & hỗ trợ',
                onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Trung tâm hỗ trợ người dùng')),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Logout / Login ─────────────────────────────────────────
          if (isLoggedIn)
            _MenuSection(
              children: [
                _MenuItem(
                  icon: Icons.logout_rounded,
                  label: 'Đăng xuất',
                  iconColor: cs.error,
                  textColor: cs.error,
                  trailing: const SizedBox.shrink(),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Đăng xuất'),
                        content: const Text(
                            'Bạn có chắc muốn đăng xuất khỏi tài khoản?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Hủy'),
                          ),
                          FilledButton(
                            onPressed: () async {
                              Navigator.pop(ctx);
                              await auth.signOut();
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Đã đăng xuất')),
                              );
                            },
                            child: const Text('Đăng xuất'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            )
          else
            _MenuSection(
              children: [
                _MenuItem(
                  icon: Icons.login_rounded,
                  label: 'Đăng nhập / Đăng ký',
                  iconColor: cs.primary,
                  textColor: cs.primary,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
class _MenuSection extends StatelessWidget {
  final List<Widget> children;
  const _MenuSection({required this.children});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        children: [
          for (int i = 0; i < children.length; i++) ...[
            children[i],
            if (i < children.length - 1)
              Divider(height: 1, indent: 48, color: cs.outlineVariant),
          ],
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? iconColor;
  final Color? textColor;
  final Widget? trailing;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconColor,
    this.textColor,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListTile(
      leading: Icon(icon,
          size: 20, color: iconColor ?? cs.onSurfaceVariant),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: textColor ?? cs.onSurface,
        ),
      ),
      trailing: trailing ??
          Icon(Icons.chevron_right_rounded,
              size: 18, color: cs.outlineVariant),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      visualDensity: VisualDensity.compact,
    );
  }
}


