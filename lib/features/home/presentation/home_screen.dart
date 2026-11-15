import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/article.dart';
import '../../../utils/app_colors.dart';
import '../../news/presentation/article_detail_screen.dart';
import '../../news/providers/news_provider.dart';
import '../../search/presentation/search_screen.dart';
import '../../weather/presentation/weather_screen.dart';
import '../../weather/providers/weather_provider.dart';

class HomeScreen extends StatelessWidget {
  final VoidCallback? onNavigateToNews;
  final VoidCallback? onNavigateToWeather;
  final VoidCallback? onNavigateToFavorites;

  const HomeScreen({
    super.key,
    this.onNavigateToNews,
    this.onNavigateToWeather,
    this.onNavigateToFavorites,
  });

  String _getTimeAgo(DateTime? date) {
    if (date == null) return 'Vừa xong';
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 0) return '${diff.inDays} ngày trước';
    if (diff.inHours > 0) return '${diff.inHours} giờ trước';
    if (diff.inMinutes > 0) return '${diff.inMinutes} phút trước';
    return 'Vừa xong';
  }

  void _showCityPicker(BuildContext context, WeatherProvider weatherProvider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(ctx).colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Chọn địa điểm',
                  style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              const SizedBox(height: 8),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: weatherProvider.cities.length,
                  itemBuilder: (ctx, idx) {
                    final city = weatherProvider.cities[idx];
                    final isSelected =
                        weatherProvider.selectedCity.name == city.name;
                    return ListTile(
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 20),
                      leading: Icon(
                        isSelected
                            ? Icons.location_on_rounded
                            : Icons.location_on_outlined,
                        color: isSelected
                            ? AppColors.primary
                            : Theme.of(ctx).colorScheme.outline,
                        size: 20,
                      ),
                      title: Text(
                        city.name,
                        style: TextStyle(
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.normal,
                          color: isSelected
                              ? AppColors.primary
                              : Theme.of(ctx).colorScheme.onSurface,
                        ),
                      ),
                      trailing: isSelected
                          ? Icon(Icons.check_rounded,
                              color: AppColors.primary, size: 18)
                          : null,
                      onTap: () {
                        weatherProvider.selectCity(city);
                        Navigator.pop(ctx);
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  void _showCategoriesSheet(BuildContext context, NewsProvider newsProvider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Chuyên mục',
                      style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      visualDensity: VisualDensity.compact,
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: newsProvider.categories.map((cat) {
                    final isSelected =
                        newsProvider.selectedCategory.id == cat.id;
                    return FilterChip(
                      label: Text(cat.label),
                      selected: isSelected,
                      onSelected: (_) {
                        newsProvider.selectCategory(cat);
                        Navigator.pop(ctx);
                        onNavigateToNews?.call();
                      },
                      selectedColor:
                          AppColors.primary.withOpacity(0.15),
                      checkmarkColor: AppColors.primary,
                      labelStyle: TextStyle(
                        color: isSelected
                            ? AppColors.primary
                            : Theme.of(ctx).colorScheme.onSurfaceVariant,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.normal,
                        fontSize: 13,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final newsProvider = context.watch<NewsProvider>();
    final weatherProvider = context.watch<WeatherProvider>();
    final weather = weatherProvider.weather;
    final articles = newsProvider.articles;
    final cs = Theme.of(context).colorScheme;

    final Article? featuredArticle =
        articles.isNotEmpty ? articles.first : null;
    final List<Article> latestArticles =
        articles.length > 1 ? articles.skip(1).take(10).toList() : [];

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([
            newsProvider.fetchNews(),
            weatherProvider.fetchWeather(),
          ]);
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // ── APP BAR với thời tiết ─────────────────────────────────
            SliverAppBar(
              expandedHeight: 160,
              pinned: true,
              backgroundColor: AppColors.primary,
              surfaceTintColor: AppColors.primary,
              automaticallyImplyLeading: false,
              title: GestureDetector(
                onTap: () => _showCityPicker(context, weatherProvider),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.location_on_rounded,
                        color: Colors.white70, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      weather?.cityName ??
                          weatherProvider.selectedCity.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Icon(Icons.keyboard_arrow_down_rounded,
                        color: Colors.white70, size: 18),
                  ],
                ),
              ),
              actions: [
                IconButton(
                  icon:
                      const Icon(Icons.search_rounded, color: Colors.white),
                  tooltip: 'Tìm kiếm',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const SearchScreen()),
                    );
                  },
                ),
                const SizedBox(width: 4),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: GestureDetector(
                  onTap: onNavigateToWeather ??
                      () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const WeatherScreen()),
                          ),
                  child: Container(
                    color: AppColors.primary,
                    padding:
                        const EdgeInsets.fromLTRB(20, 72, 20, 16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Nhiệt độ lớn
                        Text(
                          weather != null
                              ? '${weather.temperature.round()}°'
                              : '--°',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 56,
                            fontWeight: FontWeight.w300,
                            letterSpacing: -2,
                            height: 1,
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Mô tả & gió
                        Expanded(
                          child: Padding(
                            padding:
                                const EdgeInsets.only(bottom: 6),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  weather?.description ?? 'Có mây',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  weather != null
                                      ? '💧 ${weather.humidity}%  💨 ${weather.windSpeed.round()} km/h'
                                      : 'Nhấn để xem chi tiết',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // ── 4 NÚT ĐIỀU HƯỚNG NHANH ───────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _QuickButton(
                      label: 'Tin tức',
                      icon: Icons.newspaper_outlined,
                      onTap: onNavigateToNews ?? () {},
                    ),
                    _QuickButton(
                      label: 'Thời tiết',
                      icon: Icons.cloud_outlined,
                      onTap: onNavigateToWeather ?? () {},
                    ),
                    _QuickButton(
                      label: 'Yêu thích',
                      icon: Icons.bookmark_outline_rounded,
                      onTap: onNavigateToFavorites ?? () {},
                    ),
                    _QuickButton(
                      label: 'Khám phá',
                      icon: Icons.explore_outlined,
                      onTap: () =>
                          _showCategoriesSheet(context, newsProvider),
                    ),
                  ],
                ),
              ),
            ),

            // ── SECTION: TIN NỔI BẬT ─────────────────────────────────
            SliverToBoxAdapter(
              child: _SectionHeader(
                title: 'Tin nổi bật',
                onViewAll: onNavigateToNews,
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _FeaturedCard(
                  article: featuredArticle,
                  timeAgo: _getTimeAgo(featuredArticle?.publishedAt),
                ),
              ),
            ),

            // ── SECTION: TIN MỚI NHẤT ────────────────────────────────
            SliverToBoxAdapter(
              child: _SectionHeader(
                title: 'Tin mới nhất',
                onViewAll: onNavigateToNews,
              ),
            ),

            // Loading / empty state
            if (newsProvider.status == NewsStatus.loading &&
                articles.isEmpty)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 48),
                  child: Center(child: CircularProgressIndicator()),
                ),
              )
            else if (articles.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: Text(
                      'Chưa có tin tức',
                      style: TextStyle(
                          color: cs.onSurfaceVariant, fontSize: 14),
                    ),
                  ),
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, index) {
                    final article = latestArticles[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 0),
                      child: _NewsRow(
                        article: article,
                        timeAgo: _getTimeAgo(article.publishedAt),
                      ),
                    );
                  },
                  childCount: latestArticles.length,
                ),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SHARED PRIVATE WIDGETS
