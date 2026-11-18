import 'package:flutter/foundation.dart';
import '../../news/providers/news_provider.dart';
import '../../weather/providers/weather_provider.dart';

/// HomeProvider quản lý trạng thái của màn hình Trang chủ (HomeScreen)
/// bao gồm chỉ số carousel tin nổi bật, trạng thái làm mới dữ liệu và điều phối các tác vụ.
class HomeProvider extends ChangeNotifier {
  int _currentFeaturedPage = 0;
  bool _isRefreshing = false;

  int get currentFeaturedPage => _currentFeaturedPage;
  bool get isRefreshing => _isRefreshing;

  /// Cập nhật trang hiện tại của Featured News Carousel
  void setFeaturedPage(int page) {
    if (_currentFeaturedPage == page) return;
    _currentFeaturedPage = page;
    notifyListeners();
  }

  /// Làm mới đồng thời dữ liệu Tin tức và Thời tiết trên Trang chủ
  Future<void> refreshDashboard({
    required NewsProvider newsProvider,
    required WeatherProvider weatherProvider,
  }) async {
    if (_isRefreshing) return;
    _isRefreshing = true;
    notifyListeners();

    try {
      await Future.wait([
        newsProvider.fetchNews(forceRefresh: true),
        weatherProvider.fetchWeather(forceRefresh: true),
      ]);
    } catch (e) {
      debugPrint('HomeProvider.refreshDashboard error: $e');
    } finally {
      _isRefreshing = false;
      notifyListeners();
    }
  }
}
