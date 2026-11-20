import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import '../models/app_notification.dart';

/// Abstract contract for Clean Architecture / Dependency Inversion
abstract class INotificationService {
  Future<List<AppNotification>> fetch(String uid);
  Future<void> markRead(String uid, String notificationId);
  Future<void> markAllRead(String uid, Iterable<String> ids);
}

/// Firebase Realtime Database Service for notifications with timeouts & safe parsing
class NotificationService implements INotificationService {
  final FirebaseDatabase? _database;
  final FirebaseAuth? _auth;
  static const Duration _timeout = Duration(seconds: 10);

  NotificationService({FirebaseDatabase? database, FirebaseAuth? auth})
      : _database = database,
        _auth = auth;

  DatabaseReference _notificationsRef(String uid) {
    return (_database ?? FirebaseDatabase.instance).ref('users/$uid/notifications');
  }

  bool _isCloudSyncAvailable(String uid) {
    try {
      final currentAuth = _auth ?? FirebaseAuth.instance;
      final currentUser = currentAuth.currentUser;
      // Chỉ đồng bộ Firebase khi đã đăng nhập tài khoản Firebase Auth thực tế và trùng UID
      return currentUser != null && currentUser.uid == uid;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<List<AppNotification>> fetch(String uid) async {
    // Nếu là phiên nội bộ / admin_root_sys / khách hoặc chưa có session Firebase Auth thực tế
    if (!_isCloudSyncAvailable(uid)) {
      return [];
    }

    try {
      final snapshot = await _notificationsRef(uid).get().timeout(_timeout);
      if (!snapshot.exists || snapshot.value == null) return [];
      final value = snapshot.value;
      if (value is! Map) {
        return [];
      }

      final notifications = <AppNotification>[];
      for (final entry in value.entries) {
        if (entry.value is Map) {
          try {
            notifications.add(AppNotification.fromJson(
              entry.key.toString(),
              Map<String, dynamic>.from(entry.value as Map),
            ));
          } catch (_) {
            // Skip corrupted notification records
          }
        }
      }
      notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return notifications;
    } catch (e) {
      debugPrint('NotificationService.fetch warning: $e');
      // Trả về danh sách rỗng để NotificationsProvider sử dụng dữ liệu cục bộ (Local Storage)
      return [];
    }
  }

  @override
  Future<void> markRead(String uid, String notificationId) async {
    if (!_isCloudSyncAvailable(uid)) return;
    try {
      await _notificationsRef(uid)
          .child(notificationId)
          .update({'isRead': true})
          .timeout(_timeout);
    } catch (e) {
      debugPrint('NotificationService.markRead warning: $e');
    }
  }

  @override
  Future<void> markAllRead(String uid, Iterable<String> ids) async {
    if (!_isCloudSyncAvailable(uid)) return;
    try {
      final updates = <String, dynamic>{};
      for (final id in ids) {
        updates['$id/isRead'] = true;
      }
      if (updates.isNotEmpty) {
        await _notificationsRef(uid).update(updates).timeout(_timeout);
      }
    } catch (e) {
      debugPrint('NotificationService.markAllRead warning: $e');
    }
  }
}
