import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/article.dart';

class ContentService {
  final FirebaseDatabase? _database;

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

  Future<List<Article>> fetchArticles() async {
    final snapshot = await _articlesRef.get();
    if (!snapshot.exists || snapshot.value == null) return [];

    final value = snapshot.value;
    if (value is! Map) {
      throw const FormatException('Dữ liệu bài viết trên máy chủ không hợp lệ.');
    }

    final articles = <Article>[];
    for (final entry in value.entries) {
      final item = entry.value;
      if (item is Map) {
        final article = Article.fromJson({
          ...Map<String, dynamic>.from(item),
          'id': entry.key.toString(),
        });
        if (article.title.isNotEmpty && article.link.isNotEmpty) {
          articles.add(article);
        }
      }
    }
    articles.sort((a, b) {
      final aDate = a.publishedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bDate = b.publishedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bDate.compareTo(aDate);
    });
    return articles;
  }

  Future<String> saveArticle(Article article) async {
    final ref = article.id == null
        ? _articlesRef.push()
        : _articlesRef.child(article.id!);
    await ref.set(article.toJson());
    return ref.key!;
  }

  Future<void> deleteArticle(String articleId) {
    return _articlesRef.child(articleId).remove();
  }
}
