import 'dart:convert';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import '../models/weather.dart';

class City {
  final String name;
  final double lat;
  final double lon;
  const City(this.name, this.lat, this.lon);

  Map<String, dynamic> toJson() => {
        'name': name,
        'lat': lat,
        'lon': lon,
      };

  factory City.fromJson(Map<String, dynamic> json) => City(
        json['name'] as String? ?? '',
        (json['lat'] as num?)?.toDouble() ?? 0.0,
        (json['lon'] as num?)?.toDouble() ?? 0.0,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is City &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          (lat - other.lat).abs() < 0.001 &&
          (lon - other.lon).abs() < 0.001;

  @override
  int get hashCode => name.hashCode ^ lat.hashCode ^ lon.hashCode;
}

/// Abstract contract for Clean Architecture / Dependency Inversion
abstract class IWeatherService {
  Future<Weather> fetchWeather(City city, {bool forceRefresh = false});
  Future<City> getCurrentLocation();
  Future<List<City>> searchCities(String query);
}

/// Weather Service: Open-Meteo REST Client with Reverse Geocoding & Vietnam-only Geocoding
class WeatherService implements IWeatherService {
  /// Danh sách các tỉnh / thành phố và đặc khu biển đảo tiêu biểu của Việt Nam
  static const cities = <City>[
    City('Hà Nội', 21.0285, 105.8542),
    City('TP. Hồ Chí Minh', 10.8231, 106.6297),
    City('Đà Nẵng', 16.0471, 108.2062),
    City('Quần đảo Hoàng Sa (Đà Nẵng)', 16.5333, 111.6667),
    City('Quần đảo Trường Sa (Khánh Hòa)', 8.6439, 111.9192),
    City('Hải Phòng', 20.8449, 106.6881),
    City('Cần Thơ', 10.0452, 105.7469),
    City('Huế', 16.4637, 107.5909),
    City('Nha Trang', 12.2388, 109.1967),
    City('Đà Lạt', 11.9404, 108.4583),
    City('Đặc khu Phú Quốc (Kiên Giang)', 10.2899, 103.9840),
    City('Côn Đảo (Bà Rịa - Vũng Tàu)', 8.6835, 106.6062),
    City('Quy Nhơn', 13.7820, 109.2197),
    City('Hạ Long', 20.9505, 107.0734),
    City('Vũng Tàu', 10.3460, 107.0843),
    City('Phan Thiết', 10.9274, 108.0984),
    City('Sa Pa', 22.3364, 103.8438),
    City('Buôn Ma Thuột', 12.6667, 108.0500),
    City('Pleiku', 13.9833, 108.0000),
    City('Biên Hòa', 10.9575, 106.8427),
  ];

  static const Duration _cacheTtl = Duration(minutes: 10);
  static const Duration _requestTimeout = Duration(seconds: 15);

  // In-memory cache by city key to optimize battery, network & avoid rate limits
  static final Map<String, (DateTime timestamp, Weather data)> _cache = {};

  @override
  Future<Weather> fetchWeather(City city, {bool forceRefresh = false}) async {
    final cacheKey = '${city.name}_${city.lat.toStringAsFixed(3)}_${city.lon.toStringAsFixed(3)}';
    final now = DateTime.now();
    final cached = _cache[cacheKey];

    if (!forceRefresh && cached != null && now.difference(cached.$1) < _cacheTtl) {
      return cached.$2;
    }

    final uri = Uri.parse(
      'https://api.open-meteo.com/v1/forecast'
      '?latitude=${city.lat}&longitude=${city.lon}'
      '&current=temperature_2m,relative_humidity_2m,apparent_temperature,weather_code,wind_speed_10m'
      '&hourly=temperature_2m,weather_code'
      '&daily=weather_code,temperature_2m_max,temperature_2m_min'
      '&timezone=Asia%2FBangkok&forecast_days=7',
    );

    try {
      final res = await http.get(uri).timeout(_requestTimeout);
      if (res.statusCode != 200) {
        throw Exception('Không tải được thời tiết (${res.statusCode})');
      }

      final weather = Weather.fromOpenMeteo(
        jsonDecode(res.body) as Map<String, dynamic>,
        city.name,
      );
      _cache[cacheKey] = (now, weather);
      return weather;
    } catch (e) {
      // Graceful fallback to cached data if network times out
      if (cached != null) {
        return cached.$2;
      }
      rethrow;
    }
  }

