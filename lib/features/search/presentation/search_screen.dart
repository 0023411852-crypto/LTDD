import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/article.dart';
import '../../../models/weather.dart';
import '../../../services/weather_service.dart';
import '../../news/presentation/article_detail_screen.dart';
import '../../news/providers/news_provider.dart';
import '../../weather/presentation/weather_screen.dart';
import '../../weather/providers/weather_provider.dart';
import '../providers/search_provider.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final currentQ = context.read<SearchProvider>().currentQuery;
        if (currentQ.isNotEmpty && _searchController.text.isEmpty) {
          _searchController.text = currentQ;
        }
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _isIsland(String name) {
    final lower = name.toLowerCase();
    return lower.contains('hoàng sa') ||
        lower.contains('hoang sa') ||
        lower.contains('trường sa') ||
        lower.contains('truong sa');
  }

  void _triggerSearch(String query) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;
    _searchController.text = trimmed;
    final newsProvider = context.read<NewsProvider>();
    final weatherProvider = context.read<WeatherProvider>();
    context.read<SearchProvider>().performSearch(
          query: trimmed,
          newsProvider: newsProvider,
          weatherProvider: weatherProvider,
        );
  }

  @override
  Widget build(BuildContext context) {
    final search = context.watch<SearchProvider>();
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.only(right: 16),
          child: TextField(
            controller: _searchController,
            textInputAction: TextInputAction.search,
            autofocus: false,
            onChanged: (_) => setState(() {}),
            onSubmitted: _triggerSearch,
            decoration: InputDecoration(
              hintText: 'Tìm kiếm tin tức, thời tiết, Hoàng Sa...',
              hintStyle: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
              filled: true,
              fillColor: cs.surfaceContainerHighest,
              prefixIcon: IconButton(
                icon: const Icon(Icons.search_rounded, size: 20),
                onPressed: () => _triggerSearch(_searchController.text),
              ),
              suffixIcon: _searchController.text.isNotEmpty || search.hasSearched
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        context.read<SearchProvider>().resetSearch();
                      },
                    )
                  : null,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide(color: cs.primary, width: 1.5),
              ),
            ),
          ),
        ),
      ),
      body: search.hasSearched
          ? _buildSearchResults(search)
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [cs.primary, cs.primary.withOpacity(0.78)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.explore_rounded,
                          color: Colors.white, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Tìm kiếm tin tức và thời tiết mọi tỉnh thành, hải đảo Việt Nam',
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                  ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                Text(
                  'Từ khóa phổ biến',
                  style: tt.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: search.trendingTopics.map((item) {
                    final isIslandTopic =
                        item.contains('Hoàng Sa') || item.contains('Trường Sa');
                    return ActionChip(
                      avatar: isIslandTopic
                          ? const Icon(Icons.flag_rounded,
                              size: 14, color: Colors.redAccent)
                          : null,
                      label: Text(item),
                      onPressed: () => _triggerSearch(item),
                      side: BorderSide(
                          color: isIslandTopic
                              ? Colors.redAccent.withOpacity(0.4)
                              : cs.outlineVariant),
                      backgroundColor:
                          isIslandTopic ? Colors.red.withOpacity(0.06) : cs.surface,
                      labelStyle: TextStyle(
                        fontSize: 13,
                        fontWeight:
                            isIslandTopic ? FontWeight.w600 : FontWeight.normal,
                        color: isIslandTopic ? Colors.red[800] : cs.onSurfaceVariant,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),

                // Lịch sử tìm kiếm
                if (search.history.isNotEmpty) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Lịch sử tìm kiếm',
                        style: tt.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: cs.onSurface,
                        ),
                      ),
                      TextButton(
                        onPressed: () => context.read<SearchProvider>().clearHistory(),
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                        ),
                        child: Text(
                          'Xóa tất cả',
                          style: TextStyle(fontSize: 13, color: cs.primary),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...search.history.map((term) {
                    final island = _isIsland(term);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: ListTile(
                        dense: true,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        tileColor: cs.surface,
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 12),
                        leading: Icon(
                          island ? Icons.flag_rounded : Icons.history_rounded,
                          color: island ? Colors.redAccent : cs.primary,
                          size: 20,
                        ),
                        title: Text(term,
                            style:
                                TextStyle(fontSize: 14, color: cs.onSurface)),
                        trailing: IconButton(
                          icon: Icon(Icons.close_rounded,
                              size: 16, color: cs.outline),
                          tooltip: 'Xóa mục này',
                          onPressed: () => context
                              .read<SearchProvider>()
                              .removeHistoryItem(term),
                        ),
                        onTap: () => _triggerSearch(term),
                      ),
                    );
                  }),
                ],
              ],
            ),
    );
  }

  Widget _buildSearchResults(SearchProvider search) {
    final cs = Theme.of(context).colorScheme;
    final hasWeather = search.previewWeather != null ||
        search.matchingCities.isNotEmpty ||
        search.isLoadingWeather;
    final hasNews = search.searchResults.isNotEmpty;

    if (search.isLoadingNews && !hasWeather && !hasNews) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(strokeWidth: 2.5),
            const SizedBox(height: 16),
            Text(
              'Đang tìm kiếm bài báo và tin tức...',
              style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
            ),
          ],
        ),
      );
    }

    if (!hasWeather && !hasNews && !search.isLoadingNews) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search_off_rounded, size: 56, color: cs.outline),
              const SizedBox(height: 16),
              Text(
                'Không tìm thấy kết quả phù hợp',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Không tìm thấy bài báo hay địa điểm nào cho từ khóa "${_searchController.text}".',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  ActionChip(
                    avatar: const Icon(Icons.wb_sunny_rounded, size: 14),
                    label: const Text('Xem thời tiết hôm nay'),
                    onPressed: () => _triggerSearch('thời tiết'),
                  ),
                  ActionChip(
                    avatar: const Icon(Icons.flag_rounded,
                        size: 14, color: Colors.redAccent),
                    label: const Text('Hoàng Sa & Trường Sa'),
                    onPressed: () => _triggerSearch('Hoàng Sa'),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    // Xác định bộ lọc đang chọn
    final filter = search.activeFilter;
    final showNews = (filter == 'Tất cả' || filter == 'Tin tức') && hasNews;
    final showWeather = (filter == 'Tất cả' || filter == 'Thời tiết') && hasWeather;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        // Thanh bộ lọc kết quả (Tất cả, Tin tức, Thời tiết)
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              ChoiceChip(
                label: Text('Tất cả (${search.searchResults.length + (hasWeather ? 1 : 0)})'),
                selected: search.activeFilter == 'Tất cả',
                onSelected: (_) => context.read<SearchProvider>().setActiveFilter('Tất cả'),
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                avatar: const Icon(Icons.newspaper_rounded, size: 15),
                label: Text('Tin tức (${search.searchResults.length})'),
                selected: search.activeFilter == 'Tin tức',
                onSelected: (_) => context.read<SearchProvider>().setActiveFilter('Tin tức'),
              ),
              if (hasWeather) ...[
                const SizedBox(width: 8),
                ChoiceChip(
                  avatar: const Icon(Icons.wb_sunny_rounded, size: 15),
                  label: const Text('Thời tiết'),
                  selected: search.activeFilter == 'Thời tiết',
                  onSelected: (_) => context.read<SearchProvider>().setActiveFilter('Thời tiết'),
                ),
              ],
            ],
          ),
        ),
        if (search.isLoadingNews) ...[
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              minHeight: 3,
              backgroundColor: cs.surfaceContainerHighest,
              color: cs.primary,
            ),
          ),
        ],
        const SizedBox(height: 14),

        // Khi tìm chủ đề tin tức: hiển thị tin tức trước!
        if (showNews) ...[
          Row(
            children: [
              Icon(Icons.newspaper_rounded, size: 18, color: cs.primary),
              const SizedBox(width: 8),
              Text(
                'Bài viết liên quan (${search.searchResults.length})',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...search.searchResults.map((article) => _buildArticleItem(article, cs)),
          const SizedBox(height: 16),
        ],

        // Dự báo thời tiết (hiển thị khi có kết quả thời tiết và bộ lọc cho phép)
        if (showWeather) ...[
          _buildWeatherSection(cs, search),
          const SizedBox(height: 20),
        ],

        if (!showNews && filter == 'Tin tức' && !search.isLoadingNews)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text(
                'Không có bài báo nào cho từ khóa này.',
                style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildWeatherSection(ColorScheme cs, SearchProvider search) {
    final previewCity = search.selectedPreviewCity;
    final weather = search.previewWeather;
    final isIslandCity = previewCity != null && _isIsland(previewCity.name);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.wb_sunny_rounded, size: 18, color: cs.primary),
            const SizedBox(width: 8),
            Text(
              'Dự báo thời tiết trực tuyến',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Thẻ hiển thị thời tiết sống động
        if (search.isLoadingWeather)
          Container(
            height: 120,
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: cs.outlineVariant),
            ),
            child: const Center(
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
          )
        else if (weather != null && previewCity != null)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isIslandCity
                    ? [
                        const Color(0xFF0D47A1),
                        const Color(0xFF1976D2),
                        const Color(0xFFC62828),
                      ]
                    : [
                        const Color(0xFF1565C0),
                        const Color(0xFF1E88E5),
                        const Color(0xFF42A5F5),
                      ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isIslandCity)
                      const Padding(
                        padding: EdgeInsets.only(right: 6, top: 2),
                        child: Icon(Icons.flag_rounded,
                            color: Colors.yellowAccent, size: 18),
                      ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            previewCity.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (isIslandCity)
                            const Text(
                              'Lãnh thổ thiêng liêng của Việt Nam 🇻🇳',
                              style: TextStyle(
                                color: Colors.yellowAccent,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Text(
                      weather.icon,
                      style: const TextStyle(fontSize: 32),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${weather.temperature.round()}°C',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 34,
                            fontWeight: FontWeight.w900,
                            height: 1.0,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          weather.description,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Cảm giác: ${weather.feelsLike.round()}°C',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.85),
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          'Độ ẩm: ${weather.humidity}%',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.85),
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          'Gió: ${weather.windSpeed.toStringAsFixed(1)} km/h',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.85),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.2),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    icon: const Icon(Icons.calendar_today_rounded, size: 15),
                    label: const Text(
                      'Xem chi tiết dự báo thời tiết đầy đủ',
                      style:
                          TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    onPressed: () {
                      final city = previewCity;
                      if (city != null) {
                        context.read<WeatherProvider>().selectCity(city);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const WeatherScreen(),
                          ),
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ),

        // Danh sách địa điểm khớp khác
        if (search.matchingCities.length > 1) ...[
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: search.matchingCities.map((city) {
                final isCurrent = city.name == previewCity?.name;
                final island = _isIsland(city.name);
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    selected: isCurrent,
                    avatar: island
                        ? const Icon(Icons.flag_rounded,
                            size: 14, color: Colors.redAccent)
                        : null,
                    label: Text(
                      city.name.replaceAll(' (Đà Nẵng)', '').replaceAll(' (Khánh Hòa)', ''),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight:
                            isCurrent ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    onSelected: (_) =>
                        context.read<SearchProvider>().loadWeatherForCity(city),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildArticleItem(Article article, ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        key: ValueKey(article.link),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ArticleDetailScreen(article: article),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cs.outlineVariant),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: article.imageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: article.imageUrl!,
                        width: 88,
                        height: 66,
                        memCacheWidth: 264,
                        memCacheHeight: 198,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          width: 88,
                          height: 66,
                          color: cs.surfaceContainerHighest,
                          child: const Center(
                            child: SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 1.5),
                            ),
                          ),
                        ),
                        errorWidget: (_, __, ___) => Container(
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      article.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            height: 1.35,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      article.source,
                      style: TextStyle(
                        fontSize: 11,
                        color: cs.primary,
                        fontWeight: FontWeight.w500,
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
}
