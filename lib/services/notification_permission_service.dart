import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/widgets/app_confirmation_dialog.dart';

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
  static Future<bool> requestAndCheck(BuildContext context) async {
    final status = await Permission.notification.status;
    if (status.isGranted) return true;
    if (status.isPermanentlyDenied) {
      if (context.mounted) {
        await showSettingsDialog(context);
      }
      return false;
    }
    final req = await Permission.notification.request();
    if (req.isGranted) return true;
    if (req.isPermanentlyDenied) {
      if (context.mounted) {
        await showSettingsDialog(context);
      }
    }
    return false;
  }

  /// Mở màn hình Cài đặt ứng dụng của thiết bị
  static Future<bool> openSettings() async {
    return await openAppSettings();
  }

  /// Yêu cầu cấp quyền thông báo trực tiếp từ hệ thống điện thoại khi mở ứng dụng lần đầu
  static Future<void> promptOnFirstLaunch(BuildContext context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasPrompted = prefs.getBool(_keyPrompted) ?? false;
      if (hasPrompted) return;

      final status = await Permission.notification.status;
      if (status.isGranted) {
        await prefs.setBool(_keyPrompted, true);
        return;
      }

      // Đánh dấu đã từng xin quyền để không làm phiền người dùng liên tục
      await prefs.setBool(_keyPrompted, true);

      // Kích hoạt trực tiếp hộp thoại xin quyền chuẩn của hệ điều hành điện thoại (Android/iOS)
      await Permission.notification.request();
    } catch (e) {
      debugPrint('NotificationPermissionService.promptOnFirstLaunch error: $e');
    }
  }

  /// Hiển thị hộp thoại hướng dẫn người dùng mở Cài đặt thiết bị khi bị từ chối vĩnh viễn
  static Future<void> showSettingsDialog(BuildContext context) async {
    final confirmed = await showAppConfirmationDialog(
      context: context,
      type: AppConfirmationType.notification,
      icon: Icons.settings_suggest_rounded,
      title: 'Cấp quyền trong Cài đặt',
      description: 'Quyền thông báo hiện đang bị tắt trong cài đặt thiết bị của bạn. Để nhận được thông báo tin tức và cảnh báo thời tiết, vui lòng mở Cài đặt và bật "Cho phép thông báo".',
      confirmText: 'Mở Cài đặt',
      cancelText: 'Để sau',
    );
    if (confirmed == true) {
      await openAppSettings();
    }
  }
}
