class Weather {
  final String cityName;
  final double temperature;
  final double feelsLike;
  final int humidity;
  final double windSpeed;
  final int weatherCode;
  final List<DailyForecast> daily;
  final List<HourlyForecast> hourly;

  const Weather({
    required this.cityName,
    required this.temperature,
    required this.feelsLike,
    required this.humidity,
    required this.windSpeed,
    required this.weatherCode,
    required this.daily,
    this.hourly = const [],
  });

  /// Mô tả + icon từ WMO weather code của Open-Meteo
  String get description => _codeInfo(weatherCode).$1;
  String get icon => _codeInfo(weatherCode).$2;

  static (String, String) _codeInfo(int code) {
    return switch (code) {
      0 => ('Trời quang', '☀️'),
      1 || 2 => ('Ít mây', '🌤️'),
      3 => ('Nhiều mây', '☁️'),
      45 || 48 => ('Sương mù', '🌫️'),
      51 || 53 || 55 => ('Mưa phùn', '🌦️'),
      61 || 63 || 65 => ('Mưa', '🌧️'),
      71 || 73 || 75 => ('Tuyết', '❄️'),
      80 || 81 || 82 => ('Mưa rào', '🌦️'),
      95 || 96 || 99 => ('Dông', '⛈️'),
      _ => ('--', '🌡️'),
    };
  }

  factory Weather.fromOpenMeteo(Map<String, dynamic> json, String cityName) {
    final current = json['current'] as Map<String, dynamic>;
    final dailyJson = json['daily'] as Map<String, dynamic>;
    final times = (dailyJson['time'] as List).cast<String>();
    final maxs = (dailyJson['temperature_2m_max'] as List).cast<num>();
    final mins = (dailyJson['temperature_2m_min'] as List).cast<num>();
    final codes = (dailyJson['weather_code'] as List).cast<num>();

    final List<HourlyForecast> hourlyList = [];
    if (json['hourly'] != null) {
      final hourlyJson = json['hourly'] as Map<String, dynamic>;
      final hTimes = (hourlyJson['time'] as List).cast<String>();
      final hTemps = (hourlyJson['temperature_2m'] as List).cast<num>();
      final hCodes = (hourlyJson['weather_code'] as List).cast<num>();
      // Chỉ lấy 24 giờ tiếp theo
      final count = hTimes.length > 24 ? 24 : hTimes.length;
      for (int i = 0; i < count; i++) {
        hourlyList.add(HourlyForecast(
          time: DateTime.parse(hTimes[i]),
          temperature: hTemps[i].toDouble(),
          weatherCode: hCodes[i].toInt(),
        ));
      }
    }

    return Weather(
      cityName: cityName,
      temperature: (current['temperature_2m'] as num).toDouble(),
      feelsLike: (current['apparent_temperature'] as num).toDouble(),
      humidity: (current['relative_humidity_2m'] as num).toInt(),
      windSpeed: (current['wind_speed_10m'] as num).toDouble(),
      weatherCode: (current['weather_code'] as num).toInt(),
      daily: List.generate(
        times.length,
        (i) => DailyForecast(
          date: DateTime.parse(times[i]),
          tempMax: maxs[i].toDouble(),
          tempMin: mins[i].toDouble(),
          weatherCode: codes[i].toInt(),
        ),
      ),
      hourly: hourlyList,
    );
  }
}

class HourlyForecast {
  final DateTime time;
  final double temperature;
  final int weatherCode;

  const HourlyForecast({
    required this.time,
    required this.temperature,
    required this.weatherCode,
  });

  String get icon => Weather._codeInfo(weatherCode).$2;
}

class DailyForecast {
  final DateTime date;
  final double tempMax;
  final double tempMin;
  final int weatherCode;
  const DailyForecast({
    required this.date,
    required this.tempMax,
    required this.tempMin,
    required this.weatherCode,
  });
  String get icon => Weather._codeInfo(weatherCode).$2;
}
