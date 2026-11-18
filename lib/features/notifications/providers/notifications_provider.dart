import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../models/app_notification.dart';
import '../../../services/notification_service.dart';

enum NotificationsStatus { initial, loading, success, error }

class NotificationsProvider extends ChangeNotifier {
  static const String _keyLocalNotifs = 'local_app_notifications';

  final INotificationService _service;
  List<AppNotification> _notifications = [];
  NotificationsStatus _status = NotificationsStatus.initial;
  String _errorMessage = '';
  String? _uid;

  NotificationsProvider({INotificationService? service})
      : _service = service ?? NotificationService() {
    _loadLocalNotifications();
  }

  List<AppNotification> get notifications => List.unmodifiable(_notifications);
  NotificationsStatus get status => _status;
  String get errorMessage => _errorMessage;
  int get unreadCount => _notifications.where((item) => !item.isRead).length;

  Future<void> _loadLocalNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedList = prefs.getStringList(_keyLocalNotifs);
      if (savedList != null && savedList.isNotEmpty) {
        final list = <AppNotification>[];
        for (final item in savedList) {
          try {
            final map = jsonDecode(item) as Map<String, dynamic>;
            final id = map['id'] as String? ?? 'notif_${DateTime.now().millisecondsSinceEpoch}';
            list.add(AppNotification.fromJson(id, map));
          } catch (_) {}
        }
        if (list.isNotEmpty) {
          _notifications = list;
          _status = NotificationsStatus.success;
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('NotificationsProvider._loadLocalNotifications error: $e');
    }
  }

  Future<void> _saveLocalNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stringList = _notifications
          .map((n) => jsonEncode({
                'id': n.id,
                ...n.toJson(),
              }))
          .toList();
      await prefs.setStringList(_keyLocalNotifs, stringList);
    } catch (e) {
      debugPrint('NotificationsProvider._saveLocalNotifications error: $e');
    }
  }

  Future<void> addNotification({
    required String title,
    required String body,
    String type = 'news',
  }) async {
    final now = DateTime.now();
    final newNotif = AppNotification(
      id: 'notif_${now.millisecondsSinceEpoch}',
      title: title,
      body: body,
      type: type,
      createdAt: now,
      isRead: false,
    );

    _notifications = [newNotif, ..._notifications];
    notifyListeners();
    await _saveLocalNotifications();
  }

  Future<void> load(String uid) async {
    _uid = uid;
    _status = NotificationsStatus.loading;
    _errorMessage = '';
    notifyListeners();
    try {
      final remoteList = await _service.fetch(uid);
      final existingIds = _notifications.map((n) => n.id).toSet();
      final merged = List<AppNotification>.from(_notifications);
      for (final n in remoteList) {
        if (existingIds.add(n.id)) {
          merged.add(n);
        }
      }
      merged.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      _notifications = merged;
      _status = NotificationsStatus.success;
    } catch (error) {
      _status = NotificationsStatus.error;
      _errorMessage = error.toString().replaceFirst('Exception: ', '');
    }
    notifyListeners();
  }

  Future<void> markRead(AppNotification notification) async {
    final uid = _uid;
    if (uid != null && !notification.isRead) {
      await _service.markRead(uid, notification.id).catchError((_) {});
    }
    final index = _notifications.indexWhere((item) => item.id == notification.id);
    if (index >= 0) {
      _notifications[index] = notification.copyWith(isRead: true);
      notifyListeners();
      await _saveLocalNotifications();
    }
  }

  Future<void> markAllRead() async {
    final uid = _uid;
    if (uid != null) {
      await _service.markAllRead(
        uid,
        _notifications.where((item) => !item.isRead).map((item) => item.id),
      ).catchError((_) {});
    }
    _notifications = _notifications.map((item) => item.copyWith(isRead: true)).toList();
    notifyListeners();
    await _saveLocalNotifications();
  }
}
