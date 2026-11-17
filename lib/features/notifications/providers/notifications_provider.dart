import 'package:flutter/material.dart';
import '../../../models/app_notification.dart';
import '../../../services/notification_service.dart';

enum NotificationsStatus { initial, loading, success, error }

class NotificationsProvider extends ChangeNotifier {
  final NotificationService _service = NotificationService();
  List<AppNotification> _notifications = [];
  NotificationsStatus _status = NotificationsStatus.initial;
  String _errorMessage = '';
  String? _uid;

  List<AppNotification> get notifications => List.unmodifiable(_notifications);
  NotificationsStatus get status => _status;
  String get errorMessage => _errorMessage;
  int get unreadCount => _notifications.where((item) => !item.isRead).length;

  Future<void> load(String uid) async {
    _uid = uid;
    _status = NotificationsStatus.loading;
    _errorMessage = '';
    notifyListeners();
    try {
      _notifications = await _service.fetch(uid);
      _status = NotificationsStatus.success;
    } catch (error) {
      _status = NotificationsStatus.error;
      _errorMessage = error.toString().replaceFirst('Exception: ', '');
    }
    notifyListeners();
  }

  Future<void> markRead(AppNotification notification) async {
    final uid = _uid;
    if (uid == null || notification.isRead) return;
    await _service.markRead(uid, notification.id);
    final index = _notifications.indexWhere((item) => item.id == notification.id);
    if (index >= 0) {
      _notifications[index] = notification.copyWith(isRead: true);
      notifyListeners();
    }
  }

  Future<void> markAllRead() async {
    final uid = _uid;
    if (uid == null) return;
    await _service.markAllRead(
      uid,
      _notifications.where((item) => !item.isRead).map((item) => item.id),
    );
    _notifications = _notifications.map((item) => item.copyWith(isRead: true)).toList();
    notifyListeners();
  }
}
