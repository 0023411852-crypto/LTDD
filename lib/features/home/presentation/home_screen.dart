import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/article.dart';
import '../../../services/news_service.dart';
import '../../auth/providers/auth_provider.dart';
import '../../favorites/providers/favorites_provider.dart';
import '../../news/presentation/article_detail_screen.dart';
import '../../news/providers/news_provider.dart';
import '../../notifications/presentation/notifications_screen.dart';
import '../../search/presentation/search_screen.dart';
import '../../weather/presentation/weather_screen.dart';
import '../../weather/presentation/widgets/animated_weather_visual.dart';
import '../../weather/providers/weather_provider.dart';

/// Màn hình Trang Chủ (Home Screen) cao cấp:
/// - Thẻ Thời Tiết Gradient kính mờ đồng bộ thời gian thực.
/// - Slider Tin Nổi Bật (Featured News Carousel) 5 tin nóng kèm Page Indicator.
/// - Thanh Filter Danh Mục cuộn ngang mượt mà, đổi tin tức tức thì.
/// - Danh sách Tin Mới phong cách Editorial Magazine: ảnh tỷ lệ chuẩn, typography
///   sắc nét, tag chuyên mục, nút Yêu thích nhanh (Favorites).
class HomeScreen extends StatefulWidget {
  final VoidCallback? onNavigateToNews;
  final VoidCallback? onNavigateToWeather;
  final VoidCallback? onNavigateToFavorites;

