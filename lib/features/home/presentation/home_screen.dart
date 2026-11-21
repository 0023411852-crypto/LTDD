import 'dart:math' as math;
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/article.dart';
import '../../../services/breaking_news_detector_service.dart';
import '../../../services/news_service.dart';
import '../../auth/providers/auth_provider.dart';
import '../../favorites/providers/favorites_provider.dart';
import '../../news/presentation/article_detail_screen.dart';
import '../../news/providers/news_provider.dart';
import '../../notifications/presentation/notifications_screen.dart';
import '../../notifications/providers/notifications_provider.dart';
import '../../search/presentation/search_screen.dart';
import '../../weather/presentation/weather_screen.dart';
import '../../weather/presentation/widgets/animated_weather_visual.dart';
import '../../weather/providers/weather_provider.dart';
import '../providers/home_provider.dart';

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

  String _getFormattedHeaderDate() {
    final now = DateTime.now();
    const weekdays = [
      'Thứ Hai',
      'Thứ Ba',
      'Thứ Tư',
      'Thứ Năm',
      'Thứ Sáu',
      'Thứ Bảy',
      'Chủ Nhật'
    ];
    final weekday = weekdays[now.weekday - 1];
    return '$weekday, ${now.day} thg ${now.month}';
  }

  String _getGreetingTimeOfDay() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return 'CHÀO BUỔI SÁNG';
    if (hour >= 12 && hour < 18) return 'CHÀO BUỔI CHIỀU';
    return 'CHÀO BUỔI TỐI';
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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  tileColor: const Color(0xFF1E60F2).withOpacity(0.08),
                  leading: const Icon(
                    Icons.my_location_rounded,
                    color: Color(0xFF1E60F2),
                  ),
                  title: const Text(
                    'Định vị vị trí hiện tại của bạn',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E60F2),
                      fontSize: 14.5,
                    ),
                  ),
                  subtitle: const Text(
                    'Tự động xác định Xã/Phường, Quận/Huyện qua GPS',
                    style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                  ),
                  onTap: () async {
                    Navigator.pop(ctx);
                    await weatherProvider.useCurrentLocation();
                  },
                ),
              ),
              const SizedBox(height: 6),
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
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Consumer<FavoritesProvider>(
                            builder: (context, fav, _) {
                              final isFav = fav.isFavoriteCity(city);
                              return IconButton(
                                icon: Icon(
                                  isFav
                                      ? Icons.favorite_rounded
                                      : Icons.favorite_border_rounded,
                                  color: isFav
                                      ? const Color(0xFFEF4444)
                                      : Colors.grey.shade400,
                                  size: 20,
                                ),
                                onPressed: () {
                                  fav.toggleFavoriteCity(city, context: context);
                                },
                              );
                            },
                          ),
                          if (isSelected)
                            const Icon(Icons.check_circle_rounded,
                                color: Color(0xFF1E60F2)),
                        ],
                      ),
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
    // Danh sách dòng sự kiện phong phú (không bỏ sót tin tức)
    final List<Article> latestArticles =
        articles.length > 5 ? articles.skip(2).toList() : articles;

    final userName = context.select<AuthProvider, String>(
      (auth) => auth.isAuthenticated ? auth.displayName.split(' ').last : '',
    );

    // =========================================================================
    // [TỰ ĐỘNG PHÁT HIỆN & BÁO TIN NÓNG HOẶC THỜI TIẾT KHẨN CẤP]
    // 
    // [TÁC DỤNG]:
    // Ngay sau khi nạp dữ liệu xong (postFrameCallback), hệ thống tự động chạy quét:
    // 1. Phân tích tiêu đề các bài báo RSS mới nhất để phát hiện bão, thiên tai, hỏa hoạn...
    // 2. Kiểm tra thông số thời tiết xem có dông lốc, mưa đá nguy hiểm hay không.
    // 3. Nếu phát hiện sự kiện mới: tự động đẩy vào Tab Chuông thông báo và hiện
    //    Banner nổi khẩn cấp kèm nút "Xem ngay" để người dùng không bỏ lỡ thông tin sống còn.
    // =========================================================================
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (articles.isNotEmpty) {
        BreakingNewsDetectorService.checkAndNotifyBreakingNews(
          context: context,
          articles: newsProvider.allArticles,
        );
      }
      if (weather != null) {
        BreakingNewsDetectorService.checkAndNotifyWeatherAlert(
          context: context,
          weather: weather,
        );
      }
    });

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: RefreshIndicator(
          color: const Color(0xFF2563EB),
          onRefresh: () async {
            await Future.wait([
              newsProvider.fetchNews(),
              weatherProvider.fetchWeather(),
            ]);
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 10),

                      // 1. TOP BAR: LOGO + NÚT TÌM KIẾM & THÔNG BÁO
                      _buildTopHeader(context, isDark, textColor, subTextColor),
                      const SizedBox(height: 16),

                      // 2. LỜI CHÀO NGÀY MỚI (CHUẨN EDITORIAL JOURNALISM)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getGreetingTimeOfDay(),
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF2563EB),
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            userName.isNotEmpty
                                ? 'Bản tin của $userName'
                                : 'Điểm tin & Khí hậu',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: textColor,
                              letterSpacing: -0.6,
                              height: 1.2,
                            ),
                          ),
                        ],
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

                      // 4. MỤC "TIN TIÊU ĐIỂM" - CAROUSEL SLIDER
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Tin tiêu điểm',
                            style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w900,
                              color: textColor,
                              letterSpacing: -0.4,
                            ),
                          ),
                          GestureDetector(
                            onTap: widget.onNavigateToNews,
                            child: const Padding(
                              padding: EdgeInsets.only(bottom: 2),
                              child: Text(
                                'Xem tất cả',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF2563EB),
                                ),
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
                        isDark: isDark,
                      ),
                      const SizedBox(height: 24),

                      // 5. MỤC "CHUYÊN MỤC"
                      Text(
                        'Chuyên mục',
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w900,
                          color: textColor,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 12),

                      _buildCategoryPillsBar(
                        newsProvider: newsProvider,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 24),

                      // 5.1 MỤC "XU HƯỚNG ĐỌC NHIỀU" - HORIZONTAL TRENDING STRIP
                      if (featuredArticles.isNotEmpty) ...[
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEF4444).withOpacity(0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.local_fire_department_rounded,
                                color: Color(0xFFEF4444),
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Xu hướng đọc nhiều',
                              style: TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.w900,
                                color: textColor,
                                letterSpacing: -0.4,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEF4444).withOpacity(0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                '🔥 TOP TRENDING',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFFEF4444),
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildTrendingHorizontalList(
                          context: context,
                          articles: featuredArticles,
                          cardBg: cardBg,
                          borderColor: borderColor,
                          textColor: textColor,
                          subTextColor: subTextColor,
                          isDark: isDark,
                        ),
                        const SizedBox(height: 24),
                      ],

                      // 6. MỤC "DÒNG SỰ KIỆN NỔI BẬT" - EDITORIAL MAGAZINE FEED
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2563EB).withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.bolt_rounded,
                                  color: Color(0xFF2563EB),
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Dòng tin mới nhất',
                                style: TextStyle(
                                  fontSize: 19,
                                  fontWeight: FontWeight.w900,
                                  color: textColor,
                                  letterSpacing: -0.4,
                                ),
                              ),
                            ],
                          ),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 2),
                            child: Text(
                              '${latestArticles.length} bài viết',
                              style: TextStyle(
                                fontSize: 12,
                                color: subTextColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),

              // 7. DANH SÁCH BÀI BÁO ẢO HÓA (SLIVER VIRTUALIZATION - 60/120 FPS)
              if (newsProvider.status == NewsStatus.loading && articles.isEmpty)
                const SliverPadding(
                  padding: EdgeInsets.symmetric(vertical: 40, horizontal: 16),
                  sliver: SliverToBoxAdapter(
                    child: Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF2563EB),
                      ),
                    ),
                  ),
                )
              else if (latestArticles.isEmpty && featuredArticles.isEmpty)
                SliverPadding(
                  padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
                  sliver: SliverToBoxAdapter(
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
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList.builder(
                    itemCount: latestArticles.length,
                    itemBuilder: (context, index) {
                      final article = latestArticles[index];
                      // Cứ mỗi 3 bài thì hiển thị 1 thẻ đặc sắc khổ lớn (Full-width card)
                      final isFeatureLayout = index > 0 && index % 3 == 0;

                      if (isFeatureLayout) {
                        return _buildWideMagazineCard(
                          context: context,
                          article: article,
                          cardBg: cardBg,
                          borderColor: borderColor,
                          textColor: textColor,
                          subTextColor: subTextColor,
                        );
                      }

                      // Tự động kiểm tra bài viết có phải là Tin nóng khẩn cấp hay không
                      final isBreaking = BreakingNewsDetectorService.isBreakingArticle(article);
                      final String? badge = isBreaking
                          ? '🔴 TIN NÓNG'
                          : (index == 0 ? '🔥 NỔI BẬT' : (index == 1 ? '⚡ MỚI' : null));

                      return _buildStandardNewsCard(
                        context: context,
                        article: article,
                        cardBg: cardBg,
                        borderColor: borderColor,
                        textColor: textColor,
                        subTextColor: subTextColor,
                        badgeText: badge,
                      );
                    },
                  ),
                ),

              // Nút "Tải thêm tin tức" khi danh sách còn bài viết
              if (newsProvider.hasMore)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 20),
                    child: Center(
                      child: OutlinedButton.icon(
                        onPressed: () => newsProvider.loadMore(),
                        icon: const Icon(Icons.expand_more_rounded, size: 20),
                        label: const Text(
                          'Tải thêm tin tức nổi bật',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF2563EB),
                          side: const BorderSide(color: Color(0xFF2563EB), width: 1.2),
                          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                      ),
                    ),
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 36)),
            ],
          ),
            ),
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
        Expanded(
          child: Row(
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TIN TỨC & THỜI TIẾT',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: textColor,
                        letterSpacing: 0.5,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      _getFormattedHeaderDate(),
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
        ),
        const SizedBox(width: 8),
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
            Consumer<NotificationsProvider>(
              builder: (context, notifProvider, _) {
                final hasUnread = notifProvider.unreadCount > 0;
                return Stack(
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
                    if (hasUnread)
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
                );
              },
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
          gradient: LinearGradient(
            colors: isDark
                ? const [Color(0xFF0F172A), Color(0xFF1E293B)]
                : (_isDaytime
                    ? const [Color(0xFF1E3A8A), Color(0xFF0284C7)]
                    : const [Color(0xFF0F172A), Color(0xFF1E3A8A)]),
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(
            color: Colors.white.withOpacity(isDark ? 0.12 : 0.22),
            width: 1.1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.35 : 0.14),
              blurRadius: 18,
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
                    Expanded(
                      child: Column(
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
                                  Flexible(
                                    child: Text(
                                      weather?.cityName ??
                                          weatherProvider.selectedCity.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                      ),
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
                              Expanded(
                                child: Text(
                                  weather != null
                                      ? '•  ${weather.description}'
                                      : '',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white.withOpacity(0.95),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            weather != null
                                ? 'Độ ẩm: ${weather.humidity}%  •  Gió: ${weather.windSpeed.round()} km/h'
                                : 'Chạm để xem dự báo chi tiết',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withOpacity(0.85),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
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
              context.read<HomeProvider>().setFeaturedPage(page);
            },
            itemBuilder: (context, index) {
              final article = featuredArticles[index];

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

                        // Tag chuyên mục & Nguồn báo hoặc Tag TIN NÓNG góc trên
                        Positioned(
                          top: 14,
                          left: 14,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (BreakingNewsDetectorService.isBreakingArticle(article)) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 9, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEF4444),
                                    borderRadius: BorderRadius.circular(8),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFFEF4444).withOpacity(0.5),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.bolt_rounded, color: Colors.white, size: 13),
                                      SizedBox(width: 3),
                                      Text(
                                        'TIN NÓNG',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 6),
                              ],
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.55),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.25),
                                        width: 0.9,
                                      ),
                                    ),
                                    child: Text(
                                      article.source.isNotEmpty
                                          ? article.source.toUpperCase()
                                          : 'TIÊU ĐIỂM',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.6,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Nút yêu thích góc trên bên phải (Cô lập rebuild bằng Selector)
                        Positioned(
                          top: 10,
                          right: 10,
                          child: Selector<FavoritesProvider, bool>(
                            selector: (_, fav) => fav.isFavorite(article),
                            builder: (context, isFav, _) {
                              return InkWell(
                                onTap: () => context.read<FavoritesProvider>().toggleFavorite(article, context: context),
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
                              );
                            },
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
        Selector<HomeProvider, int>(
          selector: (_, hp) => hp.currentFeaturedPage,
          builder: (context, currentFeaturedPage, _) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(featuredArticles.length, (index) {
                final isActive = index == currentFeaturedPage;
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
            );
          },
        ),
      ],
    );
  }

  // --- 4. THANH FILTER CHUYÊN MỤC DẠNG CUỘN NGANG (CATEGORY PILLS) ---
  Widget _buildCategoryPillsBar({
    required NewsProvider newsProvider,
    required bool isDark,
  }) {
    final categories = newsProvider.navigationCategories;
    final selectedCat = newsProvider.selectedCategory;

    if (categories.isEmpty) {
      return Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        alignment: Alignment.centerLeft,
        child: Text(
          'Chưa có nguồn tin nào được kết nối (Vào Admin để thêm nguồn RSS)',
          style: TextStyle(
            fontSize: 12.5,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final cat = categories[index];
          final isSelected = cat.id == selectedCat.id ||
              (cat.id == 'all' && selectedCat.id == 'all');

          return InkWell(
            onTap: () => newsProvider.selectCategory(cat),
            borderRadius: BorderRadius.circular(20),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? (isDark
                        ? const Color(0xFF2563EB)
                        : const Color(0xFF1D4ED8))
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
                          color: const Color(0xFF1D4ED8).withOpacity(0.22),
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
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // --- 4.1. DANH SÁCH CUỘN NGANG XU HƯỚNG ĐỌC NHIỀU (TRENDING HOT LIST) ---
  Widget _buildTrendingHorizontalList({
    required BuildContext context,
    required List<Article> articles,
    required Color cardBg,
    required Color borderColor,
    required Color textColor,
    required Color subTextColor,
    required bool isDark,
  }) {
    final trendingList = articles.take(5).toList();
    final rankGradients = [
      [const Color(0xFFEF4444), const Color(0xFFF97316)], // #1 Đỏ cam
      [const Color(0xFFF59E0B), const Color(0xFFFBBF24)], // #2 Vàng hổ phách
      [const Color(0xFF2563EB), const Color(0xFF38BDF8)], // #3 Xanh lam
      [const Color(0xFF8B5CF6), const Color(0xFFA855F7)], // #4 Tím
      [const Color(0xFF10B981), const Color(0xFF34D399)], // #5 Xanh lục
    ];

    return SizedBox(
      height: 228,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: trendingList.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final article = trendingList[index];
          final gradientColors = rankGradients[index % rankGradients.length];

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
              width: 215,
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: borderColor, width: 1.1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Ảnh thumbnail kèm huy hiệu Rank #1..#5 và nhãn HOT
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                    child: Stack(
                      children: [
                        SizedBox(
                          height: 112,
                          width: double.infinity,
                          child: article.imageUrl != null
                              ? CachedNetworkImage(
                                  imageUrl: article.imageUrl!,
                                  memCacheWidth: 430,
                                  fit: BoxFit.cover,
                                  placeholder: (_, __) =>
                                      _buildImagePlaceholder(article.source),
                                  errorWidget: (_, __, ___) =>
                                      _buildImagePlaceholder(article.source),
                                )
                              : _buildImagePlaceholder(article.source),
                        ),
                        // Badge Rank #1, #2...
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: gradientColors,
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              '#${index + 1}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ),
                        // Badge HOT
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.65),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(Icons.whatshot_rounded, color: Color(0xFFF97316), size: 12),
                                SizedBox(width: 2),
                                Text(
                                  'HOT',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Phần thông tin phía dưới
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2563EB).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                article.source,
                                style: const TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2563EB),
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                _getTimeAgo(article.publishedAt),
                                style: TextStyle(
                                  fontSize: 10,
                                  color: subTextColor,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        Text(
                          article.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: textColor,
                            height: 1.3,
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

  // --- 5. THẺ BÁO TIÊU CHUẨN (STANDARD NEWS CARD) ---
  Widget _buildStandardNewsCard({
    required BuildContext context,
    required Article article,
    required Color cardBg,
    required Color borderColor,
    required Color textColor,
    required Color subTextColor,
    String? badgeText,
  }) {
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
            // Ảnh thumbnail tỷ lệ chuẩn 110x84 bo góc mềm
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

            // Nội dung tin tức bên phải
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nguồn báo, Tag nổi bật & Thời gian
                  Row(
                    children: [
                      if (badgeText != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: const Color(0xFFEF4444).withOpacity(0.3),
                              width: 0.8,
                            ),
                          ),
                          child: Text(
                            badgeText,
                            style: const TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFFEF4444),
                            ),
                          ),
                        ),
                        const SizedBox(width: 5),
                      ],
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
                      // Nút yêu thích (Cô lập rebuild bằng Selector)
                      Selector<FavoritesProvider, bool>(
                        selector: (_, fav) => fav.isFavorite(article),
                        builder: (context, isFav, _) {
                          return InkWell(
                            onTap: () => context.read<FavoritesProvider>().toggleFavorite(article, context: context),
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
  }) {
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
                    ? CachedNetworkImage(
                        imageUrl: article.imageUrl!,
                        memCacheWidth: 800,
                        fit: BoxFit.cover,
                        placeholder: (_, __) =>
                            _buildImagePlaceholder(article.source),
                        errorWidget: (_, __, ___) =>
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
                      // Nút yêu thích (Cô lập rebuild bằng Selector)
                      Selector<FavoritesProvider, bool>(
                        selector: (_, fav) => fav.isFavorite(article),
                        builder: (context, isFav, _) {
                          return InkWell(
                            onTap: () => context.read<FavoritesProvider>().toggleFavorite(article, context: context),
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
                          );
                        },
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


