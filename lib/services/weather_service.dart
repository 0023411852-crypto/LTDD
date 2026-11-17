import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
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
    City('Đà Lạt', 11.9404, 108.4583),
    City('Nha Trang', 12.2388, 109.1967),
    City('Cần Thơ', 10.0452, 105.7469),
    City('Hải Phòng', 20.8449, 106.6881),
    City('Huế', 16.4637, 107.5909),
    City('Sa Pa', 22.3364, 103.8438),
    City('Vũng Tàu', 10.3460, 107.0843),
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

  Future<City> getCurrentLocation() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const LocationServiceDisabledException();
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw PermissionDeniedException('Location permission denied');
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.medium,
        timeLimit: Duration(seconds: 15),
      ),
    );
    return City('Vị trí của bạn', position.latitude, position.longitude);
  }

  Future<List<City>> searchCities(String query) async {
    final uri = Uri.https('geocoding-api.open-meteo.com', '/v1/search', {
      'name': query,
      'count': '10',
      'language': 'vi',
      'format': 'json',
    });
    final res = await http.get(uri).timeout(const Duration(seconds: 10));
    if (res.statusCode != 200) {
      throw Exception('Không tìm được địa điểm (${res.statusCode})');
    }

    final json = jsonDecode(res.body) as Map<String, dynamic>;
    final results = (json['results'] as List<dynamic>? ?? const []);
    return results
        .map((item) {
          final result = item as Map<String, dynamic>;
          final name = result['name'] as String? ?? '';
          final admin1 = result['admin1'] as String?;
          final country = result['country'] as String?;
          final suffix = [admin1, country]
              .whereType<String>()
              .where((part) => part.isNotEmpty && part != name)
              .join(', ');
          return City(
            suffix.isEmpty ? name : '$name, $suffix',
            (result['latitude'] as num).toDouble(),
            (result['longitude'] as num).toDouble(),
          );
        })
        .where((city) => city.name.isNotEmpty)
        .toList();
  }
}
