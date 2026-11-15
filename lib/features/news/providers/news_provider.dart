import 'package:flutter/material.dart';
import '../../../models/article.dart';
import '../../../services/news_service.dart';

enum NewsStatus { initial, loading, success, error, empty }

class NewsProvider extends ChangeNotifier {
  final NewsService _service = NewsService();

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
      _articles = fetched;
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

  void addArticle(Article article) {
    _articles.insert(0, article);
    _updateDisplayedArticles();
    notifyListeners();
  }

  void removeArticle(String title) {
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
