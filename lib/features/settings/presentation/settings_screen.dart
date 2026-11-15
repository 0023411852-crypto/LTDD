import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _breakingNewsNotification = true;
  bool _weatherForecastNotification = true;
  bool _promotionNotification = false;

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.themeMode == ThemeMode.dark;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Cài đặt',
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
          // Section 1: Tài khoản
          _buildSectionHeader('Tài khoản'),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                _buildActionItem(
                  icon: Icons.shield_outlined,
                  title: 'Bảo mật tài khoản',
                  trailing: const Icon(Icons.chevron_right_rounded,
                      color: Colors.grey),
                  onTap: () {},
                ),
                _buildDivider(),
                _buildActionItem(
                  icon: Icons.language_rounded,
                  title: 'Ngôn ngữ',
                  trailing: const Text(
                    'Tiếng Việt >',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF1E60F2),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onTap: () {},
                ),
                _buildDivider(),
                _buildActionItem(
                  icon: Icons.palette_outlined,
                  title: 'Giao diện',
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isDark ? 'Tối' : 'Sáng',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF1E60F2),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Switch(
                        value: isDark,
                        activeColor: const Color(0xFF1E60F2),
                        onChanged: (val) {
                          themeProvider.setThemeMode(
                              val ? ThemeMode.dark : ThemeMode.light);
                        },
                      ),
                    ],
                  ),
                  onTap: () {},
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Section 2: Thông báo
          _buildSectionHeader('Thông báo'),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                _buildSwitchItem(
                  icon: Icons.notifications_active_outlined,
                  title: 'Tin tức nổi bật',
                  value: _breakingNewsNotification,
                  onChanged: (val) =>
                      setState(() => _breakingNewsNotification = val),
                ),
                _buildDivider(),
                _buildSwitchItem(
                  icon: Icons.wb_sunny_outlined,
                  title: 'Dự báo thời tiết',
                  value: _weatherForecastNotification,
                  onChanged: (val) =>
                      setState(() => _weatherForecastNotification = val),
                ),
                _buildDivider(),
                _buildSwitchItem(
                  icon: Icons.card_giftcard_rounded,
                  title: 'Khuyến mại',
                  value: _promotionNotification,
                  onChanged: (val) =>
                      setState(() => _promotionNotification = val),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Section 3: Về ứng dụng
          _buildSectionHeader('Về ứng dụng'),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                _buildActionItem(
                  icon: Icons.info_outline_rounded,
                  title: 'Giới thiệu ứng dụng',
                  trailing: const Icon(Icons.chevron_right_rounded,
                      color: Colors.grey),
                  onTap: () {},
                ),
                _buildDivider(),
                _buildActionItem(
                  icon: Icons.lock_outline_rounded,
                  title: 'Chính sách bảo mật',
                  trailing: const Icon(Icons.chevron_right_rounded,
                      color: Colors.grey),
                  onTap: () {},
                ),
                _buildDivider(),
                _buildActionItem(
                  icon: Icons.description_outlined,
                  title: 'Điều khoản sử dụng',
                  trailing: const Icon(Icons.chevron_right_rounded,
                      color: Colors.grey),
                  onTap: () {},
                ),
                _buildDivider(),
                _buildActionItem(
                  icon: Icons.app_settings_alt_outlined,
                  title: 'Phiên bản',
                  trailing: const Text(
                    '1.0.0',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onTap: () {},
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w800,
          color: Color(0xFF0F172A),
        ),
      ),
    );
  }

  Widget _buildActionItem({
    required IconData icon,
    required String title,
    required Widget trailing,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF1E60F2), size: 22),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Color(0xFF334155),
        ),
      ),
      trailing: trailing,
      onTap: onTap,
    );
  }

  Widget _buildSwitchItem({
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF1E60F2), size: 22),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Color(0xFF334155),
        ),
      ),
      trailing: Switch(
        value: value,
        activeColor: const Color(0xFF1E60F2),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9));
  }
}