// ─────────────────────────────────────────────────────────────────────────────

class _QuickButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _QuickButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 72,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: cs.primaryContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: cs.primary, size: 24),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
                color: cs.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onViewAll;

  const _SectionHeader({required this.title, this.onViewAll});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          if (onViewAll != null)
            GestureDetector(
              onTap: onViewAll,
              child: Text(
                'Xem tất cả',
                style: TextStyle(
                  fontSize: 13,
                  color: cs.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _FeaturedCard extends StatelessWidget {
  final Article? article;
  final String timeAgo;

  const _FeaturedCard({this.article, required this.timeAgo});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final title = article?.title ?? 'Đang tải tin nổi bật...';
    final imageUrl = article?.imageUrl;

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: article != null
            ? () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ArticleDetailScreen(article: article!),
                  ),
                )
            : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ảnh
            AspectRatio(
              aspectRatio: 16 / 9,
              child: imageUrl != null
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: cs.surfaceContainerHighest,
                        child: Icon(Icons.image_outlined,
                            color: cs.outline, size: 40),
                      ),
                    )
                  : Container(
                      color: cs.surfaceContainerHighest,
                      child: Icon(Icons.image_outlined,
                          color: cs.outline, size: 40),
                    ),
            ),
            // Nội dung
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (article?.source != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        article!.source.toUpperCase(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: cs.primary,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          height: 1.35,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    timeAgo,
                    style: TextStyle(
                      fontSize: 12,
                      color: cs.onSurfaceVariant,
                    ),
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

class _NewsRow extends StatelessWidget {
  final Article article;
  final String timeAgo;

  const _NewsRow({required this.article, required this.timeAgo});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ArticleDetailScreen(article: article),
            ),
          ),
          borderRadius: BorderRadius.circular(12),
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
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(
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
        ),
        Divider(height: 1, color: cs.outlineVariant),
      ],
    );
  }
}
