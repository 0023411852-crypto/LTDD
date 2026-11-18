import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
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
  static const Duration _timeout = Duration(seconds: 15);

  NotificationService({FirebaseDatabase? database}) : _database = database;

  DatabaseReference _notificationsRef(String uid) {
    return (_database ?? FirebaseDatabase.instance).ref('users/$uid/notifications');
  }

  @override
  Future<List<AppNotification>> fetch(String uid) async {
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
  }

  @override
  Future<void> markRead(String uid, String notificationId) {
    return _notificationsRef(uid)
        .child(notificationId)
        .update({'isRead': true})
        .timeout(_timeout);
  }

  @override
  Future<void> markAllRead(String uid, Iterable<String> ids) async {
    final updates = <String, dynamic>{};
    for (final id in ids) {
      updates['$id/isRead'] = true;
    }
    if (updates.isNotEmpty) {
      await _notificationsRef(uid).update(updates).timeout(_timeout);
    }
  }
}
