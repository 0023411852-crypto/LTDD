import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:daily_news_weather_portal/models/weather.dart';
import 'package:daily_news_weather_portal/features/weather/presentation/widgets/animated_weather_visual.dart';
import 'package:daily_news_weather_portal/features/weather/providers/weather_provider.dart';

class HomeWeatherMiniCard extends StatelessWidget {
  final WeatherProvider weatherProvider;
  final VoidCallback? onTap;
  final void Function(BuildContext, WeatherProvider) onChooseCity;

  const HomeWeatherMiniCard({
    super.key,
    required this.weatherProvider,
    this.onTap,
    required this.onChooseCity,
  });

  bool get _isDaytime {
    final hour = DateTime.now().hour;
    return hour >= 6 && hour < 18;
  }

  List<Color> _getCardGradients(int? code, bool isDay) {
    if (!isDay) {
      return const [
        Color(0xFF1E1B4B),
        Color(0xFF312E81),
        Color(0xFF4338CA),
      ];
    }
    return switch (code) {
      0 || 1 || 2 => const [
          Color(0xFF1D4ED8),
          Color(0xFF2563EB),
          Color(0xFF38BDF8),
        ],
      3 || 45 || 48 => const [
          Color(0xFF334155),
          Color(0xFF475569),
          Color(0xFF64748B),
        ],
      51 || 53 || 55 || 61 || 63 || 65 || 80 || 81 || 82 => const [
          Color(0xFF0F766E),
          Color(0xFF0284C7),
          Color(0xFF38BDF8),
        ],
      95 || 96 || 99 => const [
          Color(0xFF1E1B4B),
          Color(0xFF4C1D95),
          Color(0xFF7C3AED),
        ],
      _ => const [
          Color(0xFF0284C7),
          Color(0xFF0EA5E9),
          Color(0xFF38BDF8),
        ],
    };
  }

  @override
  Widget build(BuildContext context) {
    final weather = weatherProvider.weather;
    final isLoading = weatherProvider.status == WeatherStatus.loading;
    final isDay = _isDaytime;
    final code = weather?.weatherCode;
    final cardGradients = _getCardGradients(code, isDay);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: cardGradients,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withOpacity(0.35),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: cardGradients.first.withOpacity(0.35),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      InkWell(
                        onTap: () => onChooseCity(context, weatherProvider),
                        borderRadius: BorderRadius.circular(8),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.location_on_rounded,
                              size: 16,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              weather?.cityName ?? weatherProvider.selectedCity.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              size: 18,
                              color: Colors.white70,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      if (isLoading && weather == null)
                        const SizedBox(
                          height: 38,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            ),
                          ),
                        )
                      else ...[
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              weather != null
                                  ? '${weather.temperature.round()}°'
                                  : '--',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 36,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -1,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              weather?.description ?? 'Đang tải...',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        if (weather != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Cảm giác ${weather.feelsLike.round()}°C  •  Gió ${weather.windSpeed.round()} km/h  •  Ẩm ${weather.humidity}%',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.85),
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                AnimatedWeatherVisual(
                  weatherCode: code,
                  isDaytime: isDay,
                  size: 64,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
