import 'dart:async';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../models/article.dart';
import '../../../services/weather_service.dart';
import '../../auth/presentation/login_screen.dart';

/// FavoritesProvider: Quản lý Tin đã lưu & Địa điểm thời tiết yêu thích
/// Triển khai theo HƯỚNG B:
/// 1. Khách vẫn bấm tim / lưu thoải mái (lưu tạm trên máy với key `guest_...`).
/// 2. Khi khách đăng nhập: Tự động HỢP NHẤT (Merge/Union) dữ liệu tạm của khách
///    lên Database tài khoản (`users/$uid/...`), loại bỏ trùng lặp, sau đó dọn sạch dữ liệu tạm.
/// 3. Phân tách dòng DB độc lập hoàn toàn theo `uid`.
class FavoritesProvider extends ChangeNotifier {
  static const Duration _timeout = Duration(seconds: 3);
  static const String _keyGuestFavorites = 'guest_favorite_articles';
  static const String _keyGuestFavoriteCities = 'guest_favorite_cities';

  final List<Article> _favorites = [];
  final List<City> _favoriteCities = [];
  StreamSubscription<User?>? _authSubscription;
  String? _currentUid;
  bool _isExplicitLoggedIn = false;

  FirebaseAuth? get _auth {
    try {
      return FirebaseAuth.instance;
    } catch (_) {
      return null;
    }
  }

  FirebaseDatabase? get _database {
    try {
      return FirebaseDatabase.instance;
    } catch (_) {
      return null;
    }
  }

  List<Article> get favorites => List.unmodifiable(_favorites);
  List<City> get favoriteCities => List.unmodifiable(_favoriteCities);

  bool get isAuthenticated {
    if (_isExplicitLoggedIn && _currentUid != null && _currentUid!.isNotEmpty) {
      return true;
    }
    return _auth?.currentUser != null;
  }

  String? get activeUid => _currentUid ?? _auth?.currentUser?.uid;

