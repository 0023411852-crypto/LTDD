import 'package:flutter/material.dart';
import '../../favorites/presentation/favorites_screen.dart';
import '../../home/presentation/home_screen.dart';
import '../../news/presentation/news_list_screen.dart';
import '../../profile/presentation/profile_screen.dart';
import '../../weather/presentation/weather_screen.dart';

class MainNavScreen extends StatefulWidget {
  const MainNavScreen({super.key});

  @override
  State<MainNavScreen> createState() => _MainNavScreenState();
}

class _MainNavScreenState extends State<MainNavScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final List<Widget> screens = [
      HomeScreen(
        onNavigateToNews: () => setState(() => _currentIndex = 1),
        onNavigateToWeather: () => setState(() => _currentIndex = 2),
        onNavigateToFavorites: () => setState(() => _currentIndex = 3),
      ),
      const NewsListScreen(),
      const WeatherScreen(),
      const FavoritesScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        backgroundColor: cs.surface,
        indicatorColor: cs.primaryContainer,
        elevation: 1,
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded, color: cs.primary),
            label: 'Trang chủ',
          ),
          NavigationDestination(
            icon: const Icon(Icons.article_outlined),
            selectedIcon: Icon(Icons.article_rounded, color: cs.primary),
            label: 'Tin tức',
          ),
          NavigationDestination(
            icon: const Icon(Icons.cloud_outlined),
            selectedIcon: Icon(Icons.cloud_rounded, color: cs.primary),
            label: 'Thời tiết',
          ),
          NavigationDestination(
            icon: const Icon(Icons.bookmark_outline_rounded),
            selectedIcon: Icon(Icons.bookmark_rounded, color: cs.primary),
            label: 'Đã lưu',
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded, color: cs.primary),
            label: 'Cá nhân',
          ),
        ],
      ),
    );
  }
}
