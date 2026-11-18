import '../../../notifications/providers/notifications_provider.dart';
import '../../../settings/providers/settings_provider.dart';
import '../../providers/admin_provider.dart';

/// Controller xử lý nghiệp vụ phát sóng thông báo ứng dụng
class AdminNotificationsController {
  final AdminProvider adminProvider;
  final NotificationsProvider notificationsProvider;
  final SettingsProvider settingsProvider;

  AdminNotificationsController({
    required this.adminProvider,
    required this.notificationsProvider,
    required this.settingsProvider,
  });

  String get selectedType => adminProvider.selectedNotifType;
  List<Map<String, dynamic>> get broadcastHistory =>
      adminProvider.broadcastNotifications;

  void setSelectedType(String type) {
    adminProvider.setSelectedNotifType(type);
  }

  bool broadcast({
    required String title,
    required String body,
    required String type,
  }) {
    if (title.trim().isEmpty || body.trim().isEmpty) return false;

    // 1. Lưu vào lịch sử Admin
    adminProvider.broadcastNotification(
      title: title.trim(),
      body: body.trim(),
      type: type,
    );

    // 2. Lưu vào NotificationsProvider của toàn bộ ứng dụng
    notificationsProvider.addNotification(
      title: title.trim(),
      body: body.trim(),
      type: type == 'Tin nóng' ? 'breaking' : 'news',
    );

    return true;
  }

  bool get isBreakingNewsAllowed => settingsProvider.breakingNewsNotif;
}
