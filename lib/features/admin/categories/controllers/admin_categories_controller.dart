import '../../../../services/news_service.dart';
import '../../../news/providers/news_provider.dart';

/// Controller xử lý nghiệp vụ quản lý danh mục và nguồn tin RSS
class AdminCategoriesController {
  final NewsProvider newsProvider;

  AdminCategoriesController({required this.newsProvider});

  List<NewsCategory> get categories => newsProvider.allCategories;
  NewsCategory get selectedCategory => newsProvider.selectedCategory;
  Set<String> get selectedCategoryIds => newsProvider.selectedCategoryIds;
  bool get isLoading => newsProvider.status == NewsStatus.loading;

  Future<void> toggleCategoryEnabled(String id) async {
    await newsProvider.toggleCategoryEnabled(id);
  }

  void selectCategory(NewsCategory category) {
    newsProvider.selectCategory(category);
  }

  void toggleCategory(NewsCategory category) {
    newsProvider.toggleCategory(category);
  }

  void toggleCategorySelection(NewsCategory category) {
    newsProvider.toggleCategory(category);
  }

  void selectAllCategories() {
    newsProvider.selectAllCategories();
  }

  Future<bool> addCategory({
    required String label,
    required String rssUrl,
    required String source,
  }) async {
    return await newsProvider.addCategory(
      label: label,
      rssUrl: rssUrl,
      source: source,
    );
  }

  Future<void> deleteCategory(String id) async {
    await newsProvider.deleteCategory(id);
  }

  Future<bool> updateCategorySettings({
    required String categoryId,
    int? maxArticles,
    int? retentionDays,
  }) async {
    return await newsProvider.updateCategorySettings(
      categoryId: categoryId,
      maxArticles: maxArticles,
      retentionDays: retentionDays,
    );
  }

  Future<void> restoreDefaultCategories() async {
    await newsProvider.restoreDefaultCategories();
  }

  Future<void> refreshNews() async {
    await newsProvider.fetchNews();
  }
}
