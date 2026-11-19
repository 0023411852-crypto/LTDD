import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/article.dart';
import '../../../models/weather.dart';
import '../../../services/weather_service.dart';
import '../../auth/presentation/login_screen.dart';
import '../../news/presentation/article_detail_screen.dart';
import '../../weather/presentation/weather_screen.dart';
import '../../weather/presentation/widgets/animated_weather_visual.dart';
import '../../weather/providers/weather_provider.dart';
import '../providers/favorites_provider.dart';

/// Màn hình Yêu thích & Kho lưu (Favorites Screen)
/// - Có nút Mũi tên quay lại (Back arrow) để trở về màn hình Tài khoản dễ dàng.
/// - Giao diện hiện đại, sang trọng, đồng bộ thiết kế với Trang Chủ & Thời Tiết.
/// - Phân loại 2 Tab: "Tin tức đã lưu" & "Địa điểm yêu thích".
class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  int _selectedTab = 0; // 0: Tin tức, 1: Địa điểm

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
    final favoritesProvider = context.watch<FavoritesProvider>();
    final favorites = favoritesProvider.favorites;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF090D1A) : const Color(0xFFF1F5F9);
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
    final subTextColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: textColor),
          tooltip: 'Quay lại tài khoản',
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Kho lưu của bạn',
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w800,
            color: textColor,
            letterSpacing: -0.3,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Banner nhắc nhở đăng nhập để đồng bộ đám mây (nếu là Khách)
          if (!favoritesProvider.isAuthenticated)
            _buildGuestSyncBanner(context, isDark, borderColor),

          // 1. THANH CHUYỂN TAB HIỆN ĐẠI (TIN TỨC | ĐỊA ĐIỂM)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 14),
            child: Container(
              height: 44,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: borderColor),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _selectedTab = 0),
                      borderRadius: BorderRadius.circular(18),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOutCubic,
                        decoration: BoxDecoration(
                          gradient: _selectedTab == 0
                              ? const LinearGradient(
                                  colors: [Color(0xFF2563EB), Color(0xFF38BDF8)],
                                )
                              : null,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Center(
                          child: Text(
                            'Tin tức (${favorites.length})',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: _selectedTab == 0
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                              color: _selectedTab == 0
                                  ? Colors.white
                                  : subTextColor,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _selectedTab = 1),
                      borderRadius: BorderRadius.circular(18),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOutCubic,
                        decoration: BoxDecoration(
                          gradient: _selectedTab == 1
                              ? const LinearGradient(
                                  colors: [Color(0xFF2563EB), Color(0xFF38BDF8)],
                                )
                              : null,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Center(
                          child: Text(
                            'Địa điểm quan tâm',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: _selectedTab == 1
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                              color: _selectedTab == 1
                                  ? Colors.white
                                  : subTextColor,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 2. NỘI DUNG TAB TƯƠNG ỨNG
          Expanded(
            child: _selectedTab == 0
                ? _buildNewsFavoritesTab(
                    context,
                    favoritesProvider,
                    favorites,
                    cardBg,
                    borderColor,
                    textColor,
                    subTextColor,
                    isDark,
                  )
                : _buildLocationFavoritesTab(
                    context,
                    favoritesProvider,
                    cardBg,
                    borderColor,
                    textColor,
                    subTextColor,
                    isDark,
                  ),
          ),
        ],
      ),
    );
  }

  // --- TAB 1: DANH SÁCH BÀI BÁO ĐÃ LƯU ---
  Widget _buildNewsFavoritesTab(
    BuildContext context,
    FavoritesProvider favoritesProvider,
    List<Article> favorites,
    Color cardBg,
    Color borderColor,
    Color textColor,
    Color subTextColor,
    bool isDark,
  ) {
    if (favorites.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF2563EB).withOpacity(0.12),
                ),
                child: const Icon(
                  Icons.favorite_rounded,
                  size: 46,
                  color: Color(0xFF2563EB),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Chưa có bài viết yêu thích',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Nhấn vào biểu tượng trái tim khi đọc bài báo để lưu lại và xem lại bất cứ lúc nào.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13.5,
                  color: subTextColor,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      itemCount: favorites.length,
      itemBuilder: (context, index) {
        final article = favorites[index];

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
                    width: 105,
                    height: 82,
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
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                  : 'Tin tức',
                              style: const TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF2563EB),
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: () =>
                                favoritesProvider.toggleFavorite(article),
                            borderRadius: BorderRadius.circular(18),
                            child: const SizedBox(
                              width: 36,
                              height: 36,
                              child: Center(
                                child: Icon(
                                  Icons.favorite_rounded,
                                  color: Color(0xFFEF4444),
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
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
                      const SizedBox(height: 5),
                      Text(
                        _getTimeAgo(article.publishedAt),
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: subTextColor,
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

  void _showAddCityDialog(
    BuildContext context,
    FavoritesProvider favoritesProvider,
    Color cardBg,
    Color textColor,
    Color subTextColor,
    Color borderColor,
  ) {
    final searchCtrl = TextEditingController();
    List<City> filteredCities = List.from(WeatherService.cities);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            ),
            child: SizedBox(
              height: 480,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: borderColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Thêm địa điểm yêu thích',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: textColor,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: searchCtrl,
                    decoration: InputDecoration(
                      hintText: 'Tìm kiếm tỉnh thành, hải đảo...',
                      hintStyle: TextStyle(fontSize: 13, color: subTextColor),
                      prefixIcon: const Icon(Icons.search_rounded, size: 20),
                      filled: true,
                      fillColor: borderColor.withOpacity(0.3),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (val) {
                      final q = val.toLowerCase().trim();
                      setModalState(() {
                        if (q.isEmpty) {
                          filteredCities = List.from(WeatherService.cities);
                        } else {
                          filteredCities = WeatherService.cities.where((c) {
                            return c.name.toLowerCase().contains(q);
                          }).toList();
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: filteredCities.isEmpty
                        ? Center(
                            child: Text(
                              'Không tìm thấy địa điểm phù hợp',
                              style: TextStyle(color: subTextColor),
                            ),
                          )
                        : ListView.separated(
                            itemCount: filteredCities.length,
                            separatorBuilder: (_, __) =>
                                Divider(height: 1, color: borderColor),
                            itemBuilder: (context, i) {
                              final city = filteredCities[i];
                              final isFav =
                                  favoritesProvider.isFavoriteCity(city);
                              final isIsland = city.name.contains('Hoàng Sa') ||
                                  city.name.contains('Trường Sa');

                              return ListTile(
                                dense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                leading: Icon(
                                  isIsland
                                      ? Icons.flag_rounded
                                      : Icons.location_on_rounded,
                                  color: isIsland
                                      ? Colors.redAccent
                                      : const Color(0xFF2563EB),
                                  size: 22,
                                ),
                                title: Text(
                                  city.name,
                                  style: TextStyle(
                                    fontSize: 14.5,
                                    fontWeight: isFav
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: textColor,
                                  ),
                                ),
                                trailing: IconButton(
                                  icon: Icon(
                                    isFav
                                        ? Icons.favorite_rounded
                                        : Icons.favorite_border_rounded,
                                    color: isFav
                                        ? const Color(0xFFEF4444)
                                        : subTextColor,
                                  ),
                                  onPressed: () {
                                    favoritesProvider.toggleFavoriteCity(city);
                                    setModalState(() {});
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(isFav
                                            ? 'Đã bỏ thích ${city.name}'
                                            : 'Đã thêm ${city.name} vào danh sách yêu thích!'),
                                        duration: const Duration(seconds: 1),
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  },
                                ),
                              );
                            },
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

  // --- TAB 2: ĐỊA ĐIỂM QUAN TÂM THỰC TẾ ---
  Widget _buildLocationFavoritesTab(
    BuildContext context,
    FavoritesProvider favoritesProvider,
    Color cardBg,
    Color borderColor,
    Color textColor,
    Color subTextColor,
    bool isDark,
  ) {
    final cities = favoritesProvider.favoriteCities;

    if (cities.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF2563EB).withOpacity(0.12),
                ),
                child: const Icon(
                  Icons.location_city_rounded,
                  size: 46,
                  color: Color(0xFF2563EB),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Chưa có địa điểm yêu thích',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Nhấn nút bên dưới để thêm các tỉnh thành hoặc hải đảo bạn quan tâm để theo dõi thời tiết nhanh chóng.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13.5,
                  color: subTextColor,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: const Icon(Icons.add_location_alt_rounded, size: 18),
                label: const Text(
                  'Thêm địa điểm ngay',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                onPressed: () => _showAddCityDialog(
                  context,
                  favoritesProvider,
                  cardBg,
                  textColor,
                  subTextColor,
                  borderColor,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        // Thanh tiêu đề và nút thêm địa điểm
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Địa điểm đã lưu (${cities.length})',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
              TextButton.icon(
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  foregroundColor: const Color(0xFF2563EB),
                ),
                icon: const Icon(Icons.add_location_alt_rounded, size: 16),
                label: const Text(
                  'Thêm địa điểm',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
                onPressed: () => _showAddCityDialog(
                  context,
                  favoritesProvider,
                  cardBg,
                  textColor,
                  subTextColor,
                  borderColor,
                ),
              ),
            ],
          ),
        ),

        // Danh sách các địa điểm yêu thích thực tế
        ...cities.map((city) {
          final isIsland = city.name.contains('Hoàng Sa') ||
              city.name.contains('Trường Sa');

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
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
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () {
                  context.read<WeatherProvider>().selectCity(city);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const WeatherScreen(),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: FutureBuilder<Weather>(
                    future: WeatherService().fetchWeather(city),
                    builder: (context, snapshot) {
                      final weather = snapshot.data;
                      final isWaiting =
                          snapshot.connectionState == ConnectionState.waiting;

                      return Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: isIsland
                                  ? Colors.red.withOpacity(0.12)
                                  : const Color(0xFF2563EB).withOpacity(0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isIsland
                                  ? Icons.flag_rounded
                                  : Icons.location_on_rounded,
                              color: isIsland
                                  ? Colors.redAccent
                                  : const Color(0xFF2563EB),
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        city.name,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                          color: textColor,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  weather?.description ??
                                      (isWaiting
                                          ? 'Đang cập nhật...'
                                          : 'Dự báo trực tiếp'),
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    color: subTextColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isWaiting) ...[
                            const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                color: Color(0xFF2563EB),
                              ),
                            ),
                            const SizedBox(width: 8),
                          ] else if (weather != null) ...[
                            AnimatedWeatherVisual(
                              weatherCode: weather.weatherCode,
                              isDaytime: DateTime.now().hour >= 6 &&
                                  DateTime.now().hour < 18,
                              size: 40,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${weather.temperature.round()}°C',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: textColor,
                              ),
                            ),
                            const SizedBox(width: 4),
                          ],

                          // Nút BỎ THÍCH ĐỊA ĐIỂM
                          IconButton(
                            icon: const Icon(
                              Icons.favorite_rounded,
                              color: Color(0xFFEF4444),
                              size: 22,
                            ),
                            tooltip: 'Bỏ thích địa điểm này',
                            onPressed: () {
                              favoritesProvider.toggleFavoriteCity(city);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: [
                                      const Icon(Icons.heart_broken_rounded,
                                          color: Colors.white, size: 18),
                                      const SizedBox(width: 8),
                                      Text('Đã bỏ thích ${city.name}'),
                                    ],
                                  ),
                                  backgroundColor: const Color(0xFF64748B),
                                  duration: const Duration(seconds: 2),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          );
        }),
      ],
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
        child: Icon(Icons.newspaper_rounded, color: Colors.white54, size: 26),
      ),
    );
  }

  Widget _buildGuestSyncBanner(BuildContext context, bool isDark, Color borderColor) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF2563EB).withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF2563EB).withOpacity(0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.cloud_upload_outlined, color: Color(0xFF2563EB), size: 22),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Đang lưu tạm trên máy. Đăng nhập để đồng bộ đám mây vĩnh viễn!',
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500, height: 1.3),
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Đăng nhập', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
