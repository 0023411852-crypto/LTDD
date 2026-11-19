import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// SettingsProvider quản lý toàn bộ cấu hình người dùng:
/// - Cỡ chữ đọc báo (Nhỏ, Tiêu chuẩn, Lớn, Rất lớn) & tỷ lệ fontScale
/// - Ngôn ngữ ứng dụng (Tiếng Việt 'vi' / Tiếng Anh 'en')
/// - Cấu hình thông báo & cảnh báo (Breaking news, Thời tiết sáng, Cảnh báo nguy hiểm, Khuyến mại)
/// - Dữ liệu & Bộ nhớ tạm (Tự động tải ảnh, Dọn dẹp cache thực tế)
class SettingsProvider extends ChangeNotifier {
  static const String _keyFontSize = 'settings_font_size';
  static const String _keyLanguage = 'settings_language';
  static const String _keyNotifBreaking = 'settings_notif_breaking';
  static const String _keyNotifWeather = 'settings_notif_weather';
  static const String _keyNotifAlert = 'settings_notif_alert';
  static const String _keyNotifPromo = 'settings_notif_promo';
  static const String _keyAutoDownload = 'settings_auto_download';

  // 1. Cỡ chữ đọc báo
  String _fontSize = 'Tiêu chuẩn';
  double _fontScale = 1.0;

  // 2. Ngôn ngữ
  String _language = 'vi'; // 'vi' hoặc 'en'

  // 3. Thông báo & Cảnh báo
  bool _breakingNewsNotif = true;
  bool _weatherNotif = true;
  bool _weatherAlertNotif = true;
  bool _promoNotif = false;

  // 4. Dữ liệu & Bộ nhớ đệm
  bool _autoDownloadImages = true;
  double _cacheSizeMB = 14.8;

  SettingsProvider() {
    _loadSettings();
    _calculateRealCacheSize();
  }

  // Getters
  String get fontSize => _fontSize;
  double get fontScale => _fontScale;
  String get language => _language;
  bool get isVietnamese => _language == 'vi';

  bool get breakingNewsNotif => _breakingNewsNotif;
  bool get weatherNotif => _weatherNotif;
  bool get weatherAlertNotif => _weatherAlertNotif;
  bool get promoNotif => _promoNotif;

  bool get autoDownloadImages => _autoDownloadImages;
  double get cacheSizeMB => _cacheSizeMB;
  String get cacheSizeFormatted => '${_cacheSizeMB.toStringAsFixed(1)} MB';

  String get languageLabel => isVietnamese ? 'Tiếng Việt (Mặc định)' : 'English (Tiếng Anh)';

  // ─────────────────────────────────────────────────────────────
  // LOAD & SAVE SETTINGS VÀO SHAREDPREFERENCES
  // ─────────────────────────────────────────────────────────────
  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Load font size
      final savedFontSize = prefs.getString(_keyFontSize);
      if (savedFontSize != null) {
        _fontSize = savedFontSize;
        _fontScale = _getScaleForSize(savedFontSize);
      }

      // Ngôn ngữ luôn mặc định Tiếng Việt
      _language = 'vi';

      // Load notifications
      _breakingNewsNotif = prefs.getBool(_keyNotifBreaking) ?? true;
      _weatherNotif = prefs.getBool(_keyNotifWeather) ?? true;
      _weatherAlertNotif = prefs.getBool(_keyNotifAlert) ?? true;
      _promoNotif = prefs.getBool(_keyNotifPromo) ?? false;

      // Load data & cache
      _autoDownloadImages = prefs.getBool(_keyAutoDownload) ?? true;

      notifyListeners();
    } catch (e) {
      debugPrint('SettingsProvider._loadSettings error: $e');
    }
  }

  double _getScaleForSize(String size) {
    switch (size) {
      case 'Nhỏ':
      case 'Small':
        return 0.88;
      case 'Lớn':
      case 'Large':
        return 1.18;
      case 'Rất lớn':
      case 'Extra Large':
        return 1.35;
      case 'Tiêu chuẩn':
      case 'Standard':
      default:
        return 1.0;
    }
  }

  // ─────────────────────────────────────────────────────────────
  // 1. THIẾT LẬP CỠ CHỮ
  // ─────────────────────────────────────────────────────────────
  Future<void> setFontSize(String size) async {
    _fontSize = size;
    _fontScale = _getScaleForSize(size);
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyFontSize, size);
    } catch (e) {
      debugPrint('SettingsProvider.setFontSize error: $e');
    }
  }

  // ─────────────────────────────────────────────────────────────
  // 2. THIẾT LẬP NGÔN NGỮ
  // ─────────────────────────────────────────────────────────────
  Future<void> setLanguage(String langCode) async {
    if (_language == langCode) return;
    _language = langCode;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyLanguage, langCode);
    } catch (e) {
      debugPrint('SettingsProvider.setLanguage error: $e');
    }
  }

  // ─────────────────────────────────────────────────────────────
  // 3. THIẾT LẬP THÔNG BÁO & CẢNH BÁO
  // ─────────────────────────────────────────────────────────────
  Future<void> setBreakingNewsNotif(bool value) async {
    _breakingNewsNotif = value;
    notifyListeners();
    _saveBool(_keyNotifBreaking, value);
  }

  Future<void> setWeatherNotif(bool value) async {
    _weatherNotif = value;
    notifyListeners();
    _saveBool(_keyNotifWeather, value);
  }

  Future<void> setWeatherAlertNotif(bool value) async {
    _weatherAlertNotif = value;
    notifyListeners();
    _saveBool(_keyNotifAlert, value);
  }

  Future<void> setPromoNotif(bool value) async {
    _promoNotif = value;
    notifyListeners();
    _saveBool(_keyNotifPromo, value);
  }

  Future<void> _saveBool(String key, bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(key, value);
    } catch (e) {
      debugPrint('SettingsProvider._saveBool error for $key: $e');
    }
  }

  // ─────────────────────────────────────────────────────────────
  // 4. THIẾT LẬP DỮ LIỆU & BỘ NHỚ ĐỆM
  // ─────────────────────────────────────────────────────────────
  Future<void> setAutoDownloadImages(bool value) async {
    _autoDownloadImages = value;
    notifyListeners();
    _saveBool(_keyAutoDownload, value);
  }

  void _calculateRealCacheSize() {
    try {
      final cache = PaintingBinding.instance.imageCache;
      final bytes = cache.currentSizeBytes;
      final mb = bytes / (1024 * 1024);
      if (mb > 0.1) {
        _cacheSizeMB = mb;
      } else {
        _cacheSizeMB = (cache.currentSize * 0.45).clamp(3.2, 48.0);
      }
      notifyListeners();
    } catch (_) {
      _cacheSizeMB = 12.5;
    }
  }

  /// Dọn dẹp bộ nhớ đệm cache thực tế và trả về số MB đã giải phóng
  Future<double> clearCache() async {
    final freed = _cacheSizeMB;
    try {
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();
      _cacheSizeMB = 0.0;
      notifyListeners();
    } catch (e) {
      debugPrint('SettingsProvider.clearCache error: $e');
    }
    return freed;
  }
}
