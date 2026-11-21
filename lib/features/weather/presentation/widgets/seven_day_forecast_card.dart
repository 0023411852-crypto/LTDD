import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:daily_news_weather_portal/models/weather.dart';

class SevenDayForecastCard extends StatelessWidget {
  final Weather? weather;
  final bool isLoading;
  final bool isDay;

  const SevenDayForecastCard({
    super.key,
    required this.weather,
    required this.isLoading,
    required this.isDay,
  });

  String _dayLabel(DateTime date) {
    final now = DateTime.now();
    final diff = date.difference(DateTime(now.year, now.month, now.day)).inDays;
    if (diff == 0) return 'Hôm nay';
    if (diff == 1) return 'Ngày mai';
    const days = [
      'Chủ nhật',
      'Thứ 2',
      'Thứ 3',
      'Thứ 4',
      'Thứ 5',
      'Thứ 6',
      'Thứ 7'
    ];
    return days[date.weekday % 7];
  }

  @override
  Widget build(BuildContext context) {
    final dailyList = weather?.daily ?? const [];

    double weekMin = 100;
    double weekMax = -100;
    for (final d in dailyList) {
      if (d.tempMin < weekMin) weekMin = d.tempMin;
      if (d.tempMax > weekMax) weekMax = d.tempMax;
    }
    if (weekMin >= weekMax) {
      weekMin = 20;
      weekMax = 35;
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: isDay
                ? Colors.white.withOpacity(0.68)
                : const Color(0xFF1E293B).withOpacity(0.65),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDay
                  ? Colors.white.withOpacity(0.85)
                  : Colors.white.withOpacity(0.15),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.calendar_month_rounded,
                    size: 18,
                    color: isDay
                        ? const Color(0xFF1D4ED8)
                        : const Color(0xFF818CF8),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Dự báo 7 ngày tới',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: isDay ? const Color(0xFF0F172A) : Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (dailyList.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(
                      isLoading
                          ? 'Đang đồng bộ dự báo thời tiết...'
                          : 'Kéo xuống để cập nhật dữ liệu.',
                      style: TextStyle(
                        color: isDay ? Colors.black54 : Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ),
                )
              else
                ...dailyList.take(7).map((d) {
                  return _buildDailyForecastRow(
                    day: d,
                    weekMin: weekMin,
                    weekMax: weekMax,
                    isDay: isDay,
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDailyForecastRow({
    required DailyForecast day,
    required double weekMin,
    required double weekMax,
    required bool isDay,
  }) {
    final dayLabel = _dayLabel(day.date);
    final totalRange = (weekMax - weekMin).clamp(1.0, 100.0);
    final minPercent = ((day.tempMin - weekMin) / totalRange).clamp(0.0, 1.0);
    final maxPercent = ((day.tempMax - weekMin) / totalRange).clamp(0.0, 1.0);

    final textColor = isDay ? const Color(0xFF0F172A) : Colors.white;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          SizedBox(
            width: 76,
            child: Text(
              dayLabel,
              style: TextStyle(
                fontSize: 14,
                fontWeight:
                    dayLabel == 'Hôm nay' ? FontWeight.w800 : FontWeight.w600,
                color: dayLabel == 'Hôm nay'
                    ? (isDay
                        ? const Color(0xFF1D4ED8)
                        : const Color(0xFF818CF8))
                    : textColor,
              ),
            ),
          ),
          Text(day.icon, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 8),
          SizedBox(
            width: 32,
            child: Text(
              '${day.tempMin.round()}°',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: isDay ? const Color(0xFF64748B) : Colors.white70,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              height: 6,
              decoration: BoxDecoration(
                color: isDay
                    ? Colors.black.withOpacity(0.06)
                    : Colors.white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final barWidth = constraints.maxWidth;
                  final left = barWidth * minPercent;
                  final width = math.max(
                    12.0,
                    barWidth * (maxPercent - minPercent),
                  );

                  return Stack(
                    children: [
                      Positioned(
                        left: left,
                        width: width,
                        top: 0,
                        bottom: 0,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFF38BDF8),
                                Color(0xFFFBBF24),
                                Color(0xFFF97316),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 32,
            child: Text(
              '${day.tempMax.round()}°',
              textAlign: TextAlign.left,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
