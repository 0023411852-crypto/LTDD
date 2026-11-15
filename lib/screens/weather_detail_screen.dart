import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/weather.dart';
import '../services/weather_service.dart';

class WeatherDetailScreen extends StatelessWidget {
  final Weather weather;
  const WeatherDetailScreen({super.key, required this.weather});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Thời tiết ${weather.cityName}')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: Theme.of(context).colorScheme.primaryContainer,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(children: [
                Text(weather.icon, style: const TextStyle(fontSize: 56)),
                Text('${weather.temperature.round()}°C',
                    style: Theme.of(context)
                        .textTheme
                        .displayMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
                Text(weather.description,
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(
                    'Cảm giác ${weather.feelsLike.round()}° • Độ ẩm ${weather.humidity}% • Gió ${weather.windSpeed.round()} km/h'),
              ]),
            ),
          ),
          const SizedBox(height: 20),
          Text('Dự báo 7 ngày',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...weather.daily.map((d) => ListTile(
                leading: Text(d.icon, style: const TextStyle(fontSize: 24)),
                title: Text(DateFormat('EEEE dd/MM', 'vi').format(d.date)),
                trailing: Text('${d.tempMin.round()}° / ${d.tempMax.round()}°',
                    style: const TextStyle(fontWeight: FontWeight.w600)),
              )),
          const SizedBox(height: 12),
          Text(
              'Nguồn: Open-Meteo (api.open-meteo.com) • Thành phố mẫu: ${WeatherService.cities.map((c) => c.name).join(', ')}',
              style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}
