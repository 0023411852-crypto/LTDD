import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/weather.dart';

class City {
  final String name;
  final double lat;
  final double lon;
  const City(this.name, this.lat, this.lon);
}

/// Thời tiết: Open-Meteo - miễn phí, KHÔNG cần API key
/// Docs: https://open-meteo.com/
class WeatherService {
  static const cities = <City>[
    City('Hà Nội', 21.0285, 105.8542),
    City('TP. Hồ Chí Minh', 10.8231, 106.6297),
    City('Đà Nẵng', 16.0471, 108.2062),
    City('Cần Thơ', 10.0452, 105.7469),
    City('Hải Phòng', 20.8449, 106.6881),
    City('Huế', 16.4637, 107.5909),
  ];

  Future<Weather> fetchWeather(City city) async {
    final uri = Uri.parse(
      'https://api.open-meteo.com/v1/forecast'
      '?latitude=${city.lat}&longitude=${city.lon}'
      '&current=temperature_2m,relative_humidity_2m,apparent_temperature,weather_code,wind_speed_10m'
      '&hourly=temperature_2m,weather_code'
      '&daily=weather_code,temperature_2m_max,temperature_2m_min'
      '&timezone=Asia%2FBangkok&forecast_days=7',
    );
    final res = await http.get(uri).timeout(const Duration(seconds: 15));
    if (res.statusCode != 200) {
      throw Exception('Không tải được thời tiết (${res.statusCode})');
    }
    return Weather.fromOpenMeteo(
        jsonDecode(res.body) as Map<String, dynamic>, city.name);
  }
}
