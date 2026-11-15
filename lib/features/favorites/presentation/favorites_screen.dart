import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/article.dart';
import '../../news/presentation/article_detail_screen.dart';
import '../providers/favorites_provider.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final fp = context.watch<FavoritesProvider>();
    final favorites = fp.favorites;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('Đã lưu (${favorites.length})'),
        actions: favorites.isNotEmpty
            ? [
                TextButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Xóa tất cả'),
                        content: const Text(
                            'Bạn có chắc muốn xóa toàn bộ bài đã lưu?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Hủy'),
                          ),
                          FilledButton(
                            onPressed: () {
                              for (final a in List<Article>.from(favorites)) {
                                fp.toggleFavorite(a);
                              }
                              Navigator.pop(ctx);
                            },
                            child: const Text('Xóa'),
                          ),
                        ],
                      ),
                    );
                  },
                  child: const Text('Xóa tất cả'),
                ),
                const SizedBox(width: 4),
              ]
            : null,
      ),
      body: favorites.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.bookmark_outline_rounded,
                      size: 56, color: cs.outline),
                  const SizedBox(height: 16),
                  Text('Chưa có bài viết nào được lưu',
                      style: tt.titleMedium),
                  const SizedBox(height: 8),
                  Text(
                    'Nhấn ♡ trong bài báo để lưu lại đọc sau.',
                    style: TextStyle(
                        fontSize: 13, color: cs.onSurfaceVariant),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: favorites.length,
              separatorBuilder: (_, __) =>
                  Divider(height: 1, color: cs.outlineVariant),
              itemBuilder: (context, index) {
                final article = favorites[index];
                return _FavoriteRow(article: article, provider: fp);
              },
            ),
    );
  }
}

class _FavoriteRow extends StatelessWidget {
  final Article article;
  final FavoritesProvider provider;

  const _FavoriteRow({required this.article, required this.provider});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Dismissible(
      key: ValueKey(article.link),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: cs.errorContainer,
        child: Icon(Icons.delete_outline_rounded, color: cs.error),
      ),
      onDismissed: (_) => provider.toggleFavorite(article),
      child: InkWell(
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
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: article.imageUrl != null
                    ? Image.network(
                        article.imageUrl!,
                        width: 80,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 80,
                          height: 60,
                          color: cs.surfaceContainerHighest,
                          child: Icon(Icons.image_outlined,
                              color: cs.outline, size: 20),
                        ),
                      )
                    : Container(
                        width: 80,
                        height: 60,
                        color: cs.surfaceContainerHighest,
                        child: Icon(Icons.image_outlined,
                            color: cs.outline, size: 20),
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
                          ?.copyWith(fontWeight: FontWeight.w600, height: 1.35),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      article.source,
                      style: TextStyle(
                          fontSize: 11,
                          color: cs.primary,
                          fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon:
                    Icon(Icons.bookmark_remove_outlined, color: cs.error),
                tooltip: 'Bỏ lưu',
                visualDensity: VisualDensity.compact,
                onPressed: () => provider.toggleFavorite(article),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
