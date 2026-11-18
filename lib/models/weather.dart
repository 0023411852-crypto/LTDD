import 'dart:math' as math;

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

  /// Factory parser complying with Specmatic / Cohesion contract resilience
  factory Weather.fromOpenMeteo(Map<String, dynamic> json, String cityName) {
    final current = (json['current'] as Map<String, dynamic>?) ?? const {};
    final dailyJson = (json['daily'] as Map<String, dynamic>?) ?? const {};

    final rawTimes = dailyJson['time'] as List<dynamic>? ?? const [];
    final rawMaxs = dailyJson['temperature_2m_max'] as List<dynamic>? ?? const [];
    final rawMins = dailyJson['temperature_2m_min'] as List<dynamic>? ?? const [];
    final rawCodes = dailyJson['weather_code'] as List<dynamic>? ?? const [];

    final dailyCount = math.min(
      rawTimes.length,
      math.min(rawMaxs.length, math.min(rawMins.length, rawCodes.length)),
    );

    final List<DailyForecast> dailyList = [];
    for (int i = 0; i < dailyCount; i++) {
      final parsedDate = DateTime.tryParse(rawTimes[i]?.toString() ?? '');
      if (parsedDate != null) {
        dailyList.add(DailyForecast(
          date: parsedDate,
          tempMax: (rawMaxs[i] as num?)?.toDouble() ?? 0.0,
          tempMin: (rawMins[i] as num?)?.toDouble() ?? 0.0,
          weatherCode: (rawCodes[i] as num?)?.toInt() ?? 0,
        ));
      }
    }

    final List<HourlyForecast> hourlyList = [];
    if (json['hourly'] is Map<String, dynamic>) {
      final hourlyJson = json['hourly'] as Map<String, dynamic>;
      final hTimes = hourlyJson['time'] as List<dynamic>? ?? const [];
      final hTemps = hourlyJson['temperature_2m'] as List<dynamic>? ?? const [];
      final hCodes = hourlyJson['weather_code'] as List<dynamic>? ?? const [];

      final hourlyCount = math.min(
        math.min(hTimes.length, hTemps.length),
        math.min(hCodes.length, 24),
      );

      for (int i = 0; i < hourlyCount; i++) {
        final parsedTime = DateTime.tryParse(hTimes[i]?.toString() ?? '');
        if (parsedTime != null) {
          hourlyList.add(HourlyForecast(
            time: parsedTime,
            temperature: (hTemps[i] as num?)?.toDouble() ?? 0.0,
            weatherCode: (hCodes[i] as num?)?.toInt() ?? 0,
          ));
        }
      }
    }

    return Weather(
      cityName: cityName,
      temperature: (current['temperature_2m'] as num?)?.toDouble() ?? 0.0,
      feelsLike: (current['apparent_temperature'] as num?)?.toDouble() ?? 0.0,
      humidity: (current['relative_humidity_2m'] as num?)?.toInt() ?? 0,
      windSpeed: (current['wind_speed_10m'] as num?)?.toDouble() ?? 0.0,
      weatherCode: (current['weather_code'] as num?)?.toInt() ?? 0,
      daily: dailyList,
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
