import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/article.dart';
import '../../auth/providers/auth_provider.dart';
import '../../news/presentation/article_detail_screen.dart';
import '../../news/providers/news_provider.dart';
import '../../notifications/presentation/notifications_screen.dart';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1C2541) : Colors.white;
    final textColor = isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);

    showModalBottomSheet(
      context: context,
      backgroundColor: cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 14),
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF334155) : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Chọn địa điểm xem thời tiết',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 10),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  itemCount: weatherProvider.cities.length,
                  itemBuilder: (ctx, idx) {
                    final city = weatherProvider.cities[idx];
                    final isSelected =
                        weatherProvider.selectedCity.name == city.name;
                    return ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
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
                              : textColor,
                        ),
                      ),
                      trailing: isSelected
                          ? const Icon(Icons.check_circle_rounded,
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
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final newsProvider = context.watch<NewsProvider>();
    final weatherProvider = context.watch<WeatherProvider>();
    final authProvider = context.watch<AuthProvider>();
    final weather = weatherProvider.weather;
    final articles = newsProvider.articles;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0B132B) : const Color(0xFFF6F9FD);
    final textColor = isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
    final subTextColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final cardBg = isDark ? const Color(0xFF1C2541) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    final Article? featuredArticle =
        articles.isNotEmpty ? articles.first : null;
    final List<Article> latestArticles =
        articles.length > 1 ? articles.skip(1).take(12).toList() : [];

    final userName = authProvider.isAuthenticated
        ? authProvider.displayName.split(' ').last
        : '';

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          // ── HIỆU ỨNG ÁNH SÁNG MỜ ẢO NỀN (ATMOSPHERIC GLOW BLURS) ──────
          Positioned(
            top: -60,
            right: -40,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: (isDark ? const Color(0xFF1E40AF) : const Color(0xFF93C5FD))
                    .withOpacity(0.35),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 70, sigmaY: 70),
                child: Container(color: Colors.transparent),
              ),
            ),
          ),
          Positioned(
            top: 240,
            left: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: (isDark ? const Color(0xFF3730A3) : const Color(0xFFC7D2FE))
                    .withOpacity(0.28),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
                child: Container(color: Colors.transparent),
              ),
            ),
          ),

          // ── NỘI DUNG CUỘN CHÍNH ─────────────────────────────────────
          SafeArea(
            child: RefreshIndicator(
              color: const Color(0xFF1E60F2),
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
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),

                    // ══════════════════════════════════════════════════
                    // 1. TOP BAR: LOGO "DAILY NEWS" + THÔNG BÁO & SEARCH
                    // ══════════════════════════════════════════════════
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Logo + Daily News text
                        Row(
                          children: [
                            Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF2563EB), Color(0xFF38BDF8)],
                                ),
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF2563EB).withOpacity(0.35),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.newspaper_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Daily News',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: textColor,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ],
                        ),

                        // Nút Tìm kiếm & Chuông Thông báo có chấm đỏ
                        Row(
                          children: [
                            _buildFrostedIconButton(
                              icon: Icons.search_rounded,
                              isDark: isDark,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const SearchScreen(),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(width: 8),
                            Stack(
                              children: [
                                _buildFrostedIconButton(
                                  icon: Icons.notifications_none_rounded,
                                  isDark: isDark,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const NotificationsScreen(),
                                      ),
                                    );
                                  },
                                ),
                                Positioned(
                                  right: 8,
                                  top: 8,
                                  child: Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEF4444),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: isDark ? const Color(0xFF1C2541) : Colors.white,
                                        width: 1.5,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // ══════════════════════════════════════════════════
                    // 2. LỜI CHÀO "XIN CHÀO! 👋"
                    // ══════════════════════════════════════════════════
                    Text(
                      userName.isNotEmpty ? 'Xin chào, $userName! 👋' : 'Xin chào! 👋',
                      style: TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.w900,
                        color: textColor,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Cùng cập nhật tin tức mới nhất nhé!',
                      style: TextStyle(
                        fontSize: 14,
                        color: subTextColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ══════════════════════════════════════════════════
                    // 3. THẺ THỜI TIẾT GRADIENT NỔI BẬT (CHUẨN MOCKUP MỚI)
                    // ══════════════════════════════════════════════════
                    _buildWeatherHeroCard(
                      context: context,
                      weather: weather,
                      weatherProvider: weatherProvider,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 24),

                    // ══════════════════════════════════════════════════
                    // 4. MỤC "TIN NỔI BẬT" VỚI THẺ ẢNH KHỔ RỘNG
                    // ══════════════════════════════════════════════════
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Tin nổi bật',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: textColor,
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
                              color: Color(0xFF2563EB),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Thẻ Tin Nổi Bật Phủ Gradient Mờ Ảo & Chữ Trắng
                    _buildFeaturedHeroCard(context, featuredArticle),
                    const SizedBox(height: 24),

                    // ══════════════════════════════════════════════════
                    // 5. MỤC "DANH MỤC" VỚI 4 BIỂU TƯỢNG PASTEL TRÒN
                    // ══════════════════════════════════════════════════
                    Text(
                      'Danh mục',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: textColor,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // 4 Nút Danh mục chuẩn ảnh (Thời sự, Công nghệ, Kinh tế, Thể thao)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildCategoryButton(
                          label: 'Thời sự',
                          icon: Icons.star_rounded,
                          bgColor: const Color(0xFFFEF3C7),
                          iconColor: const Color(0xFFF59E0B),
                          onTap: () => _filterCategory(newsProvider, 'thoi-su'),
                        ),
                        _buildCategoryButton(
                          label: 'Công nghệ',
                          icon: Icons.laptop_mac_rounded,
                          bgColor: const Color(0xFFDBEAFE),
                          iconColor: const Color(0xFF2563EB),
                          onTap: () => _filterCategory(newsProvider, 'cong-nghe'),
                        ),
                        _buildCategoryButton(
                          label: 'Kinh tế',
                          icon: Icons.trending_up_rounded,
                          bgColor: const Color(0xFFFFEDD5),
                          iconColor: const Color(0xFFEA580C),
                          onTap: () => _filterCategory(newsProvider, 'kinh-doanh'),
                        ),
                        _buildCategoryButton(
                          label: 'Thể thao',
                          icon: Icons.sports_soccer_rounded,
                          bgColor: const Color(0xFFD1FAE5),
                          iconColor: const Color(0xFF10B981),
                          onTap: () => _filterCategory(newsProvider, 'the-thao'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 26),

                    // ══════════════════════════════════════════════════
                    // 6. MỤC "TIN MỚI NHẤT"
                    // ══════════════════════════════════════════════════
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Tin mới nhất',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: textColor,
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
                              color: Color(0xFF2563EB),
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
                            color: Color(0xFF2563EB),
                          ),
                        ),
                      )
                    else if (latestArticles.isEmpty && featuredArticle == null)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 30),
                        child: Center(
                          child: Text(
                            'Đang tải tin tức...',
                            style: TextStyle(color: subTextColor),
                          ),
                        ),
                      )
                    else
                      ...latestArticles.map((article) {
                        return _buildNewsCardFrosted(
                          context: context,
                          article: article,
                          cardBg: cardBg,
                          borderColor: borderColor,
                          textColor: textColor,
                          subTextColor: subTextColor,
                        );
                      }),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _filterCategory(NewsProvider newsProvider, String categoryId) {
    final cat = newsProvider.categories.firstWhere(
      (c) => c.id == categoryId,
      orElse: () => newsProvider.categories.first,
    );
    newsProvider.selectCategory(cat);
    onNavigateToNews?.call();
  }

  // ── WIDGET: THẺ THỜI TIẾT GRADIENT PHỦ HIỆU ỨNG MỜ ẢO ───────────────
  Widget _buildWeatherHeroCard({
    required BuildContext context,
    required dynamic weather,
    required WeatherProvider weatherProvider,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onNavigateToWeather ??
          () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const WeatherScreen()),
            );
          },
      borderRadius: BorderRadius.circular(22),
      child: Container(
        height: 136,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: const LinearGradient(
            colors: [Color(0xFF38BDF8), Color(0xFF2563EB)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2563EB).withOpacity(0.35),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Stack(
            children: [
              // Lớp gương phản chiếu ánh sáng mờ ảo
              Positioned(
                top: -30,
                left: -20,
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.12),
                  ),
                ),
              ),

              // Nội dung thẻ
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Thông tin nhiệt độ bên trái
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Nút chọn địa điểm
                        GestureDetector(
                          onTap: () => _showCityPicker(context, weatherProvider),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.location_on_rounded,
                                    color: Colors.white, size: 14),
                                const SizedBox(width: 3),
                                Text(
                                  weather?.cityName ?? weatherProvider.selectedCity.name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 2),
                                const Icon(Icons.keyboard_arrow_down_rounded,
                                    color: Colors.white, size: 15),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),

                        // Nhiệt độ lớn
                        Text(
                          weather != null
                              ? '${weather.temperature.round()}°C'
                              : '28°C',
                          style: const TextStyle(
                            fontSize: 38,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: -1.2,
                            height: 1.0,
                          ),
                        ),
                        const SizedBox(height: 4),

                        // Tình trạng thời tiết
                        Text(
                          weather?.description ?? 'Có nắng',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withOpacity(0.95),
                          ),
                        ),
                      ],
                    ),

                    // Hình Mặt Trời & Mây 3D nổi bên phải
                    _buildSunCloudGraphicLarge(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── WIDGET: CARD TIN NỔI BẬT VỚI PHỦ LỚP MỜ ẢO (MOCKUP 01) ──────────
  Widget _buildFeaturedHeroCard(BuildContext context, Article? article) {
    final title = article?.title ??
        'Việt Nam hướng tới chuyển đổi số toàn diện';
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
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: 190,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Ảnh nền toàn cảnh
              Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: const Color(0xFF1E293B),
                  child: const Center(
                    child: Icon(Icons.image_outlined, color: Colors.grey, size: 40),
                  ),
                ),
              ),

              // Gradient mờ dần từ dưới lên để làm nổi bật văn bản
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.2),
                      Colors.black.withOpacity(0.85),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0.35, 0.6, 1.0],
                  ),
                ),
              ),

              // Nội dung chữ nổi bật ở góc dưới
              Positioned(
                left: 16,
                right: 16,
                bottom: 14,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (article?.source != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        margin: const EdgeInsets.only(bottom: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2563EB).withOpacity(0.85),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          article!.source,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.3,
                        letterSpacing: -0.2,
                        shadows: [
                          Shadow(
                            color: Colors.black54,
                            blurRadius: 6,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
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

  // ── WIDGET: 4 NÚT DANH MỤC TRÒN PASTEL ──────────────────────────────
  Widget _buildCategoryButton({
    required String label,
    required IconData icon,
    required Color bgColor,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: iconColor.withOpacity(0.25),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: iconColor, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF334155),
            ),
          ),
        ],
      ),
    );
  }

  // ── WIDGET: THẺ TIN TỨC DẠNG FROSTED GLASS HÀNG NGANG ───────────────
  Widget _buildNewsCardFrosted({
    required BuildContext context,
    required Article article,
    required Color cardBg,
    required Color borderColor,
    required Color textColor,
    required Color subTextColor,
  }) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ArticleDetailScreen(article: article),
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.025),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
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
                  child: const Icon(Icons.image, color: Colors.grey),
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
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: textColor,
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
                          color: subTextColor,
                        ),
                      ),
                      Text(
                        ' • ${article.source}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2563EB),
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

  // ── WIDGET: NÚT ICON KÍNH MỜ (FROSTED GLASS BUTTON) ─────────────────
  Widget _buildFrostedIconButton({
    required IconData icon,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: (isDark ? const Color(0xFF1C2541) : Colors.white).withOpacity(0.85),
          shape: BoxShape.circle,
          border: Border.all(
            color: (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)).withOpacity(0.8),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          icon,
          size: 20,
          color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
        ),
      ),
    );
  }

  // ── WIDGET: MẶT TRỜI VÀ MÂY 3D TỎA SÁNG ────────────────────────────
  Widget _buildSunCloudGraphicLarge() {
    return SizedBox(
      width: 90,
      height: 80,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Quầng sáng tỏa ra từ mặt trời
          Positioned(
            right: 14,
            top: 4,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const RadialGradient(
                  colors: [
                    Color(0xFFFFF9C4),
                    Color(0xFFFFB300),
                    Color(0xFFFF8F00),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFFB300).withOpacity(0.6),
                    blurRadius: 18,
                    spreadRadius: 3,
                  ),
                ],
              ),
            ),
          ),
          // Mây trắng mềm mại che phía trước
          Positioned(
            left: 2,
            bottom: 4,
            child: Icon(
              Icons.cloud_rounded,
              color: Colors.white.withOpacity(0.96),
              size: 58,
            ),
          ),
        ],
      ),
    );
  }
}
