import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/weather_service.dart';
import '../providers/weather_provider.dart';

class WeatherScreen extends StatelessWidget {
  const WeatherScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final weatherProvider = context.watch<WeatherProvider>();
    final weather = weatherProvider.weather;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Thời tiết',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF0F172A)),
            tooltip: 'Làm mới',
            onPressed: () => weatherProvider.fetchWeather(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        color: const Color(0xFF1E60F2),
        onRefresh: () => weatherProvider.fetchWeather(),
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: [
            // Dropdown chọn địa điểm / thành phố
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<City>(
                  value: weatherProvider.selectedCity,
                  isExpanded: true,
                  icon: const Icon(Icons.location_on, color: Color(0xFF1E60F2)),
                  items: weatherProvider.cities.map((city) {
                    return DropdownMenuItem<City>(
                      value: city,
                      child: Text(
                        '📍 ${city.name}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (newCity) {
                    if (newCity != null) {
                      weatherProvider.selectCity(newCity);
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),

            // THẺ THỜI TIẾT CHÍNH (GRADIENT XANH DƯƠNG CHUẨN MOCKUP)
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2563EB), Color(0xFF60A5FA)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2563EB).withOpacity(0.32),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    '📍 ${weather?.cityName ?? weatherProvider.selectedCity.name}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    weather != null
                        ? 'Cảm giác như ${weather.feelsLike.round()}°C'
                        : 'Cảm giác như 30°C',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Nhiệt độ & Icon 3D
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildSunCloudLarge(),
                      const SizedBox(width: 16),
                      Text(
                        weather != null
                            ? '${weather.temperature.round()}°C'
                            : '28°C',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 48,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    weather?.description ?? 'Có mây',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Divider
                  Container(
                    height: 1,
                    color: Colors.white.withOpacity(0.25),
                  ),
                  const SizedBox(height: 16),

                  // 3 Thông số: Độ ẩm, Gió, Cảm giác nhiệt
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildWeatherParam(
                        icon: Icons.water_drop_rounded,
                        label: 'Độ ẩm',
                        value: '${weather?.humidity ?? 75}%',
                      ),
                      _buildWeatherParam(
                        icon: Icons.air_rounded,
                        label: 'Gió',
                        value: '${weather?.windSpeed.round() ?? 12} km/h',
                      ),
                      _buildWeatherParam(
                        icon: Icons.thermostat_rounded,
                        label: 'Cảm giác',
                        value: '${weather?.feelsLike.round() ?? 29}°C',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // TIÊU ĐỀ "DỰ BÁO 7 NGÀY"
            const Text(
              'Dự báo 7 ngày',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 12),

            // 7 Ngày dự báo (Từ API Open-Meteo hoặc fallback)
            if (weather != null && weather.daily.isNotEmpty) ...[
              ...weather.daily.take(7).map((d) {
                final dayLabel = _dayLabel(d.date);
                return _buildDailyForecastItem(
                  dayLabel,
                  d.icon,
                  _descFromCode(d.weatherCode),
                  '${d.tempMin.round()}°',
                  '${d.tempMax.round()}°',
                );
              }),
            ] else ...[
              _buildDailyForecastItem('Thứ 2', '☀️', 'Có nắng', '26°', '32°'),
              _buildDailyForecastItem('Thứ 3', '🌧️', 'Mưa rào', '25°', '29°'),
              _buildDailyForecastItem('Thứ 4', '⛅', 'Có mây', '26°', '31°'),
              _buildDailyForecastItem('Thứ 5', '🌦️', 'Mưa nhẹ', '25°', '30°'),
              _buildDailyForecastItem('Thứ 6', '☀️', 'Nắng đẹp', '27°', '33°'),
              _buildDailyForecastItem('Thứ 7', '⛅', 'Mây thay đổi', '26°', '32°'),
              _buildDailyForecastItem('Chủ nhật', '🌧️', 'Mưa dông', '24°', '28°'),
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
    const days = ['Chủ nhật', 'Thứ 2', 'Thứ 3', 'Thứ 4', 'Thứ 5', 'Thứ 6', 'Thứ 7'];
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
      _ => 'Có mây',
    };
  }

  Widget _buildSunCloudLarge() {
    return SizedBox(
      width: 60,
      height: 60,
      child: Stack(
        children: [
          Positioned(
            right: 4,
            top: 2,
            child: Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [Color(0xFFFFF176), Color(0xFFFF9800)],
                ),
              ),
            ),
          ),
          Positioned(
            left: 2,
            bottom: 2,
            child: Icon(
              Icons.cloud_rounded,
              color: Colors.white.withOpacity(0.95),
              size: 46,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherParam({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 22),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildDailyForecastItem(
    String day,
    String icon,
    String desc,
    String minTemp,
    String maxTemp,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.015),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 82,
            child: Text(
              day,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Color(0xFF0F172A),
              ),
            ),
          ),
          Text(icon, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              desc,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          Text(
            '$minTemp - $maxTemp',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Color(0xFF1E60F2),
            ),
          ),
        ],
      ),
    );
  }
}
