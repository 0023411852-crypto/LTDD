import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../home/presentation/home_screen.dart';
import '../../news/presentation/news_list_screen.dart';
import '../../profile/presentation/profile_screen.dart';
import '../../weather/presentation/weather_screen.dart';
import '../providers/navigation_provider.dart';

class MainNavScreen extends StatefulWidget {
  const MainNavScreen({super.key});

  @override
  State<MainNavScreen> createState() => _MainNavScreenState();
}

class _MainNavScreenState extends State<MainNavScreen> {
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      HomeScreen(
        onNavigateToNews: () => context.read<NavigationProvider>().toNews(),
        onNavigateToWeather: () => context.read<NavigationProvider>().toWeather(),
      ),
      const NewsListScreen(),
      const WeatherScreen(),
      const ProfileScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final nav = context.watch<NavigationProvider>();
    final currentIndex = nav.currentIndex;
    final cs = Theme.of(context).colorScheme;
    const appMaxWidth = 560.0;

    final navigationBar = SafeArea(
      minimum: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      child: Center(
        heightFactor: 1.0,
        child: SizedBox(
          width: math.min(
            MediaQuery.sizeOf(context).width - 24,
            appMaxWidth,
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: cs.surface.withOpacity(0.94),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: cs.outlineVariant.withOpacity(0.7)),
              boxShadow: [
                BoxShadow(
                  color: cs.primary.withOpacity(0.13),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(26),
              child: NavigationBar(
                height: 68,
                selectedIndex: currentIndex,
                onDestinationSelected: (index) {
                  nav.setIndex(index);
                },
                backgroundColor: Colors.transparent,
                indicatorColor: cs.primaryContainer,
                elevation: 0,
                labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
                destinations: [
                  NavigationDestination(
                    icon: const Icon(Icons.home_outlined),
                    selectedIcon: Icon(Icons.home_rounded, color: cs.primary),
                    label: 'Trang chủ',
                  ),
                  NavigationDestination(
                    icon: const Icon(Icons.article_outlined),
                    selectedIcon:
                        Icon(Icons.article_rounded, color: cs.primary),
                    label: 'Tin tức',
                  ),
                  NavigationDestination(
                    icon: const Icon(Icons.cloud_outlined),
                    selectedIcon: Icon(Icons.cloud_rounded, color: cs.primary),
                    label: 'Thời tiết',
                  ),
                  NavigationDestination(
                    icon: const Icon(Icons.person_outline_rounded),
                    selectedIcon:
                        Icon(Icons.person_rounded, color: cs.primary),
                    label: 'Tài khoản',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      body: ColoredBox(
        color: cs.surfaceContainerLowest,
        child: Center(
          child: SizedBox(
            width: math.min(MediaQuery.sizeOf(context).width, appMaxWidth),
            height: double.infinity,
            child: IndexedStack(
              index: currentIndex,
              children: _screens,
            ),
          ),
        ),
      ),
      bottomNavigationBar: navigationBar,
    );
  }
}
