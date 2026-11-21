import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/widgets/app_confirmation_dialog.dart';
import '../../../services/notification_permission_service.dart';
import 'package:daily_news_weather_portal/features/settings/providers/settings_provider.dart';
import 'package:daily_news_weather_portal/features/settings/providers/theme_provider.dart';
import 'package:daily_news_weather_portal/features/settings/presentation/widgets/settings_font_size_dialog.dart';
import 'package:daily_news_weather_portal/features/settings/presentation/widgets/settings_policy_dialog.dart';
import 'package:daily_news_weather_portal/features/settings/presentation/widgets/settings_tile_components.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

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

  void _confirmClearCache(
    BuildContext context,
    SettingsProvider settings,
    Color cardColor,
    Color textColor,
  ) {
    if (settings.cacheSizeMB <= 0.05) {
      _showToast(context, 'Bộ nhớ đệm đã sạch sẽ (0.0 MB)');
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AppConfirmationDialog(
        type: AppConfirmationType.danger,
        icon: Icons.cleaning_services_rounded,
        title: 'Xóa bộ nhớ đệm (Cache)',
        description:
            'Bạn có chắc chắn muốn xóa ${settings.cacheSizeFormatted} dữ liệu bộ nhớ tạm không? Hình ảnh bài báo sẽ được tải lại khi mở.',
        confirmText: 'Xóa ngay',
        cancelText: 'Hủy',
        isDestructive: true,
        onConfirm: () async {
          Navigator.pop(ctx);
          await settings.clearCache();
          if (context.mounted) {
            _showToast(context, 'Đã dọn dẹp sạch sẽ bộ nhớ đệm!');
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final settings = context.watch<SettingsProvider>();
    final currentMode = themeProvider.themeMode;
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
          // 1. CHỌN CHẾ ĐỘ GIAO DIỆN (SÁNG / TỐI / HỆ THỐNG)
          SettingsSectionHeader(title: 'GIAO DIỆN & HIỂN THỊ', color: subTextColor),
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
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textColor),
                ),
                const SizedBox(height: 4),
                Text(
                  'Chọn giao diện phù hợp giúp bảo vệ mắt và tiết kiệm pin.',
                  style: TextStyle(fontSize: 12.5, color: subTextColor),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: SettingsThemeCard(
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
                      child: SettingsThemeCard(
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
                      child: SettingsThemeCard(
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
                SettingsActionRow(
                  icon: Icons.format_size_rounded,
                  iconBg: const Color(0xFF8B5CF6).withOpacity(0.14),
                  iconColor: const Color(0xFF8B5CF6),
                  title: 'Cỡ chữ đọc báo',
                  subtitle: '${settings.fontSize} (${(settings.fontScale * 100).round()}%)',
                  textColor: textColor,
                  subTextColor: subTextColor,
                  onTap: () => SettingsFontSizeDialog.show(
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

          // 2. THÔNG BÁO & TIN TỨC
          SettingsSectionHeader(title: 'THÔNG BÁO & CẢNH BÁO', color: subTextColor),
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
                SettingsActionRow(
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
                      _showToast(context, '✓ Ứng dụng đã được cấp quyền thông báo hệ thống');
                    } else {
                      final ok = await NotificationPermissionService.requestAndCheck(context);
                      if (!context.mounted) return;
                      if (ok) {
                        _showToast(context, 'Đã cấp quyền thông báo thành công!');
                      }
                    }
                  },
                ),
                Divider(color: borderColor),
                SettingsSwitchRow(
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
                SettingsSwitchRow(
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
                SettingsSwitchRow(
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
                const Icon(Icons.info_outline_rounded, color: Color(0xFF1654F0), size: 18),
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

          // 3. DỮ LIỆU & BỘ NHỚ TẠM
          SettingsSectionHeader(title: 'DỮ LIỆU & BỘ NHỚ TẠM', color: subTextColor),
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
                SettingsSwitchRow(
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
                SettingsActionRow(
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

          // 4. VỀ ỨNG DỤNG & ĐIỀU KHOẢN
          SettingsSectionHeader(title: 'THÔNG TIN ỨNG DỤNG', color: subTextColor),
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
                SettingsActionRow(
                  icon: Icons.info_outline_rounded,
                  iconBg: const Color(0xFF1E60F2).withOpacity(0.14),
                  iconColor: const Color(0xFF1E60F2),
                  title: 'Phiên bản ứng dụng',
                  subtitle: 'Daily News & Weather v1.5.5 (Build 2026)',
                  textColor: textColor,
                  subTextColor: subTextColor,
                  onTap: () {},
                ),
                Divider(color: borderColor),
                SettingsActionRow(
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
                SettingsActionRow(
                  icon: Icons.privacy_tip_outlined,
                  iconBg: const Color(0xFF14B8A6).withOpacity(0.14),
                  iconColor: const Color(0xFF14B8A6),
                  title: 'Chính sách bảo mật',
                  subtitle: 'Cách chúng tôi bảo vệ thông tin của bạn',
                  textColor: textColor,
                  subTextColor: subTextColor,
                  onTap: () => SettingsPolicyDialog.show(
                    context,
                    'Chính sách bảo mật',
                    cardColor,
                    textColor,
                  ),
                ),
                Divider(color: borderColor),
                SettingsActionRow(
                  icon: Icons.description_outlined,
                  iconBg: const Color(0xFF64748B).withOpacity(0.14),
                  iconColor: const Color(0xFF64748B),
                  title: 'Điều khoản sử dụng',
                  subtitle: 'Quy định và quyền lợi người dùng',
                  textColor: textColor,
                  subTextColor: subTextColor,
                  onTap: () => SettingsPolicyDialog.show(
                    context,
                    'Điều khoản sử dụng',
                    cardColor,
                    textColor,
                  ),
                ),
                Divider(color: borderColor),
                SettingsActionRow(
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
}
