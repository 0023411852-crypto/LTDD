import 'package:flutter/material.dart';
import '../models/weather.dart';

class WeatherCard extends StatelessWidget {
  final Weather? weather;
  final bool loading;
  final VoidCallback? onTap;
  const WeatherCard(
      {super.key, required this.weather, this.loading = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.primaryContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: loading
              ? const SizedBox(
                  height: 72, child: Center(child: CircularProgressIndicator()))
              : weather == null
                  ? const SizedBox(
                      height: 72,
                      child: Center(
                          child: Text(
                              'Chưa tải được thời tiết — chạm để thử lại')))
                  : Row(
                      children: [
                        Text(weather!.icon,
                            style: const TextStyle(fontSize: 44)),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(weather!.cityName,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(fontWeight: FontWeight.bold)),
                              Text(
                                  '${weather!.description} • Độ ẩm ${weather!.humidity}% • Gió ${weather!.windSpeed.round()} km/h',
                                  style: Theme.of(context).textTheme.bodySmall),
                            ],
                          ),
                        ),
                        Text('${weather!.temperature.round()}°',
                            style: Theme.of(context)
                                .textTheme
                                .displaySmall
                                ?.copyWith(fontWeight: FontWeight.bold)),
                      ],
                    ),
        ),
      ),
    );
  }
}
