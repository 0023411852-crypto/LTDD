import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../models/article.dart';

class FavoritesProvider extends ChangeNotifier {
  static const String _keyFavorites = 'favorite_articles';
  final List<Article> _favorites = [];

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

  FavoritesProvider() {
    loadFavorites();
    try {
      _auth?.authStateChanges().listen((user) {
        if (user != null) {
          syncWithCloud(user.uid);
        }
      });
    } catch (_) {}
  }

  Future<void> loadFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final listJson = prefs.getStringList(_keyFavorites);
      if (listJson != null) {
        _favorites.clear();
        for (final itemStr in listJson) {
          try {
            final map = jsonDecode(itemStr) as Map<String, dynamic>;
            _favorites.add(Article.fromJson(map));
          } catch (_) {}
        }
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> syncWithCloud(String uid) async {
    final db = _database;
    if (db == null) return;

    try {
      final ref = db.ref('users/$uid/favorites');
      final snapshot = await ref.get();

      if (snapshot.exists && snapshot.value != null) {
        final cloudData = snapshot.value;
        final List<Article> cloudList = [];

        if (cloudData is List) {
          for (final item in cloudData) {
            if (item != null) {
              final map = Map<String, dynamic>.from(item as Map);
              cloudList.add(Article.fromJson(map));
            }
          }
        } else if (cloudData is Map) {
          cloudData.forEach((key, val) {
            if (val != null) {
              final map = Map<String, dynamic>.from(val as Map);
              cloudList.add(Article.fromJson(map));
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
    return _favorites.any((item) => item.link == article.link);
  }

  Future<void> toggleFavorite(Article article) async {
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
      await ref.set(listMaps);
    } catch (_) {}
  }
}
