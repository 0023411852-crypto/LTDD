import 'dart:async';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../models/article.dart';
import '../../../services/weather_service.dart';

class FavoritesProvider extends ChangeNotifier {
  static const String _keyFavorites = 'favorite_articles';
  static const String _keyFavoriteCities = 'favorite_cities';
  static const Duration _timeout = Duration(seconds: 15);

  final List<Article> _favorites = [];
  final List<City> _favoriteCities = [];
  StreamSubscription<User?>? _authSubscription;

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

  FavoritesProvider() {
    loadFavorites();
    _loadFavoriteCities();
    try {
      _authSubscription = _auth?.authStateChanges().listen((user) {
        if (user != null) {
          syncWithCloud(user.uid);
        }
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────
  // 1. QUẢN LÝ BÀI BÁO YÊU THÍCH (ARTICLES)
  // ─────────────────────────────────────────────────────────────
  Future<void> loadFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final listJson = prefs.getStringList(_keyFavorites);
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
  Future<void> _loadFavoriteCities() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final listJson = prefs.getStringList(_keyFavoriteCities);
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
        // Mặc định lưu sẵn các địa điểm tiêu biểu của Việt Nam
        _favoriteCities.addAll([
          WeatherService.cities[0], // Hà Nội
          WeatherService.cities[1], // TP. Hồ Chí Minh
          WeatherService.cities[3], // Quần đảo Hoàng Sa (Đà Nẵng)
          WeatherService.cities[4], // Quần đảo Trường Sa (Khánh Hòa)
        ]);
        await _saveCitiesToPrefs();
        notifyListeners();
      }
    } catch (_) {}
  }

  bool isFavoriteCity(City city) {
    if (city.name.trim().isEmpty) return false;
    return _favoriteCities.any((c) => c.name.toLowerCase() == city.name.toLowerCase());
  }

  Future<void> toggleFavoriteCity(City city) async {
    if (city.name.trim().isEmpty) return;

    final index = _favoriteCities.indexWhere(
        (c) => c.name.toLowerCase() == city.name.toLowerCase());
    if (index >= 0) {
      _favoriteCities.removeAt(index);
    } else {
      _favoriteCities.insert(0, city);
    }
    notifyListeners();
    await _saveCitiesToPrefs();

    final user = _auth?.currentUser;
    if (user != null) {
      await _saveCitiesToCloud(user.uid);
    }
  }

  Future<void> removeFavoriteCity(City city) async {
    final index = _favoriteCities.indexWhere(
        (c) => c.name.toLowerCase() == city.name.toLowerCase());
    if (index >= 0) {
      _favoriteCities.removeAt(index);
      notifyListeners();
      await _saveCitiesToPrefs();

      final user = _auth?.currentUser;
      if (user != null) {
        await _saveCitiesToCloud(user.uid);
      }
    }
  }

  Future<void> _saveCitiesToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final listJson =
          _favoriteCities.map((c) => jsonEncode(c.toJson())).toList();
      await prefs.setStringList(_keyFavoriteCities, listJson);
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

  Future<void> syncWithCloud(String uid) async {
    final db = _database;
    if (db == null) return;

    try {
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

        // Merge: Giữ những bài đã có cục bộ và thêm bài từ cloud nếu chưa có
        for (final cloudArticle in cloudList) {
          if (!_favorites.any((a) => a.link == cloudArticle.link)) {
            _favorites.add(cloudArticle);
          }
        }
        notifyListeners();
        await _saveToPrefs();
      }

      // Đẩy danh sách đã gộp lên cloud
      await _saveToCloud(uid);
    } catch (_) {}
  }

  bool isFavorite(Article article) {
    if (article.link.trim().isEmpty) return false;
    return _favorites.any((item) => item.link == article.link);
  }

  Future<void> toggleFavorite(Article article) async {
    if (article.link.trim().isEmpty || article.title.trim().isEmpty) return;

    final index = _favorites.indexWhere((item) => item.link == article.link);
    if (index >= 0) {
      _favorites.removeAt(index);
    } else {
      _favorites.insert(0, article);
    }
    notifyListeners();
    await _saveToPrefs();

    final user = _auth?.currentUser;
    if (user != null) {
      await _saveToCloud(user.uid);
    }
  }

  Future<void> removeFavorite(Article article) async {
    final index = _favorites.indexWhere((item) => item.link == article.link);
    if (index >= 0) {
      _favorites.removeAt(index);
      notifyListeners();
      await _saveToPrefs();

      final user = _auth?.currentUser;
      if (user != null) {
        await _saveToCloud(user.uid);
      }
    }
  }

  Future<void> _saveToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final listJson = _favorites.map((a) => jsonEncode(a.toJson())).toList();
      await prefs.setStringList(_keyFavorites, listJson);
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
}
