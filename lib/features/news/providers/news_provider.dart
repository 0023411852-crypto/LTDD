import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../models/article.dart';
import '../../../services/news_service.dart';
import '../../../services/content_service.dart';

enum NewsStatus { initial, loading, success, error, empty }

class NewsProvider extends ChangeNotifier {
  static const String _keySelectedCatIds = 'news_selected_category_ids';
  static const String _keyCustomCategories = 'custom_news_categories';
  static const String _keyPendingTitles = 'news_pending_titles';
  static const String _keyDeletedTitles = 'news_deleted_titles';

  final INewsService _service;
  final IContentService _contentService;

  NewsStatus _status = NewsStatus.initial;
  String _errorMessage = '';
  List<NewsCategory> _categories = List.from(NewsService.categories);
  late NewsCategory _selectedCategory;
  Set<String> _selectedCategoryIds = {'moi-nhat'};
  List<Article> _articles = [];
  List<Article> _displayedArticles = [];

  // Trạng thái kiểm duyệt và xóa bài viết bền vững
  Set<String> _pendingArticleTitles = {};
  Set<String> _deletedArticleTitles = {};

  final int _pageSize = 30;
  int _currentPage = 1;

  NewsStatus get status => _status;
  String get errorMessage => _errorMessage;
  NewsCategory get selectedCategory => _selectedCategory;
  Set<String> get selectedCategoryIds => Set.unmodifiable(_selectedCategoryIds);
  List<Article> get articles => _displayedArticles;
  List<Article> get allArticles => List.unmodifiable(_articles);
  int get totalArticlesCount => _articles.length;
  List<NewsCategory> get categories => List.unmodifiable(_categories);
  Set<String> get pendingArticleTitles => Set.unmodifiable(_pendingArticleTitles);
  Set<String> get deletedArticleTitles => Set.unmodifiable(_deletedArticleTitles);
  bool get hasMore => _displayedArticles.length < _getApprovedArticles().length;

  NewsProvider({
    INewsService? service,
    IContentService? contentService,
  })  : _service = service ?? NewsService(),
        _contentService = contentService ?? ContentService() {
    _selectedCategory = _categories.first;
    _initAndLoad();
  }

  Future<void> _initAndLoad() async {
    await _loadPersistedSettings();
    await fetchNews();
  }

  Future<void> _loadPersistedSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // 1. Khôi phục danh mục / nguồn tin tùy chỉnh
      final savedCatsJson = prefs.getStringList(_keyCustomCategories);
      if (savedCatsJson != null && savedCatsJson.isNotEmpty) {
        final loaded = <NewsCategory>[];
        for (final item in savedCatsJson) {
          try {
            final map = jsonDecode(item) as Map<String, dynamic>;
            loaded.add(NewsCategory.fromJson(map));
          } catch (_) {}
        }
        if (loaded.isNotEmpty) {
          _categories = loaded;
        }
      }

      // 2. Khôi phục các nguồn đang được chọn (để khi mở lại app không bị reset)
      final savedSelected = prefs.getStringList(_keySelectedCatIds);
      if (savedSelected != null && savedSelected.isNotEmpty) {
        final validIds = _categories.map((c) => c.id).toSet();
        final filtered = savedSelected.where((id) => validIds.contains(id)).toSet();
        if (filtered.isNotEmpty) {
          _selectedCategoryIds = filtered;
          _selectedCategory = _categories.firstWhere(
            (c) => _selectedCategoryIds.contains(c.id),
            orElse: () => _categories.first,
          );
        }
      }

      // 3. Khôi phục danh sách bài viết Chờ duyệt & Đã xóa
      final savedPending = prefs.getStringList(_keyPendingTitles);
      if (savedPending != null) {
        _pendingArticleTitles = savedPending.toSet();
      }

