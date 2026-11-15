import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/article.dart';
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
    if (diff.inDays > 0) return '${diff.inDays} giờ trước';
    if (diff.inHours > 0) return '${diff.inHours} giờ trước';
    if (diff.inMinutes > 0) return '${diff.inMinutes} phút trước';
    return 'Vừa xong';
  }

  void _showCityPicker(BuildContext context, WeatherProvider weatherProvider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Chọn địa điểm xem thời tiết',
                style: TextStyle(
                  fontSize: 16.5,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 10),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: weatherProvider.cities.length,
                  itemBuilder: (ctx, idx) {
                    final city = weatherProvider.cities[idx];
                    final isSelected =
                        weatherProvider.selectedCity.name == city.name;
                    return ListTile(
                      leading: Icon(
                        Icons.location_on_rounded,
                        color: isSelected
                            ? const Color(0xFF1E60F2)
                            : Colors.grey.shade400,
                      ),
                      title: Text(
                        city.name,
                        style: TextStyle(
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected
                              ? const Color(0xFF1E60F2)
                              : const Color(0xFF0F172A),
                        ),
                      ),
                      trailing: isSelected
                          ? const Icon(Icons.check_rounded,
                              color: Color(0xFF1E60F2))
                          : null,
                      onTap: () {
                        weatherProvider.selectCity(city);
                        Navigator.pop(ctx);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showCategoriesSheet(BuildContext context, NewsProvider newsProvider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Tất cả chuyên mục tin tức',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const Divider(),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: newsProvider.categories.map((cat) {
                    final isSelected = newsProvider.selectedCategory.id == cat.id;
                    return InkWell(
                      onTap: () {
                        newsProvider.selectCategory(cat);
                        Navigator.pop(ctx);
                        onNavigateToNews?.call();
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF1E60F2)
                              : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          cat.label,
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : const Color(0xFF334155),
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
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

    final Article? featuredArticle =
        articles.isNotEmpty ? articles.first : null;
    final List<Article> latestArticles =
        articles.length > 1 ? articles.skip(1).take(10).toList() : [];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: RefreshIndicator(
            onRefresh: () async {
              await Future.wait([
                newsProvider.fetchNews(),
                weatherProvider.fetchWeather(),
              ]);
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              child: Column(
                children: [
                  // ══════════════════════════════════════════════════════
                  // 1. TOP WEATHER HERO SECTION (Gradient Xanh Trời + Thành Phố)
                  // ══════════════════════════════════════════════════════
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFF1654F0),
                          Color(0xFF2667FF),
                          Color(0xFF5BA0FC),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    child: SafeArea(
                      bottom: false,
                      child: Column(
                        children: [
                          // Top bar: Location Hà Nội v  &  Search Icon
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 8, 12, 10),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Địa điểm chọn thành phố
                                InkWell(
                                  onTap: () =>
                                      _showCityPicker(context, weatherProvider),
                                  borderRadius: BorderRadius.circular(20),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.location_on_rounded,
                                          color: Colors.white,
                                          size: 19,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          weather?.cityName ??
                                              weatherProvider.selectedCity.name,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 16.5,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: -0.2,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        const Icon(
                                          Icons.keyboard_arrow_down_rounded,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                // Search icon
                                IconButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const SearchScreen(),
                                      ),
                                    );
                                  },
                                  icon: const Icon(
                                    Icons.search_rounded,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                  tooltip: 'Tìm kiếm',
                                ),
                              ],
                            ),
                          ),

                          // Weather stats: 3D Sun & Cloud  +  28°C Có mây
                          InkWell(
                            onTap: onNavigateToWeather ??
                                () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const WeatherScreen(),
                                    ),
                                  );
                                },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 4),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  // Left: Sun & Cloud Graphic 3D
                                  _buildSunCloudGraphic(),

                                  // Center/Right: Temperature & Condition
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        weather != null
                                            ? '${weather.temperature.round()}°C'
                                            : '28°C',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 42,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: -1.5,
                                          height: 1.0,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Text(
                                            weather?.description ?? 'Có mây',
                                            style: TextStyle(
                                              color: Colors.white
                                                  .withOpacity(0.95),
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Icon(
                                            Icons.air_rounded,
                                            color:
                                                Colors.white.withOpacity(0.85),
                                            size: 16,
                                          ),
                                          const SizedBox(width: 2),
                                          Text(
                                            '${weather?.windSpeed.round() ?? 12}km/h',
                                            style: TextStyle(
                                              color: Colors.white
                                                  .withOpacity(0.85),
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Dải hình ảnh thành phố toàn cảnh chân trời (Mockup City Skyline)
                          SizedBox(
                            height: 75,
                            width: double.infinity,
                            child: Image.network(
                              'https://images.unsplash.com/photo-1508873696983-2df5293cb32f?w=1000',
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Image.asset(
                                'assets/images/city_skyline.png',
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    const SizedBox(height: 30),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ══════════════════════════════════════════════════════
                  // 2. FLOATING ACTION CARD (Thẻ Trắng Bo Góc Gồm 4 Nút Tròn Chuẩn Mẫu)
                  // ══════════════════════════════════════════════════════
                  Transform.translate(
                    offset: const Offset(0, -18),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.06),
                              blurRadius: 18,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildActionButton(
                              label: 'Tin tức',
                              icon: Icons.newspaper_rounded,
                              color: const Color(0xFF2563EB),
                              onTap: onNavigateToNews ?? () {},
                            ),
                            _buildActionButton(
                              label: 'Thời tiết',
                              icon: Icons.cloud_rounded,
                              color: const Color(0xFF0284C7),
                              onTap: onNavigateToWeather ?? () {},
                            ),
                            _buildActionButton(
                              label: 'Yêu thích',
                              icon: Icons.favorite_rounded,
                              color: const Color(0xFFFF6B00),
                              onTap: onNavigateToFavorites ?? () {},
                            ),
                            _buildActionButton(
                              label: 'Thêm',
                              icon: Icons.tune_rounded,
                              color: const Color(0xFF0D9488),
                              onTap: () =>
                                  _showCategoriesSheet(context, newsProvider),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // ══════════════════════════════════════════════════════
                  // 3. MỤC "TIN NỔI BẬT" (Chuẩn Mockup: Card Trắng + Ảnh Khung Rộng)
                  // ══════════════════════════════════════════════════════
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Tin nổi bật',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0F172A),
                                letterSpacing: -0.3,
                              ),
                            ),
                            GestureDetector(
                              onTap: onNavigateToNews,
                              child: const Text(
                                'Xem tất cả >',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1E60F2),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Card Tin Nổi Bật Chuẩn Mockup
                        _buildFeaturedCard(context, featuredArticle),
                      ],
                    ),
                  ),

                  // ══════════════════════════════════════════════════════
                  // 4. MỤC "TIN MỚI NHẤT" (Danh Sách Tin)
                  // ══════════════════════════════════════════════════════
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Tin mới nhất',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0F172A),
                                letterSpacing: -0.3,
                              ),
                            ),
                            GestureDetector(
                              onTap: onNavigateToNews,
                              child: const Text(
                                'Xem tất cả >',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1E60F2),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        if (newsProvider.status == NewsStatus.loading &&
                            articles.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 40),
                            child: Center(
                              child: CircularProgressIndicator(
                                color: Color(0xFF1E60F2),
                              ),
                            ),
                          )
                        else if (latestArticles.isEmpty &&
                            featuredArticle == null)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 30),
                            child: Center(
                              child: Text(
                                'Đang tải tin tức...',
                                style: TextStyle(color: Colors.grey.shade500),
                              ),
                            ),
                          )
                        else
                          ...latestArticles.map((article) {
                            return _buildNewsItem(context, article);
                          }),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── WIDGET: 4 NÚT TRÒN TRÊN THẺ TRẮNG ──────────────────────────────
  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.32),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: Color(0xFF334155),
            ),
          ),
        ],
      ),
    );
  }

  // ── WIDGET: CARD TIN NỔI BẬT (Ảnh toàn cảnh + Tiêu đề nền trắng chuẩn mẫu) ──
  Widget _buildFeaturedCard(BuildContext context, Article? article) {
    final title = article?.title ??
        'Việt Nam đẩy mạnh chuyển đổi số trong năm 2025';
    final imageUrl = article?.imageUrl ??
        'https://images.unsplash.com/photo-1508873696983-2df5293cb32f?w=900';

    return InkWell(
      onTap: article != null
          ? () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ArticleDetailScreen(article: article),
                ),
              );
            }
          : null,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top: Large photographic landscape image
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(18)),
              child: Image.network(
                imageUrl,
                height: 145,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 145,
                  width: double.infinity,
                  color: const Color(0xFFDBEAFE),
                  child: const Icon(
                    Icons.image_outlined,
                    color: Color(0xFF1E60F2),
                    size: 40,
                  ),
                ),
              ),
            ),

            // Bottom: Title & Source/Time
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                      height: 1.35,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          article?.source ?? 'VnExpress',
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E60F2),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _getTimeAgo(article?.publishedAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
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

  // ── WIDGET: TIN MỚI NHẤT DẠNG HÀNG NGANG ────────────────────────────
  Widget _buildNewsItem(BuildContext context, Article article) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ArticleDetailScreen(article: article),
          ),
        );
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                article.imageUrl ??
                    'https://images.unsplash.com/photo-1585829365295-ab7cd400c167?w=400',
                width: 95,
                height: 72,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 95,
                  height: 72,
                  color: Colors.grey.shade200,
                  child: Icon(Icons.image, color: Colors.grey.shade400),
                ),
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
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        _getTimeAgo(article.publishedAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                      Text(
                        ' • ${article.source}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E60F2),
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

  // ── GRAPHIC: MẶT TRỜI VÀNG & MÂY TRẮNG 3D ──────────────────────────
  Widget _buildSunCloudGraphic() {
    return SizedBox(
      width: 80,
      height: 70,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Mặt trời vàng tỏa sáng
          Positioned(
            right: 10,
            top: 2,
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const RadialGradient(
                  colors: [Color(0xFFFFF9C4), Color(0xFFFFB300), Color(0xFFFF8F00)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFFB300).withOpacity(0.5),
                    blurRadius: 14,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
          ),
          // Đám mây trắng mềm mại che phía trước
          Positioned(
            left: 0,
            bottom: 0,
            child: Icon(
              Icons.cloud_rounded,
              color: Colors.white.withOpacity(0.96),
              size: 52,
            ),
          ),
        ],
      ),
    );
  }
}
