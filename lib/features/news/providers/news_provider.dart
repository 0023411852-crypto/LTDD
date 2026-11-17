import 'package:flutter/material.dart';
import '../../../models/article.dart';
import '../../../services/news_service.dart';
import '../../../services/content_service.dart';

enum NewsStatus { initial, loading, success, error, empty }

class NewsProvider extends ChangeNotifier {
  final NewsService _service = NewsService();
  final ContentService _contentService = ContentService();

  NewsStatus _status = NewsStatus.initial;
  String _errorMessage = '';
  NewsCategory _selectedCategory = NewsService.categories.first;
  List<Article> _articles = [];
  List<Article> _displayedArticles = [];
  final int _pageSize = 10;
  int _currentPage = 1;

  NewsStatus get status => _status;
  String get errorMessage => _errorMessage;
  NewsCategory get selectedCategory => _selectedCategory;
  List<Article> get articles => _displayedArticles;
  List<NewsCategory> get categories => NewsService.categories;
  bool get hasMore => _displayedArticles.length < _articles.length;

  NewsProvider() {
    fetchNews();
  }

  Future<void> selectCategory(NewsCategory category) async {
    if (_selectedCategory.id == category.id && _status == NewsStatus.success) {
      return;
    }
    _selectedCategory = category;
    await fetchNews();
  }

  Future<void> fetchNews() async {
    _status = NewsStatus.loading;
    _errorMessage = '';
    notifyListeners();

    try {
      final fetched = await _service.fetchCategory(_selectedCategory);
      final backendArticles = await _contentService.fetchArticles();
      _articles = [
        ...backendArticles.where(
          (article) => article.category == _selectedCategory.label,
        ),
        ...fetched,
      ];
      final seenLinks = <String>{};
      _articles =
          _articles.where((article) => seenLinks.add(article.link)).toList();
      _currentPage = 1;
      _updateDisplayedArticles();

      if (_articles.isEmpty) {
        _status = NewsStatus.empty;
      } else {
        _status = NewsStatus.success;
      }
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _status = NewsStatus.error;
    }
    notifyListeners();
  }

  void loadMore() {
    if (!hasMore) return;
    _currentPage++;
    _updateDisplayedArticles();
    notifyListeners();
  }

  void _updateDisplayedArticles() {
    final count = _currentPage * _pageSize;
    if (count >= _articles.length) {
      _displayedArticles = List.from(_articles);
    } else {
      _displayedArticles = _articles.take(count).toList();
    }
  }

  Future<void> addArticle(Article article) async {
    final id = await _contentService.saveArticle(article);
    final savedArticle = Article(
      id: id,
      title: article.title,
      link: article.link,
      description: article.description,
      imageUrl: article.imageUrl,
      source: article.source,
      publishedAt: article.publishedAt,
      category: article.category,
      tags: article.tags,
      inlineImageUrls: article.inlineImageUrls,
    );
    _articles.insert(0, savedArticle);
    _updateDisplayedArticles();
    notifyListeners();
  }

  Future<void> removeArticle(String title) async {
    final matches = _articles.where((a) => a.title == title);
    final article = matches.isEmpty ? null : matches.first;
    if (article?.id != null) {
      await _contentService.deleteArticle(article!.id!);
    }
    _articles.removeWhere((a) => a.title == title);
    _updateDisplayedArticles();
    notifyListeners();
  }

  List<Article> searchArticles(String query) {
    if (query.trim().isEmpty) return [];
    final lower = query.toLowerCase().trim();
    return _articles.where((article) {
      return article.title.toLowerCase().contains(lower) ||
          article.description.toLowerCase().contains(lower) ||
          article.source.toLowerCase().contains(lower);
    }).toList();
  }
}
