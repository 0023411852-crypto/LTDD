import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../models/article.dart';
import '../../../models/weather.dart';
import '../../../services/weather_service.dart';
import '../../news/providers/news_provider.dart';
import '../../weather/providers/weather_provider.dart';

/// SearchProvider quản lý trạng thái tìm kiếm (từ khóa, lịch sử tìm kiếm,
/// kết quả bài viết tin tức, kết quả thành phố & thời tiết tương ứng).
class SearchProvider extends ChangeNotifier {
  final WeatherService _weatherService = WeatherService();

  List<String> _history = [];
  List<Article> _searchResults = [];
  List<City> _matchingCities = [];
  City? _selectedPreviewCity;
  Weather? _previewWeather;
  bool _isLoadingNews = false;
  bool _isLoadingWeather = false;
  bool _hasSearched = false;
  String _currentQuery = '';
  String _activeFilter = 'Tất cả'; // 'Tất cả', 'Tin tức', 'Thời tiết'

  final List<String> _trendingTopics = const [
    'Thời tiết hôm nay',
    'Hoàng Sa & Trường Sa',
    'Bóng đá',
    'Công nghệ AI',
    'Kinh tế',
    'Giao thông',
    'Giáo dục',
  ];

  List<String> get history => _history;
  List<Article> get searchResults => _searchResults;
  List<City> get matchingCities => _matchingCities;
  City? get selectedPreviewCity => _selectedPreviewCity;
  Weather? get previewWeather => _previewWeather;
  bool get isLoadingNews => _isLoadingNews;
  bool get isLoadingWeather => _isLoadingWeather;
  bool get hasSearched => _hasSearched;
  String get currentQuery => _currentQuery;
  String get activeFilter => _activeFilter;
  List<String> get trendingTopics => _trendingTopics;

  SearchProvider() {
    loadHistory();
  }

  void setActiveFilter(String filter) {
    if (_activeFilter == filter) return;
    _activeFilter = filter;
    notifyListeners();
  }

