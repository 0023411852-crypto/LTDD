import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/widgets/app_confirmation_dialog.dart';
import '../../../services/notification_permission_service.dart';
import '../providers/settings_provider.dart';
import '../providers/theme_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final settings = context.watch<SettingsProvider>();
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
          _buildSectionHeader(
            'GIAO DIỆN & HIỂN THỊ',
            subTextColor,
          ),
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
                  subtitle: '${settings.fontSize} (${(settings.fontScale * 100).round()}%)',
                  textColor: textColor,
                  subTextColor: subTextColor,
                  onTap: () => _showFontSizeDialog(
                    context,
                    settings,
                    cardColor,
                    textColor,
                    primaryColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),

          // ══════════════════════════════════════════════════════════
          // 2. THÔNG BÁO & TIN TỨC
          // ══════════════════════════════════════════════════════════
          _buildSectionHeader(
            'THÔNG BÁO & CẢNH BÁO',
            subTextColor,
          ),
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
                  icon: Icons.app_settings_alt_rounded,
                  iconBg: const Color(0xFF10B981).withOpacity(0.14),
                  iconColor: const Color(0xFF10B981),
                  title: 'Quyền thông báo hệ thống',
                  subtitle: 'Kiểm tra & quản lý quyền trên thiết bị',
                  textColor: textColor,
                  subTextColor: subTextColor,
                  onTap: () async {
                    final granted = await NotificationPermissionService.isGranted();
                    if (!context.mounted) return;
                    if (granted) {
                      _showToast(
                        context,
                        '✓ Ứng dụng đã được cấp quyền thông báo hệ thống',
                      );
                    } else {
                      final ok = await NotificationPermissionService.requestAndCheck(context);
                      if (!context.mounted) return;
                      if (ok) {
                        _showToast(
                          context,
                          'Đã cấp quyền thông báo thành công!',
                        );
                      }
                    }
                  },
                ),
                Divider(color: borderColor),
                _buildSwitchRow(
                  icon: Icons.newspaper_rounded,
                  iconBg: const Color(0xFFEF4444).withOpacity(0.14),
                  iconColor: const Color(0xFFEF4444),
                  title: 'Tin tức nóng & khẩn cấp',
                  subtitle: 'Nhận thông báo khi có sự kiện xã hội quan trọng',
                  value: settings.breakingNewsNotif,
                  textColor: textColor,
                  subTextColor: subTextColor,
                  onChanged: (val) async {
                    if (val) {
                      final ok = await NotificationPermissionService.requestAndCheck(context);
                      if (!ok) return;
                    }
                    settings.setBreakingNewsNotif(val);
                    if (context.mounted) {
                      _showToast(
                        context,
                        val ? 'Đã bật thông báo tin nóng' : 'Đã tắt thông báo tin nóng',
                      );
                    }
                  },
                ),
                Divider(color: borderColor),
                _buildSwitchRow(
                  icon: Icons.wb_sunny_rounded,
                  iconBg: const Color(0xFFF59E0B).withOpacity(0.14),
                  iconColor: const Color(0xFFF59E0B),
                  title: 'Dự báo thời tiết mỗi sáng',
                  subtitle: 'Gửi bản tin dự báo thời tiết lúc 07:00 hàng ngày',
                  value: settings.weatherNotif,
                  textColor: textColor,
                  subTextColor: subTextColor,
                  onChanged: (val) async {
                    if (val) {
                      final ok = await NotificationPermissionService.requestAndCheck(context);
                      if (!ok) return;
                    }
                    settings.setWeatherNotif(val);
                    if (context.mounted) {
                      _showToast(
                        context,
                        val ? 'Đã bật dự báo thời tiết sáng' : 'Đã tắt dự báo thời tiết sáng',
                      );
                    }
                  },
                ),
                Divider(color: borderColor),
                _buildSwitchRow(
                  icon: Icons.warning_amber_rounded,
                  iconBg: const Color(0xFF0D9488).withOpacity(0.14),
                  iconColor: const Color(0xFF0D9488),
                  title: 'Cảnh báo thời tiết nguy hiểm',
                  subtitle: 'Cảnh báo dông lốc, mưa to ngập lụt hoặc chỉ số UV cao',
                  value: settings.weatherAlertNotif,
                  textColor: textColor,
                  subTextColor: subTextColor,
                  onChanged: (val) async {
                    if (val) {
                      final ok = await NotificationPermissionService.requestAndCheck(context);
                      if (!ok) return;
                    }
                    settings.setWeatherAlertNotif(val);
                    if (context.mounted) {
                      _showToast(
                        context,
                        val
                            ? 'Đã bật cảnh báo thời tiết nguy hiểm'
                            : 'Đã tắt cảnh báo thời tiết nguy hiểm',
                      );
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF1654F0).withOpacity(0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF1654F0).withOpacity(0.18)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline_rounded,
                    color: Color(0xFF1654F0), size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Lưu ý: Bạn có thể tắt riêng "Tin tức nóng" để không nhận thông báo bài báo mới, trong khi "Dự báo thời tiết 07:00 sáng" vẫn hoạt động độc lập và gửi thông báo đúng giờ mỗi ngày.',
                    style: TextStyle(
                      fontSize: 12,
                      color: textColor.withOpacity(0.85),
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),

          // ══════════════════════════════════════════════════════════
          // 3. DỮ LIỆU & BỘ NHỚ TẠM
          // ══════════════════════════════════════════════════════════
          _buildSectionHeader(
            'DỮ LIỆU & BỘ NHỚ TẠM',
            subTextColor,
          ),
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
                  value: settings.autoDownloadImages,
                  textColor: textColor,
                  subTextColor: subTextColor,
                  onChanged: (val) {
                    settings.setAutoDownloadImages(val);
                    _showToast(
                      context,
                      val
                          ? 'Đã bật tự động tải ảnh'
                          : 'Đã bật chế độ tiết kiệm dữ liệu (tắt tải trước ảnh)',
                    );
                  },
                ),
                Divider(color: borderColor),
                _buildActionRow(
                  icon: Icons.cleaning_services_rounded,
                  iconBg: const Color(0xFF10B981).withOpacity(0.14),
                  iconColor: const Color(0xFF10B981),
                  title: 'Xóa bộ nhớ đệm (Cache)',
                  subtitle: settings.cacheSizeMB > 0.05
                      ? 'Giải phóng khoảng ${settings.cacheSizeFormatted} bộ nhớ tạm'
                      : 'Bộ nhớ đệm sạch sẽ (0.0 MB)',
                  textColor: textColor,
                  subTextColor: subTextColor,
                  onTap: () => _confirmClearCache(context, settings, cardColor, textColor),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),

          // ══════════════════════════════════════════════════════════
          // 4. VỀ ỨNG DỤNG & ĐIỀU KHOẢN
          // ══════════════════════════════════════════════════════════
          _buildSectionHeader(
            'THÔNG TIN ỨNG DỤNG',
            subTextColor,
          ),
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
                  subtitle: 'Daily News & Weather v1.3.3 (Build 2026)',
                  textColor: textColor,
                  subTextColor: subTextColor,
                  onTap: () {},
                ),
                Divider(color: borderColor),
                _buildActionRow(
                  icon: Icons.source_rounded,
                  iconBg: const Color(0xFF8B5CF6).withOpacity(0.14),
                  iconColor: const Color(0xFF8B5CF6),
                  title: 'Giấy phép mã nguồn mở',
                  subtitle: 'Bản quyền & giấy phép các thư viện bên thứ ba',
                  textColor: textColor,
                  subTextColor: subTextColor,
                  onTap: () {
                    showLicensePage(
                      context: context,
                      applicationName: 'Tin tức & Thời tiết',
                      applicationVersion: 'v1.3.3',
                      applicationLegalese:
                          'Bản quyền © 2026 Daily News & Weather Portal.\nỨng dụng sử dụng các thành phần phần mềm nguồn mở tuân thủ theo các giấy phép MIT, BSD, Apache 2.0.',
                      applicationIcon: Padding(
                        padding: const EdgeInsets.all(12),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.asset(
                            'assets/images/app_icon.jpg',
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    );
                  },
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
                  onTap: () => _showPolicyDialog(
                    context,
                    'Chính sách bảo mật',
                    cardColor,
                    textColor,
                  ),
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
                  onTap: () => _showPolicyDialog(
                    context,
                    'Điều khoản sử dụng',
                    cardColor,
                    textColor,
                  ),
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
                    _showToast(
                      context,
                      'Cảm ơn bạn đã yêu thích và đánh giá ứng dụng! ❤️',
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

  void _showToast(BuildContext context, String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor.withOpacity(0.12) : cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? primaryColor : (isDarkTheme ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: iconColor, size: 24),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected ? primaryColor : (isDarkTheme ? Colors.white70 : Colors.black87),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── HÀNG THAO TÁC CÓ ICON VÀ MŨI TÊN CHUYỂN TRANG ────────────────────────────
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
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: iconBg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14.5,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 12, color: subTextColor),
      ),
      trailing: Icon(Icons.chevron_right_rounded, color: subTextColor, size: 20),
      onTap: onTap,
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
    return SwitchListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      secondary: Container(
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: iconBg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14.5,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 12, color: subTextColor),
      ),
      value: value,
      thumbColor: WidgetStateProperty.resolveWith<Color>((states) => Colors.white),
      trackColor: WidgetStateProperty.resolveWith<Color>((states) {
        if (states.contains(WidgetState.selected)) {
          return const Color(0xFF10B981);
        }
        return const Color(0xFFCBD5E1);
      }),
      trackOutlineColor: WidgetStateProperty.resolveWith<Color>((states) {
        if (states.contains(WidgetState.selected)) {
          return Colors.transparent;
        }
        return const Color(0xFF94A3B8).withOpacity(0.4);
      }),
      onChanged: onChanged,
    );
  }

  // ── DIALOG CHỌN CỠ CHỮ ĐỌC BÁO (KÈM PREVIEW THỰC TẾ) ───────────────────────
  void _showFontSizeDialog(
    BuildContext context,
    SettingsProvider settings,
    Color cardColor,
    Color textColor,
    Color primaryColor,
  ) {
    final sizes = [
      {'name': 'Nhỏ', 'scale': '88%'},
      {'name': 'Tiêu chuẩn', 'scale': '100%'},
      {'name': 'Lớn', 'scale': '118%'},
      {'name': 'Rất lớn', 'scale': '135%'},
    ];

    showDialog(
      context: context,
      builder: (ctx) => Consumer<SettingsProvider>(
        builder: (ctx2, currentSettings, _) {
          return AlertDialog(
            backgroundColor: cardColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
            title: Row(
              children: [
                Icon(Icons.format_size_rounded, color: primaryColor, size: 24),
                const SizedBox(width: 10),
                Text(
                  'Chọn cỡ chữ đọc bài',
                  style: TextStyle(fontWeight: FontWeight.bold, color: textColor, fontSize: 17),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Preview text
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: primaryColor.withOpacity(0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Xem trước nội dung:',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: primaryColor),
                          ),
                          Text(
                            '${(currentSettings.fontScale * 100).round()}%',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: primaryColor),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Dự báo thời tiết hôm nay trời nắng nhẹ, nhiệt độ 28°C. Không khí trong lành.',
                        style: TextStyle(
                          fontSize: 15.0 * currentSettings.fontScale,
                          color: textColor,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                ...sizes.map((item) {
                  final sizeName = item['name']!;
                  final scale = item['scale']!;
                  final isSelected = currentSettings.fontSize == sizeName;

                  return ListTile(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    tileColor: isSelected ? primaryColor.withOpacity(0.1) : null,
                    leading: Icon(
                      isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                      color: isSelected ? primaryColor : Colors.grey,
                      size: 20,
                    ),
                    title: Text(
                      sizeName,
                      style: TextStyle(
                        color: isSelected ? primaryColor : textColor,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      ),
                    ),
                    trailing: Text(
                      scale,
                      style: TextStyle(fontSize: 12, color: isSelected ? primaryColor : Colors.grey.shade500),
                    ),
                    onTap: () async {
                      await currentSettings.setFontSize(sizeName);
                      if (ctx.mounted) Navigator.pop(ctx);
                      _showToast(
                        context,
                        'Đã đổi cỡ chữ sang: $sizeName ($scale)',
                      );
                    },
                  );
                }),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── XÁC NHẬN DỌN DẸP BỘ NHỚ ĐỆM CACHE ─────────────────────────────────────
  Future<void> _confirmClearCache(
    BuildContext context,
    SettingsProvider settings,
    Color cardColor,
    Color textColor,
  ) async {
    final confirmed = await showAppConfirmationDialog(
      context: context,
      type: AppConfirmationType.success,
      icon: Icons.cleaning_services_rounded,
      title: 'Dọn dẹp bộ nhớ đệm?',
      description:
          'Thao tác này sẽ xóa toàn bộ hình ảnh và tệp lưu tạm để giải phóng dung lượng bộ nhớ máy. Ứng dụng sẽ tự động tải lại khi cần.',
      confirmText: 'Dọn dẹp ngay',
      cancelText: 'Để sau',
      extraContent: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: const Color(0xFF10B981).withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF10B981).withOpacity(0.2)),
        ),
        child: Row(
          children: [
            const Icon(Icons.storage_rounded, color: Color(0xFF10B981), size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Dung lượng giải phóng ước tính: ${settings.cacheSizeFormatted}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Color(0xFF10B981),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true && context.mounted) {
      final freed = await settings.clearCache();
      if (context.mounted) {
        _showToast(
          context,
          'Đã dọn dẹp ${freed.toStringAsFixed(1)} MB bộ nhớ đệm cache thành công!',
        );
      }
    }
  }

  // ── DIALOG HIỂN THỊ CHÍNH SÁCH & BẢN QUYỀN (NGHỊ ĐỊNH 13 & GOOGLE PLAY COMPLIANCE) ───
  void _showPolicyDialog(
    BuildContext context,
    String title,
    Color cardColor,
    Color textColor,
  ) {
    final isPrivacy = title.contains('Bảo mật');
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        titlePadding: const EdgeInsets.fromLTRB(22, 20, 22, 10),
        contentPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
        title: Row(
          children: [
            Icon(
              isPrivacy ? Icons.security_rounded : Icons.gavel_rounded,
              color: isPrivacy ? const Color(0xFF10B981) : const Color(0xFF2563EB),
              size: 26,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: textColor,
                ),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isPrivacy) ...[
                  // 1. CHÍNH SÁCH BẢO MẬT (NGHỊ ĐỊNH 13/2023/NĐ-CP & GOOGLE PLAY)
                  _buildPolicyBadge(
                    'Tuân thủ Nghị định 13/2023/NĐ-CP & Google Play Data Safety',
                    const Color(0xFF10B981),
                  ),
                  const SizedBox(height: 14),
                  _buildPolicyParagraph(
                    '1. Mục đích xử lý dữ liệu',
                    'Ứng dụng chỉ xử lý các dữ liệu thiết yếu nhằm cung cấp bản tin dự báo thời tiết địa phương, đề xuất chuyên mục tin tức và đồng bộ danh sách bài viết đã lưu của người dùng.',
                    textColor,
                  ),
                  _buildPolicyParagraph(
                    '2. Dữ liệu Vị trí địa lý (GPS)',
                    '• Dữ liệu vị trí GPS chỉ được sử dụng tức thời khi người dùng cho phép để lấy dự báo thời tiết qua Open-Meteo API.\n'
                    '• Ứng dụng KHÔNG theo dõi hành trình ngầm, KHÔNG lưu trữ lịch sử vị trí và KHÔNG bán hoặc chia sẻ dữ liệu vị trí với bất kỳ bên thứ ba nào.',
                    textColor,
                  ),
                  _buildPolicyParagraph(
                    '3. Quyền Thông báo (Push Notifications)',
                    'Quyền thông báo chỉ được kích hoạt khi có sự đồng ý của bạn (Android 13+). Thông báo chỉ phục vụ mục đích gửi tin nóng và cảnh báo thời tiết nguy hiểm.',
                    textColor,
                  ),
                  _buildPolicyParagraph(
                    '4. Quyền của Chủ thể dữ liệu (Xóa tài khoản)',
                    'Bạn có toàn quyền chỉnh sửa thông tin cá nhân và có thể yêu cầu XÓA VĨNH VIỄN TÀI KHOẢN & DỮ LIỆU bất cứ lúc nào trong mục "Thông tin cá nhân". Toàn bộ dữ liệu liên kết sẽ được xóa sạch khỏi cơ sở dữ liệu Firebase.',
                    textColor,
                  ),
                ] else ...[
                  // 2. ĐIỀU KHOẢN SỬ DỤNG & BẢN QUYỀN NGUỒN TIN (DISCLAIMER)
                  _buildPolicyBadge(
                    'Tuyên bố bản quyền báo chí & Miễn trừ trách nhiệm',
                    const Color(0xFF2563EB),
                  ),
                  const SizedBox(height: 14),
                  _buildPolicyParagraph(
                    '1. Nguồn trích dẫn tin tức',
                    'Ứng dụng hoạt động như một nền tảng đọc tin tổng hợp (News Aggregator), trích dẫn nội dung tự động từ các nguồn cấp RSS công khai hợp pháp của các cơ quan báo chí chính thống tại Việt Nam (VnExpress, Tuổi Trẻ, Thanh Niên...).',
                    textColor,
                  ),
                  _buildPolicyParagraph(
                    '2. Quyền sở hữu trí tuệ',
                    '• Bản quyền toàn văn bài báo, tiêu đề, hình ảnh và nhãn hiệu thuộc về cơ quan báo chí phát hành gốc.\n'
                    '• Ứng dụng luôn ghi rõ nguồn tin gốc và cung cấp tính năng mở trang web chính thức của báo để người dùng đọc toàn văn.',
                    textColor,
                  ),
                  _buildPolicyParagraph(
                    '3. Cơ chế gỡ bỏ nội dung (Notice & Takedown)',
                    'Chúng tôi tôn trọng quyền tác giả và luật sở hữu trí tuệ. Nếu cơ quan báo chí hoặc đơn vị sở hữu bản quyền có yêu cầu gỡ bỏ hoặc ngừng tổng hợp nguồn tin, ban quản trị cam kết tiếp nhận và xử lý gỡ bỏ trong vòng 24 giờ qua kênh phản hồi.',
                    textColor,
                  ),
                ],
              ],
            ),
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            style: FilledButton.styleFrom(
              backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              foregroundColor: textColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Đã hiểu & Đồng ý'),
          ),
        ],
      ),
    );
  }

  Widget _buildPolicyBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified_user_rounded, color: color, size: 14),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: color,
                fontSize: 11.5,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPolicyParagraph(String heading, String body, Color textColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            heading,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13.5,
              color: textColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            body,
            style: TextStyle(
              fontSize: 12.5,
              height: 1.45,
              color: textColor.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }
}
