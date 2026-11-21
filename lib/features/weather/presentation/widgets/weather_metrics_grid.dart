import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:daily_news_weather_portal/models/weather.dart';

class WeatherMetricsGrid extends StatelessWidget {
  final Weather weather;
  final bool isDay;

  const WeatherMetricsGrid({
    super.key,
    required this.weather,
    required this.isDay,
  });

  String _humidityDescriptor(int h) {
    if (h < 40) return 'Khô ráo';
    if (h <= 70) return 'Thoải mái';
    return 'Ẩm ướt cao';
  }

  String _windDescriptor(double speed) {
    if (speed < 12) return 'Gió êm dịu';
    if (speed < 28) return 'Gió vừa phải';
    return 'Gió mạnh, thận trọng';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMetricTile(
                isDay: isDay,
                icon: Icons.water_drop_rounded,
                iconColor: const Color(0xFF0284C7),
                title: 'Độ ẩm',
                value: '${weather.humidity}%',
                subtitle: _humidityDescriptor(weather.humidity),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricTile(
                isDay: isDay,
                icon: Icons.air_rounded,
                iconColor: const Color(0xFF0D9488),
                title: 'Tốc độ gió',
                value: '${weather.windSpeed.round()} km/h',
                subtitle: _windDescriptor(weather.windSpeed),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMetricTile(
                isDay: isDay,
                icon: Icons.thermostat_rounded,
                iconColor: const Color(0xFFEA580C),
                title: 'Cảm giác như',
                value: '${weather.feelsLike.round()}°C',
                subtitle: weather.feelsLike > weather.temperature
                    ? 'Nóng hơn thực tế'
                    : 'Dịu mát hơn',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricTile(
                isDay: isDay,
                icon: Icons.wb_twilight_rounded,
                iconColor: const Color(0xFF7C3AED),
                title: 'Tình trạng',
                value: weather.description,
                subtitle: isDay ? 'Đang ban ngày' : 'Đang về đêm',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricTile({
    required bool isDay,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    required String subtitle,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDay
                ? Colors.white.withOpacity(0.68)
                : const Color(0xFF1E293B).withOpacity(0.65),
            borderRadius: BorderRadius.circular(20),
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
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: iconColor.withOpacity(0.14),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, size: 18, color: iconColor),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: isDay
                          ? const Color(0xFF64748B)
                          : const Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                value,
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: isDay ? const Color(0xFF0F172A) : Colors.white,
                  letterSpacing: -0.5,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  color: isDay
                      ? const Color(0xFF64748B)
                      : const Color(0xFFCBD5E1),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
