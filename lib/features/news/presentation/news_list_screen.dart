import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/article.dart';
import '../../favorites/providers/favorites_provider.dart';
import '../../search/presentation/search_screen.dart';
import '../providers/news_provider.dart';
import 'article_detail_screen.dart';

/// Màn hình Danh sách Tin Tức (News List Screen)
/// - Đồng bộ màu sắc và ngôn ngữ thiết kế hoàn toàn với Trang Chủ.
/// - Thiết kế lại phần Header: có Logo, Tiêu đề và Thanh tìm kiếm (Search Bar) bo tròn hiện đại,
///   thay thế nút tìm kiếm trơ trọi cũ.
/// - Thanh Chuyên mục cuộn ngang phong cách Pill Gradient.
/// - Danh sách thẻ tin tức chuẩn Magazine, tích hợp nút Lưu bài viết (Favorites).
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

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF090D1A) : const Color(0xFFF1F5F9);
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
    final subTextColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // 1. TOP HEADER: LOGO, TIÊU ĐỀ & THANH TÌM KIẾM CÂN ĐỐI
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF2563EB), Color(0xFF38BDF8)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF2563EB).withOpacity(0.35),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.feed_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tin tức thời sự',
                              style: TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.w900,
                                color: textColor,
                                letterSpacing: -0.4,
                              ),
                            ),
                            Text(
                              'Tổng hợp từ các nguồn báo chí chính thống',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: subTextColor,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Thanh tìm kiếm dạng Capsule thay cho nút đơn độc cũ
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SearchScreen()),
                      );
                    },
                    child: Container(
                      height: 44,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: borderColor),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.search_rounded,
                              color: const Color(0xFF2563EB), size: 21),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Tìm kiếm tin tức, sự kiện nóng...',
                              style: TextStyle(
                                color: subTextColor,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.tune_rounded,
                            color: subTextColor.withOpacity(0.7),
                            size: 19,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 2. THANH CHUYÊN MỤC DẠNG CUỘN NGANG (CATEGORY PILLS)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: SizedBox(
                height: 38,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: newsProvider.categories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final cat = newsProvider.categories[index];
                    final isSelected =
                        newsProvider.selectedCategory.id == cat.id;

                    return InkWell(
                      onTap: () => newsProvider.selectCategory(cat),
                      borderRadius: BorderRadius.circular(20),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOutCubic,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? (isDark
                                  ? const Color(0xFF2563EB)
                                  : const Color(0xFF1D4ED8))
                              : cardBg,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected
                                ? Colors.transparent
                                : borderColor,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: const Color(0xFF1D4ED8)
                                        .withOpacity(0.22),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Text(
                          cat.label,
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : (isDark
                                    ? const Color(0xFFCBD5E1)
                                    : const Color(0xFF475569)),
                            fontSize: 13,
                            fontWeight:
                                isSelected ? FontWeight.w800 : FontWeight.w600,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            // 3. DANH SÁCH BÀI BÁO (PULL TO REFRESH & LOAD MORE)
            Expanded(
              child: RefreshIndicator(
                color: const Color(0xFF2563EB),
                onRefresh: () => newsProvider.fetchNews(),
                child: _buildArticlesList(
                  context,
                  newsProvider,
                  articles,
                  cardBg,
                  borderColor,
                  textColor,
                  subTextColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArticlesList(
    BuildContext context,
    NewsProvider provider,
    List<Article> articles,
    Color cardBg,
    Color borderColor,
    Color textColor,
    Color subTextColor,
  ) {
    if (provider.status == NewsStatus.loading && articles.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF2563EB)),
      );
    }

    if (provider.status == NewsStatus.error && articles.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.cloud_off_rounded, color: subTextColor, size: 54),
              const SizedBox(height: 12),
              Text(
                'Không tải được tin tức: ${provider.errorMessage}',
                textAlign: TextAlign.center,
                style: TextStyle(color: subTextColor),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => provider.fetchNews(),
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification scrollInfo) {
        if (scrollInfo.metrics.pixels >=
                scrollInfo.metrics.maxScrollExtent - 200 &&
            provider.hasMore) {
          provider.loadMore();
        }
        return false;
      },
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        itemCount: articles.length + (provider.hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == articles.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    color: Color(0xFF2563EB),
                  ),
                ),
              ),
            );
          }

          final article = articles[index];

          // Bài viết đầu tiên: Thẻ Featured Card khổ lớn
          if (index == 0) {
            return _buildFeaturedArticleCard(
              context: context,
              article: article,
            );
          }

          // Các bài tiếp theo: Thẻ tin tức Magazine Card chuẩn
          return InkWell(
            key: ValueKey(article.link),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ArticleDetailScreen(article: article),
                ),
              );
            },
            borderRadius: BorderRadius.circular(20),
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: borderColor, width: 1.1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: SizedBox(
                      width: 110,
                      height: 84,
                      child: article.imageUrl != null
                          ? CachedNetworkImage(
                              imageUrl: article.imageUrl!,
                              memCacheWidth: 330,
                              memCacheHeight: 252,
                              fit: BoxFit.cover,
                              placeholder: (_, __) =>
                                  _buildImagePlaceholder(article.source),
                              errorWidget: (_, __, ___) =>
                                  _buildImagePlaceholder(article.source),
                            )
                          : _buildImagePlaceholder(article.source),
                    ),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2563EB).withOpacity(0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                article.source.isNotEmpty
                                    ? article.source
                                    : article.category,
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF2563EB),
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                _getTimeAgo(article.publishedAt),
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w500,
                                  color: subTextColor,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Selector<FavoritesProvider, bool>(
                              selector: (_, fav) => fav.isFavorite(article),
                              builder: (context, isFav, _) {
                                return InkWell(
                                  onTap: () => context
                                      .read<FavoritesProvider>()
                                      .toggleFavorite(article),
                                  borderRadius: BorderRadius.circular(20),
                                  child: SizedBox(
                                    width: 36,
                                    height: 36,
                                    child: Center(
                                      child: Icon(
                                        isFav
                                            ? Icons.favorite_rounded
                                            : Icons.favorite_border_rounded,
                                        color: isFav
                                            ? const Color(0xFFEF4444)
                                            : subTextColor.withOpacity(0.7),
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        Text(
                          article.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            color: textColor,
                            height: 1.35,
                            letterSpacing: -0.2,
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
      ),
    );
  }

  // Thẻ bài viết đầu tiên nổi bật (Featured Hero Card)
  Widget _buildFeaturedArticleCard({
    required BuildContext context,
    required Article article,
  }) {
    return InkWell(
      key: ValueKey('featured_${article.link}'),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ArticleDetailScreen(article: article),
          ),
        );
      },
      borderRadius: BorderRadius.circular(22),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        height: 220,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.18),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (article.imageUrl != null)
                CachedNetworkImage(
                  imageUrl: article.imageUrl!,
                  memCacheWidth: 800,
                  fit: BoxFit.cover,
                  placeholder: (_, __) =>
                      _buildImagePlaceholder(article.source),
                  errorWidget: (_, __, ___) =>
                      _buildImagePlaceholder(article.source),
                )
              else
                _buildImagePlaceholder(article.source),

              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.35),
                      Colors.black.withOpacity(0.88),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0.35, 0.60, 1.0],
                  ),
                ),
              ),

              Positioned(
                top: 14,
                left: 14,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2563EB).withOpacity(0.85),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.bolt_rounded,
                              size: 14, color: Colors.yellow),
                          const SizedBox(width: 4),
                          Text(
                            article.source.isNotEmpty
                                ? article.source
                                : 'TIÊU ĐIỂM',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              Positioned(
                top: 10,
                right: 10,
                child: Selector<FavoritesProvider, bool>(
                  selector: (_, fav) => fav.isFavorite(article),
                  builder: (context, isFav, _) {
                    return InkWell(
                      onTap: () => context.read<FavoritesProvider>().toggleFavorite(article),
                      borderRadius: BorderRadius.circular(22),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.45),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withOpacity(0.35),
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            isFav
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            color: isFav ? const Color(0xFFEF4444) : Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              Positioned(
                left: 16,
                right: 16,
                bottom: 14,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      article.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16.5,
                        fontWeight: FontWeight.w800,
                        height: 1.3,
                        letterSpacing: -0.2,
                        shadows: [
                          Shadow(
                            color: Colors.black87,
                            blurRadius: 8,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.access_time_rounded,
                            size: 13, color: Colors.white.withOpacity(0.8)),
                        const SizedBox(width: 4),
                        Text(
                          _getTimeAgo(article.publishedAt),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withOpacity(0.85),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '•  ${article.category}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF93C5FD),
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
      ),
    );
  }

  Widget _buildImagePlaceholder(String source) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1E293B), Color(0xFF334155)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.newspaper_rounded, color: Colors.white54, size: 28),
            const SizedBox(height: 4),
            Text(
              source.isNotEmpty ? source : 'Tin tức',
              style: const TextStyle(
                color: Colors.white60,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
