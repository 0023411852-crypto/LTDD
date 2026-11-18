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
    final isVi = settings.isVietnamese;

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
          isVi ? 'Cài đặt' : 'Settings',
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
            isVi ? 'GIAO DIỆN & HIỂN THỊ' : 'APPEARANCE & DISPLAY',
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
                  isVi ? 'Chế độ hiển thị màn hình' : 'Screen Display Mode',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isVi
                      ? 'Chọn giao diện phù hợp giúp bảo vệ mắt và tiết kiệm pin.'
                      : 'Choose a theme that helps protect eyes and saves battery.',
                  style: TextStyle(fontSize: 12.5, color: subTextColor),
                ),
                const SizedBox(height: 14),

                // 3 Thẻ trực quan: Sáng, Tối, Hệ thống
                Row(
                  children: [
                    Expanded(
                      child: _buildThemeCard(
                        title: isVi ? 'Sáng' : 'Light',
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
                        title: isVi ? 'Tối' : 'Dark',
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
                        title: isVi ? 'Hệ thống' : 'System',
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
                  title: isVi ? 'Cỡ chữ đọc báo' : 'Article Font Size',
                  subtitle: '${settings.fontSize} (${(settings.fontScale * 100).round()}%)',
                  textColor: textColor,
                  subTextColor: subTextColor,
                  onTap: () => _showFontSizeDialog(
                    context,
                    settings,
                    isVi,
                    cardColor,
                    textColor,
                    primaryColor,
                  ),
                ),
                Divider(color: borderColor),

                // Ngôn ngữ ứng dụng
                _buildActionRow(
                  icon: Icons.language_rounded,
                  iconBg: const Color(0xFF0284C7).withOpacity(0.14),
                  iconColor: const Color(0xFF0284C7),
                  title: isVi ? 'Ngôn ngữ ứng dụng' : 'App Language',
                  subtitle: settings.languageLabel,
                  textColor: textColor,
                  subTextColor: subTextColor,
                  onTap: () => _showLanguageDialog(
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
            isVi ? 'THÔNG BÁO & CẢNH BÁO' : 'NOTIFICATIONS & ALERTS',
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
                  title: isVi ? 'Quyền thông báo hệ thống' : 'System Notification Permission',
                  subtitle: isVi
                      ? 'Kiểm tra & quản lý quyền trên thiết bị'
                      : 'Check & manage permissions on device',
                  textColor: textColor,
                  subTextColor: subTextColor,
                  onTap: () async {
                    final granted = await NotificationPermissionService.isGranted();
                    if (!context.mounted) return;
                    if (granted) {
                      _showToast(
                        context,
                        isVi
                            ? '✓ Ứng dụng đã được cấp quyền thông báo hệ thống'
                            : '✓ System notification permission is granted',
                      );
                    } else {
                      final ok = await NotificationPermissionService.requestAndCheck(context, isVi: isVi);
                      if (!context.mounted) return;
                      if (ok) {
                        _showToast(
                          context,
                          isVi ? 'Đã cấp quyền thông báo thành công!' : 'Permission granted successfully!',
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
                  title: isVi ? 'Tin tức nóng & khẩn cấp' : 'Breaking News Alerts',
                  subtitle: isVi
                      ? 'Nhận thông báo khi có sự kiện xã hội quan trọng'
                      : 'Notify on critical and breaking social events',
                  value: settings.breakingNewsNotif,
                  textColor: textColor,
                  subTextColor: subTextColor,
                  onChanged: (val) async {
                    if (val) {
                      final ok = await NotificationPermissionService.requestAndCheck(context, isVi: isVi);
                      if (!ok) return;
                    }
                    settings.setBreakingNewsNotif(val);
                    if (context.mounted) {
                      _showToast(
                        context,
                        val
                            ? (isVi ? 'Đã bật thông báo tin nóng' : 'Breaking news enabled')
                            : (isVi ? 'Đã tắt thông báo tin nóng' : 'Breaking news disabled'),
                      );
                    }
                  },
                ),
                Divider(color: borderColor),
                _buildSwitchRow(
                  icon: Icons.wb_sunny_rounded,
                  iconBg: const Color(0xFFF59E0B).withOpacity(0.14),
                  iconColor: const Color(0xFFF59E0B),
                  title: isVi ? 'Dự báo thời tiết mỗi sáng' : 'Daily Morning Weather',
                  subtitle: isVi
                      ? 'Gửi bản tin dự báo thời tiết lúc 07:00 hàng ngày'
                      : 'Receive morning weather forecast at 07:00 AM',
                  value: settings.weatherNotif,
                  textColor: textColor,
                  subTextColor: subTextColor,
                  onChanged: (val) async {
                    if (val) {
                      final ok = await NotificationPermissionService.requestAndCheck(context, isVi: isVi);
                      if (!ok) return;
                    }
                    settings.setWeatherNotif(val);
                    if (context.mounted) {
                      _showToast(
                        context,
                        val
                            ? (isVi ? 'Đã bật dự báo thời tiết sáng' : 'Morning weather forecast enabled')
                            : (isVi ? 'Đã tắt dự báo thời tiết sáng' : 'Morning weather forecast disabled'),
                      );
                    }
                  },
                ),
                Divider(color: borderColor),
                _buildSwitchRow(
                  icon: Icons.warning_amber_rounded,
                  iconBg: const Color(0xFF0D9488).withOpacity(0.14),
                  iconColor: const Color(0xFF0D9488),
                  title: isVi ? 'Cảnh báo thời tiết nguy hiểm' : 'Severe Weather Warnings',
                  subtitle: isVi
                      ? 'Cảnh báo dông lốc, mưa to ngập lụt hoặc chỉ số UV cao'
                      : 'Alerts for storms, heavy rainfall, flooding or high UV index',
                  value: settings.weatherAlertNotif,
                  textColor: textColor,
                  subTextColor: subTextColor,
                  onChanged: (val) async {
                    if (val) {
                      final ok = await NotificationPermissionService.requestAndCheck(context, isVi: isVi);
                      if (!ok) return;
                    }
                    settings.setWeatherAlertNotif(val);
                    if (context.mounted) {
                      _showToast(
                        context,
                        val
                            ? (isVi ? 'Đã bật cảnh báo thời tiết nguy hiểm' : 'Severe weather alerts enabled')
                            : (isVi ? 'Đã tắt cảnh báo thời tiết nguy hiểm' : 'Severe weather alerts disabled'),
                      );
                    }
                  },
                ),
                Divider(color: borderColor),
                _buildSwitchRow(
                  icon: Icons.card_giftcard_rounded,
                  iconBg: const Color(0xFF6366F1).withOpacity(0.14),
                  iconColor: const Color(0xFF6366F1),
                  title: isVi ? 'Tin tức tiện ích & Khuyến mại' : 'Promotions & Utilities',
                  subtitle: isVi
                      ? 'Các chương trình và thông tin ưu đãi tiện ích'
                      : 'Utility programs and discount campaigns',
                  value: settings.promoNotif,
                  textColor: textColor,
                  subTextColor: subTextColor,
                  onChanged: (val) async {
                    if (val) {
                      final ok = await NotificationPermissionService.requestAndCheck(context, isVi: isVi);
                      if (!ok) return;
                    }
                    settings.setPromoNotif(val);
                    if (context.mounted) {
                      _showToast(
                        context,
                        val
                            ? (isVi ? 'Đã bật thông báo tiện ích' : 'Promotions enabled')
                            : (isVi ? 'Đã tắt thông báo tiện ích' : 'Promotions disabled'),
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
              border:
                  Border.all(color: const Color(0xFF1654F0).withOpacity(0.18)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline_rounded,
                    color: Color(0xFF1654F0), size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    isVi
                        ? 'Lưu ý: Bạn có thể tắt riêng "Tin tức nóng" để không nhận thông báo bài báo mới, trong khi "Dự báo thời tiết 07:00 sáng" vẫn hoạt động độc lập và gửi thông báo đúng giờ mỗi ngày.'
                        : 'Note: You can turn off Breaking News to stop news alerts, while 07:00 AM Weather Briefing operates independently and still delivers daily on time.',
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
            isVi ? 'DỮ LIỆU & BỘ NHỚ TẠM' : 'DATA & CACHE MEMORY',
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
                  title: isVi ? 'Tự động tải ảnh tin tức' : 'Auto-load News Images',
                  subtitle: isVi
                      ? 'Tải trước hình ảnh bài báo để đọc nhanh hơn'
                      : 'Pre-cache article pictures for faster reading',
                  value: settings.autoDownloadImages,
                  textColor: textColor,
                  subTextColor: subTextColor,
                  onChanged: (val) {
                    settings.setAutoDownloadImages(val);
                    _showToast(
                      context,
                      val
                          ? (isVi ? 'Đã bật tự động tải ảnh' : 'Auto image loading enabled')
                          : (isVi ? 'Đã bật chế độ tiết kiệm dữ liệu (tắt tải trước ảnh)' : 'Data saver enabled'),
                    );
                  },
                ),
                Divider(color: borderColor),
                _buildActionRow(
                  icon: Icons.cleaning_services_rounded,
                  iconBg: const Color(0xFF10B981).withOpacity(0.14),
                  iconColor: const Color(0xFF10B981),
                  title: isVi ? 'Xóa bộ nhớ đệm (Cache)' : 'Clear Cached Data',
                  subtitle: settings.cacheSizeMB > 0.05
                      ? (isVi
                          ? 'Giải phóng khoảng ${settings.cacheSizeFormatted} bộ nhớ tạm'
                          : 'Free up approx ${settings.cacheSizeFormatted} memory')
                      : (isVi ? 'Bộ nhớ đệm sạch sẽ (0.0 MB)' : 'Cache is completely clean (0.0 MB)'),
                  textColor: textColor,
                  subTextColor: subTextColor,
                  onTap: () => _confirmClearCache(context, settings, isVi, cardColor, textColor),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),

          // ══════════════════════════════════════════════════════════
          // 4. VỀ ỨNG DỤNG & ĐIỀU KHOẢN
          // ══════════════════════════════════════════════════════════
          _buildSectionHeader(
            isVi ? 'THÔNG TIN ỨNG DỤNG' : 'APPLICATION INFO',
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
                  title: isVi ? 'Phiên bản ứng dụng' : 'App Version',
                  subtitle: 'Daily News & Weather v1.2.0 (Build 2026)',
                  textColor: textColor,
                  subTextColor: subTextColor,
                  onTap: () {},
                ),
                Divider(color: borderColor),
                _buildActionRow(
                  icon: Icons.source_rounded,
                  iconBg: const Color(0xFF8B5CF6).withOpacity(0.14),
                  iconColor: const Color(0xFF8B5CF6),
                  title: isVi ? 'Giấy phép mã nguồn mở' : 'Open Source Licenses',
                  subtitle: isVi
                      ? 'Bản quyền & giấy phép các thư viện bên thứ ba'
                      : 'Third-party library copyright notices & licenses',
                  textColor: textColor,
                  subTextColor: subTextColor,
                  onTap: () {
                    showLicensePage(
                      context: context,
                      applicationName:
                          isVi ? 'Tin tức & Thời tiết' : 'Daily News & Weather Portal',
                      applicationVersion: 'v1.3.1',
                      applicationLegalese: isVi
                          ? 'Bản quyền © 2026 Daily News & Weather Portal.\nỨng dụng sử dụng các thành phần phần mềm nguồn mở tuân thủ theo các giấy phép MIT, BSD, Apache 2.0.'
                          : 'Copyright © 2026 Daily News & Weather Portal.\nPowered by open source software under MIT, BSD, and Apache 2.0 licenses.',
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
                  title: isVi ? 'Chính sách bảo mật' : 'Privacy Policy',
                  subtitle: isVi
                      ? 'Cách chúng tôi bảo vệ thông tin của bạn'
                      : 'How we safeguard your personal data',
                  textColor: textColor,
                  subTextColor: subTextColor,
                  onTap: () => _showPolicyDialog(
                    context,
                    isVi ? 'Chính sách bảo mật' : 'Privacy Policy',
                    cardColor,
                    textColor,
                    isVi,
                  ),
                ),
                Divider(color: borderColor),
                _buildActionRow(
                  icon: Icons.description_outlined,
                  iconBg: const Color(0xFF64748B).withOpacity(0.14),
                  iconColor: const Color(0xFF64748B),
                  title: isVi ? 'Điều khoản sử dụng' : 'Terms of Service',
                  subtitle: isVi
                      ? 'Quy định và quyền lợi người dùng'
                      : 'User rights and platform terms',
                  textColor: textColor,
                  subTextColor: subTextColor,
                  onTap: () => _showPolicyDialog(
                    context,
                    isVi ? 'Điều khoản sử dụng' : 'Terms of Service',
                    cardColor,
                    textColor,
                    isVi,
                  ),
                ),
                Divider(color: borderColor),
                _buildActionRow(
                  icon: Icons.star_rate_rounded,
                  iconBg: const Color(0xFFF59E0B).withOpacity(0.14),
                  iconColor: const Color(0xFFF59E0B),
                  title: isVi ? 'Đánh giá ứng dụng 5 sao' : 'Rate Us 5 Stars',
                  subtitle: isVi
                      ? 'Ủng hộ nhà phát triển trên Google Play'
                      : 'Support developers on Google Play Store',
                  textColor: textColor,
                  subTextColor: subTextColor,
                  onTap: () {
                    _showToast(
                      context,
                      isVi
                          ? 'Cảm ơn bạn đã yêu thích và đánh giá ứng dụng! ❤️'
                          : 'Thank you for supporting and rating our app! ❤️',
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
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? primaryColor.withOpacity(isDarkTheme ? 0.22 : 0.1)
              : cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? primaryColor
                : (isDarkTheme ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
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

  // ── DIALOG CHỌN CỠ CHỮ ĐỌC BÁO (KÈM PREVIEW THỰC TẾ) ───────────────────────
  void _showFontSizeDialog(
    BuildContext context,
    SettingsProvider settings,
    bool isVi,
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
                  isVi ? 'Chọn cỡ chữ đọc bài' : 'Reading Font Size',
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
                            isVi ? 'Xem trước nội dung:' : 'Content Preview:',
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
                        isVi
                            ? 'Dự báo thời tiết hôm nay trời nắng nhẹ, nhiệt độ 28°C. Không khí trong lành.'
                            : 'Today forecast shows mild sunlight, temperature 28°C. Clean fresh air.',
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
                        isVi
                            ? 'Đã đổi cỡ chữ sang: $sizeName ($scale)'
                            : 'Font size changed to: $sizeName ($scale)',
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

  // ── DIALOG CHỌN NGÔN NGỮ (TIẾNG VIỆT / TIẾNG ANH) ───────────────────────────
  void _showLanguageDialog(
    BuildContext context,
    SettingsProvider settings,
    Color cardColor,
    Color textColor,
    Color primaryColor,
  ) {
    final currentLang = settings.language;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Row(
          children: [
            Icon(Icons.language_rounded, color: primaryColor, size: 24),
            const SizedBox(width: 10),
            Text(
              settings.isVietnamese ? 'Ngôn ngữ ứng dụng' : 'Select App Language',
              style: TextStyle(fontWeight: FontWeight.bold, color: textColor, fontSize: 17),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Tiếng Việt
            ListTile(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              tileColor: currentLang == 'vi' ? primaryColor.withOpacity(0.1) : null,
              leading: const Text('🇻🇳', style: TextStyle(fontSize: 24)),
              title: Text(
                'Tiếng Việt',
                style: TextStyle(
                  fontWeight: currentLang == 'vi' ? FontWeight.bold : FontWeight.w600,
                  color: currentLang == 'vi' ? primaryColor : textColor,
                ),
              ),
              subtitle: const Text('Ngôn ngữ mặc định', style: TextStyle(fontSize: 12)),
              trailing: currentLang == 'vi'
                  ? Icon(Icons.check_circle_rounded, color: primaryColor)
                  : null,
              onTap: () {
                settings.setLanguage('vi');
                Navigator.pop(ctx);
                _showToast(context, 'Đã chuyển sang Tiếng Việt thành công!');
              },
            ),
            const SizedBox(height: 6),

            // English
            ListTile(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              tileColor: currentLang == 'en' ? primaryColor.withOpacity(0.1) : null,
              leading: const Text('🇬🇧', style: TextStyle(fontSize: 24)),
              title: Text(
                'English',
                style: TextStyle(
                  fontWeight: currentLang == 'en' ? FontWeight.bold : FontWeight.w600,
                  color: currentLang == 'en' ? primaryColor : textColor,
                ),
              ),
              subtitle: const Text('English language', style: TextStyle(fontSize: 12)),
              trailing: currentLang == 'en'
                  ? Icon(Icons.check_circle_rounded, color: primaryColor)
                  : null,
              onTap: () {
                settings.setLanguage('en');
                Navigator.pop(ctx);
                _showToast(context, 'Language changed to English successfully!');
              },
            ),
          ],
        ),
      ),
    );
  }

  // ── XÁC NHẬN DỌN DẸP BỘ NHỚ ĐỆM CACHE ─────────────────────────────────────
  Future<void> _confirmClearCache(
    BuildContext context,
    SettingsProvider settings,
    bool isVi,
    Color cardColor,
    Color textColor,
  ) async {
    final confirmed = await showAppConfirmationDialog(
      context: context,
      type: AppConfirmationType.success,
      icon: Icons.cleaning_services_rounded,
      title: isVi ? 'Dọn dẹp bộ nhớ đệm?' : 'Clear Cache Memory?',
      description: isVi
          ? 'Thao tác này sẽ xóa toàn bộ hình ảnh và tệp lưu tạm để giải phóng dung lượng bộ nhớ máy. Ứng dụng sẽ tự động tải lại khi cần.'
          : 'This will purge all temporary cached images and files to free up storage space. The app will reload files when needed.',
      confirmText: isVi ? 'Dọn dẹp ngay' : 'Clear Now',
      cancelText: isVi ? 'Để sau' : 'Cancel',
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
                isVi
                    ? 'Dung lượng giải phóng ước tính: ${settings.cacheSizeFormatted}'
                    : 'Estimated storage freed: ${settings.cacheSizeFormatted}',
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
          isVi
              ? 'Đã dọn dẹp ${freed.toStringAsFixed(1)} MB bộ nhớ đệm cache thành công!'
              : 'Cleared ${freed.toStringAsFixed(1)} MB cache successfully!',
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
    bool isVi,
  ) {
    final isPrivacy = title.contains('Bảo mật') || title.contains('Privacy');
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
                    isVi ? 'Tuân thủ Nghị định 13/2023/NĐ-CP & Google Play Data Safety' : 'Compliant with Vietnam Decree 13 & Google Play Policies',
                    const Color(0xFF10B981),
                  ),
                  const SizedBox(height: 14),
                  _buildPolicyParagraph(
                    isVi ? '1. Mục đích xử lý dữ liệu' : '1. Purpose of Data Processing',
                    isVi
                        ? 'Ứng dụng chỉ xử lý các dữ liệu thiết yếu nhằm cung cấp bản tin dự báo thời tiết địa phương, đề xuất chuyên mục tin tức và đồng bộ danh sách bài viết đã lưu của người dùng.'
                        : 'The app only processes essential data to deliver localized weather forecasts, news feed customization, and synchronized bookmarks.',
                    textColor,
                  ),
                  _buildPolicyParagraph(
                    isVi ? '2. Dữ liệu Vị trí địa lý (GPS)' : '2. Geographic Location Data (GPS)',
                    isVi
                        ? '• Dữ liệu vị trí GPS chỉ được sử dụng tức thời khi người dùng cho phép để lấy dự báo thời tiết qua Open-Meteo API.\n'
                          '• Ứng dụng KHÔNG theo dõi hành trình ngầm, KHÔNG lưu trữ lịch sử vị trí và KHÔNG bán hoặc chia sẻ dữ liệu vị trí với bất kỳ bên thứ ba nào.'
                        : '• GPS location is accessed in real-time only upon explicit consent to query weather from Open-Meteo API.\n'
                          '• We DO NOT track user movements, DO NOT retain location logs, and DO NOT sell location data to third parties.',
                    textColor,
                  ),
                  _buildPolicyParagraph(
                    isVi ? '3. Quyền Thông báo (Push Notifications)' : '3. Notification Permissions',
                    isVi
                        ? 'Quyền thông báo chỉ được kích hoạt khi có sự đồng ý của bạn (Android 13+). Thông báo chỉ phục vụ mục đích gửi tin nóng và cảnh báo thời tiết nguy hiểm.'
                        : 'Notification permissions are requested via system prompt (Android 13+). Alerts are limited to breaking news and severe weather warnings.',
                    textColor,
                  ),
                  _buildPolicyParagraph(
                    isVi ? '4. Quyền của Chủ thể dữ liệu (Xóa tài khoản)' : '4. User Data Rights & Account Deletion',
                    isVi
                        ? 'Bạn có toàn quyền chỉnh sửa thông tin cá nhân và có thể yêu cầu XÓA VĨNH VIỄN TÀI KHOẢN & DỮ LIỆU bất cứ lúc nào trong mục "Thông tin cá nhân". Toàn bộ dữ liệu liên kết sẽ được xóa sạch khỏi cơ sở dữ liệu Firebase.'
                        : 'You retain full rights to edit and PERMANENTLY DELETE YOUR ACCOUNT & DATA anytime via "Personal Information". All user records will be purged from Firebase database.',
                    textColor,
                  ),
                ] else ...[
                  // 2. ĐIỀU KHOẢN SỬ DỤNG & BẢN QUYỀN NGUỒN TIN (DISCLAIMER)
                  _buildPolicyBadge(
                    isVi ? 'Tuyên bố bản quyền báo chí & Miễn trừ trách nhiệm' : 'Editorial Copyright & Disclaimer',
                    const Color(0xFF2563EB),
                  ),
                  const SizedBox(height: 14),
                  _buildPolicyParagraph(
                    isVi ? '1. Nguồn trích dẫn tin tức' : '1. Content Aggregation & Sources',
                    isVi
                        ? 'Ứng dụng hoạt động như một nền tảng đọc tin tổng hợp (News Aggregator), trích dẫn nội dung tự động từ các nguồn cấp RSS công khai hợp pháp của các cơ quan báo chí chính thống tại Việt Nam (VnExpress, Tuổi Trẻ, Thanh Niên...).'
                        : 'This application acts as a news aggregator, fetching feeds from public, official RSS channels of Vietnamese mainstream press agencies.',
                    textColor,
                  ),
                  _buildPolicyParagraph(
                    isVi ? '2. Quyền sở hữu trí tuệ' : '2. Intellectual Property Rights',
                    isVi
                        ? '• Bản quyền toàn văn bài báo, tiêu đề, hình ảnh và nhãn hiệu thuộc về cơ quan báo chí phát hành gốc.\n'
                          '• Ứng dụng luôn ghi rõ nguồn tin gốc và cung cấp tính năng mở trang web chính thức của báo để người dùng đọc toàn văn.'
                        : '• Full articles, images, and headlines remain the sole property of original publishers.\n'
                          '• The app strictly attributes all sources and directs users to original publisher websites via WebView.',
                    textColor,
                  ),
                  _buildPolicyParagraph(
                    isVi ? '3. Cơ chế gỡ bỏ nội dung (Notice & Takedown)' : '3. Notice and Takedown Policy',
                    isVi
                        ? 'Chúng tôi tôn trọng quyền tác giả và luật sở hữu trí tuệ. Nếu cơ quan báo chí hoặc đơn vị sở hữu bản quyền có yêu cầu gỡ bỏ hoặc ngừng tổng hợp nguồn tin, ban quản trị cam kết tiếp nhận và xử lý gỡ bỏ trong vòng 24 giờ qua kênh phản hồi.'
                        : 'We respect copyright laws. If any publisher wishes to discontinue feed aggregation, our team commits to removing feeds within 24 hours upon official notice.',
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
            child: Text(isVi ? 'Đã hiểu & Đồng ý' : 'Understood & Accept'),
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
