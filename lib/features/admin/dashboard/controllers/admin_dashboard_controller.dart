import 'package:flutter/material.dart';
import '../../../../models/article.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../favorites/providers/favorites_provider.dart';
import '../../../news/providers/news_provider.dart';
import '../../../weather/providers/weather_provider.dart';

/// Controller xử lý nghiệp vụ và logic dữ liệu cho Dashboard Quản trị viên
class AdminDashboardController {
  final NewsProvider newsProvider;
  final AuthProvider authProvider;
  final FavoritesProvider favoritesProvider;
  final WeatherProvider weatherProvider;

  AdminDashboardController({
    required this.newsProvider,
    required this.authProvider,
    required this.favoritesProvider,
    required this.weatherProvider,
  });

  int get totalArticles => newsProvider.totalArticlesCount;
  int get totalCategories => newsProvider.categories.length;
  int get totalFavorites => favoritesProvider.favorites.length;
  int? get currentTemperature => weatherProvider.weather?.temperature.round();
  String get currentCity => weatherProvider.weather?.cityName ?? 'Hà Nội';

  String get adminDisplayName => authProvider.isAuthenticated
      ? authProvider.displayName
      : 'Admin (Chế độ khách)';

  String get adminEmail => authProvider.isAuthenticated
      ? authProvider.email
      : 'Chưa đăng nhập tài khoản Firebase';

  bool get isOnline => authProvider.isAuthenticated;

  List<Article> get allArticles => newsProvider.allArticles;

  /// Đếm số bài viết theo từng thứ trong tuần (1: T2 -> 7: CN)
  List<int> calculateWeeklyDistribution() {
    final counts = List<int>.filled(7, 0);
    for (final a in allArticles) {
      if (a.publishedAt != null) {
        final weekday = a.publishedAt!.weekday;
        if (weekday >= 1 && weekday <= 7) {
          counts[weekday - 1]++;
        }
      }
    }
    return counts;
  }
}
