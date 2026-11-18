import 'package:flutter/foundation.dart';

/// NavigationProvider quản lý trạng thái điều hướng chính của ứng dụng
/// (Bottom Navigation Bar, chuyển đổi tab giữa Trang chủ, Tin tức, Thời tiết, Tài khoản).
class NavigationProvider extends ChangeNotifier {
  int _currentIndex = 0;

  int get currentIndex => _currentIndex;

  /// Đặt tab điều hướng hiện tại
  void setIndex(int index) {
    if (_currentIndex == index) return;
    _currentIndex = index;
    notifyListeners();
  }

  /// Phím tắt chuyển đến Trang chủ (Tab 0)
  void toHome() => setIndex(0);

  /// Phím tắt chuyển đến Tin tức (Tab 1)
  void toNews() => setIndex(1);

  /// Phím tắt chuyển đến Thời tiết (Tab 2)
  void toWeather() => setIndex(2);

  /// Phím tắt chuyển đến Tài khoản / Cá nhân (Tab 3)
  void toProfile() => setIndex(3);
}
