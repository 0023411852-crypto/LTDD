import 'package:firebase_database/firebase_database.dart';
import '../models/app_notification.dart';

class NotificationService {
  final FirebaseDatabase? _database;

  NotificationService({FirebaseDatabase? database}) : _database = database;

  DatabaseReference _notificationsRef(String uid) {
    return (_database ?? FirebaseDatabase.instance).ref('users/$uid/notifications');
  }

  Future<List<AppNotification>> fetch(String uid) async {
    final snapshot = await _notificationsRef(uid).get();
    if (!snapshot.exists || snapshot.value == null) return [];
    final value = snapshot.value;
    if (value is! Map) {
      throw const FormatException('Dữ liệu thông báo trên máy chủ không hợp lệ.');
    }

    final notifications = <AppNotification>[];
    for (final entry in value.entries) {
      if (entry.value is Map) {
        notifications.add(AppNotification.fromJson(
          entry.key.toString(),
          Map<String, dynamic>.from(entry.value as Map),
        ));
      }
    }
    notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return notifications;
  }

  Future<void> markRead(String uid, String notificationId) {
    return _notificationsRef(uid).child(notificationId).update({'isRead': true});
  }

  Future<void> markAllRead(String uid, Iterable<String> ids) async {
    final updates = <String, dynamic>{};
    for (final id in ids) {
      updates['$id/isRead'] = true;
    }
    if (updates.isNotEmpty) {
      await _notificationsRef(uid).update(updates);
    }
  }
}
