import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:daily_news_weather_portal/models/weather.dart';
import 'package:daily_news_weather_portal/features/weather/presentation/widgets/animated_weather_visual.dart';

class HeroWeatherCard extends StatelessWidget {
  final Weather? weather;
  final bool isLoading;
  final bool isDay;

  const HeroWeatherCard({
    super.key,
    required this.weather,
    required this.isLoading,
    required this.isDay,
  });

  String _formatCurrentDate() {
    final now = DateTime.now();
    const days = [
      'Chủ Nhật',
      'Thứ Hai',
      'Thứ Ba',
      'Thứ Tư',
      'Thứ Năm',
      'Thứ Sáu',
      'Thứ Bảy'
    ];
    final dayStr = days[now.weekday % 7];
    return '$dayStr, ngày ${now.day} tháng ${now.month}';
  }

  String _getWeatherSmartAdvice(int? code, double? temp) {
    if (code == null) return 'Đang cập nhật chỉ số dự báo thời tiết...';
    if (const [95, 96, 99].contains(code)) {
      return 'Dự báo có dông bão sấm sét, hạn chế ra ngoài và chú ý trú ẩn an toàn!';
    }
    if (const [51, 53, 55, 61, 63, 65, 80, 81, 82].contains(code)) {
      return 'Có mưa rải rác, nhớ mang theo ô hoặc áo mưa khi di chuyển nhé!';
    }
    if (const [45, 48].contains(code)) {
      return 'Sương mù làm giảm tầm nhìn, chú ý giảm tốc độ khi lái xe buổi sớm!';
    }
    if (temp != null && temp >= 34) {
      return 'Nhiệt độ ngoài trời khá gay gắt, nhớ uống đủ nước và chống nắng kỹ!';
    }
    if (temp != null && temp <= 16) {
      return 'Thời tiết se lạnh, đừng quên mặc áo ấm khi ra ngoài!';
    }
    return 'Thời tiết ôn hòa dễ chịu, rất thích hợp cho các hoạt động ngoài trời!';
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
    final code = weather?.weatherCode;
    final cardGradients = _getCardGradients(code, isDay);
    final advice = _getWeatherSmartAdvice(code, weather?.temperature);

    final todayForecast = weather != null && weather!.daily.isNotEmpty
        ? weather!.daily.first
        : null;

    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: cardGradients,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: Colors.white.withOpacity(0.35),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: cardGradients.first.withOpacity(0.4),
                blurRadius: 26,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.near_me_rounded,
                              size: 17,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                weather?.cityName ?? 'Đang tải địa điểm...',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.4,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _formatCurrentDate(),
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.85),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.22),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.35)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isDay
                              ? Icons.wb_sunny_rounded
                              : Icons.nightlight_round,
                          size: 13,
                          color: isDay ? const Color(0xFFFDE047) : Colors.white,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          isDay ? 'BAN NGÀY' : 'BAN ĐÊM',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isLoading && weather == null)
                        const SizedBox(
                          height: 70,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 3.5,
                            ),
                          ),
                        )
                      else ...[
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              weather != null
                                  ? '${weather!.temperature.round()}'
                                  : '--',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 68,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -2.5,
                                height: 0.95,
                              ),
                            ),
                            const Text(
                              '°C',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          weather?.description ?? 'Đang kết nối...',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (todayForecast != null) ...[
                          const SizedBox(height: 3),
                          Text(
                            'Thấp ${todayForecast.tempMin.round()}° • Cao ${todayForecast.tempMax.round()}°',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.85),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ],
                  ),
                  AnimatedWeatherVisual(
                    weatherCode: code,
                    isDaytime: isDay,
                    size: 96,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.25)),
                ),
                child: Row(
                  children: [
                    const Text('💡', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        advice,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          height: 1.25,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
