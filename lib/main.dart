import 'dart:ui';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'features/admin/providers/admin_provider.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/favorites/providers/favorites_provider.dart';
import 'features/home/providers/home_provider.dart';
import 'features/navigation/presentation/splash_screen.dart';
import 'features/navigation/providers/navigation_provider.dart';
import 'features/news/providers/news_provider.dart';
import 'features/notifications/providers/notifications_provider.dart';
import 'features/profile/providers/profile_provider.dart';
import 'features/search/providers/search_provider.dart';
import 'features/settings/providers/settings_provider.dart';
import 'features/settings/providers/theme_provider.dart';
import 'features/weather/providers/weather_provider.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Full-Stack Audit & RepoGuard: Global Top-Level Error Boundaries
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('Uncaught Flutter Error: ${details.exceptionAsString()}');
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('Uncaught Platform Async Error: $error');
    return true; // Handled, prevent crash
  };

  // Safe cold-boot initialization with error tolerance
  await Future.wait([
    Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).catchError((e) {
      debugPrint('Firebase init warning (offline fallback active): $e');
      return Firebase.app(); // Graceful fallback
    }),
    initializeDateFormatting('vi', null).catchError((_) {}),
  ]);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => NewsProvider()),
        ChangeNotifierProvider(create: (_) => WeatherProvider()),
        ChangeNotifierProvider(create: (_) => FavoritesProvider()),
        ChangeNotifierProvider(create: (_) => NotificationsProvider()),
        ChangeNotifierProvider(create: (_) => NavigationProvider()),
        ChangeNotifierProvider(create: (_) => HomeProvider()),
        ChangeNotifierProvider(create: (_) => SearchProvider()),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
        ChangeNotifierProvider(create: (_) => AdminProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
      ],
      child: const DailyNewsApp(),
    ),
  );
}

class DailyNewsApp extends StatelessWidget {
  const DailyNewsApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return MaterialApp(
      title: 'Tin tức & Thời tiết',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.themeMode,
      home: const SplashScreen(),
    );
  }
}
