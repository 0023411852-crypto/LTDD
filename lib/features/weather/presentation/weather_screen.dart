import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/weather.dart';
import '../../../services/weather_service.dart';
import '../../favorites/providers/favorites_provider.dart';
import '../providers/weather_provider.dart';
import 'widgets/animated_weather_visual.dart';

/// Màn hình Thời tiết cao cấp (Ultra-Premium Animated Weather Screen)
/// - Hiệu ứng thời tiết sống động thời gian thực (Nắng, Mưa, Sấm chớp, Tuyết, Mây, Đêm sao, Sao băng).
/// - Thẻ thời tiết Glassmorphism rực rỡ với icon động 3D vector.
/// - Dự báo 24 giờ tiếp theo (Hourly Forecast) dạng carousel mượt mà.
/// - Lưới 4 chỉ số chi tiết (Độ ẩm, Gió, Cảm giác nhiệt, Tình trạng).
/// - Dự báo 7 ngày phong cách hiện đại kèm thanh biên độ nhiệt trực quan (Temperature Range Bar).
/// - Thanh chọn nhanh địa điểm phổ biến & tìm kiếm không giới hạn.
class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _ambientController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _ambientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _ambientController.repeat();
    } else {
      _ambientController.stop();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ambientController.dispose();
    super.dispose();
  }

  bool get _isDaytime {
    final hour = DateTime.now().hour;
    return hour >= 6 && hour < 18;
  }

  @override
  Widget build(BuildContext context) {
    final weatherProvider = context.watch<WeatherProvider>();
    final weather = weatherProvider.weather;
    final cs = Theme.of(context).colorScheme;
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final isLoading = weatherProvider.status == WeatherStatus.loading;
    final hasError = weatherProvider.status == WeatherStatus.error;
    final isDay = _isDaytime;
    final code = weather?.weatherCode;

    final bgColors = _getSkyGradient(code, isDay);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text(
          'Thời Tiết',
          style: TextStyle(
            color: isDay ? const Color(0xFF0F172A) : Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 20,
            letterSpacing: -0.3,
          ),
        ),
        actions: [
          Consumer<FavoritesProvider>(
            builder: (context, fav, _) {
              final currentCity = weatherProvider.selectedCity;
              final isFav = fav.isFavoriteCity(currentCity);
              return IconButton(
                icon: Icon(
                  isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  color: isFav
                      ? const Color(0xFFEF4444)
                      : (isDay ? const Color(0xFF1E3A8A) : Colors.white),
                ),
                tooltip: isFav
                    ? 'Bỏ thích địa điểm này'
                    : 'Thêm vào địa điểm yêu thích',
                onPressed: () async {
                  final wasFav = fav.isFavoriteCity(currentCity);
                  final success = await fav.toggleFavoriteCity(currentCity, context: context);
                  if (!success || !context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          Icon(
                            wasFav
                                ? Icons.heart_broken_rounded
                                : Icons.favorite_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              wasFav
                                  ? 'Đã bỏ thích ${currentCity.name}'
                                  : 'Đã lưu ${currentCity.name} vào Địa điểm yêu thích!',
                            ),
                          ),
                        ],
                      ),
                      backgroundColor: isFav
                          ? const Color(0xFF64748B)
                          : const Color(0xFFEF4444),
                      duration: const Duration(seconds: 2),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              );
            },
          ),
          IconButton(
            icon: Icon(
              Icons.my_location_rounded,
              color: isDay ? const Color(0xFF1E3A8A) : Colors.white,
            ),
            tooltip: 'Vị trí hiện tại (GPS)',
            onPressed: () => weatherProvider.useCurrentLocation(),
          ),
          IconButton(
            icon: Icon(
              Icons.search_rounded,
              color: isDay ? const Color(0xFF1E3A8A) : Colors.white,
            ),
            tooltip: 'Tìm kiếm địa điểm',
            onPressed: () => _showLocationSearch(context, weatherProvider),
          ),
          IconButton(
            icon: Icon(
              Icons.refresh_rounded,
              color: isDay ? const Color(0xFF1E3A8A) : Colors.white,
            ),
            tooltip: 'Làm mới',
            onPressed: () => weatherProvider.fetchWeather(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          // 1. NỀN GRADIENT BẦU TRỜI CHUYỂN ĐỘNG THEO THỜI TIẾT
          Positioned.fill(
            child: RepaintBoundary(
              child: AnimatedBuilder(
                animation: _ambientController,
                builder: (context, _) {
                  final shift = math.sin(_ambientController.value * math.pi * 2) * 0.15;
                  return DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: bgColors,
                        begin: Alignment(-0.5 + shift, -1.0),
                        end: Alignment(0.5 - shift, 1.0),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // 2. CANVAS HIỆU ỨNG THỜI TIẾT (Mưa, Sao đêm, Tuyết, Nắng, Sấm chớp)
          Positioned.fill(
            child: IgnorePointer(
              child: RepaintBoundary(
                child: TickerMode(
                  enabled: !reduceMotion,
                  child: AnimatedBuilder(
                    animation: _ambientController,
                    builder: (context, _) {
                      return CustomPaint(
                        painter: _WeatherAtmospherePainter(
                          progress: reduceMotion ? 0.5 : _ambientController.value,
                          code: code,
                          isDaytime: isDay,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),

          // 3. NỘI DUNG CHÍNH (CUỘN MƯỢT VỚI REFRESH INDICATOR)
          SafeArea(
            child: RefreshIndicator(
              color: cs.primary,
              backgroundColor: cs.surface,
              onRefresh: () => weatherProvider.fetchWeather(),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                children: [
                  // Thanh chọn nhanh các thành phố lớn
                  _buildQuickCitySelector(context, weatherProvider, isDay),
                  const SizedBox(height: 14),

                  // Thông báo lỗi nếu có
                  if (hasError && weather == null)
                    _buildErrorCard(context, weatherProvider, cs)
                  else ...[
                    // THẺ THỜI TIẾT CHÍNH (HERO GLASS CARD)
                    _buildHeroWeatherCard(context, weather, isLoading, isDay),
                    const SizedBox(height: 16),

                    // DỰ BÁO 24 GIỜ TIẾP THEO (HOURLY FORECAST)
                    if (weather != null && weather.hourly.isNotEmpty) ...[
                      _buildHourlyForecastSection(context, weather.hourly, isDay),
                      const SizedBox(height: 16),
                    ],

                    // LƯỚI 4 CHỈ SỐ MÔI TRƯỜNG (METRICS GRID)
                    if (weather != null) ...[
                      _buildWeatherMetricsGrid(context, weather, isDay),
                      const SizedBox(height: 16),
                    ],

                    // DỰ BÁO 7 NGÀY (7-DAY FORECAST VỚI TEMPERATURE RANGE BARS)
                    _build7DayForecastCard(context, weather, isLoading, isDay),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- THANH CHỌN NHANH ĐỊA ĐIỂM (QUICK CITY SELECTOR) ---
  Widget _buildQuickCitySelector(
    BuildContext context,
    WeatherProvider provider,
    bool isDay,
  ) {
    final currentCity = provider.selectedCity;
    final textColor = isDay ? const Color(0xFF1E293B) : Colors.white;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 38,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: WeatherService.cities.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final city = WeatherService.cities[index];
              final isSelected = city.name == currentCity.name;

              return InkWell(
                onTap: () => provider.selectCity(city),
                borderRadius: BorderRadius.circular(20),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (isDay
                            ? const Color(0xFF2563EB)
                            : const Color(0xFF6366F1))
                        : (isDay
                            ? Colors.white.withOpacity(0.65)
                            : Colors.white.withOpacity(0.12)),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? Colors.transparent
                          : (isDay
                              ? Colors.white.withOpacity(0.9)
                              : Colors.white.withOpacity(0.2)),
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: (isDay
                                      ? const Color(0xFF2563EB)
                                      : const Color(0xFF6366F1))
                                  .withOpacity(0.35),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isSelected) ...[
                        const Icon(
                          Icons.location_on_rounded,
                          size: 14,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 4),
                      ],
                      Text(
                        city.name,
                        style: TextStyle(
                          color: isSelected ? Colors.white : textColor,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // --- THẺ THỜI TIẾT CHÍNH (HERO WEATHER CARD) ---
  Widget _buildHeroWeatherCard(
    BuildContext context,
    Weather? weather,
    bool isLoading,
    bool isDay,
  ) {
    final code = weather?.weatherCode;
    final cardGradients = _getCardGradients(code, isDay);
    final advice = _getWeatherSmartAdvice(code, weather?.temperature);

    // Tìm min/max hôm nay nếu có
    final todayForecast = weather != null && weather.daily.isNotEmpty
        ? weather.daily.first
        : null;

    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: cardGradients,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: Colors.white.withOpacity(0.35),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: cardGradients.first.withOpacity(0.4),
                blurRadius: 26,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hàng thông tin thành phố & thời điểm
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.near_me_rounded,
                              size: 17,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                weather?.cityName ?? 'Đang tải địa điểm...',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.4,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _formatCurrentDate(),
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.85),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Tag ngày / đêm
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.22),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.35)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isDay
                              ? Icons.wb_sunny_rounded
                              : Icons.nightlight_round,
                          size: 13,
                          color: isDay ? const Color(0xFFFDE047) : Colors.white,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          isDay ? 'BAN NGÀY' : 'BAN ĐÊM',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // KHỐI NHIỆT ĐỘ & ICON ĐỘNG 3D
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Nhiệt độ & Biên độ
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isLoading && weather == null)
                        const SizedBox(
                          height: 70,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 3.5,
                            ),
                          ),
                        )
                      else ...[
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              weather != null
                                  ? '${weather.temperature.round()}'
                                  : '--',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 68,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -2.5,
                                height: 0.95,
                              ),
                            ),
                            const Text(
                              '°C',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        // Tình trạng & Min/Max
                        Text(
                          weather?.description ?? 'Đang kết nối...',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (todayForecast != null) ...[
                          const SizedBox(height: 3),
                          Text(
                            'Thấp ${todayForecast.tempMin.round()}° • Cao ${todayForecast.tempMax.round()}°',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.85),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ],
                  ),

                  // ICON THỜI TIẾT ĐỘNG
                  AnimatedWeatherVisual(
                    weatherCode: code,
                    isDaytime: isDay,
                    size: 96,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // GỢI Ý THỜI TIẾT THÔNG MINH (SMART ADVICE)
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.25)),
                ),
                child: Row(
                  children: [
                    const Text('💡', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        advice,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          height: 1.25,
                        ),
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

  // --- DỰ BÁO 24 GIỜ TIẾP THEO (HOURLY FORECAST) ---
  Widget _buildHourlyForecastSection(
    BuildContext context,
    List<HourlyForecast> hourly,
    bool isDay,
  ) {
    final now = DateTime.now();

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isDay
                ? Colors.white.withOpacity(0.68)
                : const Color(0xFF1E293B).withOpacity(0.65),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isDay
                  ? Colors.white.withOpacity(0.85)
                  : Colors.white.withOpacity(0.15),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Icon(
                      Icons.schedule_rounded,
                      size: 18,
                      color: isDay
                          ? const Color(0xFF1D4ED8)
                          : const Color(0xFF818CF8),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Dự báo theo giờ',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: isDay ? const Color(0xFF0F172A) : Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 108,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  itemCount: hourly.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    final item = hourly[index];
                    final isCurrentHour =
                        now.day == item.time.day && now.hour == item.time.hour;
                    final timeLabel = isCurrentHour
                        ? 'Bây giờ'
                        : '${item.time.hour.toString().padLeft(2, '0')}:00';

                    return Container(
                      width: 66,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: isCurrentHour
                            ? (isDay
                                ? const Color(0xFF2563EB).withOpacity(0.15)
                                : const Color(0xFF6366F1).withOpacity(0.28))
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                        border: isCurrentHour
                            ? Border.all(
                                color: isDay
                                    ? const Color(0xFF2563EB)
                                    : const Color(0xFF818CF8),
                                width: 1.2,
                              )
                            : null,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Text(
                            timeLabel,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: isCurrentHour
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                              color: isCurrentHour
                                  ? (isDay
                                      ? const Color(0xFF1D4ED8)
                                      : const Color(0xFFA5B4FC))
                                  : (isDay
                                      ? const Color(0xFF475569)
                                      : Colors.white70),
                            ),
                          ),
                          Text(
                            item.icon,
                            style: const TextStyle(fontSize: 22),
                          ),
                          Text(
                            '${item.temperature.round()}°',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: isDay
                                  ? const Color(0xFF0F172A)
                                  : Colors.white,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- LƯỚI 4 CHỈ SỐ MÔI TRƯỜNG (2x2 GRID) ---
  Widget _buildWeatherMetricsGrid(
    BuildContext context,
    Weather weather,
    bool isDay,
  ) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMetricTile(
                isDay: isDay,
                icon: Icons.water_drop_rounded,
                iconColor: const Color(0xFF0284C7),
                title: 'Độ ẩm',
                value: '${weather.humidity}%',
                subtitle: _humidityDescriptor(weather.humidity),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricTile(
                isDay: isDay,
                icon: Icons.air_rounded,
                iconColor: const Color(0xFF0D9488),
                title: 'Tốc độ gió',
                value: '${weather.windSpeed.round()} km/h',
                subtitle: _windDescriptor(weather.windSpeed),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMetricTile(
                isDay: isDay,
                icon: Icons.thermostat_rounded,
                iconColor: const Color(0xFFEA580C),
                title: 'Cảm giác như',
                value: '${weather.feelsLike.round()}°C',
                subtitle: weather.feelsLike > weather.temperature
                    ? 'Nóng hơn thực tế'
                    : 'Dịu mát hơn',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricTile(
                isDay: isDay,
                icon: Icons.wb_twilight_rounded,
                iconColor: const Color(0xFF7C3AED),
                title: 'Tình trạng',
                value: weather.description,
                subtitle: isDay ? 'Đang ban ngày' : 'Đang về đêm',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricTile({
    required bool isDay,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    required String subtitle,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDay
                ? Colors.white.withOpacity(0.68)
                : const Color(0xFF1E293B).withOpacity(0.65),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDay
                  ? Colors.white.withOpacity(0.85)
                  : Colors.white.withOpacity(0.15),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: iconColor.withOpacity(0.14),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, size: 18, color: iconColor),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: isDay
                          ? const Color(0xFF64748B)
                          : const Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                value,
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: isDay ? const Color(0xFF0F172A) : Colors.white,
                  letterSpacing: -0.5,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  color: isDay
                      ? const Color(0xFF64748B)
                      : const Color(0xFFCBD5E1),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- DỰ BÁO 7 NGÀY VỚI TEMPERATURE RANGE BARS (APPLE STYLE) ---
  Widget _build7DayForecastCard(
    BuildContext context,
    Weather? weather,
    bool isLoading,
    bool isDay,
  ) {
    final dailyList = weather?.daily ?? const [];

    // Tìm min và max toàn tuần để chuẩn hóa thang đo nhiệt độ
    double weekMin = 100;
    double weekMax = -100;
    for (final d in dailyList) {
      if (d.tempMin < weekMin) weekMin = d.tempMin;
      if (d.tempMax > weekMax) weekMax = d.tempMax;
    }
    if (weekMin >= weekMax) {
      weekMin = 20;
      weekMax = 35;
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: isDay
                ? Colors.white.withOpacity(0.68)
                : const Color(0xFF1E293B).withOpacity(0.65),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDay
                  ? Colors.white.withOpacity(0.85)
                  : Colors.white.withOpacity(0.15),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.calendar_month_rounded,
                    size: 18,
                    color: isDay
                        ? const Color(0xFF1D4ED8)
                        : const Color(0xFF818CF8),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Dự báo 7 ngày tới',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: isDay ? const Color(0xFF0F172A) : Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (dailyList.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(
                      isLoading
                          ? 'Đang đồng bộ dự báo thời tiết...'
                          : 'Kéo xuống để cập nhật dữ liệu.',
                      style: TextStyle(
                        color: isDay ? Colors.black54 : Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ),
                )
              else
                ...dailyList.take(7).map((d) {
                  return _buildDailyForecastRow(
                    day: d,
                    weekMin: weekMin,
                    weekMax: weekMax,
                    isDay: isDay,
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDailyForecastRow({
    required DailyForecast day,
    required double weekMin,
    required double weekMax,
    required bool isDay,
  }) {
    final dayLabel = _dayLabel(day.date);
    final totalRange = (weekMax - weekMin).clamp(1.0, 100.0);
    final minPercent = ((day.tempMin - weekMin) / totalRange).clamp(0.0, 1.0);
    final maxPercent = ((day.tempMax - weekMin) / totalRange).clamp(0.0, 1.0);

    final textColor = isDay ? const Color(0xFF0F172A) : Colors.white;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          // Tên ngày
          SizedBox(
            width: 76,
            child: Text(
              dayLabel,
              style: TextStyle(
                fontSize: 14,
                fontWeight:
                    dayLabel == 'Hôm nay' ? FontWeight.w800 : FontWeight.w600,
                color: dayLabel == 'Hôm nay'
                    ? (isDay
                        ? const Color(0xFF1D4ED8)
                        : const Color(0xFF818CF8))
                    : textColor,
              ),
            ),
          ),
          // Icon thời tiết
          Text(day.icon, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 8),

          // Nhiệt độ thấp nhất
          SizedBox(
            width: 32,
            child: Text(
              '${day.tempMin.round()}°',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: isDay ? const Color(0xFF64748B) : Colors.white70,
              ),
            ),
          ),
          const SizedBox(width: 10),

          // THANH ĐO BIÊN ĐỘ NHIỆT (TEMPERATURE RANGE BAR)
          Expanded(
            child: Container(
              height: 6,
              decoration: BoxDecoration(
                color: isDay
                    ? Colors.black.withOpacity(0.06)
                    : Colors.white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final barWidth = constraints.maxWidth;
                  final left = barWidth * minPercent;
                  final width = math.max(
                    12.0,
                    barWidth * (maxPercent - minPercent),
                  );

                  return Stack(
                    children: [
                      Positioned(
                        left: left,
                        width: width,
                        top: 0,
                        bottom: 0,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFF38BDF8),
                                Color(0xFFFBBF24),
                                Color(0xFFF97316),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Nhiệt độ cao nhất
          SizedBox(
            width: 32,
            child: Text(
              '${day.tempMax.round()}°',
              textAlign: TextAlign.left,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- THẺ BÁO LỖI VÀ NÚT THỬ LẠI ---
  Widget _buildErrorCard(
    BuildContext context,
    WeatherProvider provider,
    ColorScheme cs,
  ) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: cs.errorContainer.withOpacity(0.9),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          Icon(Icons.cloud_off_rounded, size: 48, color: cs.error),
          const SizedBox(height: 12),
          Text(
            provider.errorMessage.isNotEmpty
                ? provider.errorMessage
                : 'Không thể kết nối đến máy chủ dự báo thời tiết.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: cs.onErrorContainer,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: () => provider.fetchWeather(),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Thử lại ngay'),
          ),
        ],
      ),
    );
  }

  // --- DIALOG TÌM KIẾM ĐỊA ĐIỂM ---
  Future<void> _showLocationSearch(
    BuildContext context,
    WeatherProvider provider,
  ) async {
    final controller = TextEditingController();
    Future<List<City>>? searchFuture;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.72,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              padding: EdgeInsets.fromLTRB(
                18,
                16,
                18,
                MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: Column(
                children: [
                  Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.35),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.search_rounded, size: 24),
                      const SizedBox(width: 8),
                      const Text(
                        'Tìm kiếm địa điểm',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: controller,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'Nhập tên xã, phường, quận, huyện, tỉnh thành...',
                      prefixIcon: const Icon(Icons.location_city_rounded),
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (val) {
                      final q = val.trim();
                      setState(() {
                        searchFuture = q.length < 2
                            ? null
                            : provider.searchCities(q);
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: searchFuture == null
                        ? const Center(
                            child: Text(
                              'Nhập từ khóa (xã, phường, quận, huyện, tỉnh thành) để tra cứu thời tiết tại Việt Nam.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey),
                            ),
                          )
                        : FutureBuilder<List<City>>(
                            future: searchFuture,
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              }
                              if (snapshot.hasError) {
                                return Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.cloud_off_rounded,
                                            size: 40, color: Colors.orange),
                                        const SizedBox(height: 10),
                                        const Text(
                                          'Chưa thể kết nối tới máy chủ tra cứu. Vui lòng thử lại.',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(color: Colors.grey),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }
                              final list = snapshot.data ?? const [];
                              if (list.isEmpty) {
                                return const Center(
                                  child: Text('Không tìm thấy địa điểm nào phù hợp.'),
                                );
                              }
                              return ListView.separated(
                                itemCount: list.length,
                                separatorBuilder: (_, __) => const Divider(height: 1),
                                itemBuilder: (context, i) {
                                  final city = list[i];
                                  final isIsland = city.name.contains('Hoàng Sa') ||
                                      city.name.contains('Trường Sa');
                                  return ListTile(
                                    leading: Icon(
                                      isIsland
                                          ? Icons.flag_rounded
                                          : Icons.location_on_outlined,
                                      color: isIsland
                                          ? Colors.red
                                          : const Color(0xFF1E60F2),
                                    ),
                                    title: Text(
                                      city.name,
                                      style: TextStyle(
                                        fontWeight: isIsland
                                            ? FontWeight.w800
                                            : FontWeight.w600,
                                        color: isIsland
                                            ? const Color(0xFFDC2626)
                                            : null,
                                      ),
                                    ),
                                    subtitle: isIsland
                                        ? const Text(
                                            'Lãnh thổ thiêng liêng của Việt Nam 🇻🇳',
                                            style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.red,
                                                fontWeight: FontWeight.bold),
                                          )
                                        : null,
                                    onTap: () {
                                      Navigator.pop(ctx);
                                      provider.selectCity(city);
                                    },
                                  );
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
      },
    );
    controller.dispose();
  }

  // --- CÁC HÀM TIỆN ÍCH DỮ LIỆU & GIAO DIỆN ---
  String _formatCurrentDate() {
    final now = DateTime.now();
    const days = [
      'Chủ Nhật',
      'Thứ Hai',
      'Thứ Ba',
      'Thứ Tư',
      'Thứ Năm',
      'Thứ Sáu',
      'Thứ Bảy'
    ];
    final dayStr = days[now.weekday % 7];
    return '$dayStr, ngày ${now.day} tháng ${now.month}';
  }

  String _dayLabel(DateTime date) {
    final now = DateTime.now();
    final diff = date.difference(DateTime(now.year, now.month, now.day)).inDays;
    if (diff == 0) return 'Hôm nay';
    if (diff == 1) return 'Ngày mai';
    const days = [
      'Chủ nhật',
      'Thứ 2',
      'Thứ 3',
      'Thứ 4',
      'Thứ 5',
      'Thứ 6',
      'Thứ 7'
    ];
    return days[date.weekday % 7];
  }

  String _humidityDescriptor(int h) {
    if (h < 40) return 'Khô ráo';
    if (h <= 70) return 'Thoải mái';
    return 'Ẩm ướt cao';
  }

  String _windDescriptor(double speed) {
    if (speed < 12) return 'Gió êm dịu';
    if (speed < 28) return 'Gió vừa phải';
    return 'Gió mạnh, thận trọng';
  }

  String _getWeatherSmartAdvice(int? code, double? temp) {
    if (code == null) return 'Đang cập nhật chỉ số dự báo thời tiết...';
    if (const [95, 96, 99].contains(code)) {
      return 'Dự báo có dông bão sấm sét, hạn chế ra ngoài và chú ý trú ẩn an toàn!';
    }
    if (const [51, 53, 55, 61, 63, 65, 80, 81, 82].contains(code)) {
      return 'Có mưa rải rác, nhớ mang theo ô hoặc áo mưa khi di chuyển nhé!';
    }
    if (const [45, 48].contains(code)) {
      return 'Sương mù làm giảm tầm nhìn, chú ý giảm tốc độ khi lái xe buổi sớm!';
    }
    if (temp != null && temp >= 34) {
      return 'Nhiệt độ ngoài trời khá gay gắt, nhớ uống đủ nước và chống nắng kỹ!';
    }
    if (temp != null && temp <= 16) {
      return 'Thời tiết se lạnh, đừng quên mặc áo ấm khi ra ngoài!';
    }
    return 'Thời tiết ôn hòa dễ chịu, rất thích hợp cho các hoạt động ngoài trời!';
  }

  List<Color> _getSkyGradient(int? code, bool isDay) {
    if (!isDay) {
      return const [
        Color(0xFF090D1A),
        Color(0xFF0F172A),
        Color(0xFF1E1B4B),
      ];
    }
    return switch (code) {
      0 || 1 || 2 => const [
          Color(0xFF60A5FA),
          Color(0xFF93C5FD),
          Color(0xFFE0F2FE),
        ],
      3 || 45 || 48 => const [
          Color(0xFF64748B),
          Color(0xFF94A3B8),
          Color(0xFFE2E8F0),
        ],
      51 || 53 || 55 || 61 || 63 || 65 || 80 || 81 || 82 => const [
          Color(0xFF475569),
          Color(0xFF64748B),
          Color(0xFF94A3B8),
        ],
      95 || 96 || 99 => const [
          Color(0xFF312E81),
          Color(0xFF4338CA),
          Color(0xFF6366F1),
        ],
      _ => const [
          Color(0xFF38BDF8),
          Color(0xFFBAE6FD),
          Color(0xFFF0F9FF),
        ],
    };
  }

  List<Color> _getCardGradients(int? code, bool isDay) {
    if (!isDay) {
      return const [
        Color(0xFF1E1B4B),
        Color(0xFF312E81),
        Color(0xFF4338CA),
      ];
    }
    return switch (code) {
      0 || 1 || 2 => const [
          Color(0xFF1D4ED8),
          Color(0xFF2563EB),
          Color(0xFF38BDF8),
        ],
      3 || 45 || 48 => const [
          Color(0xFF334155),
          Color(0xFF475569),
          Color(0xFF64748B),
        ],
      51 || 53 || 55 || 61 || 63 || 65 || 80 || 81 || 82 => const [
          Color(0xFF0F766E),
          Color(0xFF0284C7),
          Color(0xFF38BDF8),
        ],
      95 || 96 || 99 => const [
          Color(0xFF1E1B4B),
          Color(0xFF4C1D95),
          Color(0xFF7C3AED),
        ],
      _ => const [
          Color(0xFF0284C7),
          Color(0xFF0EA5E9),
          Color(0xFF38BDF8),
        ],
    };
  }
}

/// BỘ VẼ HIỆU ỨNG THỜI TIẾT TOÀN DIỆN (CANVAS ATMOSPHERE PAINTER)
class _WeatherAtmospherePainter extends CustomPainter {
  final double progress;
  final int? code;
  final bool isDaytime;

  _WeatherAtmospherePainter({
    required this.progress,
    required this.code,
    required this.isDaytime,
  });

  bool get _isRain => const [51, 53, 55, 61, 63, 65, 80, 81, 82].contains(code);
  bool get _isStorm => const [95, 96, 99].contains(code);
  bool get _isSnow => const [71, 73, 75, 77, 85, 86].contains(code);
  bool get _isFog => const [45, 48].contains(code);
  bool get _isClear => code == 0 || code == 1 || code == 2;

  @override
  void paint(Canvas canvas, Size size) {
    if (_isClear && isDaytime) {
      _paintSunnyAtmosphere(canvas, size);
    } else if (!isDaytime) {
      _paintNightAtmosphere(canvas, size);
    }

    if (_isRain || _isStorm) {
      _paintRainAndLightning(canvas, size);
    } else if (_isSnow) {
      _paintSnowAtmosphere(canvas, size);
    } else if (_isFog) {
      _paintFogAtmosphere(canvas, size);
    }

    // Luôn vẽ mây trôi nhẹ ở hậu cảnh tạo chiều sâu
    _paintFloatingClouds(canvas, size);
  }

  // Bộ nhớ đệm tĩnh tái sử dụng đối tượng Paint & Path tránh cấp phát trên frame loop (60-120 FPS)
  static final Paint _coronaPaint = Paint();
  static final Paint _sparklePaint = Paint()..color = const Color(0xFFFEF3C7).withOpacity(0.35);
  static final Paint _starPaint = Paint()..color = Colors.white;
  static final Paint _shootPaint = Paint()
    ..strokeWidth = 2.0
    ..strokeCap = StrokeCap.round;
  static final Paint _rainPaint = Paint()..strokeCap = StrokeCap.round;
  static final Paint _ripplePaint = Paint()
    ..color = Colors.white.withOpacity(0.25)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.0;
  static final Paint _flashOverlay = Paint()
    ..color = const Color(0xFFFDE047).withOpacity(0.18);
  static final Paint _boltPaint = Paint()
    ..color = const Color(0xFFFEF08A)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3.5
    ..strokeJoin = StrokeJoin.round;
  static final Path _boltPath = Path();
  static final Paint _snowPaint = Paint()..color = Colors.white.withOpacity(0.8);
  static final Paint _fogPaint = Paint()..color = Colors.white.withOpacity(0.16);
  static final Paint _cloudPaint = Paint();
  static final Path _cloudPath = Path();

  // --- TRỜI NẮNG VÀ BỤI NẮNG BOKEH ---
  void _paintSunnyAtmosphere(Canvas canvas, Size size) {
    final sunCenter = Offset(
      size.width * 0.82 + math.sin(progress * math.pi * 2) * 12,
      size.height * 0.14,
    );

    // Hào quang mặt trời lan rộng (Tái sử dụng _coronaPaint)
    _coronaPaint.shader = RadialGradient(
      colors: [
        const Color(0xFFFFFBEB).withOpacity(0.38),
        const Color(0xFFFDE68A).withOpacity(0.18),
        Colors.transparent,
      ],
    ).createShader(Rect.fromCircle(center: sunCenter, radius: 170));
    canvas.drawCircle(sunCenter, 170, _coronaPaint);

    // Bụi nắng lơ lửng (Sun dust sparkles)
    for (var i = 0; i < 22; i++) {
      final x = (i * 61.0 + math.sin(progress * math.pi * 2 + i) * 18) % size.width;
      final y = (i * 87.0 + progress * 40) % (size.height * 0.7);
      canvas.drawCircle(Offset(x, y), 1.4 + (i % 3) * 0.8, _sparklePaint);
    }
  }

  // --- ĐÊM SAO VÀ SAO BĂNG (STARRY NIGHT & SHOOTING STAR) ---
  void _paintNightAtmosphere(Canvas canvas, Size size) {
    // 48 ngôi sao nhấp nháy với chu kỳ khác nhau
    for (var i = 0; i < 48; i++) {
      final x = (i * 79.0 + (i * 17) % 31) % size.width;
      final y = (i * 47.0 + (i * 23) % 41) % (size.height * 0.75);
      final twinkle = 0.25 + 0.75 * math.sin(progress * math.pi * 6 + i * 2.1).abs();
      _starPaint.color = Colors.white.withOpacity(twinkle);
      canvas.drawCircle(Offset(x, y), 1.0 + (i % 3) * 0.6, _starPaint);
    }

    // Sao băng lướt qua bầu trời (Shooting Star)
    final shootingProgress = (progress * 2.5) % 1.0;
    if (shootingProgress < 0.35) {
      final t = shootingProgress / 0.35;
      final startX = size.width * (0.2 + t * 0.6);
      final startY = size.height * (0.05 + t * 0.25);
      _shootPaint.shader = LinearGradient(
        colors: [
          Colors.transparent,
          Colors.white.withOpacity(0.85),
        ],
      ).createShader(
        Rect.fromPoints(
          Offset(startX - 50, startY - 25),
          Offset(startX, startY),
        ),
      );
      canvas.drawLine(
        Offset(startX - 50, startY - 25),
        Offset(startX, startY),
        _shootPaint,
      );
    }
  }

  // --- MƯA VÀ SẤM CHỚP (RAIN & LIGHTNING) ---
  void _paintRainAndLightning(Canvas canvas, Size size) {
    _rainPaint
      ..color = Colors.white.withOpacity(_isStorm ? 0.38 : 0.28)
      ..strokeWidth = _isStorm ? 2.2 : 1.7;

    // 64 giọt mưa rơi chéo
    for (var i = 0; i < 64; i++) {
      final speedFactor = 1.0 + (i % 4) * 0.3;
      final x = (i * 37.0) % (size.width + 50);
      final y = (i * 59.0 + progress * size.height * 1.8 * speedFactor) %
          (size.height + 60);

      canvas.drawLine(
        Offset(x, y),
        Offset(x - 6, y + (_isStorm ? 18 : 13)),
        _rainPaint,
      );

      // Hiệu ứng giọt nước bắn khi chạm mép dưới (Splash ripples)
      if (y > size.height - 70 && i % 3 == 0) {
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(x - 6, y + 14),
            width: 14 + (i % 3) * 6,
            height: 4,
          ),
          _ripplePaint,
        );
      }
    }

    // Chớp sấm sét dữ dội (Lightning Flash)
    if (_isStorm) {
      final flashVal = (progress * 5) % 1.0;
      if (flashVal > 0.82 && flashVal < 0.94) {
        // Ánh chớp làm bừng sáng màn hình
        canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), _flashOverlay);

        // Tia sét chính (Tái sử dụng _boltPath)
        _boltPath.reset();
        _boltPath.moveTo(size.width * 0.72, size.height * 0.08);
        _boltPath.lineTo(size.width * 0.65, size.height * 0.22);
        _boltPath.lineTo(size.width * 0.70, size.height * 0.21);
        _boltPath.lineTo(size.width * 0.58, size.height * 0.38);
        _boltPath.lineTo(size.width * 0.62, size.height * 0.37);
        _boltPath.lineTo(size.width * 0.52, size.height * 0.52);
        canvas.drawPath(_boltPath, _boltPaint);
      }
    }
  }

  // --- TUYẾT RƠI BỒNG BỀNH (SNOW ATMOSPHERE) ---
  void _paintSnowAtmosphere(Canvas canvas, Size size) {
    for (var i = 0; i < 40; i++) {
      final progressOffset = (progress + i * 0.025) % 1.0;
      final sway = math.sin(progressOffset * math.pi * 4 + i) * 22;
      final x = (i * 47.0 + sway) % size.width;
      final y = (i * 73.0 + progressOffset * size.height * 1.1) % (size.height + 30);
      final radius = 1.8 + (i % 4) * 1.1;

      canvas.drawCircle(Offset(x, y), radius, _snowPaint);
    }
  }

  // --- SƯƠNG MÙ (FOG) ---
  void _paintFogAtmosphere(Canvas canvas, Size size) {
    for (var i = 0; i < 6; i++) {
      final y = size.height * (0.35 + i * 0.10);
      final drift = math.sin(progress * math.pi * 2 + i * 1.4) * 45;
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(size.width * 0.5 + drift, y),
          width: size.width * 1.1,
          height: 32 + i * 6,
        ),
        _fogPaint,
      );
    }
  }

  // --- DẢI MÂY TRÔI PARALLAX HẬU CẢNH ---
  void _paintFloatingClouds(Canvas canvas, Size size) {
    _cloudPaint.color = Colors.white.withOpacity(_isStorm ? 0.08 : 0.14);

    final travel = size.width + 280;
    for (var layer = 0; layer < 2; layer++) {
      final direction = layer == 0 ? 1 : -1;
      final scale = layer == 0 ? 1.0 : 1.35;
      final y = size.height * (0.78 + layer * 0.12);

      for (var i = 0; i < 3; i++) {
        final x = ((progress * travel * direction * 0.6 + i * 220 * scale) % travel) -
            140 * scale;
        _cloudPath.reset();
        _cloudPath.addOval(Rect.fromLTWH(x, y, 160 * scale, 52 * scale));
        _cloudPath.addOval(Rect.fromLTWH(x + 32 * scale, y - 28 * scale, 80 * scale, 64 * scale));
        _cloudPath.addOval(Rect.fromLTWH(x + 88 * scale, y - 18 * scale, 95 * scale, 56 * scale));
        canvas.drawPath(_cloudPath, _cloudPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _WeatherAtmospherePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.code != code ||
        oldDelegate.isDaytime != isDaytime;
  }
}
