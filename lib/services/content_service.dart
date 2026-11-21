import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/article.dart';

/// Abstract contract for Clean Architecture / Dependency Inversion
abstract class IContentService {
  Future<List<Article>> fetchArticles({bool forceRefresh = false});
  Future<String> saveArticle(Article article);
  Future<void> deleteArticle(String articleId);
}

/// Firebase Realtime Database Service for articles with timeout, in-memory TTL cache & safe serialization
class ContentService implements IContentService {
  final FirebaseDatabase? _database;
  static const Duration _timeout = Duration(seconds: 15);
  static const Duration _cacheTtl = Duration(minutes: 5);

  DateTime? _lastFetchTime;
  List<Article>? _cachedArticles;

  ContentService({FirebaseDatabase? database})
      : _database = database;

  DatabaseReference get _articlesRef {
    try {
      return (_database ?? FirebaseDatabase.instance).ref('articles');
    } on FirebaseException catch (error) {
      throw StateError(
        'Firebase chưa được khởi tạo, không thể đồng bộ bài viết: ${error.message}',
      );
    }
  }

  @override
  Future<List<Article>> fetchArticles({bool forceRefresh = false}) async {
    final now = DateTime.now();
    if (!forceRefresh &&
        _cachedArticles != null &&
        _lastFetchTime != null &&
        now.difference(_lastFetchTime!) < _cacheTtl) {
      return _cachedArticles!;
    }

    final snapshot = await _articlesRef.get().timeout(
      _timeout,
      onTimeout: () => throw TimeoutException('Quá thời gian kết nối đến máy chủ bài viết.'),
    );

    if (!snapshot.exists || snapshot.value == null) {
      _cachedArticles = [];
      _lastFetchTime = now;
      return [];
    }

    final value = snapshot.value;
    if (value is! Map) {
      _cachedArticles = [];
      _lastFetchTime = now;
      return [];
    }

    final articles = <Article>[];
    for (final entry in value.entries) {
      final item = entry.value;
      if (item is Map) {
        try {
          final article = Article.fromJson({
            ...Map<String, dynamic>.from(item),
            'id': entry.key.toString(),
          });
          if (article.title.isNotEmpty && article.link.isNotEmpty && !article.isExpired) {
            articles.add(article);
          }
        } catch (_) {
          // Skip corrupted individual records without failing entire fetch
        }
      }
    }

    articles.sort((a, b) {
      final aDate = a.publishedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bDate = b.publishedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bDate.compareTo(aDate);
    });

    _cachedArticles = List.unmodifiable(articles);
    _lastFetchTime = now;
    return _cachedArticles!;
  }

  @override
  Future<String> saveArticle(Article article) async {
    _cachedArticles = null; // Invalidate cache immediately on new article
    // Model-Level Validation (database_consistency requirement):
    final cleanTitle = article.title.trim();
    final cleanLink = article.link.trim();
    if (cleanTitle.isEmpty) {
      throw ArgumentError('Tiêu đề bài viết không được để trống.');
    }
    if (cleanLink.isEmpty ||
        (!cleanLink.startsWith('https://') &&
            !cleanLink.startsWith('http://') &&
            !cleanLink.startsWith('internal://'))) {
      throw ArgumentError(
          'Đường dẫn bài viết không hợp lệ (phải bắt đầu bằng http://, https:// hoặc internal://).');
    }
    if (cleanTitle.length > 500) {
      throw ArgumentError('Tiêu đề bài viết vượt quá giới hạn 500 ký tự.');
    }

    final ref = article.id == null
        ? _articlesRef.push()
        : _articlesRef.child(article.id!);
    await ref.set(article.toJson()).timeout(
      _timeout,
      onTimeout: () => throw TimeoutException('Lưu bài viết quá thời gian chờ.'),
    );
    return ref.key!;
  }

  @override
  Future<void> deleteArticle(String articleId) {
    _cachedArticles = null; // Invalidate cache immediately on deletion
    return _articlesRef.child(articleId).remove().timeout(
      _timeout,
      onTimeout: () => throw TimeoutException('Xóa bài viết quá thời gian chờ.'),
    );
  }
}

class TimeoutException implements Exception {
  final String message;
  const TimeoutException(this.message);
  @override
  String toString() => message;
}
