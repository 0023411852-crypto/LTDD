import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:daily_news_weather_portal/models/weather.dart';

class HourlyForecastSection extends StatelessWidget {
  final List<HourlyForecast> hourly;
  final bool isDay;

  const HourlyForecastSection({
    super.key,
    required this.hourly,
    required this.isDay,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isDay
                ? Colors.white.withOpacity(0.68)
                : const Color(0xFF1E293B).withOpacity(0.65),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isDay
                  ? Colors.white.withOpacity(0.85)
                  : Colors.white.withOpacity(0.15),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Icon(
                      Icons.schedule_rounded,
                      size: 18,
                      color: isDay
                          ? const Color(0xFF1D4ED8)
                          : const Color(0xFF818CF8),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Dự báo theo giờ',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: isDay ? const Color(0xFF0F172A) : Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 108,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  itemCount: hourly.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    final item = hourly[index];
                    final isCurrentHour =
                        now.day == item.time.day && now.hour == item.time.hour;
                    final timeLabel = isCurrentHour
                        ? 'Bây giờ'
                        : '${item.time.hour.toString().padLeft(2, '0')}:00';

                    return Container(
                      width: 66,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: isCurrentHour
                            ? (isDay
                                ? const Color(0xFF2563EB).withOpacity(0.15)
                                : const Color(0xFF6366F1).withOpacity(0.28))
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                        border: isCurrentHour
                            ? Border.all(
                                color: isDay
                                    ? const Color(0xFF2563EB)
                                    : const Color(0xFF818CF8),
                                width: 1.2,
                              )
                            : null,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Text(
                            timeLabel,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: isCurrentHour
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                              color: isCurrentHour
                                  ? (isDay
                                      ? const Color(0xFF1D4ED8)
                                      : const Color(0xFFA5B4FC))
                                  : (isDay
                                      ? const Color(0xFF475569)
                                      : Colors.white70),
                            ),
                          ),
                          Text(
                            item.icon,
                            style: const TextStyle(fontSize: 22),
                          ),
                          Text(
                            '${item.temperature.round()}°',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: isDay
                                  ? const Color(0xFF0F172A)
                                  : Colors.white,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