  @override
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
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 15),
      ),
    );

    // Xác định tên xã/phường/quận/huyện thực tế của người dùng qua Reverse Geocoding
    final locationName = await _reverseGeocode(position.latitude, position.longitude);
    return City(locationName, position.latitude, position.longitude);
  }

  /// Tra cứu ngược tọa độ GPS thành tên Xã/Phường, Quận/Huyện, Tỉnh/TP tại Việt Nam
  Future<String> _reverseGeocode(double lat, double lon) async {
    // 1. Thử BigDataCloud Reverse Geocoding API (chuẩn tiếng Việt miễn phí, nhanh, chính xác đến phường/xã)
    try {
      final uri = Uri.parse(
        'https://api.bigdatacloud.net/data/reverse-geocode-client?latitude=$lat&longitude=$lon&localityLanguage=vi',
      );
      final res = await http.get(uri).timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final locality = (data['locality'] as String? ?? '').trim(); // Phường / Xã
        final city = (data['city'] as String? ?? '').trim(); // Quận / Huyện / TP
        final subdivision = (data['principalSubdivision'] as String? ?? '').trim(); // Tỉnh / TP

        final parts = <String>[];
        if (locality.isNotEmpty && locality != city) parts.add(locality);
        if (city.isNotEmpty) parts.add(city);
        if (parts.isEmpty && subdivision.isNotEmpty) parts.add(subdivision);

        if (parts.isNotEmpty) {
          return parts.join(', ');
        }
      }
    } catch (_) {}

    // 2. Dự phòng: OpenStreetMap Nominatim Reverse Geocoding
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?lat=$lat&lon=$lon&format=json&accept-language=vi',
      );
      final res = await http.get(uri, headers: {
        'User-Agent': 'DailyNewsWeatherApp/1.0 (Vietnam Geolocation Service)',
      }).timeout(const Duration(seconds: 5));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final addr = data['address'] as Map<String, dynamic>?;
        if (addr != null) {
          final ward = (addr['suburb'] ?? addr['quarter'] ?? addr['village'] ?? addr['neighbourhood'] ?? '').toString().trim();
          final district = (addr['city_district'] ?? addr['district'] ?? addr['county'] ?? '').toString().trim();
          final cityOrState = (addr['city'] ?? addr['state'] ?? '').toString().trim();

          final parts = <String>[];
          if (ward.isNotEmpty) parts.add(ward);
          if (district.isNotEmpty && district != ward) parts.add(district);
          if (parts.isEmpty && cityOrState.isNotEmpty) parts.add(cityOrState);

          if (parts.isNotEmpty) {
            return parts.join(', ');
          }
        }
      }
    } catch (_) {}

    // 3. Dự phòng ngoại tuyến: Tìm tỉnh / thành phố gần nhất trong bán kính
    return _findNearestCityName(lat, lon);
  }

  String _findNearestCityName(double lat, double lon) {
    City? nearest;
    double minDistance = double.infinity;
    for (final c in cities) {
      final d = math.pow(c.lat - lat, 2) + math.pow(c.lon - lon, 2);
      if (d < minDistance) {
        minDistance = d.toDouble();
        nearest = c;
      }
    }
    if (nearest != null && minDistance < 1.5) {
      return nearest.name;
    }
    return 'Vị trí của bạn';
  }

  @override
  Future<List<City>> searchCities(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return const [];

    final normQuery = _removeDiacritics(trimmed.toLowerCase());

    // Tách bỏ tiền tố như "thời tiết ", "thời ", "dự báo ", "weather " nếu có để tìm địa danh
    final searchKey = normQuery
        .replaceFirst(
            RegExp(
                r'^(thoi\s*tiet\s*hom\s*nay|thoi\s*tiet\s*|thoi\s*|weather\s*|du\s*bao\s*thoi\s*tiet\s*|du\s*bao\s*)'),
            '')
        .trim();

    // Nếu người dùng nhập từ khóa chung như "thời", "thời tiết", "weather"...
    // Trả về ngay danh sách các thành phố & quần đảo tiêu biểu của Việt Nam
    if (searchKey.isEmpty ||
        normQuery == 'thoi' ||
        normQuery == 'thoi tiet' ||
        normQuery == 'thoi tiet hom nay' ||
        normQuery == 'weather' ||
        normQuery == 'du bao') {
      return List<City>.from(cities);
    }

    final List<City> combinedResults = [];
    final seenNames = <String>{};

    // Khớp trước tiên với danh sách tỉnh thành và Quần đảo Hoàng Sa, Trường Sa
    for (final c in cities) {
      final normCity = _removeDiacritics(c.name.toLowerCase());
      if ((normCity.contains(searchKey) || normCity.contains(normQuery)) &&
          seenNames.add(c.name)) {
        combinedResults.add(c);
      }
    }

    // 1. Tìm kiếm trên OpenStreetMap Nominatim giới hạn nghiêm ngặt tại Việt Nam (countrycodes=vn)
    // Giúp tìm chính xác từ cấp Xã/Phường, Quận/Huyện đến Tỉnh/Thành phố
    try {
      final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
        'q': trimmed,
        'countrycodes': 'vn',
        'format': 'json',
        'accept-language': 'vi',
        'addressdetails': '1',
        'limit': '10',
      });
      final res = await http.get(uri, headers: {
        'User-Agent': 'DailyNewsWeatherApp/1.0 (Vietnam Geolocation Service)',
      }).timeout(const Duration(seconds: 6));

      if (res.statusCode == 200) {
        final list = jsonDecode(res.body);
        if (list is List) {
          for (final item in list) {
            if (item is Map<String, dynamic>) {
              final addr = item['address'] as Map<String, dynamic>? ?? {};
              final countryCode = (addr['country_code'] ?? item['country_code'] ?? '').toString().toLowerCase();
              if (countryCode != 'vn' && countryCode.isNotEmpty) continue;

              final name = (item['name'] as String? ?? '').trim();
              final ward = (addr['suburb'] ?? addr['quarter'] ?? addr['village'] ?? '').toString().trim();
              final district = (addr['city_district'] ?? addr['district'] ?? '').toString().trim();
              final cityOrState = (addr['city'] ?? addr['state'] ?? '').toString().trim();

              final parts = <String>[];
              if (name.isNotEmpty) parts.add(name);
              if (ward.isNotEmpty && !parts.contains(ward)) parts.add(ward);
              if (district.isNotEmpty && !parts.contains(district)) parts.add(district);
              if (cityOrState.isNotEmpty && !parts.contains(cityOrState)) parts.add(cityOrState);

              final finalName = parts.take(2).join(', ');
              final lat = double.tryParse(item['lat']?.toString() ?? '') ?? 0.0;
              final lon = double.tryParse(item['lon']?.toString() ?? '') ?? 0.0;

              if (finalName.isNotEmpty && lat != 0.0 && lon != 0.0 && seenNames.add(finalName)) {
                combinedResults.add(City(finalName, lat, lon));
              }
            }
          }
        }
      }
    } catch (_) {}

    // 2. Tìm kiếm dự phòng trên Open-Meteo Geocoding lọc chặt chẽ chỉ lấy kết quả tại Việt Nam
    try {
      final uri = Uri.https('geocoding-api.open-meteo.com', '/v1/search', {
        'name': trimmed,
        'count': '20',
        'language': 'vi',
        'format': 'json',
      });

      final res = await http.get(uri).timeout(const Duration(seconds: 6));
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        final results = json['results'];
        if (results is List) {
          for (final item in results) {
            if (item is Map<String, dynamic>) {
              final countryCode = (item['country_code'] as String? ?? '').toUpperCase();
              final country = (item['country'] as String? ?? '').toLowerCase();

              // Giới hạn tuyệt đối chỉ lấy kết quả thuộc Việt Nam
              if (countryCode != 'VN' && !country.contains('việt nam') && !country.contains('vietnam')) {
                continue;
              }

              final city = _parseCityResult(item);
              if (city.name.isNotEmpty && seenNames.add(city.name)) {
                combinedResults.add(city);
              }
            }
          }
        }
      }
    } catch (_) {}

    // 3. Khớp với danh sách tỉnh thành Việt Nam có sẵn trong app nếu chưa có kết quả
    final lowerQuery = trimmed.toLowerCase();
    for (final c in cities) {
      if (c.name.toLowerCase().contains(lowerQuery) && seenNames.add(c.name)) {
        combinedResults.add(c);
      }
    }

    return combinedResults;
  }

  City _parseCityResult(Map<String, dynamic> result) {
    final name = result['name'] as String? ?? '';
    final admin1 = result['admin1'] as String?;
    final country = result['country'] as String?;
    final suffix = [admin1, country]
        .whereType<String>()
        .where((part) => part.isNotEmpty && part != name)
        .join(', ');

    return City(
      suffix.isEmpty ? name : '$name, $suffix',
      (result['latitude'] as num?)?.toDouble() ?? 0.0,
      (result['longitude'] as num?)?.toDouble() ?? 0.0,
    );
  }

  static String _removeDiacritics(String str) {
    const withDia = 'àáạảãâầấậẩẫăằắặẳẵèéẹẻẽêềếệểễìíịỉĩòóọỏõôồốộổỗơờớợởỡùúụủũưừứựửữỳýỵỷỹđ';
    const without = 'aaaaaaaaaaaaaaaaaeeeeeeeeeeeiiiiiooooooooooooooooouuuuuuuuuuuyyyyyd';
    var result = str.toLowerCase();
    for (int i = 0; i < withDia.length; i++) {
      result = result.replaceAll(withDia[i], without[i]);
    }
    return result;
  }

  static void clearCache() {
    _cache.clear();
  }
}
