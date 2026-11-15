import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/article.dart';
import '../../search/presentation/search_screen.dart';
import '../providers/news_provider.dart';
import 'article_detail_screen.dart';

class NewsListScreen extends StatelessWidget {
  const NewsListScreen({super.key});

  String _getTimeAgo(DateTime? date) {
    if (date == null) return 'Vừa xong';
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 0) return '${diff.inDays} ngày trước';
    if (diff.inHours > 0) return '${diff.inHours} giờ trước';
    if (diff.inMinutes > 0) return '${diff.inMinutes} phút trước';
    return 'Vừa xong';
  }

  @override
  Widget build(BuildContext context) {
    final newsProvider = context.watch<NewsProvider>();
    final articles = newsProvider.articles;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tin tức'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            tooltip: 'Tìm kiếm',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SearchScreen()),
            ),
          ),
          const SizedBox(width: 4),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: Container(
            color: Theme.of(context).colorScheme.surface,
            child: SizedBox(
              height: 48,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: newsProvider.categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final cat = newsProvider.categories[index];
                  final isSelected =
                      newsProvider.selectedCategory.id == cat.id;
                  return FilterChip(
                    label: Text(cat.label),
                    selected: isSelected,
                    onSelected: (_) => newsProvider.selectCategory(cat),
                    selectedColor: cs.primaryContainer,
                    checkmarkColor: cs.primary,
                    labelStyle: TextStyle(
                      color: isSelected
                          ? cs.primary
                          : cs.onSurfaceVariant,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                      fontSize: 13,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    visualDensity: VisualDensity.compact,
                  );
                },
              ),
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => newsProvider.fetchNews(),
        child: _buildBody(context, newsProvider, articles),
      ),
    );
  }

  Widget _buildBody(
      BuildContext context, NewsProvider provider, List<Article> articles) {
    final cs = Theme.of(context).colorScheme;

    if (provider.status == NewsStatus.loading && articles.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.status == NewsStatus.error && articles.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.cloud_off_outlined, size: 48, color: cs.outline),
              const SizedBox(height: 16),
              Text(
                'Không tải được tin tức',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                provider.errorMessage,
                textAlign: TextAlign.center,
                style:
                    TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: 20),
              FilledButton.tonal(
                onPressed: () => provider.fetchNews(),
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (info) {
        if (info.metrics.pixels >= info.metrics.maxScrollExtent - 200 &&
            provider.hasMore) {
          provider.loadMore();
        }
        return false;
      },
      child: ListView.separated(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: articles.length + (provider.hasMore ? 1 : 0),
        separatorBuilder: (_, __) =>
            Divider(height: 1, color: cs.outlineVariant),
        itemBuilder: (context, index) {
          if (index == articles.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            );
          }

          final article = articles[index];
          return _ArticleRow(
            article: article,
            timeAgo: _getTimeAgo(article.publishedAt),
          );
        },
      ),
    );
  }
}

class _ArticleRow extends StatelessWidget {
  final Article article;
  final String timeAgo;

  const _ArticleRow({required this.article, required this.timeAgo});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => ArticleDetailScreen(article: article)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
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
            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    article.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style:
                        Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              height: 1.35,
                            ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        article.source,
                        style: TextStyle(
                          fontSize: 11,
                          color: cs.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '  ·  $timeAgo',
                        style: TextStyle(
                          fontSize: 11,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
