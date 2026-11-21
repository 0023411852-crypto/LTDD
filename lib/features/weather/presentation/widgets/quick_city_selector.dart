import 'package:flutter/material.dart';
import 'package:daily_news_weather_portal/services/weather_service.dart';
import 'package:daily_news_weather_portal/features/weather/providers/weather_provider.dart';

class QuickCitySelector extends StatelessWidget {
  final WeatherProvider provider;
  final bool isDay;

  const QuickCitySelector({
    super.key,
    required this.provider,
    required this.isDay,
  });

  @override
  Widget build(BuildContext context) {
    final currentCity = provider.selectedCity;
    final textColor = isDay ? const Color(0xFF1E293B) : Colors.white;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 38,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: WeatherService.cities.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final city = WeatherService.cities[index];
              final isSelected = city.name == currentCity.name;

              return InkWell(
                onTap: () => provider.selectCity(city),
                borderRadius: BorderRadius.circular(20),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (isDay
                            ? const Color(0xFF2563EB)
                            : const Color(0xFF6366F1))
                        : (isDay
                            ? Colors.white.withOpacity(0.65)
                            : Colors.white.withOpacity(0.12)),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? Colors.transparent
                          : (isDay
                              ? Colors.white.withOpacity(0.9)
                              : Colors.white.withOpacity(0.2)),
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: (isDay
                                      ? const Color(0xFF2563EB)
                                      : const Color(0xFF6366F1))
                                  .withOpacity(0.35),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isSelected) ...[
                        const Icon(
                          Icons.location_on_rounded,
                          size: 14,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 4),
                      ],
                      Text(
                        city.name,
                        style: TextStyle(
                          color: isSelected ? Colors.white : textColor,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