  FavoritesProvider() {
    _loadInitialState();
    try {
      _authSubscription = _auth?.authStateChanges().listen((user) {
        if (user != null) {
          updateUserContext(isAuthenticated: true, uid: user.uid);
        } else if (!_isExplicitLoggedIn) {
          updateUserContext(isAuthenticated: false, uid: null);
        }
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadInitialState() async {
    final user = _auth?.currentUser;
    if (user != null) {
      updateUserContext(isAuthenticated: true, uid: user.uid);
    } else {
      await _loadGuestFavorites();
      await _loadGuestFavoriteCities();
    }
  }

  /// Đồng bộ trạng thái người dùng (HỢP NHẤT DỮ LIỆU TẠM KHI ĐĂNG NHẬP)
  Future<void> updateUserContext({required bool isAuthenticated, String? uid}) async {
    final effectiveUid = (isAuthenticated && uid != null && uid.isNotEmpty) ? uid : null;
    if (_currentUid == effectiveUid && _isExplicitLoggedIn == isAuthenticated) {
      return;
    }

    _isExplicitLoggedIn = isAuthenticated;
    _currentUid = effectiveUid;

    _favorites.clear();
    _favoriteCities.clear();

    if (effectiveUid == null) {
      // Chế độ Khách: Nạp dữ liệu lưu tạm trên máy
      await _loadGuestFavorites();
      await _loadGuestFavoriteCities();
    } else {
      // Đã đăng nhập: Nạp và HỢP NHẤT (Merge) dữ liệu khách lên tài khoản Cloud
      await _loadAndMergeUserFavorites(effectiveUid);
    }
  }

  // ─────────────────────────────────────────────────────────────
  // 1. TẢI & HỢP NHẤT DỮ LIỆU (MERGE LOGIC - HƯỚNG B)
  // ─────────────────────────────────────────────────────────────
  Future<void> _loadGuestFavorites() async {
    if (_currentUid != null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_currentUid != null) return;
      final listJson = prefs.getStringList(_keyGuestFavorites);
      if (listJson != null && _currentUid == null) {
        _favorites.clear();
        for (final itemStr in listJson) {
          try {
            final map = jsonDecode(itemStr) as Map<String, dynamic>;
            final article = Article.fromJson(map);
            if (article.title.isNotEmpty && article.link.isNotEmpty) {
              _favorites.add(article);
            }
          } catch (_) {}
        }
        if (_currentUid == null) notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> _loadGuestFavoriteCities() async {
    if (_currentUid != null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_currentUid != null) return;
      final listJson = prefs.getStringList(_keyGuestFavoriteCities);
      if (listJson != null && _currentUid == null) {
        _favoriteCities.clear();
        for (final itemStr in listJson) {
          try {
            final map = jsonDecode(itemStr) as Map<String, dynamic>;
            final city = City.fromJson(map);
            if (city.name.isNotEmpty) {
              _favoriteCities.add(city);
            }
          } catch (_) {}
        }
        if (_currentUid == null) notifyListeners();
      }
    } catch (_) {}
  }

  /// Hợp nhất dữ liệu tạm của Khách vào tài khoản Cloud của User
  Future<void> _loadAndMergeUserFavorites(String uid) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // 1. Đọc dữ liệu tạm của Khách trước khi xóa
      final guestArticlesJson = prefs.getStringList(_keyGuestFavorites) ?? [];
      final guestArticles = <Article>[];
      for (final s in guestArticlesJson) {
        try {
          guestArticles.add(Article.fromJson(jsonDecode(s)));
        } catch (_) {}
      }

      final guestCitiesJson = prefs.getStringList(_keyGuestFavoriteCities) ?? [];
      final guestCities = <City>[];
      for (final s in guestCitiesJson) {
        try {
          guestCities.add(City.fromJson(jsonDecode(s)));
        } catch (_) {}
      }

      // 2. Đọc dữ liệu cục bộ của User (nếu có từ trước)
      final userArticlesJson = prefs.getStringList('favorite_articles_$uid') ?? [];
      final userArticles = <Article>[];
      for (final s in userArticlesJson) {
        try {
          userArticles.add(Article.fromJson(jsonDecode(s)));
        } catch (_) {}
      }

      final userCitiesJson = prefs.getStringList('favorite_cities_$uid') ?? [];
      final userCities = <City>[];
      for (final s in userCitiesJson) {
        try {
          userCities.add(City.fromJson(jsonDecode(s)));
        } catch (_) {}
      }

      // 3. Tải dữ liệu từ Firebase Realtime Database
      final cloudArticles = <Article>[];
      final cloudCities = <City>[];
      final db = _database;
      if (db != null) {
        try {
          final snapFavs = await db.ref('users/$uid/favorites').get().timeout(_timeout);
          if (snapFavs.exists && snapFavs.value != null) {
            final val = snapFavs.value;
            if (val is List) {
              for (final it in val) {
                if (it is Map) cloudArticles.add(Article.fromJson(Map<String, dynamic>.from(it)));
              }
            } else if (val is Map) {
              val.forEach((_, v) {
                if (v is Map) cloudArticles.add(Article.fromJson(Map<String, dynamic>.from(v)));
              });
            }
          }

          final snapCities = await db.ref('users/$uid/favorite_cities').get().timeout(_timeout);
          if (snapCities.exists && snapCities.value is List) {
            for (final it in (snapCities.value as List)) {
              if (it is Map) cloudCities.add(City.fromJson(Map<String, dynamic>.from(it)));
            }
          }
        } catch (_) {}
      }

      // 4. HỢP NHẤT DỮ LIỆU (DEDUPLICATION UNION CHÍNH XÁC CAO):
      // Tiêu chí Article: canonical URL (bỏ tracking, trailing slash) hoặc id
      final mergedArticles = <Article>[...cloudArticles];
      for (final a in userArticles) {
        if (!mergedArticles.any((m) => isSameArticle(m, a))) {
          mergedArticles.add(a);
        }
      }
      for (final a in guestArticles) {
        if (!mergedArticles.any((m) => isSameArticle(m, a))) {
          mergedArticles.insert(0, a); // Đưa bài khách vừa lưu lên đầu
        }
      }

      // Tiêu chí City: Tọa độ địa lý (sai số < 2km) hoặc Trùng tên + cùng khu vực (< 25km)
      final mergedCities = <City>[...cloudCities];
      for (final c in userCities) {
        if (!mergedCities.any((m) => isSameCity(m, c))) {
          mergedCities.add(c);
        }
      }
      for (final c in guestCities) {
        if (!mergedCities.any((m) => isSameCity(m, c))) {
          mergedCities.insert(0, c);
        }
      }

      // 5. Cập nhật state in-memory (Bảo lưu cả các thao tác phát sinh trong khi đang đồng bộ)
      for (final fresh in _favorites) {
        if (!mergedArticles.any((m) => isSameArticle(m, fresh))) {
          mergedArticles.insert(0, fresh);
        }
      }
      _favorites.clear();
      _favorites.addAll(mergedArticles);

      for (final fresh in _favoriteCities) {
        if (!mergedCities.any((m) => isSameCity(m, fresh))) {
          mergedCities.insert(0, fresh);
        }
      }
      _favoriteCities.clear();
      _favoriteCities.addAll(mergedCities);
      notifyListeners();

      // 6. Lưu vào bộ nhớ cục bộ của user và Cloud
      await _saveToPrefs(uid);
      await _saveToCloud(uid);
      await _saveCitiesToPrefs(uid);
      await _saveCitiesToCloud(uid);

      // 7. DỌN SẠCH DỮ LIỆU TẠM CỦA KHÁCH ĐỂ TRÁNH LẪN VÀO USER KHÁC
      if (guestArticles.isNotEmpty || guestCities.isNotEmpty) {
        await prefs.remove(_keyGuestFavorites);
        await prefs.remove(_keyGuestFavoriteCities);
      }
    } catch (_) {}
  }

  // ─────────────────────────────────────────────────────────────
  // TIÊU CHUẨN XÁC ĐỊNH TRÙNG LẶP (DEDUPLICATION STANDARDS)
  // ─────────────────────────────────────────────────────────────

  /// Xác định 2 bài viết có phải là một hay không:
  /// 1. Nếu có `id` hợp lệ và không rỗng -> So theo `id`.
  /// 2. So theo URL chuẩn hóa (bỏ query parameters quảng cáo/tracking, trailing slash, khoảng trắng).
  static bool isSameArticle(Article a, Article b) {
    if (a.id != null && b.id != null && a.id!.isNotEmpty && b.id!.isNotEmpty) {
      if (a.id == b.id) return true;
    }
    final normA = normalizeUrl(a.link);
    final normB = normalizeUrl(b.link);
    return normA.isNotEmpty && normA == normB;
  }

  /// Chuẩn hóa URL bài viết: bỏ khoảng trắng, chữ thường, bỏ trailing slash, bỏ UTM/tracking query
  static String normalizeUrl(String rawUrl) {
    var url = rawUrl.trim().toLowerCase();
    if (url.isEmpty) return '';
    try {
      final uri = Uri.parse(url);
      final cleanParams = Map<String, String>.from(uri.queryParameters);
      cleanParams.removeWhere((k, _) =>
          k.startsWith('utm_') ||
          k == 'ref' ||
          k == 'fbclid' ||
          k == 'source' ||
          k == 'token');
      final cleanUri = Uri(
        scheme: uri.scheme,
        host: uri.host,
        port: uri.hasPort ? uri.port : null,
        path: uri.path.endsWith('/') && uri.path.length > 1
            ? uri.path.substring(0, uri.path.length - 1)
            : uri.path,
        queryParameters: cleanParams.isEmpty ? null : cleanParams,
      );
      return cleanUri.toString();
    } catch (_) {
      if (url.endsWith('/')) {
        url = url.substring(0, url.length - 1);
      }
      return url;
    }
  }

  /// Xác định 2 địa điểm thời tiết có phải là một hay không:
  /// 1. Cùng tọa độ địa lý (sai số < 0.02 độ, xấp xỉ < 2km) -> Cùng vị trí.
  /// 2. Hoặc trùng tên (không phân biệt hoa/thường) VÀ sai số tọa độ < 0.25 độ (cùng khu vực).
  /// -> Nếu trùng tên nhưng tọa độ khác xa nhau (ví dụ: các huyện/xã trùng tên ở tỉnh khác),
  /// hệ thống coi là hai địa điểm khác biệt, KHÔNG làm mất bài/địa điểm của người dùng.
  static bool isSameCity(City a, City b) {
    final latDiff = (a.lat - b.lat).abs();
    final lonDiff = (a.lon - b.lon).abs();

    if (latDiff < 0.02 && lonDiff < 0.02) return true;

    final nameA = a.name.trim().toLowerCase();
    final nameB = b.name.trim().toLowerCase();
    if (nameA == nameB && latDiff < 0.25 && lonDiff < 0.25) {
      return true;
    }

    return false;
  }

  // ─────────────────────────────────────────────────────────────
  // 2. THAO TÁC YÊU THÍCH (ARTICLES & CITIES)
  // ─────────────────────────────────────────────────────────────
  bool isFavorite(Article article) {
    if (article.link.trim().isEmpty) return false;
    return _favorites.any((item) => isSameArticle(item, article));
  }

  Future<bool> toggleFavorite(Article article, {BuildContext? context}) async {
    if (article.link.trim().isEmpty || article.title.trim().isEmpty) return false;

    final uid = activeUid;
    final isGuest = uid == null || uid.isEmpty;

    final index = _favorites.indexWhere((item) => isSameArticle(item, article));
    final wasAdded = index < 0;
    if (wasAdded) {
      _favorites.insert(0, article);
    } else {
      _favorites.removeAt(index);
    }
    notifyListeners();

    if (isGuest) {
      await _saveGuestFavorites();
      if (context != null && wasAdded) {
        _showGuestSavedPrompt(
          context,
          'Bài viết đã lưu tạm trên máy. Đăng nhập để đồng bộ đám mây!',
        );
      }
    } else {
      await _saveToPrefs(uid);
      await _saveToCloud(uid);
    }
    return true;
  }

  Future<void> removeFavorite(Article article) async {
    final index = _favorites.indexWhere((item) => isSameArticle(item, article));
    if (index >= 0) {
      _favorites.removeAt(index);
      notifyListeners();
      final uid = activeUid;
      if (uid != null && uid.isNotEmpty) {
        await _saveToPrefs(uid);
        await _saveToCloud(uid);
      } else {
        await _saveGuestFavorites();
      }
    }
  }

  bool isFavoriteCity(City city) {
    if (city.name.trim().isEmpty) return false;
    return _favoriteCities.any((c) => isSameCity(c, city));
  }

  Future<bool> toggleFavoriteCity(City city, {BuildContext? context}) async {
    if (city.name.trim().isEmpty) return false;

    final uid = activeUid;
    final isGuest = uid == null || uid.isEmpty;

    final index = _favoriteCities.indexWhere((c) => isSameCity(c, city));
    final wasAdded = index < 0;
    if (wasAdded) {
      _favoriteCities.insert(0, city);
    } else {
      _favoriteCities.removeAt(index);
    }
    notifyListeners();

    if (isGuest) {
      await _saveGuestCities();
      if (context != null && wasAdded) {
        _showGuestSavedPrompt(
          context,
          'Địa điểm đã lưu tạm trên máy. Đăng nhập để đồng bộ đám mây!',
        );
      }
    } else {
      await _saveCitiesToPrefs(uid);
      await _saveCitiesToCloud(uid);
    }
    return true;
  }

  Future<void> removeFavoriteCity(City city) async {
    final index = _favoriteCities.indexWhere((c) => isSameCity(c, city));
    if (index >= 0) {
      _favoriteCities.removeAt(index);
      notifyListeners();
      final uid = activeUid;
      if (uid != null && uid.isNotEmpty) {
        await _saveCitiesToPrefs(uid);
        await _saveCitiesToCloud(uid);
      } else {
        await _saveGuestCities();
      }
    }
  }

  // ─────────────────────────────────────────────────────────────
  // 3. STORAGE HELPERS
  // ─────────────────────────────────────────────────────────────
  Future<void> _saveGuestFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final listJson = _favorites.map((a) => jsonEncode(a.toJson())).toList();
      await prefs.setStringList(_keyGuestFavorites, listJson);
    } catch (_) {}
  }

  Future<void> _saveGuestCities() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final listJson = _favoriteCities.map((c) => jsonEncode(c.toJson())).toList();
      await prefs.setStringList(_keyGuestFavoriteCities, listJson);
    } catch (_) {}
  }

  Future<void> _saveToPrefs(String uid) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final listJson = _favorites.map((a) => jsonEncode(a.toJson())).toList();
      await prefs.setStringList('favorite_articles_$uid', listJson);
    } catch (_) {}
  }

  Future<void> _saveCitiesToPrefs(String uid) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final listJson = _favoriteCities.map((c) => jsonEncode(c.toJson())).toList();
      await prefs.setStringList('favorite_cities_$uid', listJson);
    } catch (_) {}
  }

  Future<void> _saveToCloud(String uid) async {
    final db = _database;
    if (db == null) return;
    try {
      final ref = db.ref('users/$uid/favorites');
      final listMaps = _favorites.map((a) => a.toJson()).toList();
      await ref.set(listMaps).timeout(_timeout);
    } catch (_) {}
  }

  Future<void> _saveCitiesToCloud(String uid) async {
    final db = _database;
    if (db == null) return;
    try {
      final ref = db.ref('users/$uid/favorite_cities');
      final listMaps = _favoriteCities.map((c) => c.toJson()).toList();
      await ref.set(listMaps).timeout(_timeout);
    } catch (_) {}
  }

  void _showGuestSavedPrompt(BuildContext context, String message) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.cloud_upload_outlined, color: Colors.amberAccent, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontSize: 13),
              ),
            ),
          ],
        ),
        action: SnackBarAction(
          label: 'Đăng nhập',
          textColor: const Color(0xFF60A5FA),
          onPressed: () {
            messenger.hideCurrentSnackBar();
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LoginScreen()),
            );
          },
        ),
        showCloseIcon: true,
        closeIconColor: Colors.white70,
        backgroundColor: const Color(0xFF1E293B),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(milliseconds: 2600),
        dismissDirection: DismissDirection.horizontal,
      ),
    );
  }
}
