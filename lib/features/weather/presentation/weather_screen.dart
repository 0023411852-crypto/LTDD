import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/weather_service.dart';
import '../providers/weather_provider.dart';

class WeatherScreen extends StatelessWidget {
  const WeatherScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final wp = context.watch<WeatherProvider>();
    final weather = wp.weather;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thời tiết'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Làm mới',
            onPressed: () => wp.fetchWeather(),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => wp.fetchWeather(),
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: [
            // ── City selector ─────────────────────────────────────────
            DropdownButtonHideUnderline(
              child: DropdownButton<City>(
                value: wp.selectedCity,
                isExpanded: true,
                icon: Icon(Icons.keyboard_arrow_down_rounded,
                    color: cs.primary),
                selectedItemBuilder: (_) => wp.cities
                    .map((c) => Row(
                          children: [
                            Icon(Icons.location_on_outlined,
                                size: 18, color: cs.primary),
                            const SizedBox(width: 6),
                            Text(c.name,
                                style: tt.bodyLarge?.copyWith(
                                    fontWeight: FontWeight.w600)),
                          ],
                        ))
                    .toList(),
                items: wp.cities
                    .map((c) => DropdownMenuItem<City>(
                          value: c,
                          child: Text(c.name),
                        ))
                    .toList(),
                onChanged: (c) {
                  if (c != null) wp.selectCity(c);
                },
              ),
            ),
            Divider(color: cs.outlineVariant),
            const SizedBox(height: 16),

            // ── Current conditions card ───────────────────────────────
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // Temp + icon
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          weather != null
                              ? '${weather.temperature.round()}'
                              : '--',
                          style: tt.displayLarge?.copyWith(
                            fontWeight: FontWeight.w200,
                            letterSpacing: -4,
                            height: 1,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            '°C',
                            style: tt.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w300,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      weather?.description ?? 'Có mây',
                      style: tt.titleMedium
                          ?.copyWith(color: cs.onSurfaceVariant),
                    ),
                    const SizedBox(height: 20),
                    // Stats row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _Stat(
                          icon: Icons.water_drop_outlined,
                          label: 'Độ ẩm',
                          value: '${weather?.humidity ?? '--'}%',
                        ),
                        _Stat(
                          icon: Icons.air_rounded,
                          label: 'Gió',
                          value:
                              '${weather?.windSpeed.round() ?? '--'} km/h',
                        ),
                        _Stat(
                          icon: Icons.thermostat_outlined,
                          label: 'Cảm giác',
                          value: weather != null
                              ? '${weather.feelsLike.round()}°'
                              : '--°',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ── Dự báo 7 ngày ─────────────────────────────────────────
            if (weather != null && weather.daily.isNotEmpty) ...[
              Text('Dự báo 7 ngày',
                  style: tt.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              ...weather.daily.take(7).map((d) {
                final dayLabel = _dayLabel(d.date);
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 80,
                            child: Text(dayLabel,
                                style: tt.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w500)),
                          ),
                          Text(d.icon,
                              style: const TextStyle(fontSize: 20)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _descFromCode(d.weatherCode),
                              style: TextStyle(
                                  fontSize: 13,
                                  color: cs.onSurfaceVariant),
                            ),
                          ),
                          Text(
                            '${d.tempMin.round()}° – ${d.tempMax.round()}°',
                            style: tt.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                    Divider(height: 1, color: cs.outlineVariant),
                  ],
                );
              }),
            ] else ...[
              // Hardcoded nhãn rõ ràng là tham chiếu, không phải dự báo thực
              Text('Dự báo 7 ngày',
                  style: tt.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline_rounded,
                        size: 16, color: cs.onSurfaceVariant),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Dữ liệu dự báo đang được tải từ Open-Meteo API.',
                        style: TextStyle(
                            fontSize: 12, color: cs.onSurfaceVariant),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  String _dayLabel(DateTime date) {
    final now = DateTime.now();
    final diff = date.difference(DateTime(now.year, now.month, now.day)).inDays;
    if (diff == 0) return 'Hôm nay';
    if (diff == 1) return 'Ngày mai';
    const days = [
      'CN', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7'
    ];
    return days[date.weekday % 7];
  }

  String _descFromCode(int code) {
    return switch (code) {
      0 => 'Trời quang',
      1 || 2 => 'Ít mây',
      3 => 'Nhiều mây',
      45 || 48 => 'Sương mù',
      51 || 53 || 55 => 'Mưa phùn',
      61 || 63 || 65 => 'Mưa',
      71 || 73 || 75 => 'Tuyết',
      80 || 81 || 82 => 'Mưa rào',
      95 || 96 || 99 => 'Dông',
      _ => '--',
    };
  }
}

class _Stat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _Stat(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        Icon(icon, size: 20, color: cs.primary),
        const SizedBox(height: 4),
        Text(label,
            style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
        const SizedBox(height: 2),
        Text(value,
            style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
