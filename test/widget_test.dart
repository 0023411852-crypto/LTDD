import 'package:daily_news_weather_portal/features/auth/providers/auth_provider.dart';
import 'package:daily_news_weather_portal/features/favorites/providers/favorites_provider.dart';
import 'package:daily_news_weather_portal/features/navigation/presentation/main_nav_screen.dart';
import 'package:daily_news_weather_portal/features/navigation/providers/navigation_provider.dart';
import 'package:daily_news_weather_portal/features/news/providers/news_provider.dart';
import 'package:daily_news_weather_portal/features/notifications/providers/notifications_provider.dart';
import 'package:daily_news_weather_portal/features/settings/providers/settings_provider.dart';
import 'package:daily_news_weather_portal/features/settings/providers/theme_provider.dart';
import 'package:daily_news_weather_portal/features/weather/providers/weather_provider.dart';
import 'package:daily_news_weather_portal/models/article.dart';
import 'package:daily_news_weather_portal/models/weather.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Weather Model & Logic Tests', () {
    test('Weather code mapping', () {
      const w = Weather(
        cityName: 'Hà Nội',
        temperature: 28,
        feelsLike: 30,
        humidity: 70,
        windSpeed: 10,
        weatherCode: 0,
        daily: [],
      );
      expect(w.description, 'Trời quang');
      expect(w.icon, '☀️');
    });

    test('HourlyForecast creation', () {
      final h = HourlyForecast(
        time: DateTime(2026, 11, 15, 12, 0),
        temperature: 26.5,
        weatherCode: 1,
      );
      expect(h.icon, '🌤️');
      expect(h.temperature, 26.5);
    });
  });

  group('Article Model Tests', () {
    test('Article JSON serialization and deserialization', () {
      const article = Article(
        title: 'Tin tức tiêu điểm hôm nay',
        link: 'https://vnexpress.net/tin-tuc-1234.html',
        description: 'Mô tả bài viết thời sự.',
        imageUrl: 'https://example.com/img.jpg',
        source: 'VnExpress',
      );

      final json = article.toJson();
      final fromJson = Article.fromJson(json);

      expect(fromJson.title, article.title);
      expect(fromJson.link, article.link);
      expect(fromJson.source, article.source);
    });
  });

  group('FavoritesProvider Tests', () {
    test('Toggle and check favorites (Per-User Authenticated)', () async {
      final provider = FavoritesProvider();
      provider.updateUserContext(isAuthenticated: true, uid: 'test_user_123');

      const article = Article(
        title: 'Thử nghiệm lưu bài',
        link: 'https://vnexpress.net/bai-test',
        description: 'Mô tả',
        source: 'VnExpress',
      );

      expect(provider.isFavorite(article), isFalse);

      final added = await provider.toggleFavorite(article);
      expect(added, isTrue);
      expect(provider.isFavorite(article), isTrue);
      expect(provider.favorites.length, 1);

      final removed = await provider.toggleFavorite(article);
      expect(removed, isTrue);
      expect(provider.isFavorite(article), isFalse);
      expect(provider.favorites.isEmpty, isTrue);
    });

    test('Guest can save favorites and merge on login (Hướng B)', () async {
      final provider = FavoritesProvider();
      const articleGuest = Article(
        title: 'Bài của khách',
        link: 'https://vnexpress.net/guest-1',
        description: 'Mô tả',
        source: 'VnExpress',
      );
      final guestAdded = await provider.toggleFavorite(articleGuest);
      expect(guestAdded, isTrue);
      expect(provider.isFavorite(articleGuest), isTrue);

      // Khách đăng nhập -> Dữ liệu được giữ và merge lên user
      provider.updateUserContext(isAuthenticated: true, uid: 'user_merged_test');
      expect(provider.isFavorite(articleGuest), isTrue);
    });
  });

  group('Widget Navigation Test', () {
    testWidgets('MainNavScreen renders the four primary navigation tabs',
        (tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => ThemeProvider()),
            ChangeNotifierProvider(create: (_) => AuthProvider()),
            ChangeNotifierProvider(create: (_) => NewsProvider()),
            ChangeNotifierProvider(create: (_) => WeatherProvider()),
            ChangeNotifierProvider(create: (_) => FavoritesProvider()),
            ChangeNotifierProvider(create: (_) => NotificationsProvider()),
            ChangeNotifierProvider(create: (_) => NavigationProvider()),
            ChangeNotifierProvider(create: (_) => SettingsProvider()),
          ],
          child: const MaterialApp(
            home: MainNavScreen(),
          ),
        ),
      );

      // Verify bottom navigation bar destinations
      expect(find.text('Trang chủ'), findsOneWidget);
      expect(find.text('Tin tức'), findsOneWidget);
      expect(find.text('Thời tiết'), findsOneWidget);
      expect(find.text('Tài khoản'), findsOneWidget);
    });
  });
}
