import 'dart:async';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../models/article.dart';
import '../../../services/weather_service.dart';
import '../../auth/presentation/login_screen.dart';

class FavoritesProvider extends ChangeNotifier {
  static const Duration _timeout = Duration(seconds: 12);

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

  /// Đồng bộ trạng thái người dùng độc lập (Per-User DB Isolation)
  void updateUserContext({required bool isAuthenticated, String? uid}) {
    final effectiveUid = (isAuthenticated && uid != null && uid.isNotEmpty) ? uid : null;
    if (_currentUid == effectiveUid && _isExplicitLoggedIn == isAuthenticated) {
      return;
    }

    _isExplicitLoggedIn = isAuthenticated;
    _currentUid = effectiveUid;

    _favorites.clear();
    _favoriteCities.clear();

    if (effectiveUid == null) {
      notifyListeners();
      return;
    }

    // Tải dữ liệu độc lập của riêng User này
    _loadUserFavorites(effectiveUid);
    _loadUserFavoriteCities(effectiveUid);
    syncWithCloud(effectiveUid);
  }

  // ─────────────────────────────────────────────────────────────
  // 1. QUẢN LÝ BÀI BÁO YÊU THÍCH (ARTICLES)
  // ─────────────────────────────────────────────────────────────
  Future<void> _loadUserFavorites(String uid) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final listJson = prefs.getStringList('favorite_articles_$uid');
      if (listJson != null) {
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
        notifyListeners();
      }
    } catch (_) {}
  }

  // ─────────────────────────────────────────────────────────────
  // 2. QUẢN LÝ ĐỊA ĐIỂM YÊU THÍCH (CITIES)
  // ─────────────────────────────────────────────────────────────
  Future<void> _loadUserFavoriteCities(String uid) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final listJson = prefs.getStringList('favorite_cities_$uid');
      if (listJson != null) {
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
        notifyListeners();
      } else {
        // Mặc định khởi tạo các địa điểm tiêu biểu cho tài khoản mới
        _favoriteCities.addAll([
          WeatherService.cities[0], // Hà Nội
          WeatherService.cities[1], // TP. Hồ Chí Minh
          WeatherService.cities[3], // Quần đảo Hoàng Sa (Đà Nẵng)
          WeatherService.cities[4], // Quần đảo Trường Sa (Khánh Hòa)
        ]);
        await _saveCitiesToPrefs(uid);
        notifyListeners();
      }
    } catch (_) {}
  }

  bool isFavoriteCity(City city) {
    if (city.name.trim().isEmpty) return false;
    return _favoriteCities.any((c) => c.name.toLowerCase() == city.name.toLowerCase());
  }

  Future<bool> toggleFavoriteCity(City city, {BuildContext? context}) async {
    final uid = activeUid;
    if (!isAuthenticated || uid == null || uid.isEmpty) {
      if (context != null) {
        _showLoginRequiredPrompt(context, 'lưu địa điểm thời tiết yêu thích');
      }
      return false;
    }

    if (city.name.trim().isEmpty) return false;

    final index = _favoriteCities.indexWhere(
        (c) => c.name.toLowerCase() == city.name.toLowerCase());
    if (index >= 0) {
      _favoriteCities.removeAt(index);
    } else {
      _favoriteCities.insert(0, city);
    }
    notifyListeners();
    await _saveCitiesToPrefs(uid);
    await _saveCitiesToCloud(uid);
    return true;
  }

  Future<void> removeFavoriteCity(City city) async {
    final uid = activeUid;
    if (uid == null) return;

    final index = _favoriteCities.indexWhere(
        (c) => c.name.toLowerCase() == city.name.toLowerCase());
    if (index >= 0) {
      _favoriteCities.removeAt(index);
      notifyListeners();
      await _saveCitiesToPrefs(uid);
      await _saveCitiesToCloud(uid);
    }
  }

  Future<void> _saveCitiesToPrefs(String uid) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final listJson =
          _favoriteCities.map((c) => jsonEncode(c.toJson())).toList();
      await prefs.setStringList('favorite_cities_$uid', listJson);
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

  // ─────────────────────────────────────────────────────────────
  // 3. ĐỒNG BỘ CLOUD THEO ĐÚNG DÒNG UID ĐỘC LẬP (PER-USER ISOLATION)
  // ─────────────────────────────────────────────────────────────
  Future<void> syncWithCloud(String uid) async {
    final db = _database;
    if (db == null) return;

    try {
      // 1. Đồng bộ tin bài yêu thích
      final ref = db.ref('users/$uid/favorites');
      final snapshot = await ref.get().timeout(_timeout);

      if (snapshot.exists && snapshot.value != null) {
        final cloudData = snapshot.value;
        final List<Article> cloudList = [];

        if (cloudData is List) {
          for (final item in cloudData) {
            if (item != null && item is Map) {
              final map = Map<String, dynamic>.from(item);
              final article = Article.fromJson(map);
              if (article.title.isNotEmpty && article.link.isNotEmpty) {
                cloudList.add(article);
              }
            }
          }
        } else if (cloudData is Map) {
          cloudData.forEach((key, val) {
            if (val != null && val is Map) {
              final map = Map<String, dynamic>.from(val);
              final article = Article.fromJson(map);
              if (article.title.isNotEmpty && article.link.isNotEmpty) {
                cloudList.add(article);
              }
            }
          });
        }

        // Set danh sách riêng của chính user này từ Database
        if (cloudList.isNotEmpty) {
          _favorites.clear();
          _favorites.addAll(cloudList);
          notifyListeners();
          await _saveToPrefs(uid);
        } else if (_favorites.isNotEmpty) {
          await _saveToCloud(uid);
        }
      } else if (_favorites.isNotEmpty) {
        await _saveToCloud(uid);
      }

      // 2. Đồng bộ danh sách địa điểm yêu thích từ Database
      final citiesRef = db.ref('users/$uid/favorite_cities');
      final citiesSnapshot = await citiesRef.get().timeout(_timeout);
      if (citiesSnapshot.exists && citiesSnapshot.value is List) {
        final cloudCities = <City>[];
        for (final item in (citiesSnapshot.value as List)) {
          if (item != null && item is Map) {
            try {
              cloudCities.add(City.fromJson(Map<String, dynamic>.from(item)));
            } catch (_) {}
          }
        }
        if (cloudCities.isNotEmpty) {
          _favoriteCities.clear();
          _favoriteCities.addAll(cloudCities);
          notifyListeners();
          await _saveCitiesToPrefs(uid);
        }
      }
    } catch (_) {}
  }

  bool isFavorite(Article article) {
    if (article.link.trim().isEmpty) return false;
    return _favorites.any((item) => item.link == article.link);
  }

  Future<bool> toggleFavorite(Article article, {BuildContext? context}) async {
    final uid = activeUid;
    if (!isAuthenticated || uid == null || uid.isEmpty) {
      if (context != null) {
        _showLoginRequiredPrompt(context, 'lưu tin tức vào danh sách yêu thích');
      }
      return false;
    }

    if (article.link.trim().isEmpty || article.title.trim().isEmpty) return false;

    final index = _favorites.indexWhere((item) => item.link == article.link);
    if (index >= 0) {
      _favorites.removeAt(index);
    } else {
      _favorites.insert(0, article);
    }
    notifyListeners();
    await _saveToPrefs(uid);
    await _saveToCloud(uid);
    return true;
  }

  Future<void> removeFavorite(Article article) async {
    final uid = activeUid;
    if (uid == null) return;

    final index = _favorites.indexWhere((item) => item.link == article.link);
    if (index >= 0) {
      _favorites.removeAt(index);
      notifyListeners();
      await _saveToPrefs(uid);
      await _saveToCloud(uid);
    }
  }

  Future<void> _saveToPrefs(String uid) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final listJson = _favorites.map((a) => jsonEncode(a.toJson())).toList();
      await prefs.setStringList('favorite_articles_$uid', listJson);
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

  void _showLoginRequiredPrompt(BuildContext context, String actionText) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.lock_outline_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Vui lòng đăng nhập để $actionText.',
                style: const TextStyle(fontSize: 13.5),
              ),
            ),
          ],
        ),
        action: SnackBarAction(
          label: 'Đăng nhập',
          textColor: const Color(0xFF60A5FA),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LoginScreen()),
            );
          },
        ),
        backgroundColor: const Color(0xFF1E293B),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 4),
      ),
    );
  }
}
