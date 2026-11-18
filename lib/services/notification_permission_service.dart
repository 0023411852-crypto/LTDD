import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Dịch vụ quản lý và yêu cầu quyền gửi thông báo (Android 13+ POST_NOTIFICATIONS & iOS)
class NotificationPermissionService {
  static const String _keyPrompted = 'has_prompted_notification_permission';

  /// Kiểm tra quyền thông báo đã được cấp chưa
  static Future<bool> isGranted() async {
    return await Permission.notification.isGranted;
  }

  /// Lấy trạng thái hiện tại của quyền thông báo
  static Future<PermissionStatus> getStatus() async {
    return await Permission.notification.status;
  }

  /// Kiểm tra xem quyền có bị từ chối vĩnh viễn không
  static Future<bool> isPermanentlyDenied() async {
    return await Permission.notification.isPermanentlyDenied;
  }

  /// Yêu cầu cấp quyền trực tiếp
  static Future<PermissionStatus> request() async {
    return await Permission.notification.request();
  }

  /// Yêu cầu cấp quyền và trả về true nếu được cấp thành công
  static Future<bool> requestAndCheck(BuildContext context, {bool isVi = true}) async {
    final status = await Permission.notification.status;
    if (status.isGranted) return true;
    if (status.isPermanentlyDenied) {
      if (context.mounted) {
        await showSettingsDialog(context, isVi: isVi);
      }
      return false;
    }
    final req = await Permission.notification.request();
    if (req.isGranted) return true;
    if (req.isPermanentlyDenied) {
      if (context.mounted) {
        await showSettingsDialog(context, isVi: isVi);
      }
    }
    return false;
  }

  /// Mở màn hình Cài đặt ứng dụng của thiết bị
  static Future<bool> openSettings() async {
    return await openAppSettings();
  }

  /// Hỏi xin quyền khi người dùng mở ứng dụng lần đầu (kèm giải thích thân thiện)
  static Future<void> promptOnFirstLaunch(BuildContext context, {bool isVi = true}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasPrompted = prefs.getBool(_keyPrompted) ?? false;
      if (hasPrompted) return;

      final status = await Permission.notification.status;
      if (status.isGranted) {
        await prefs.setBool(_keyPrompted, true);
        return;
      }

      // Đánh dấu đã từng hiển thị để không làm phiền người dùng liên tục
      await prefs.setBool(_keyPrompted, true);

      if (!context.mounted) return;

      final isDark = Theme.of(context).brightness == Brightness.dark;

      final result = await showDialog<bool>(
        context: context,
        barrierDismissible: true,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF0284C7).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.notifications_active_rounded,
                  color: Color(0xFF0284C7),
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  isVi ? 'Bật thông báo ứng dụng' : 'Enable Notifications',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isVi
                    ? 'Cho phép ứng dụng gửi thông báo tức thời về các tin tức nóng hổi, cảnh báo bão lũ và bản tin thời tiết mỗi sáng.'
                    : 'Allow the app to send instant alerts on breaking news, severe weather warnings, and morning forecasts.',
                style: TextStyle(
                  fontSize: 14,
                  height: 1.45,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
              const SizedBox(height: 14),
              _buildFeatureBullet(
                icon: Icons.bolt_rounded,
                color: Colors.amber.shade700,
                text: isVi ? 'Tin nóng & sự kiện khẩn cấp' : 'Breaking news & emergency alerts',
                isDark: isDark,
              ),
              const SizedBox(height: 8),
              _buildFeatureBullet(
                icon: Icons.wb_sunny_rounded,
                color: Colors.orange,
                text: isVi ? 'Dự báo thời tiết lúc 07:00 sáng' : 'Morning weather forecast at 7:00 AM',
                isDark: isDark,
              ),
              const SizedBox(height: 8),
              _buildFeatureBullet(
                icon: Icons.warning_amber_rounded,
                color: Colors.redAccent,
                text: isVi ? 'Cảnh báo bão, mưa lớn, chỉ số UV cao' : 'Storm, heavy rain & high UV warnings',
                isDark: isDark,
              ),
            ],
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(
                isVi ? 'Để sau' : 'Later',
                style: TextStyle(color: isDark ? Colors.white54 : Colors.grey.shade600),
              ),
            ),
            FilledButton.icon(
              onPressed: () => Navigator.of(ctx).pop(true),
              icon: const Icon(Icons.check_rounded, size: 18),
              label: Text(isVi ? 'Cho phép' : 'Allow'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF0284C7),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      );

      if (result == true) {
        final newStatus = await Permission.notification.request();
        if (newStatus.isPermanentlyDenied && context.mounted) {
          showSettingsDialog(context, isVi: isVi);
        }
      }
    } catch (e) {
      debugPrint('NotificationPermissionService.promptOnFirstLaunch error: $e');
    }
  }

  static Widget _buildFeatureBullet({
    required IconData icon,
    required Color color,
    required String text,
    required bool isDark,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  /// Hiển thị hộp thoại hướng dẫn người dùng mở Cài đặt thiết bị khi bị từ chối vĩnh viễn
  static Future<void> showSettingsDialog(BuildContext context, {bool isVi = true}) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        title: Row(
          children: [
            const Icon(Icons.settings_suggest_rounded, color: Color(0xFF0284C7)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                isVi ? 'Cấp quyền trong Cài đặt' : 'Enable in App Settings',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
              ),
            ),
          ],
        ),
        content: Text(
          isVi
              ? 'Quyền thông báo hiện đang bị tắt trong cài đặt thiết bị của bạn. Để nhận được thông báo tin tức và cảnh báo thời tiết, vui lòng mở Cài đặt và bật "Cho phép thông báo".'
              : 'Notification permission is disabled in your device settings. Please open Settings and enable "Allow Notifications" to receive updates.',
          style: TextStyle(
            fontSize: 14,
            height: 1.4,
            color: isDark ? Colors.white70 : Colors.black87,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(isVi ? 'Để sau' : 'Cancel'),
          ),
          FilledButton.icon(
            onPressed: () {
              Navigator.of(ctx).pop();
              openAppSettings();
            },
            icon: const Icon(Icons.open_in_new_rounded, size: 16),
            label: Text(isVi ? 'Mở Cài đặt' : 'Open Settings'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF0284C7),
            ),
          ),
        ],
      ),
    );
  }
}
