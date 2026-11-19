import 'package:flutter/material.dart';
import '../../../../models/article.dart';
import '../../../../services/news_service.dart';
import '../../../news/providers/news_provider.dart';
import '../../providers/admin_provider.dart';

/// Controller xử lý nghiệp vụ quản lý tin tức (Search, Filter, Duyệt bài, Xóa bài)
class AdminNewsController {
  final NewsProvider newsProvider;
  final AdminProvider adminProvider;

  AdminNewsController({
    required this.newsProvider,
    required this.adminProvider,
  });

  String get searchQuery => adminProvider.newsSearchQuery;
  String get filter => adminProvider.newsFilter;
  Set<String> get pendingTitles => newsProvider.pendingArticleTitles;
  List<Article> get allArticles => newsProvider.allArticles;
  List<NewsCategory> get categories => newsProvider.categories;

  void setSearchQuery(String query) => adminProvider.setNewsSearchQuery(query);
  void setFilter(String filter) => adminProvider.setNewsFilter(filter);

  List<Article> getFilteredArticles() {
    return allArticles.where((a) {
      final matchesSearch = searchQuery.isEmpty ||
          a.title.toLowerCase().contains(searchQuery.toLowerCase()) ||
          a.source.toLowerCase().contains(searchQuery.toLowerCase());
      if (!matchesSearch) return false;

      final isPending = pendingTitles.contains(a.title);
      if (filter == 'Chờ duyệt') return isPending;
      if (filter == 'Đã duyệt') return !isPending;
      return true;
    }).toList();
  }

  void toggleApproval(String title) {
    adminProvider.toggleApproval(title);
    newsProvider.toggleArticleApproval(title);
  }

  Future<void> deleteArticlePermanently(String title) async {
    await newsProvider.deleteArticlePermanently(title);
  }

  Future<void> addNewArticle(Article article) async {
    await newsProvider.addArticle(article);
  }
}
