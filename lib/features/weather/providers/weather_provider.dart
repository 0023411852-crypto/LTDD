import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../../models/weather.dart';
import '../../../services/weather_service.dart';

enum WeatherStatus { initial, loading, success, error }

class WeatherProvider extends ChangeNotifier {
  final IWeatherService _service;

  WeatherStatus _status = WeatherStatus.initial;
  String _errorMessage = '';
  City _selectedCity = WeatherService.cities.first;
  Weather? _weather;
  bool _isUsingCurrentLocation = false;

  WeatherStatus get status => _status;
  String get errorMessage => _errorMessage;
  City get selectedCity => _selectedCity;
  Weather? get weather => _weather;
  bool get isUsingCurrentLocation => _isUsingCurrentLocation;
  List<City> get cities => [
        ...WeatherService.cities,
        if (!WeatherService.cities
            .any((city) => city.name == _selectedCity.name))
          _selectedCity,
      ];

  WeatherProvider({IWeatherService? service})
      : _service = service ?? WeatherService() {
    _loadInitialWeather();
  }

  Future<List<City>> searchCities(String query) {
    return _service.searchCities(query);
  }

  Future<void> selectCity(City city) async {
    if (_selectedCity.name == city.name && _status == WeatherStatus.success) {
      return;
    }
    _selectedCity = city;
    _isUsingCurrentLocation = false;
    _weather = null;
    await fetchWeather();
  }

  Future<void> useCurrentLocation() async {
    _status = WeatherStatus.loading;
    _errorMessage = '';
    notifyListeners();

    try {
      _selectedCity = await _service.getCurrentLocation();
      _isUsingCurrentLocation = true;
      final data = await _service.fetchWeather(_selectedCity);
      _weather = data;
      _status = WeatherStatus.success;
    } on LocationServiceDisabledException {
      _setLocationError('Vui lòng bật dịch vụ định vị trên thiết bị.');
    } on PermissionDeniedException {
      _setLocationError(
        'Bạn chưa cấp quyền vị trí. Có thể chọn thành phố thủ công.',
      );
    } on TimeoutException {
      _setLocationError(
        'Không lấy được vị trí hiện tại trong thời gian cho phép.',
      );
    } catch (e) {
      _errorMessage = _formatErrorMessage(e);
      _status = WeatherStatus.error;
    }
    notifyListeners();
  }

  Future<void> _loadInitialWeather() async {
    try {
      _selectedCity = await _service.getCurrentLocation();
      _isUsingCurrentLocation = true;
      final data = await _service.fetchWeather(_selectedCity);
      _weather = data;
      _status = WeatherStatus.success;
    } on LocationServiceDisabledException {
      await fetchWeather();
    } on PermissionDeniedException {
      await fetchWeather();
    } on TimeoutException {
      await fetchWeather();
    } catch (_) {
      await fetchWeather();
    }
    notifyListeners();
  }

  void _setLocationError(String message) {
    _errorMessage = message;
    _status = WeatherStatus.error;
  }

  Future<void> fetchWeather({bool forceRefresh = false}) async {
    _status = WeatherStatus.loading;
    _errorMessage = '';
    notifyListeners();

    try {
      final data = await _service.fetchWeather(_selectedCity, forceRefresh: forceRefresh);
      _weather = data;
      _status = WeatherStatus.success;
    } catch (e) {
      _errorMessage = _formatErrorMessage(e);
      _status = WeatherStatus.error;
    }
    notifyListeners();
  }

  String _formatErrorMessage(dynamic e) {
    final str = e.toString();
    if (str.contains('SocketException') ||
        str.contains('SocketFailed') ||
        str.contains('ClientException') ||
        str.contains('No address associated with hostname') ||
        str.contains('Failed host lookup') ||
        str.contains('errno = 7')) {
      return 'Không thể kết nối Internet. Vui lòng kiểm tra lại đường truyền mạng của bạn.';
    }
    if (str.contains('TimeoutException') || str.contains('timed out')) {
      return 'Kết nối máy chủ thời tiết quá thời gian chờ (Timeout). Vui lòng thử lại.';
    }
    return str.replaceAll('Exception: ', '');
  }
}
