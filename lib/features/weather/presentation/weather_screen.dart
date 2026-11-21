import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:daily_news_weather_portal/features/favorites/providers/favorites_provider.dart';
import 'package:daily_news_weather_portal/features/weather/providers/weather_provider.dart';
import 'package:daily_news_weather_portal/features/weather/presentation/widgets/hero_weather_card.dart';
import 'package:daily_news_weather_portal/features/weather/presentation/widgets/hourly_forecast_section.dart';
import 'package:daily_news_weather_portal/features/weather/presentation/widgets/quick_city_selector.dart';
import 'package:daily_news_weather_portal/features/weather/presentation/widgets/seven_day_forecast_card.dart';
import 'package:daily_news_weather_portal/features/weather/presentation/widgets/weather_atmosphere_painter.dart';
import 'package:daily_news_weather_portal/features/weather/presentation/widgets/weather_location_search_dialog.dart';
import 'package:daily_news_weather_portal/features/weather/presentation/widgets/weather_metrics_grid.dart';

/// Màn hình Thời tiết cao cấp (Ultra-Premium Animated Weather Screen)
class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _ambientController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _ambientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _ambientController.repeat();
    } else {
      _ambientController.stop();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ambientController.dispose();
    super.dispose();
  }

  bool get _isDaytime {
    final hour = DateTime.now().hour;
    return hour >= 6 && hour < 18;
  }

  List<Color> _getSkyGradient(int? code, bool isDay) {
    if (!isDay) {
      return const [
        Color(0xFF090D1A),
        Color(0xFF0F172A),
        Color(0xFF1E1B4B),
      ];
    }
    return switch (code) {
      0 || 1 || 2 => const [
          Color(0xFF60A5FA),
          Color(0xFF93C5FD),
          Color(0xFFE0F2FE),
        ],
      3 || 45 || 48 => const [
          Color(0xFF64748B),
          Color(0xFF94A3B8),
          Color(0xFFE2E8F0),
        ],
      51 || 53 || 55 || 61 || 63 || 65 || 80 || 81 || 82 => const [
          Color(0xFF475569),
          Color(0xFF64748B),
          Color(0xFF94A3B8),
        ],
      95 || 96 || 99 => const [
          Color(0xFF312E81),
          Color(0xFF4338CA),
          Color(0xFF6366F1),
        ],
      _ => const [
          Color(0xFF38BDF8),
          Color(0xFFBAE6FD),
          Color(0xFFF0F9FF),
        ],
    };
  }

  @override
  Widget build(BuildContext context) {
    final weatherProvider = context.watch<WeatherProvider>();
    final weather = weatherProvider.weather;
    final cs = Theme.of(context).colorScheme;
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final isLoading = weatherProvider.status == WeatherStatus.loading;
    final hasError = weatherProvider.status == WeatherStatus.error;
    final isDay = _isDaytime;
    final code = weather?.weatherCode;
    final bgColors = _getSkyGradient(code, isDay);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text(
          'Thời Tiết',
          style: TextStyle(
            color: isDay ? const Color(0xFF0F172A) : Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 20,
            letterSpacing: -0.3,
          ),
        ),
        actions: [
          Consumer<FavoritesProvider>(
            builder: (context, fav, _) {
              final currentCity = weatherProvider.selectedCity;
              final isFav = fav.isFavoriteCity(currentCity);
              return IconButton(
                icon: Icon(
                  isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  color: isFav
                      ? const Color(0xFFEF4444)
                      : (isDay ? const Color(0xFF1E3A8A) : Colors.white),
                ),
                tooltip: isFav
                    ? 'Bỏ thích địa điểm này'
                    : 'Thêm vào địa điểm yêu thích',
                onPressed: () async {
                  final wasFav = fav.isFavoriteCity(currentCity);
                  final success = await fav.toggleFavoriteCity(currentCity, context: context);
                  if (!success || !context.mounted) return;
                  final messenger = ScaffoldMessenger.of(context);
                  messenger.clearSnackBars();
                  messenger.showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          Icon(
                            wasFav
                                ? Icons.heart_broken_rounded
                                : Icons.favorite_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              wasFav
                                  ? 'Đã bỏ thích ${currentCity.name}'
                                  : 'Đã lưu ${currentCity.name} vào Địa điểm yêu thích!',
                            ),
                          ),
                        ],
                      ),
                      backgroundColor: isFav
                          ? const Color(0xFF64748B)
                          : const Color(0xFFEF4444),
                      duration: const Duration(seconds: 2),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              );
            },
          ),
          IconButton(
            icon: Icon(
              Icons.my_location_rounded,
              color: isDay ? const Color(0xFF1E3A8A) : Colors.white,
            ),
            tooltip: 'Vị trí hiện tại (GPS)',
            onPressed: () => weatherProvider.useCurrentLocation(),
          ),
          IconButton(
            icon: Icon(
              Icons.search_rounded,
              color: isDay ? const Color(0xFF1E3A8A) : Colors.white,
            ),
            tooltip: 'Tìm kiếm địa điểm',
            onPressed: () => WeatherLocationSearchDialog.show(context, weatherProvider),
          ),
          IconButton(
            icon: Icon(
              Icons.refresh_rounded,
              color: isDay ? const Color(0xFF1E3A8A) : Colors.white,
            ),
            tooltip: 'Làm mới',
            onPressed: () => weatherProvider.fetchWeather(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          // 1. NỀN GRADIENT BẦU TRỜI CHUYỂN ĐỘNG THEO THỜI TIẾT
          Positioned.fill(
            child: RepaintBoundary(
              child: AnimatedBuilder(
                animation: _ambientController,
                builder: (context, _) {
                  final shift = math.sin(_ambientController.value * math.pi * 2) * 0.15;
                  return DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: bgColors,
                        begin: Alignment(-0.5 + shift, -1.0),
                        end: Alignment(0.5 - shift, 1.0),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // 2. CANVAS HIỆU ỨNG THỜI TIẾT
          Positioned.fill(
            child: IgnorePointer(
              child: RepaintBoundary(
                child: TickerMode(
                  enabled: !reduceMotion,
                  child: AnimatedBuilder(
                    animation: _ambientController,
                    builder: (context, _) {
                      return CustomPaint(
                        painter: WeatherAtmospherePainter(
                          progress: reduceMotion ? 0.5 : _ambientController.value,
                          code: code,
                          isDaytime: isDay,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),

          // 3. NỘI DUNG CHÍNH
          SafeArea(
            child: RefreshIndicator(
              color: cs.primary,
              backgroundColor: cs.surface,
              onRefresh: () => weatherProvider.fetchWeather(),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                children: [
                  QuickCitySelector(provider: weatherProvider, isDay: isDay),
                  const SizedBox(height: 14),

                  if (hasError && weather == null)
                    _buildErrorCard(context, weatherProvider, cs)
                  else ...[
                    HeroWeatherCard(
                      weather: weather,
                      isLoading: isLoading,
                      isDay: isDay,
                    ),
                    const SizedBox(height: 16),

                    if (weather != null && weather.hourly.isNotEmpty) ...[
                      HourlyForecastSection(hourly: weather.hourly, isDay: isDay),
                      const SizedBox(height: 16),
                    ],

                    if (weather != null) ...[
                      WeatherMetricsGrid(weather: weather, isDay: isDay),
                      const SizedBox(height: 16),
                    ],

                    SevenDayForecastCard(
                      weather: weather,
                      isLoading: isLoading,
                      isDay: isDay,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard(
    BuildContext context,
    WeatherProvider provider,
    ColorScheme cs,
  ) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: cs.errorContainer.withOpacity(0.9),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          Icon(Icons.cloud_off_rounded, size: 48, color: cs.error),
          const SizedBox(height: 12),
          Text(
            provider.errorMessage.isNotEmpty
                ? provider.errorMessage
                : 'Không thể kết nối đến máy chủ dự báo thời tiết.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: cs.onErrorContainer,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: () => provider.fetchWeather(),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Thử lại ngay'),
          ),
        ],
      ),
    );
  }
}
