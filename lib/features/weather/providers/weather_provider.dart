import 'package:flutter/material.dart';
import '../../../models/weather.dart';
import '../../../services/weather_service.dart';

enum WeatherStatus { initial, loading, success, error }

class WeatherProvider extends ChangeNotifier {
  final WeatherService _service = WeatherService();

  WeatherStatus _status = WeatherStatus.initial;
  String _errorMessage = '';
  City _selectedCity = WeatherService.cities.first;
  Weather? _weather;

  WeatherStatus get status => _status;
  String get errorMessage => _errorMessage;
  City get selectedCity => _selectedCity;
  Weather? get weather => _weather;
  List<City> get cities => WeatherService.cities;

  WeatherProvider() {
    fetchWeather();
  }

  Future<void> selectCity(City city) async {
    if (_selectedCity.name == city.name && _status == WeatherStatus.success) {
      return;
    }
    _selectedCity = city;
    await fetchWeather();
  }

  Future<void> fetchWeather() async {
    _status = WeatherStatus.loading;
    _errorMessage = '';
    notifyListeners();

    try {
      final data = await _service.fetchWeather(_selectedCity);
      _weather = data;
      _status = WeatherStatus.success;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _status = WeatherStatus.error;
    }
    notifyListeners();
  }
}