      final savedDeleted = prefs.getStringList(_keyDeletedTitles);
      if (savedDeleted != null) {
        _deletedArticleTitles = savedDeleted.toSet();
      }
    } catch (e) {
      debugPrint('NewsProvider._loadPersistedSettings error: $e');
    }
  }

  Future<void> _saveSelectedCategoryIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_keySelectedCatIds, _selectedCategoryIds.toList());
    } catch (e) {
      debugPrint('NewsProvider._saveSelectedCategoryIds error: $e');
    }
  }

  Future<void> _saveCategories() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stringList = _categories.map((c) => jsonEncode(c.toJson())).toList();
      await prefs.setStringList(_keyCustomCategories, stringList);
    } catch (e) {
      debugPrint('NewsProvider._saveCategories error: $e');
    }
  }

  Future<void> _savePendingArticles() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_keyPendingTitles, _pendingArticleTitles.toList());
    } catch (e) {
      debugPrint('NewsProvider._savePendingArticles error: $e');
    }
  }

  Future<void> _saveDeletedArticles() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_keyDeletedTitles, _deletedArticleTitles.toList());
    } catch (e) {
      debugPrint('NewsProvider._saveDeletedArticles error: $e');
    }
  }

  // ─────────────────────────────────────────────────────────────
  // QUẢN LÝ NGUỒN TIN (THÊM / XÓA / KHÔI PHỤC NGUỒN BÁO)
  // ─────────────────────────────────────────────────────────────
  Future<bool> addCategory({
    required String label,
    required String rssUrl,
    required String source,
  }) async {
    final cleanLabel = label.trim();
    final cleanUrl = rssUrl.trim();
    final cleanSource = source.trim().isEmpty ? 'Báo điện tử' : source.trim();

    if (cleanLabel.isEmpty || cleanUrl.isEmpty) {
      return false;
    }

    final id = 'cat_${DateTime.now().millisecondsSinceEpoch}';
    final newCategory = NewsCategory(id, cleanLabel, cleanUrl, cleanSource);

    _categories.add(newCategory);
    _selectedCategoryIds.add(id);
    _selectedCategory = newCategory;

    await _saveCategories();
    await _saveSelectedCategoryIds();
    await fetchNews(forceRefresh: true);
    return true;
  }

  /// Cập nhật cấu hình số lượng bài tối đa và thời gian giữ lại cho từng nguồn tin
  Future<bool> updateCategorySettings({
    required String categoryId,
    int? maxArticles,
    int? retentionDays,
  }) async {
    final index = _categories.indexWhere((c) => c.id == categoryId);
    if (index == -1) return false;

    _categories[index] = _categories[index].copyWith(
      maxArticles: maxArticles,
      retentionDays: retentionDays,
    );

    await _saveCategories();
    notifyListeners();
    // Làm mới để áp dụng số lượng và thời gian lưu trữ mới
    await fetchNews(forceRefresh: true);
    return true;
  }

  Future<void> deleteCategory(String categoryId) async {
    _categories.removeWhere((c) => c.id == categoryId);
    _selectedCategoryIds.remove(categoryId);

    if (_categories.isEmpty) {
      _categories = List.from(NewsService.categories);
    }

    if (_selectedCategoryIds.isEmpty) {
      _selectedCategory = _categories.first;
      _selectedCategoryIds = {_categories.first.id};
    } else if (!_categories.any((c) => c.id == _selectedCategory.id)) {
      _selectedCategory = _categories.firstWhere(
        (c) => _selectedCategoryIds.contains(c.id),
        orElse: () => _categories.first,
      );
    }

    await _saveCategories();
    await _saveSelectedCategoryIds();
    await fetchNews(forceRefresh: true);
  }

  Future<void> restoreDefaultCategories() async {
    _categories = List.from(NewsService.categories);
    _selectedCategory = _categories.first;
    _selectedCategoryIds = {_categories.first.id};
    await _saveCategories();
    await _saveSelectedCategoryIds();
    await fetchNews(forceRefresh: true);
  }

  // ─────────────────────────────────────────────────────────────
  // CHỌN DANH MỤC & ĐỒNG BỘ
  // ─────────────────────────────────────────────────────────────
  Future<void> selectCategory(NewsCategory category) async {
    if (_selectedCategoryIds.length == 1 &&
        _selectedCategoryIds.contains(category.id) &&
        _status == NewsStatus.success) {
      return;
    }
    _selectedCategory = category;
    _selectedCategoryIds = {category.id};
    await _saveSelectedCategoryIds();
    await fetchNews();
  }

  Future<void> toggleCategory(NewsCategory category) async {
    if (_selectedCategoryIds.contains(category.id)) {
      if (_selectedCategoryIds.length > 1) {
        _selectedCategoryIds.remove(category.id);
        if (_selectedCategory.id == category.id) {
          _selectedCategory = _categories.firstWhere(
            (c) => _selectedCategoryIds.contains(c.id),
            orElse: () => _categories.first,
          );
        }
      }
    } else {
      _selectedCategoryIds.add(category.id);
      _selectedCategory = category;
    }
    await _saveSelectedCategoryIds();
    await fetchNews();
  }

  Future<void> selectAllCategories() async {
    _selectedCategoryIds = _categories.map((c) => c.id).toSet();
    await _saveSelectedCategoryIds();
    await fetchNews();
  }

  Future<void> resetToCategory(NewsCategory category) async {
    _selectedCategory = category;
    _selectedCategoryIds = {category.id};
    await _saveSelectedCategoryIds();
    await fetchNews();
  }

  // ─────────────────────────────────────────────────────────────
  // QUẢN LÝ DUYỆT BÀI VÀ XÓA BÀI VIẾT BỀN VỮNG
  // ─────────────────────────────────────────────────────────────
  bool isArticlePending(String title) {
    return _pendingArticleTitles.contains(title);
  }

  Future<void> toggleArticleApproval(String title) async {
    if (_pendingArticleTitles.contains(title)) {
      _pendingArticleTitles.remove(title);
    } else {
      _pendingArticleTitles.add(title);
    }
    await _savePendingArticles();
    _updateDisplayedArticles();
    notifyListeners();
  }

  Future<void> deleteArticlePermanently(String title) async {
    _deletedArticleTitles.add(title);
    _pendingArticleTitles.remove(title);

    final matches = _articles.where((a) => a.title == title);
    final article = matches.isEmpty ? null : matches.first;
    if (article?.id != null) {
      await _contentService.deleteArticle(article!.id!);
    }
    if (article?.link != null) {
      _deletedArticleTitles.add(article!.link);
    }

    _articles.removeWhere((a) => a.title == title);
    await _saveDeletedArticles();
    await _savePendingArticles();
    _updateDisplayedArticles();
    notifyListeners();
  }

  List<Article> _getApprovedArticles() {
    return _articles.where((a) {
      if (_deletedArticleTitles.contains(a.title) || _deletedArticleTitles.contains(a.link)) {
        return false;
      }
      return !_pendingArticleTitles.contains(a.title);
    }).toList();
  }

  // ─────────────────────────────────────────────────────────────
  // TẢI VÀ ĐỒNG BỘ DỮ LIỆU TIN TỨC
  // ─────────────────────────────────────────────────────────────
  Future<void> fetchNews({bool forceRefresh = false}) async {
    _status = NewsStatus.loading;
    _errorMessage = '';
    notifyListeners();

    try {
      final targetCategories = _selectedCategoryIds.isEmpty
          ? [_selectedCategory]
          : _categories
              .where((c) => _selectedCategoryIds.contains(c.id))
              .toList();

      final rssFutures = targetCategories.map(
        (cat) => _service
            .fetchCategory(cat, forceRefresh: forceRefresh)
            .catchError((_) => <Article>[]),
      );

      final results = await Future.wait([
        Future.wait(rssFutures),
        _contentService.fetchArticles(forceRefresh: forceRefresh).catchError((_) => <Article>[]),
      ]);

      final allRssLists = results[0] as List<List<Article>>;
      final backendArticles = results[1] as List<Article>;

      final List<Article> fetchedRss =
          allRssLists.expand((list) => list).toList();

      final activeLabels = targetCategories.map((c) => c.label).toSet();
      final rawArticles = [
        ...backendArticles.where(
          (article) =>
              activeLabels.contains(article.category) ||
              targetCategories.length > 1,
        ),
        ...fetchedRss,
      ];

      // Sắp xếp bài viết mới nhất lên đầu
      rawArticles.sort((a, b) {
        if (a.publishedAt == null && b.publishedAt == null) return 0;
        if (a.publishedAt == null) return 1;
        if (b.publishedAt == null) return -1;
        return b.publishedAt!.compareTo(a.publishedAt!);
      });

      // Lọc trùng lặp & lọc bỏ vĩnh viễn bài viết đã xóa
      final seenLinks = <String>{};
      _articles = rawArticles.where((article) {
        if (_deletedArticleTitles.contains(article.title) ||
            _deletedArticleTitles.contains(article.link)) {
          return false;
        }
        return seenLinks.add(article.link);
      }).toList();

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
    final approved = _getApprovedArticles();
    final count = _currentPage * _pageSize;
    if (count >= approved.length) {
      _displayedArticles = List.from(approved);
    } else {
      _displayedArticles = approved.take(count).toList();
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
    await deleteArticlePermanently(title);
  }

  List<Article> searchArticles(String query) {
    if (query.trim().isEmpty) return [];
    final lower = query.toLowerCase().trim();
    return _getApprovedArticles().where((article) {
      return article.title.toLowerCase().contains(lower) ||
          article.description.toLowerCase().contains(lower) ||
          article.source.toLowerCase().contains(lower);
    }).toList();
  }

  /// Tìm kiếm bài viết toàn diện trên toàn bộ nguồn tin và chuyên mục
  Future<List<Article>> searchArticlesAsync(String query) async {
    if (query.trim().isEmpty) return [];
    final lower = query.toLowerCase().trim();

    final localMatches = searchArticles(query);
    if (localMatches.length >= 8) {
      return localMatches;
    }

    try {
      final seenLinks = localMatches.map((a) => a.link).toSet();
      final results = List<Article>.from(localMatches);

      final targetCategories = _categories.take(7);
      final futures = targetCategories
          .map((c) => _service.fetchCategory(c).catchError((_) => <Article>[]));
      final lists = await Future.wait(futures);

      for (final list in lists) {
        for (final a in list) {
          if (_deletedArticleTitles.contains(a.title) ||
              _deletedArticleTitles.contains(a.link) ||
              _pendingArticleTitles.contains(a.title)) {
            continue;
          }
          if (seenLinks.add(a.link)) {
            if (a.title.toLowerCase().contains(lower) ||
                a.description.toLowerCase().contains(lower) ||
                a.source.toLowerCase().contains(lower)) {
              results.add(a);
            }
          }
        }
      }
      return results;
    } catch (_) {
      return localMatches;
    }
  }
}