  /// Tải lịch sử tìm kiếm từ SharedPreferences
  Future<void> loadHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _history = prefs.getStringList('search_history') ??
          ['thời tiết', 'Hoàng Sa', 'Trường Sa', 'tin thể thao'];
      notifyListeners();
    } catch (e) {
      debugPrint('SearchProvider.loadHistory error: $e');
    }
  }

  /// Lưu truy vấn vào lịch sử
  Future<void> saveHistory(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;
    _history.remove(trimmed);
    _history.insert(0, trimmed);
    if (_history.length > 8) _history = _history.sublist(0, 8);
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('search_history', _history);
    } catch (e) {
      debugPrint('SearchProvider.saveHistory error: $e');
    }
  }

  /// Xóa sạch lịch sử tìm kiếm
  Future<void> clearHistory() async {
    _history.clear();
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('search_history');
    } catch (e) {
      debugPrint('SearchProvider.clearHistory error: $e');
    }
  }

  /// Tải thời tiết xem trước cho thành phố cụ thể
  Future<void> loadWeatherForCity(City city) async {
    _selectedPreviewCity = city;
    _isLoadingWeather = true;
    notifyListeners();

    try {
      final weather = await _weatherService.fetchWeather(city);
      _previewWeather = weather;
    } catch (e) {
      debugPrint('SearchProvider.loadWeatherForCity error: $e');
    } finally {
      _isLoadingWeather = false;
      notifyListeners();
    }
  }

  /// Kiểm tra xem từ khóa có chủ ý tìm kiếm thời tiết hoặc địa danh hay không
  bool _isLocationOrWeatherQuery(String query) {
    final lower = query.toLowerCase().trim();

    // 1. Từ khóa thời tiết rõ ràng
    const weatherKeywords = [
      'thời tiết', 'thoi tiet', 'weather', 'nhiệt độ', 'nhiet do',
      'dự báo', 'du bao', 'mưa', 'nắng', 'bão', 'áp thấp', 'lốc',
      'độ ẩm', 'không khí', 'gió', 'uv', 'rét', 'lạnh', 'nóng'
    ];
    for (final kw in weatherKeywords) {
      if (lower.contains(kw)) return true;
    }

    // 2. Danh sách địa danh / tỉnh thành / biển đảo tiêu biểu của Việt Nam
    const locationKeywords = [
      'hà nội', 'ha noi', 'hồ chí minh', 'sài gòn', 'saigon', 'tp hcm', 'tphcm',
      'đà nẵng', 'da nang', 'hoàng sa', 'hoang sa', 'trường sa', 'truong sa',
      'hải phòng', 'hai phong', 'cần thơ', 'can tho', 'huế', 'hue',
      'nha trang', 'đà lạt', 'da lat', 'phú quốc', 'phu quoc',
      'côn đảo', 'con dao', 'quy nhơn', 'hạ long', 'vũng tàu',
      'phan thiết', 'sa pa', 'sapa', 'buôn ma thuột', 'pleiku',
      'quảng ninh', 'bắc ninh', 'thanh hóa', 'nghệ an', 'hà tĩnh',
      'quảng bình', 'quảng trị', 'quảng nam', 'quảng ngãi', 'bình định',
      'phú yên', 'khánh hòa', 'ninh thuận', 'bình thuận', 'kon tum',
      'gia lai', 'đắk lắk', 'đắk nông', 'lâm đồng', 'bình phước',
      'tây ninh', 'bình dương', 'đồng nai', 'bà rịa', 'long an',
      'tiền giang', 'bến tre', 'trà vinh', 'vĩnh long', 'đồng tháp',
      'an giang', 'kiên giang', 'hậu giang', 'sóc trăng', 'bạc liêu',
      'cà mau', 'tuyên quang', 'lào cai', 'yên bái', 'thái nguyên',
      'lạng sơn', 'bắc kạn', 'cao bằng', 'hà giang', 'sơn la',
      'điện biên', 'lai châu', 'hòa bình', 'vĩnh phúc', 'phú thọ',
      'hải dương', 'hưng yên', 'thái bình', 'hà nam', 'nam định',
      'ninh bình'
    ];
    for (final loc in locationKeywords) {
      if (lower == loc || lower.startsWith('$loc ') || lower.endsWith(' $loc')) {
        return true;
      }
    }
    return false;
  }

  /// Thực hiện tìm kiếm tổng hợp: Tin tức + Thời tiết / Địa điểm
  Future<void> performSearch({
    required String query,
    required NewsProvider newsProvider,
    required WeatherProvider weatherProvider,
  }) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;

    _currentQuery = trimmed;
    _activeFilter = 'Tất cả';
    saveHistory(trimmed);

    _hasSearched = true;
    _isLoadingNews = true;
    _matchingCities = [];
    _previewWeather = null;
    _selectedPreviewCity = null;
    notifyListeners();

    // 1. Tìm tin tức sâu rộng trên toàn bộ chuyên mục (VnExpress, Tuổi Trẻ, Thanh Niên...)
    try {
      final newsResults = await newsProvider.searchArticlesAsync(trimmed);
      _searchResults = newsResults;
    } catch (e) {
      debugPrint('SearchProvider.performSearch news error: $e');
      _searchResults = newsProvider.searchArticles(trimmed);
    } finally {
      _isLoadingNews = false;
      notifyListeners();
    }

    // 2. Chỉ tìm thời tiết khi từ khóa thực sự có ý định tìm thời tiết hoặc địa phương!
    final isWeatherIntent = _isLocationOrWeatherQuery(trimmed);

    if (isWeatherIntent) {
      _isLoadingWeather = true;
      notifyListeners();
      try {
        final cities = await weatherProvider.searchCities(trimmed);
        _matchingCities = cities;

        if (cities.isNotEmpty) {
          final targetCity = cities.first;
          await loadWeatherForCity(targetCity);
        } else {
          final defaultCity = weatherProvider.selectedCity;
          await loadWeatherForCity(defaultCity);
        }
      } catch (e) {
        debugPrint('SearchProvider.performSearch weather error: $e');
      } finally {
        _isLoadingWeather = false;
        notifyListeners();
      }
    } else {
      // Từ khóa thuần tin tức: không gọi thời tiết để tránh làm nhiễu kết quả bài viết
      _matchingCities = [];
      _previewWeather = null;
      _selectedPreviewCity = null;
      _isLoadingWeather = false;
      notifyListeners();
    }
  }

  /// Đặt lại trạng thái tìm kiếm
  void resetSearch() {
    _currentQuery = '';
    _searchResults = [];
    _matchingCities = [];
    _selectedPreviewCity = null;
    _previewWeather = null;
    _hasSearched = false;
    _isLoadingNews = false;
    _isLoadingWeather = false;
    _activeFilter = 'Tất cả';
    notifyListeners();
  }
}
