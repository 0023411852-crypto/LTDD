import 'package:flutter/foundation.dart';

/// AdminProvider quản lý trạng thái của Bảng điều khiển Quản trị viên (Admin Panel),
/// bao gồm tab đang mở, tìm kiếm & bộ lọc tin tức, trạng thái duyệt bài,
/// phát sóng thông báo và các chỉ số thống kê.
class AdminProvider extends ChangeNotifier {
  // Tab hiện tại: 0: Dashboard, 1: Tin tức, 2: Danh mục, 3: Người dùng, 4: Gửi thông báo, 5: Báo cáo
  int _currentTab = 0;

  // Search & Filter
  String _newsSearchQuery = '';
  String _newsFilter = 'Tất cả'; // Tất cả, Đã duyệt, Chờ duyệt

  // Quản lý duyệt bài (dựa trên Title bài viết)
  final Set<String> _pendingArticleTitles = {};

  // Danh sách thông báo thực tế do Admin phát sóng trong phiên
  final List<Map<String, dynamic>> _broadcastNotifications = [];

  // Loại thông báo đang chọn
  String _selectedNotifType = 'Tin nóng';

  int get currentTab => _currentTab;
  String get newsSearchQuery => _newsSearchQuery;
  String get newsFilter => _newsFilter;
  Set<String> get pendingArticleTitles => _pendingArticleTitles;
  List<Map<String, dynamic>> get broadcastNotifications => _broadcastNotifications;
  String get selectedNotifType => _selectedNotifType;

  /// Đổi tab trang quản trị
  void setTab(int tab) {
    if (_currentTab == tab) return;
    _currentTab = tab;
    notifyListeners();
  }

  /// Cập nhật từ khóa tìm kiếm tin tức trong Admin
  void setNewsSearchQuery(String query) {
    _newsSearchQuery = query;
    notifyListeners();
  }

  /// Cập nhật bộ lọc trạng thái duyệt
  void setNewsFilter(String filter) {
    if (_newsFilter == filter) return;
    _newsFilter = filter;
    notifyListeners();
  }

  /// Đảo trạng thái duyệt bài (Đã duyệt <-> Chờ duyệt)
  void toggleApproval(String title) {
    if (_pendingArticleTitles.contains(title)) {
      _pendingArticleTitles.remove(title);
    } else {
      _pendingArticleTitles.add(title);
    }
    notifyListeners();
  }

  /// Đặt loại thông báo
  void setSelectedNotifType(String type) {
    if (_selectedNotifType == type) return;
    _selectedNotifType = type;
    notifyListeners();
  }

  /// Phát sóng thông báo trong phiên quản trị
  void broadcastNotification({
    required String title,
    required String body,
    String? type,
  }) {
    final effectiveType = type ?? _selectedNotifType;
    final now = DateTime.now();
    final notif = {
      'id': 'notif_${now.millisecondsSinceEpoch}',
      'title': title,
      'body': body,
      'type': effectiveType,
      'time': now,
      'sentTime': '${now.hour}:${now.minute < 10 ? '0' : ''}${now.minute}',
    };

    _broadcastNotifications.insert(0, notif);
    notifyListeners();
  }

  /// Xóa lịch sử thông báo đã phát sóng
  void clearBroadcasts() {
    _broadcastNotifications.clear();
    notifyListeners();
  }
}
