import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _breakingNewsNotif = true;
  bool _weatherNotif = true;
  bool _weatherAlertNotif = true;
  bool _promoNotif = false;
  bool _autoDownloadImages = true;
  String _fontSize = 'Tiêu chuẩn';

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final currentMode = themeProvider.themeMode;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Màu sắc hài hòa theo chế độ Sáng / Tối
    final bgColor = isDark ? const Color(0xFF0B132B) : const Color(0xFFF8FAFC);
    final cardColor = isDark ? const Color(0xFF1C2541) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final textColor = isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
    final subTextColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final primaryColor = isDark ? const Color(0xFF3B82F6) : const Color(0xFF1E60F2);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: cardColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Cài đặt',
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w800,
            fontSize: 20,
            letterSpacing: -0.3,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        children: [
          // ══════════════════════════════════════════════════════════
          // 1. CHỌN CHẾ ĐỘ GIAO DIỆN (SÁNG / TỐI / HỆ THỐNG)
          // ══════════════════════════════════════════════════════════
          _buildSectionHeader('GIAO DIỆN & HIỂN THỊ', subTextColor),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: borderColor),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.2 : 0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Chế độ hiển thị màn hình',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Chọn giao diện phù hợp giúp bảo vệ mắt và tiết kiệm pin.',
                  style: TextStyle(fontSize: 12.5, color: subTextColor),
                ),
                const SizedBox(height: 14),

                // 3 Thẻ trực quan: Sáng, Tối, Hệ thống
                Row(
                  children: [
                    Expanded(
                      child: _buildThemeCard(
                        title: 'Sáng',
                        icon: Icons.wb_sunny_rounded,
                        iconColor: const Color(0xFFF59E0B),
                        isSelected: currentMode == ThemeMode.light,
                        onTap: () => themeProvider.setThemeMode(ThemeMode.light),
                        isDarkTheme: isDark,
                        primaryColor: primaryColor,
                        cardColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildThemeCard(
                        title: 'Tối',
                        icon: Icons.nightlight_round,
                        iconColor: const Color(0xFF818CF8),
                        isSelected: currentMode == ThemeMode.dark,
                        onTap: () => themeProvider.setThemeMode(ThemeMode.dark),
                        isDarkTheme: isDark,
                        primaryColor: primaryColor,
                        cardColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildThemeCard(
                        title: 'Hệ thống',
                        icon: Icons.settings_system_daydream_rounded,
                        iconColor: const Color(0xFF10B981),
                        isSelected: currentMode == ThemeMode.system,
                        onTap: () => themeProvider.setThemeMode(ThemeMode.system),
                        isDarkTheme: isDark,
                        primaryColor: primaryColor,
                        cardColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Divider(color: borderColor),

                // Cỡ chữ đọc báo
                _buildActionRow(
                  icon: Icons.format_size_rounded,
                  iconBg: const Color(0xFF8B5CF6).withOpacity(0.14),
                  iconColor: const Color(0xFF8B5CF6),
                  title: 'Cỡ chữ đọc báo',
                  subtitle: _fontSize,
                  textColor: textColor,
                  subTextColor: subTextColor,
                  onTap: () => _showFontSizeDialog(context, isDark, cardColor, textColor, primaryColor),
                ),
                Divider(color: borderColor),

                // Ngôn ngữ
                _buildActionRow(
                  icon: Icons.language_rounded,
                  iconBg: const Color(0xFF0284C7).withOpacity(0.14),
                  iconColor: const Color(0xFF0284C7),
                  title: 'Ngôn ngữ ứng dụng',
                  subtitle: 'Tiếng Việt (Mặc định)',
                  textColor: textColor,
                  subTextColor: subTextColor,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Ứng dụng hiện hỗ trợ ngôn ngữ Tiếng Việt.')),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),

          // ══════════════════════════════════════════════════════════
          // 2. THÔNG BÁO & TIN TỨC
          // ══════════════════════════════════════════════════════════
          _buildSectionHeader('THÔNG BÁO & CẢNH BÁO', subTextColor),
          Container(
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: borderColor),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.2 : 0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildSwitchRow(
                  icon: Icons.newspaper_rounded,
                  iconBg: const Color(0xFFEF4444).withOpacity(0.14),
                  iconColor: const Color(0xFFEF4444),
                  title: 'Tin tức nóng & khẩn cấp',
                  subtitle: 'Nhận thông báo khi có sự kiện xã hội quan trọng',
                  value: _breakingNewsNotif,
                  textColor: textColor,
                  subTextColor: subTextColor,
                  onChanged: (val) => setState(() => _breakingNewsNotif = val),
                ),
                Divider(color: borderColor),
                _buildSwitchRow(
                  icon: Icons.wb_sunny_rounded,
                  iconBg: const Color(0xFFF59E0B).withOpacity(0.14),
                  iconColor: const Color(0xFFF59E0B),
                  title: 'Dự báo thời tiết mỗi sáng',
                  subtitle: 'Gửi bản tin dự báo thời tiết lúc 07:00 hàng ngày',
                  value: _weatherNotif,
                  textColor: textColor,
                  subTextColor: subTextColor,
                  onChanged: (val) => setState(() => _weatherNotif = val),
                ),
                Divider(color: borderColor),
                _buildSwitchRow(
                  icon: Icons.warning_amber_rounded,
                  iconBg: const Color(0xFF0D9488).withOpacity(0.14),
                  iconColor: const Color(0xFF0D9488),
                  title: 'Cảnh báo thời tiết nguy hiểm',
                  subtitle: 'Cảnh báo dông lốc, mưa to ngập lụt hoặc chỉ số UV cao',
                  value: _weatherAlertNotif,
                  textColor: textColor,
                  subTextColor: subTextColor,
                  onChanged: (val) => setState(() => _weatherAlertNotif = val),
                ),
                Divider(color: borderColor),
                _buildSwitchRow(
                  icon: Icons.card_giftcard_rounded,
                  iconBg: const Color(0xFF6366F1).withOpacity(0.14),
                  iconColor: const Color(0xFF6366F1),
                  title: 'Tin tức tiện ích & Khuyến mại',
                  subtitle: 'Các chương trình và thông tin ưu đãi tiện ích',
                  value: _promoNotif,
                  textColor: textColor,
                  subTextColor: subTextColor,
                  onChanged: (val) => setState(() => _promoNotif = val),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),

          // ══════════════════════════════════════════════════════════
          // 3. DỮ LIỆU & BỘ NHỚ
          // ══════════════════════════════════════════════════════════
          _buildSectionHeader('DỮ LIỆU & BỘ NHỚ TẠM', subTextColor),
          Container(
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: borderColor),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.2 : 0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildSwitchRow(
                  icon: Icons.photo_size_select_actual_outlined,
                  iconBg: const Color(0xFF3B82F6).withOpacity(0.14),
                  iconColor: const Color(0xFF3B82F6),
                  title: 'Tự động tải ảnh tin tức',
                  subtitle: 'Tải trước hình ảnh bài báo để đọc nhanh hơn',
                  value: _autoDownloadImages,
                  textColor: textColor,
                  subTextColor: subTextColor,
                  onChanged: (val) => setState(() => _autoDownloadImages = val),
                ),
                Divider(color: borderColor),
                _buildActionRow(
                  icon: Icons.cleaning_services_rounded,
                  iconBg: const Color(0xFF10B981).withOpacity(0.14),
                  iconColor: const Color(0xFF10B981),
                  title: 'Xóa bộ nhớ đệm (Cache)',
                  subtitle: 'Giải phóng khoảng 14.8 MB bộ nhớ máy',
                  textColor: textColor,
                  subTextColor: subTextColor,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Đã dọn dẹp bộ nhớ đệm cache thành công!'),
                        backgroundColor: Color(0xFF10B981),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),

          // ══════════════════════════════════════════════════════════
          // 4. VỀ ỨNG DỤNG & ĐIỀU KHOẢN
          // ══════════════════════════════════════════════════════════
          _buildSectionHeader('THÔNG TIN ỨNG DỤNG', subTextColor),
          Container(
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: borderColor),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.2 : 0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildActionRow(
                  icon: Icons.info_outline_rounded,
                  iconBg: const Color(0xFF1E60F2).withOpacity(0.14),
                  iconColor: const Color(0xFF1E60F2),
                  title: 'Phiên bản ứng dụng',
                  subtitle: 'Daily News & Weather Portal v1.0.0',
                  textColor: textColor,
                  subTextColor: subTextColor,
                  onTap: () {},
                ),
                Divider(color: borderColor),
                _buildActionRow(
                  icon: Icons.privacy_tip_outlined,
                  iconBg: const Color(0xFF14B8A6).withOpacity(0.14),
                  iconColor: const Color(0xFF14B8A6),
                  title: 'Chính sách bảo mật',
                  subtitle: 'Cách chúng tôi bảo vệ thông tin của bạn',
                  textColor: textColor,
                  subTextColor: subTextColor,
                  onTap: () => _showPolicyDialog(context, 'Chính sách bảo mật', isDark, cardColor, textColor),
                ),
                Divider(color: borderColor),
                _buildActionRow(
                  icon: Icons.description_outlined,
                  iconBg: const Color(0xFF64748B).withOpacity(0.14),
                  iconColor: const Color(0xFF64748B),
                  title: 'Điều khoản sử dụng',
                  subtitle: 'Quy định và quyền lợi người dùng',
                  textColor: textColor,
                  subTextColor: subTextColor,
                  onTap: () => _showPolicyDialog(context, 'Điều khoản sử dụng', isDark, cardColor, textColor),
                ),
                Divider(color: borderColor),
                _buildActionRow(
                  icon: Icons.star_rate_rounded,
                  iconBg: const Color(0xFFF59E0B).withOpacity(0.14),
                  iconColor: const Color(0xFFF59E0B),
                  title: 'Đánh giá ứng dụng 5 sao',
                  subtitle: 'Ủng hộ nhà phát triển trên Google Play',
                  textColor: textColor,
                  subTextColor: subTextColor,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Cảm ơn bạn đã yêu thích và đánh giá ứng dụng! ❤️')),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // ── TIÊU ĐỀ SECTION ────────────────────────────────────────────────────────
  Widget _buildSectionHeader(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(left: 6, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: color,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  // ── THẺ CHỌN CHẾ ĐỘ GIAO DIỆN SÁNG / TỐI ────────────────────────────────────
  Widget _buildThemeCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDarkTheme,
    required Color primaryColor,
    required Color cardColor,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? primaryColor.withOpacity(isDarkTheme ? 0.22 : 0.1)
              : cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? primaryColor : (isDarkTheme ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: iconColor, size: 28),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected
                    ? primaryColor
                    : (isDarkTheme ? const Color(0xFFF8FAFC) : const Color(0xFF334155)),
              ),
            ),
            const SizedBox(height: 4),
            Icon(
              isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
              size: 16,
              color: isSelected ? primaryColor : Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }

  // ── HÀNG SWITCH BẬT / TẮT ──────────────────────────────────────────────────
  Widget _buildSwitchRow({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required Color textColor,
    required Color subTextColor,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12, color: subTextColor),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  // ── HÀNG HÀNH ĐỘNG CÓ MŨI TÊN HOẶC TEXT ────────────────────────────────────
  Widget _buildActionRow({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    required Color textColor,
    required Color subTextColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: subTextColor),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: subTextColor, size: 20),
          ],
        ),
      ),
    );
  }

  // ── DIALOG CHỌN CỠ CHỮ ─────────────────────────────────────────────────────
  void _showFontSizeDialog(
      BuildContext context, bool isDark, Color cardColor, Color textColor, Color primaryColor) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Chọn cỡ chữ đọc bài', style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ['Nhỏ', 'Tiêu chuẩn', 'Lớn'].map((size) {
            final isSelected = _fontSize == size;
            return ListTile(
              title: Text(size,
                  style: TextStyle(
                    color: isSelected ? primaryColor : textColor,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  )),
              trailing: isSelected ? Icon(Icons.check_rounded, color: primaryColor) : null,
              onTap: () {
                setState(() => _fontSize = size);
                Navigator.pop(ctx);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  // ── DIALOG HIỂN THỊ CHÍNH SÁCH ─────────────────────────────────────────────
  void _showPolicyDialog(
      BuildContext context, String title, bool isDark, Color cardColor, Color textColor) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
        content: Text(
          'Ứng dụng Daily News & Weather Portal cam kết bảo mật tối đa dữ liệu của người dùng, tôn trọng quyền riêng tư và chỉ lưu trữ các thông tin thiết yếu phục vụ cho việc cá nhân hóa trải nghiệm đọc tin và dự báo thời tiết.',
          style: TextStyle(fontSize: 14, color: textColor.withOpacity(0.85), height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Đã hiểu'),
          ),
        ],
      ),
    );
  }
}
