import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../models/article.dart';
import '../../news/presentation/article_detail_screen.dart';
import '../../news/providers/news_provider.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<String> _history = [];
  List<Article> _searchResults = [];
  bool _hasSearched = false;

  final List<String> _trendingTopics = [
    'Thời tiết hôm nay',
    'Bóng đá',
    'Công nghệ AI',
    'Kinh tế',
    'Giao thông',
    'Giáo dục',
  ];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _history = prefs.getStringList('search_history') ??
          ['thời tiết', 'tin thể thao', 'công nghệ'];
    });
  }

  Future<void> _saveHistory(String query) async {
    if (query.trim().isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    _history.remove(query.trim());
    _history.insert(0, query.trim());
    if (_history.length > 8) _history = _history.sublist(0, 8);
    await prefs.setStringList('search_history', _history);
    setState(() {});
  }

  Future<void> _clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('search_history');
    setState(() {
      _history.clear();
    });
  }

  void _performSearch(String query) {
    if (query.trim().isEmpty) return;
    _saveHistory(query);
    _searchController.text = query;
    final newsProvider = context.read<NewsProvider>();
    final results = newsProvider.searchArticles(query);
    setState(() {
      _searchResults = results;
      _hasSearched = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.only(right: 16),
          child: TextField(
            controller: _searchController,
            textInputAction: TextInputAction.search,
            autofocus: true,
            onSubmitted: _performSearch,
            decoration: InputDecoration(
              hintText: 'Tìm kiếm tin tức...',
              filled: true,
              fillColor: cs.surfaceContainerHighest,
              prefixIcon: const Icon(Icons.search_rounded, size: 20),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _hasSearched = false;
                          _searchResults.clear();
                        });
                      },
                    )
                  : null,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide(color: cs.primary, width: 1.5),
              ),
            ),
          ),
        ),
      ),
      body: _hasSearched
          ? _buildSearchResults()
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [cs.primary, cs.primary.withOpacity(0.78)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.explore_rounded,
                          color: Colors.white, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Khám phá tin tức theo chủ đề bạn quan tâm',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                Text(
                  'Từ khóa phổ biến',
                  style: tt.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _trendingTopics.map((item) {
                    return ActionChip(
                      label: Text(item),
                      onPressed: () => _performSearch(item),
                      side: BorderSide(color: cs.outlineVariant),
                      backgroundColor: cs.surface,
                      labelStyle: TextStyle(
                        fontSize: 13,
                        color: cs.onSurfaceVariant,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),

                // 2. Lịch sử tìm kiếm
                if (_history.isNotEmpty) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Lịch sử tìm kiếm',
                        style: tt.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: cs.onSurface,
                        ),
                      ),
                      TextButton(
                        onPressed: _clearHistory,
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                        ),
                        child: Text(
                          'Xóa tất cả',
                          style: TextStyle(fontSize: 13, color: cs.primary),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ..._history.map((term) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: ListTile(
                        dense: true,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        tileColor: cs.surface,
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 12),
                        leading: Icon(Icons.history_rounded,
                            color: cs.primary, size: 20),
                        title: Text(term,
                            style:
                                TextStyle(fontSize: 14, color: cs.onSurface)),
                        trailing: Icon(Icons.north_west_rounded,
                            size: 16, color: cs.outline),
                        onTap: () => _performSearch(term),
                      ),
                    );
                  }),
                ],
              ],
            ),
    );
  }

  Widget _buildSearchResults() {
    final cs = Theme.of(context).colorScheme;

    if (_searchResults.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search_off_rounded, size: 56, color: cs.outline),
              const SizedBox(height: 16),
              Text(
                'Không tìm thấy kết quả',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Không có bài báo nào phù hợp với từ khóa "${_searchController.text}".',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: _searchResults.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final article = _searchResults[index];
        return InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ArticleDetailScreen(article: article),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: cs.outlineVariant),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: article.imageUrl != null
                      ? Image.network(
                          article.imageUrl!,
                          width: 88,
                          height: 66,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 88,
                            height: 66,
                            color: cs.surfaceContainerHighest,
                            child: Icon(Icons.image_outlined,
                                color: cs.outline, size: 24),
                          ),
                        )
                      : Container(
                          width: 88,
                          height: 66,
                          color: cs.surfaceContainerHighest,
                          child: Icon(Icons.image_outlined,
                              color: cs.outline, size: 24),
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        article.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w600,
                              height: 1.35,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        article.source,
                        style: TextStyle(
                          fontSize: 11,
                          color: cs.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