  const HomeScreen({
    super.key,
    this.onNavigateToNews,
    this.onNavigateToWeather,
    this.onNavigateToFavorites,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final PageController _featuredPageController;
  int _currentFeaturedPage = 0;

  @override
  void initState() {
    super.initState();
    _featuredPageController = PageController();
  }

  @override
  void dispose() {
    _featuredPageController.dispose();
    super.dispose();
  }

  String _getTimeAgo(DateTime? date) {
    if (date == null) return 'Vừa xong';
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 0) return '${diff.inDays} ngày trước';
    if (diff.inHours > 0) return '${diff.inHours} giờ trước';
    if (diff.inMinutes > 0) return '${diff.inMinutes} phút trước';
    return 'Vừa xong';
  }

  bool get _isDaytime {
    final hour = DateTime.now().hour;
    return hour >= 6 && hour < 18;
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
    final favoritesProvider = context.watch<FavoritesProvider>();
    final weather = weatherProvider.weather;
    final articles = newsProvider.articles;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF090D1A) : const Color(0xFFF1F5F9);
    final textColor = isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
    final subTextColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    // Lấy top 5 bài tin nổi bật cho Slider
    final List<Article> featuredArticles =
        articles.take(math.min(5, articles.length)).toList();
    // Các bài còn lại hiển thị ở phần tin mới nhất
    final List<Article> latestArticles =
        articles.length > 5 ? articles.skip(5).toList() : articles;

    final userName = authProvider.isAuthenticated
        ? authProvider.displayName.split(' ').last
        : '';

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          // Nền ambient mờ ảo
          Positioned.fill(
            child: IgnorePointer(
              child: RepaintBoundary(
                child: _HomeAmbientBackground(isDark: isDark),
              ),
            ),
          ),

          // Lớp ánh sáng phát quang nhẹ ở các góc
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
                filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
                child: Container(color: Colors.transparent),
              ),
            ),
          ),

          // NỘI DUNG CUỘN CHÍNH
          SafeArea(
            child: RefreshIndicator(
              color: const Color(0xFF2563EB),
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

                    // 1. TOP BAR: LOGO + NÚT TÌM KIẾM & THÔNG BÁO
                    _buildTopHeader(context, isDark, textColor, subTextColor),
                    const SizedBox(height: 16),

                    // 2. LỜI CHÀO NGÀY MỚI
                    Text(
                      userName.isNotEmpty
                          ? 'Xin chào, $userName! 👋'
                          : 'Xin chào bạn! 👋',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: textColor,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Khám phá tin tức & thời tiết hôm nay',
                      style: TextStyle(
                        fontSize: 13.5,
                        color: subTextColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 3. THẺ THỜI TIẾT MINI GLASSMORPHISM
                    _buildWeatherHeroCard(
                      context: context,
                      weather: weather,
                      weatherProvider: weatherProvider,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 24),

                    // 4. MỤC "TIN NỔI BẬT" - CAROUSEL SLIDER HIỆN ĐẠI
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 4,
                              height: 18,
                              decoration: BoxDecoration(
                                color: const Color(0xFF2563EB),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Tin nổi bật',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: textColor,
                                letterSpacing: -0.3,
                              ),
                            ),
                          ],
                        ),
                        GestureDetector(
                          onTap: widget.onNavigateToNews,
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

                    // Slider Tin Nổi Bật
                    _buildFeaturedCarousel(
                      context: context,
                      featuredArticles: featuredArticles,
                      isLoading: newsProvider.status == NewsStatus.loading,
                      favoritesProvider: favoritesProvider,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 24),

                    // 5. MỤC "CHUYÊN MỤC" - THANH CHIP CUỘN NGANG
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 4,
                              height: 18,
                              decoration: BoxDecoration(
                                color: const Color(0xFF0284C7),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Chuyên mục',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: textColor,
                                letterSpacing: -0.3,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    _buildCategoryPillsBar(
                      newsProvider: newsProvider,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 24),

                    // 6. MỤC "TIN MỚI NHẤT" - EDITORIAL MAGAZINE FEED
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 4,
                              height: 18,
                              decoration: BoxDecoration(
                                color: const Color(0xFFEA580C),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Tin mới nhất',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: textColor,
                                letterSpacing: -0.3,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '${latestArticles.length} bài viết',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: subTextColor,
                            fontWeight: FontWeight.w600,
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
                    else if (latestArticles.isEmpty && featuredArticles.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 36),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(Icons.feed_outlined,
                                  size: 46, color: subTextColor),
                              const SizedBox(height: 10),
                              Text(
                                'Không có tin tức nào trong danh mục này',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: textColor,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Hãy kéo xuống để tải lại hoặc chọn danh mục khác.',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: subTextColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ...List.generate(latestArticles.length, (index) {
                        final article = latestArticles[index];
                        // Cứ mỗi 4 bài thì hiển thị 1 thẻ đặc sắc khổ lớn (Full-width card)
                        final isFeatureLayout = index > 0 && index % 4 == 0;

                        if (isFeatureLayout) {
                          return _buildWideMagazineCard(
                            context: context,
                            article: article,
                            cardBg: cardBg,
                            borderColor: borderColor,
                            textColor: textColor,
                            subTextColor: subTextColor,
                            favoritesProvider: favoritesProvider,
                          );
                        }

                        return _buildStandardNewsCard(
                          context: context,
                          article: article,
                          cardBg: cardBg,
                          borderColor: borderColor,
                          textColor: textColor,
                          subTextColor: subTextColor,
                          favoritesProvider: favoritesProvider,
                        );
                      }),
                    const SizedBox(height: 36),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- 1. TOP HEADER BAR ---
  Widget _buildTopHeader(
    BuildContext context,
    bool isDark,
    Color textColor,
    Color subTextColor,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                Icons.newspaper_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tin tức & Thời tiết',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    color: textColor,
                    letterSpacing: -0.4,
                  ),
                ),
                Text(
                  'Cổng tin tức trực tuyến 24/7',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: subTextColor,
                  ),
                ),
              ],
            ),
          ],
        ),
        Row(
          children: [
            _buildFrostedIconButton(
              icon: Icons.search_rounded,
              isDark: isDark,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SearchScreen()),
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
                        builder: (_) => const NotificationsScreen(),
                      ),
                    );
                  },
                ),
                Positioned(
                  right: 9,
                  top: 9,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
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
    );
  }

  // --- 2. THẺ THỜI TIẾT HERO MINI ---
  Widget _buildWeatherHeroCard({
    required BuildContext context,
    required dynamic weather,
    required WeatherProvider weatherProvider,
    required bool isDark,
  }) {
    return InkWell(
      onTap: widget.onNavigateToWeather ??
          () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const WeatherScreen()),
            );
          },
      borderRadius: BorderRadius.circular(24),
      child: Container(
        height: 138,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            colors: [Color(0xFF2563EB), Color(0xFF0284C7), Color(0xFF38BDF8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2563EB).withOpacity(0.35),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              Positioned(
                top: -30,
                left: -20,
                child: Container(
                  width: 130,
                  height: 130,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.12),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: () => _showCityPicker(context, weatherProvider),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.22),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.35),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.location_on_rounded,
                                    color: Colors.white, size: 14),
                                const SizedBox(width: 4),
                                Text(
                                  weather?.cityName ??
                                      weatherProvider.selectedCity.name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
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
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              weather != null
                                  ? '${weather.temperature.round()}'
                                  : '--',
                              style: const TextStyle(
                                fontSize: 40,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: -1.5,
                                height: 1.0,
                              ),
                            ),
                            const Text(
                              '°C',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: Colors.white70,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              weather != null
                                  ? '•  ${weather.description}'
                                  : '',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white.withOpacity(0.95),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          weather != null
                              ? 'Độ ẩm: ${weather.humidity}%  •  Gió: ${weather.windSpeed.round()} km/h'
                              : 'Chạm để xem dự báo chi tiết',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.85),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    AnimatedWeatherVisual(
                      weatherCode: weather?.weatherCode,
                      isDaytime: _isDaytime,
                      size: 78,
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

  // --- 3. CAROUSEL TIN NỔI BẬT (SLIDER 5 TIN NÓNG NHẤT) ---
  Widget _buildFeaturedCarousel({
    required BuildContext context,
    required List<Article> featuredArticles,
    required bool isLoading,
    required FavoritesProvider favoritesProvider,
    required bool isDark,
  }) {
    if (featuredArticles.isEmpty) {
      return Container(
        height: 210,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.newspaper_rounded,
                size: 40,
                color: isDark ? Colors.white38 : Colors.grey.shade400,
              ),
              const SizedBox(height: 10),
              Text(
                isLoading ? 'Đang cập nhật tin tức nổi bật...' : 'Chưa có tin nổi bật',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        SizedBox(
          height: 215,
          child: PageView.builder(
            controller: _featuredPageController,
            itemCount: featuredArticles.length,
            onPageChanged: (page) {
              setState(() {
                _currentFeaturedPage = page;
              });
            },
            itemBuilder: (context, index) {
              final article = featuredArticles[index];
              final isFav = favoritesProvider.isFavorite(article);

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ArticleDetailScreen(article: article),
                    ),
                  );
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
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
                        // Ảnh bìa
                        if (article.imageUrl != null)
                          Image.network(
                            article.imageUrl!,
                            cacheWidth: 800,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                _buildImagePlaceholder(article.source),
                          )
                        else
                          _buildImagePlaceholder(article.source),

                        // Gradient tối phía dưới để đọc chữ rõ ràng
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.3),
                                Colors.black.withOpacity(0.88),
                              ],
                              stops: const [0.35, 0.60, 1.0],
                            ),
                          ),
                        ),

                        // Tag chuyên mục & Nguồn báo góc trên
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
                                    const SizedBox(width: 3),
                                    Text(
                                      article.source.isNotEmpty
                                          ? article.source
                                          : 'NỔI BẬT',
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

                        // Nút yêu thích góc trên bên phải
                        Positioned(
                          top: 10,
                          right: 10,
                          child: InkWell(
                            onTap: () => favoritesProvider.toggleFavorite(article),
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
                                  color: isFav
                                      ? const Color(0xFFEF4444)
                                      : Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Tiêu đề & Thời gian ở góc dưới
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
                                      size: 13,
                                      color: Colors.white.withOpacity(0.8)),
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
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF93C5FD),
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
            },
          ),
        ),
        const SizedBox(height: 10),

        // Indicator Dots cho Slider
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(featuredArticles.length, (index) {
            final isActive = index == _currentFeaturedPage;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: isActive ? 22 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: isActive
                    ? const Color(0xFF2563EB)
                    : (isDark ? Colors.white24 : Colors.grey.shade300),
                borderRadius: BorderRadius.circular(3),
              ),
            );
          }),
        ),
      ],
    );
  }

  // --- 4. THANH FILTER CHUYÊN MỤC DẠNG CUỘN NGANG (CATEGORY PILLS) ---
  Widget _buildCategoryPillsBar({
    required NewsProvider newsProvider,
    required bool isDark,
  }) {
    final categories = newsProvider.categories;
    final selectedCat = newsProvider.selectedCategory;

    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final cat = categories[index];
          final isSelected = cat.id == selectedCat.id;

          return InkWell(
            onTap: () => newsProvider.selectCategory(cat),
            borderRadius: BorderRadius.circular(20),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? const LinearGradient(
                        colors: [Color(0xFF2563EB), Color(0xFF38BDF8)],
                      )
                    : null,
                color: isSelected
                    ? null
                    : (isDark
                        ? const Color(0xFF1E293B)
                        : Colors.white),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? Colors.transparent
                      : (isDark
                          ? const Color(0xFF334155)
                          : const Color(0xFFE2E8F0)),
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: const Color(0xFF2563EB).withOpacity(0.35),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
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
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // --- 5. THẺ BÁO TIÊU CHUẨN (STANDARD NEWS CARD) ---
  Widget _buildStandardNewsCard({
    required BuildContext context,
    required Article article,
    required Color cardBg,
    required Color borderColor,
    required Color textColor,
    required Color subTextColor,
    required FavoritesProvider favoritesProvider,
  }) {
    final isFav = favoritesProvider.isFavorite(article);

    return InkWell(
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
            // Ảnh thumbnail tỷ lệ chuẩn 110x84 bo góc mềm
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: SizedBox(
                width: 110,
                height: 84,
                child: article.imageUrl != null
                    ? Image.network(
                        article.imageUrl!,
                        cacheWidth: 330,
                        cacheHeight: 252,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            _buildImagePlaceholder(article.source),
                      )
                    : _buildImagePlaceholder(article.source),
              ),
            ),
            const SizedBox(width: 13),

            // Nội dung tin tức bên phải
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nguồn báo & Tag chuyên mục
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
                      // Nút yêu thích
                      InkWell(
                        onTap: () => favoritesProvider.toggleFavorite(article),
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
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),

                  // Tiêu đề bài báo
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
  }

  // --- 6. THẺ BÁO ĐẶC SẮC KHỔ RỘNG (WIDE EDITORIAL CARD) ---
  Widget _buildWideMagazineCard({
    required BuildContext context,
    required Article article,
    required Color cardBg,
    required Color borderColor,
    required Color textColor,
    required Color subTextColor,
    required FavoritesProvider favoritesProvider,
  }) {
    final isFav = favoritesProvider.isFavorite(article);

    return InkWell(
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
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: borderColor, width: 1.1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ảnh lớn khổ rộng
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
              child: SizedBox(
                height: 155,
                width: double.infinity,
                child: article.imageUrl != null
                    ? Image.network(
                        article.imageUrl!,
                        cacheWidth: 800,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            _buildImagePlaceholder(article.source),
                      )
                    : _buildImagePlaceholder(article.source),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEA580C).withOpacity(0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              article.source,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFFEA580C),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _getTimeAgo(article.publishedAt),
                            style: TextStyle(
                              fontSize: 12,
                              color: subTextColor,
                            ),
                          ),
                        ],
                      ),
                      InkWell(
                        onTap: () => favoritesProvider.toggleFavorite(article),
                        borderRadius: BorderRadius.circular(18),
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
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    article.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: textColor,
                      height: 1.35,
                      letterSpacing: -0.3,
                    ),
                  ),
                  if (article.description.isNotEmpty) ...[
                    const SizedBox(height: 5),
                    Text(
                      article.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: subTextColor,
                        height: 1.3,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Placeholder ảnh khi không tải được hoặc ảnh null
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

  // Nút Icon kính mờ ở Top bar
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
          color: (isDark ? const Color(0xFF1E293B) : Colors.white).withOpacity(0.9),
          shape: BoxShape.circle,
          border: Border.all(
            color: (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
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
}

// ── HIỆU ỨNG AMBIENT NỀN TRANG CHỦ ─────────────────────────────────────
class _HomeAmbientBackground extends StatefulWidget {
  final bool isDark;

  const _HomeAmbientBackground({required this.isDark});

  @override
  State<_HomeAmbientBackground> createState() => _HomeAmbientBackgroundState();
}

class _HomeAmbientBackgroundState extends State<_HomeAmbientBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _HomeAmbientPainter(
            progress: reduceMotion ? 0.5 : _controller.value,
            isDark: widget.isDark,
          ),
        );
      },
    );
  }
}

class _HomeAmbientPainter extends CustomPainter {
  final double progress;
  final bool isDark;

  const _HomeAmbientPainter({
    required this.progress,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    final glow = Paint()..style = PaintingStyle.fill;
    final offset = math.sin(progress * math.pi * 2) * 32;

    glow.color = (isDark ? const Color(0xFF2563EB) : const Color(0xFF93C5FD))
        .withOpacity(isDark ? 0.10 : 0.13);
    canvas.drawCircle(Offset(size.width * 0.78 + offset, 90), 170, glow);

    glow.color = (isDark ? const Color(0xFF06B6D4) : const Color(0xFFBAE6FD))
        .withOpacity(isDark ? 0.08 : 0.12);
    canvas.drawCircle(
      Offset(size.width * 0.12 - offset, size.height * 0.52),
      145,
      glow,
    );
  }

  @override
  bool shouldRepaint(covariant _HomeAmbientPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.isDark != isDark;
  }
}
