import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/article.dart';
import '../../../services/news_service.dart';
import '../../auth/providers/auth_provider.dart';
import '../../favorites/providers/favorites_provider.dart';
import '../../news/providers/news_provider.dart';
import '../../notifications/providers/notifications_provider.dart';
import '../../settings/providers/settings_provider.dart';
import '../../weather/providers/weather_provider.dart';
import '../providers/admin_provider.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  // Trạng thái Admin được quản lý tập trung qua AdminProvider & NewsProvider
  int get _currentTab => context.read<AdminProvider>().currentTab;
  String get _newsSearchQuery => context.read<AdminProvider>().newsSearchQuery;
  String get _newsFilter => context.read<AdminProvider>().newsFilter;
  Set<String> get _pendingArticleTitles =>
      context.watch<NewsProvider>().pendingArticleTitles;
  List<Map<String, dynamic>> get _broadcastNotifications =>
      context.read<AdminProvider>().broadcastNotifications;
  String get _selectedNotifType =>
      context.read<AdminProvider>().selectedNotifType;

  void _setTab(int tab) => context.read<AdminProvider>().setTab(tab);
  void _setNewsSearchQuery(String query) =>
      context.read<AdminProvider>().setNewsSearchQuery(query);
  void _setNewsFilter(String filter) =>
      context.read<AdminProvider>().setNewsFilter(filter);
  void _setSelectedNotifType(String type) =>
      context.read<AdminProvider>().setSelectedNotifType(type);
  void _toggleApproval(String title) {
    context.read<AdminProvider>().toggleApproval(title);
    context.read<NewsProvider>().toggleArticleApproval(title);
  }

  void _broadcastNotification(String title, String body, String type) {
    context.read<AdminProvider>().broadcastNotification(
          title: title,
          body: body,
          type: type,
        );

    // Đồng bộ vào NotificationsProvider để lưu vĩnh viễn và hiển thị cho toàn bộ người dùng
    context.read<NotificationsProvider>().addNotification(
          title: title,
          body: body,
          type: type == 'Tin nóng' ? 'breaking' : 'news',
        );

    final settings = context.read<SettingsProvider>();
    final isAllowed = type == 'Tin nóng' ? settings.breakingNewsNotif : true;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                isAllowed
                    ? 'Đã phát sóng thông báo "$title" đến người dùng'
                    : 'Đã lưu thông báo (người dùng đang tắt nhận thông báo tin nóng trong Cài đặt)',
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF10B981),
      ),
    );
  }

  // Controllers cho form gửi thông báo
  final _notifTitleController = TextEditingController();
  final _notifBodyController = TextEditingController();

  @override
  void dispose() {
    _notifTitleController.dispose();
    _notifBodyController.dispose();
    super.dispose();
  }

  // ── Màu theo theme (Light/Dark) cho toàn bộ màn Admin ──────────────
  // Trước đây màn Admin ghim cứng nền trắng / chữ đen nên bật Dark mode
  // vẫn trắng chói. Nay mọi màu nền / thẻ / chữ / viền đều đi qua các
  // getter này (cùng tông với AppTheme: nền tối 0B132B, thẻ 1C2541).
  bool get _isDarkMode => Theme.of(context).brightness == Brightness.dark;
  Color get _bgColor =>
      _isDarkMode ? const Color(0xFF0B132B) : const Color(0xFFF1F5F9);
  Color get _surfaceColor =>
      _isDarkMode ? const Color(0xFF1C2541) : Colors.white;
  Color get _textColor =>
      _isDarkMode ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
  Color get _subTextColor =>
      _isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
  Color get _borderColor =>
      _isDarkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
  Color get _chipColor =>
      _isDarkMode ? const Color(0xFF334155) : const Color(0xFFF1F5F9);
  Color get _inputFillColor =>
      _isDarkMode ? const Color(0xFF0B132B) : const Color(0xFFF8FAFC);

  String _getTabTitle() {
    switch (_currentTab) {
      case 0:
        return 'Admin Dashboard';
      case 1:
        return 'Quản lý tin tức';
      case 2:
        return 'Quản lý danh mục';
      case 3:
        return 'Tài khoản người dùng';
      case 4:
        return 'Phát sóng thông báo';
      case 5:
        return 'Thống kê & Báo cáo';
      default:
        return 'Admin Panel';
    }
  }

  @override
  Widget build(BuildContext context) {
    final newsProvider = context.watch<NewsProvider>();
    final authProvider = context.watch<AuthProvider>();
    final favProvider = context.watch<FavoritesProvider>();
    final weatherProvider = context.watch<WeatherProvider>();
    context.watch<AdminProvider>();

    if (!authProvider.isAdmin) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Bảng quản trị viên'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.admin_panel_settings_outlined,
                    size: 64, color: Color(0xFF0D9488)),
                const SizedBox(height: 16),
                const Text(
                  'Quyền truy cập bị từ chối',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Chỉ tài khoản có vai trò Quản trị viên (Admin) mới có quyền truy cập trang này.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                ),
                const SizedBox(height: 24),
                FilledButton.tonal(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Quay lại'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final realArticles = newsProvider.allArticles;
    final realCategories = newsProvider.categories;

    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF1654F0),
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_back_rounded,
                color: Colors.white, size: 20),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _getTabTitle(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 18,
                letterSpacing: -0.3,
              ),
            ),
            Text(
              'Số liệu thực tế: ${realArticles.length} bài viết • ${realCategories.length} chuyên mục',
              style: const TextStyle(
                color: Color(0xFFBFDBFE),
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Làm mới dữ liệu từ RSS',
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: () async {
              await newsProvider.fetchNews();
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Đã đồng bộ lại dữ liệu tin tức từ RSS!'),
                    backgroundColor: Colors.green),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            children: [
              // Top Navigation Bar
              _buildModernTabBar(),

              // Body content
              Expanded(
                child: IndexedStack(
                  index: _currentTab,
                  children: [
                    _buildDashboardTab(newsProvider, authProvider, favProvider,
                        weatherProvider),
                    _buildNewsManagementTab(newsProvider),
                    _buildCategoryManagementTab(newsProvider),
                    _buildUserManagementTab(authProvider),
                    _buildPushNotificationTab(),
                    _buildReportStatisticsTab(newsProvider, favProvider),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════
  // TOP HORIZONTAL TAB BAR (Chuyển nhanh giữa 6 chức năng)
  // ══════════════════════════════════════════════════════════════════
  Widget _buildModernTabBar() {
    final tabs = [
      {'icon': Icons.dashboard_rounded, 'label': 'Dashboard'},
      {'icon': Icons.newspaper_rounded, 'label': 'Tin tức'},
      {'icon': Icons.category_rounded, 'label': 'Danh mục'},
      {'icon': Icons.manage_accounts_rounded, 'label': 'Tài khoản'},
      {'icon': Icons.send_rounded, 'label': 'Thông báo'},
      {'icon': Icons.insights_rounded, 'label': 'Báo cáo'},
    ];

    return Container(
      color: _surfaceColor,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: List.generate(tabs.length, (idx) {
            final isSelected = _currentTab == idx;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: InkWell(
                onTap: () => _setTab(idx),
                borderRadius: BorderRadius.circular(20),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF1654F0) : _chipColor,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: const Color(0xFF1654F0).withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        tabs[idx]['icon'] as IconData,
                        size: 17,
                        color: isSelected ? Colors.white : _subTextColor,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        tabs[idx]['label'] as String,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w600,
                          color: isSelected ? Colors.white : _subTextColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════
  // 1. DASHBOARD THỰC TẾ (Không số liệu giả)
  // ══════════════════════════════════════════════════════════════════
  Widget _buildDashboardTab(
    NewsProvider news,
    AuthProvider auth,
    FavoritesProvider fav,
    WeatherProvider weather,
  ) {
    final articleCount = news.totalArticlesCount;
    final categoryCount = news.categories.length;
    final favCount = fav.favorites.length;
    final temp = weather.weather?.temperature.round();
    final city = weather.weather?.cityName ?? 'Hà Nội';

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Admin Profile Card thực tế
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1E60F2), Color(0xFF2563EB)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1E60F2).withOpacity(0.3),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: CircleAvatar(
                  radius: 26,
                  backgroundColor: const Color(0xFFDBEAFE),
                  child: Icon(
                    auth.isAuthenticated
                        ? Icons.person_rounded
                        : Icons.person_outline_rounded,
                    color: const Color(0xFF1654F0),
                    size: 30,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            auth.isAuthenticated
                                ? auth.displayName
                                : 'Admin (Chế độ khách)',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 16.5,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: auth.isAuthenticated
                                ? const Color(0xFF10B981)
                                : Colors.amber.shade700,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            auth.isAuthenticated ? 'ONLINE' : 'GUEST',
                            style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      auth.isAuthenticated
                          ? auth.email
                          : 'Chưa đăng nhập tài khoản Firebase',
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFFDBEAFE)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 4 Thẻ chỉ số thực tế
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                title: 'Tổng số tin tức',
                value: '$articleCount',
                subText: 'Đang tải từ RSS & Admin',
                icon: Icons.article_rounded,
                color: const Color(0xFF2563EB),
                bgGradient: const [Color(0xFFEFF6FF), Color(0xFFDBEAFE)],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                title: 'Số chuyên mục',
                value: '$categoryCount',
                subText: 'Đang hoạt động',
                icon: Icons.category_rounded,
                color: const Color(0xFFF59E0B),
                bgGradient: const [Color(0xFFFFFBEB), Color(0xFFFEF3C7)],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                title: 'Tin đã lưu',
                value: '$favCount',
                subText: 'Người dùng yêu thích',
                icon: Icons.bookmark_rounded,
                color: const Color(0xFF10B981),
                bgGradient: const [Color(0xFFECFDF5), Color(0xFFD1FAE5)],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                title: 'Thời tiết hiện tại',
                value: temp != null ? '$temp°C' : '--°C',
                subText: city,
                icon: Icons.cloud_queue_rounded,
                color: const Color(0xFF0284C7),
                bgGradient: const [Color(0xFFF0F9FF), Color(0xFFE0F2FE)],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Tác vụ nhanh
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _surfaceColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tác vụ quản trị nhanh',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: _textColor),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _buildQuickActionBtn(
                    label: '+ Đăng tin mới',
                    icon: Icons.post_add_rounded,
                    color: const Color(0xFF1E60F2),
                    onTap: () {
                      _setTab(1);
                      _showAddArticleDialog(context);
                    },
                  ),
                  _buildQuickActionBtn(
                    label: 'Xem danh sách tin',
                    icon: Icons.newspaper_rounded,
                    color: const Color(0xFF10B981),
                    onTap: () => _setTab(1),
                  ),
                  _buildQuickActionBtn(
                    label: 'Phát sóng thông báo',
                    icon: Icons.send_rounded,
                    color: const Color(0xFFEC4899),
                    onTap: () => _setTab(4),
                  ),
                  _buildQuickActionBtn(
                    label: 'Báo cáo nguồn tin',
                    icon: Icons.pie_chart_rounded,
                    color: const Color(0xFF8B5CF6),
                    onTap: () => _setTab(5),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Biểu đồ phân bổ bài viết thực tế theo ngày trong tuần
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: _surfaceColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Phân bổ tin bài thực tế',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: _textColor),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Đếm số lượng bài viết theo ngày đăng (publishedAt)',
                          style: TextStyle(fontSize: 12, color: _subTextColor),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Tổng $articleCount bài',
                      style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E60F2)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Vẽ biểu đồ dựa trên số lượng bài viết thật
              SizedBox(
                height: 150,
                width: double.infinity,
                child: CustomPaint(
                  painter: _RealNewsDistributionChartPainter(
                    articles: news.allArticles,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children:
                    const ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'].map((d) {
                  return Text(d,
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF94A3B8)));
                }).toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════
  // 2. TAB: QUẢN LÝ TIN TỨC THỰC TẾ (Lấy trực tiếp từ NewsProvider)
  // ══════════════════════════════════════════════════════════════════
  Widget _buildNewsManagementTab(NewsProvider news) {
    final allArticles = news.allArticles;

    final filtered = allArticles.where((a) {
      final matchesSearch = _newsSearchQuery.isEmpty ||
          a.title.toLowerCase().contains(_newsSearchQuery.toLowerCase()) ||
          a.source.toLowerCase().contains(_newsSearchQuery.toLowerCase());
      if (!matchesSearch) return false;

      final isPending = _pendingArticleTitles.contains(a.title);
      if (_newsFilter == 'Chờ duyệt') return isPending;
      if (_newsFilter == 'Đã duyệt') return !isPending;
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          // Search & Filter header
          Container(
            color: _surfaceColor,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              children: [
                TextField(
                  onChanged: (val) => _setNewsSearchQuery(val),
                  decoration: InputDecoration(
                    hintText:
                        'Tìm kiếm trên ${allArticles.length} bài viết thật...',
                    hintStyle:
                        TextStyle(color: Colors.grey.shade400, fontSize: 13.5),
                    prefixIcon: const Icon(Icons.search_rounded,
                        color: Color(0xFF1E60F2), size: 22),
                    suffixIcon: _newsSearchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () => _setNewsSearchQuery(''),
                          )
                        : null,
                    filled: true,
                    fillColor: _inputFillColor,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: _borderColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: _borderColor),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Filter tabs: Tất cả, Đã duyệt, Chờ duyệt (Cuộn ngang tránh tràn màn hình)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: ['Tất cả', 'Đã duyệt', 'Chờ duyệt'].map((tab) {
                      final isSel = _newsFilter == tab;
                      final count = tab == 'Tất cả'
                          ? allArticles.length
                          : tab == 'Chờ duyệt'
                              ? _pendingArticleTitles.length
                              : allArticles.length -
                                  _pendingArticleTitles.length;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text('$tab ($count)'),
                          selected: isSel,
                          onSelected: (_) => _setNewsFilter(tab),
                          selectedColor:
                              const Color(0xFF1E60F2).withOpacity(0.12),
                          checkmarkColor: const Color(0xFF1E60F2),
                          labelStyle: TextStyle(
                            fontSize: 12.5,
                            fontWeight:
                                isSel ? FontWeight.w700 : FontWeight.w500,
                            color:
                                isSel ? const Color(0xFF1E60F2) : _subTextColor,
                          ),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20)),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // News list
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.article_outlined,
                            size: 54, color: Color(0xFFCBD5E1)),
                        const SizedBox(height: 12),
                        Text(
                          allArticles.isEmpty
                              ? 'Đang tải dữ liệu từ RSS...'
                              : 'Không tìm thấy bài viết nào phù hợp',
                          style: TextStyle(color: _subTextColor),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final article = filtered[index];
                      final isPending =
                          _pendingArticleTitles.contains(article.title);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _surfaceColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: _borderColor),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Thumbnail
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                width: 80,
                                height: 74,
                                color: _borderColor,
                                child: article.imageUrl != null
                                    ? CachedNetworkImage(
                                        imageUrl: article.imageUrl!,
                                        memCacheWidth: 240,
                                        fit: BoxFit.cover,
                                        placeholder: (_, __) => const Center(
                                          child: SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(strokeWidth: 2),
                                          ),
                                        ),
                                        errorWidget: (_, __, ___) =>
                                            const Icon(
                                          Icons.image_not_supported_outlined,
                                          color: Color(0xFF94A3B8),
                                          size: 28,
                                        ),
                                      )
                                    : const Icon(Icons.newspaper_rounded,
                                        color: Color(0xFF1E60F2), size: 30),
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Content
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
                                      color: _textColor,
                                      height: 1.3,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 7, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: _chipColor,
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          article.source,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF1E60F2),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        article.publishedAt != null
                                            ? '${article.publishedAt!.day}/${article.publishedAt!.month}'
                                            : 'Gần đây',
                                        style: const TextStyle(
                                            fontSize: 11,
                                            color: Color(0xFF94A3B8)),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),

                            // Actions
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                // Toggle status
                                InkWell(
                                  onTap: () {
                                    _toggleApproval(article.title);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(isPending
                                            ? 'Đã duyệt bài viết "${article.title}"'
                                            : 'Đã chuyển bài viết sang Chờ duyệt'),
                                        backgroundColor: isPending
                                            ? Colors.green
                                            : Colors.orange,
                                      ),
                                    );
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: !isPending
                                          ? const Color(0xFFECFDF5)
                                          : const Color(0xFFFFFBEB),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: !isPending
                                            ? const Color(0xFF10B981)
                                                .withOpacity(0.3)
                                            : const Color(0xFFF59E0B)
                                                .withOpacity(0.3),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          !isPending
                                              ? Icons.check_circle_rounded
                                              : Icons.hourglass_top_rounded,
                                          size: 13,
                                          color: !isPending
                                              ? const Color(0xFF059669)
                                              : const Color(0xFFD97706),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          !isPending ? 'Đã duyệt' : 'Chờ duyệt',
                                          style: TextStyle(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w800,
                                            color: !isPending
                                                ? const Color(0xFF059669)
                                                : const Color(0xFFD97706),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 14),

                                // Delete from real news provider
                                InkWell(
                                  onTap: () {
                                    showDialog(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(16)),
                                        title: const Text(
                                            'Xác nhận xóa bài viết',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold)),
                                        content: Text(
                                            'Xóa bài viết "${article.title}" khỏi hệ thống ứng dụng?'),
                                        actions: [
                                          TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(ctx),
                                              child: const Text('Hủy')),
                                          ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    const Color(0xFFEF4444)),
                                            onPressed: () async {
                                              Navigator.pop(ctx);
                                              await news.deleteArticlePermanently(article.title);
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                const SnackBar(
                                                    content: Text(
                                                        'Đã xóa bài viết khỏi ứng dụng'),
                                                    backgroundColor:
                                                        Colors.red),
                                              );
                                            },
                                            child: const Text('Xóa ngay',
                                                style: TextStyle(
                                                    color: Colors.white)),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                  borderRadius: BorderRadius.circular(6),
                                  child: const Padding(
                                    padding: EdgeInsets.all(4),
                                    child: Icon(Icons.delete_outline_rounded,
                                        color: Color(0xFFEF4444), size: 19),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF1654F0),
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Đăng tin mới',
            style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
        onPressed: () => _showAddArticleDialog(context),
      ),
    );
  }

  void _showAddArticleDialog(BuildContext context) {
    final titleCtrl = TextEditingController();
    final subtitleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final authorCtrl = TextEditingController(text: 'Ban Biên Tập');
    final tagsCtrl = TextEditingController();
    final inlineImagesCtrl = TextEditingController();
    final imageUrlCtrl = TextEditingController();
    final linkCtrl = TextEditingController();
    String selectedCatLabel = 'Thời sự';
    final catOptions = [
      'Thời sự',
      'Công nghệ',
      'Kinh tế',
      'Thể thao',
      'Thế giới',
      'Giải trí',
      'Sức khỏe'
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx2).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Header ──
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1654F0).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.post_add_rounded,
                              color: Color(0xFF1654F0), size: 20),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Đăng bài viết mới',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: _textColor),
                        ),
                      ],
                    ),
                    IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(ctx2)),
                  ],
                ),
                const SizedBox(height: 4),
                Text('Bài viết sẽ hiển thị ngay trên toàn bộ ứng dụng',
                    style: TextStyle(fontSize: 12, color: _subTextColor)),
                const Divider(height: 20),

                // ── Tiêu đề ──
                _buildDialogLabel('Tiêu đề bài viết', isRequired: true),
                const SizedBox(height: 6),
                TextField(
                  controller: titleCtrl,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600),
                  decoration: _dialogInputDeco(
                      'Nhập tiêu đề tin tức nổi bật...', Icons.title_rounded),
                ),
                const SizedBox(height: 12),

                // ── Phụ đề ──
                _buildDialogLabel('Phụ đề / Dòng mô tả ngắn'),
                const SizedBox(height: 6),
                TextField(
                  controller: subtitleCtrl,
                  decoration: _dialogInputDeco(
                      'Dòng mô tả phụ bên dưới tiêu đề...',
                      Icons.short_text_rounded),
                ),
                const SizedBox(height: 12),

                // ── Danh mục ──
                _buildDialogLabel('Danh mục / Chuyên mục'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: catOptions.map((cat) {
                    final isSel = selectedCatLabel == cat;
                    return GestureDetector(
                      onTap: () => setModalState(() => selectedCatLabel = cat),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSel ? const Color(0xFF1654F0) : _chipColor,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: isSel
                                  ? const Color(0xFF1654F0)
                                  : _borderColor),
                        ),
                        child: Text(
                          cat,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: isSel ? Colors.white : _subTextColor,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),

                _buildDialogLabel('Tags / Từ khóa'),
                const SizedBox(height: 6),
                TextField(
                  controller: tagsCtrl,
                  decoration: _dialogInputDeco(
                    'Ví dụ: công nghệ, AI, Việt Nam (cách nhau bằng dấu phẩy)',
                    Icons.sell_outlined,
                  ),
                ),
                const SizedBox(height: 12),

                // ── URL Ảnh đại diện ──
                _buildDialogLabel('URL Ảnh đại diện (thumbnail)'),
                const SizedBox(height: 6),
                TextField(
                  controller: imageUrlCtrl,
                  keyboardType: TextInputType.url,
                  decoration: _dialogInputDeco(
                      'https://example.com/image.jpg', Icons.image_rounded),
                ),
                // Preview ảnh
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: imageUrlCtrl,
                  builder: (_, val, __) {
                    final url = val.text.trim();
                    if (url.isEmpty || !url.startsWith('http'))
                      return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: CachedNetworkImage(
                          imageUrl: url,
                          height: 140,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          memCacheWidth: 600,
                          errorWidget: (_, __, ___) => Container(
                            height: 60,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF2F2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.broken_image_outlined,
                                    color: Color(0xFFEF4444), size: 18),
                                SizedBox(width: 6),
                                Text('URL ảnh không hợp lệ hoặc không tải được',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFFEF4444))),
                              ],
                            ),
                          ),
                          placeholder: (_, __) => Container(
                            height: 140,
                            color: _chipColor,
                            child: const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),

                _buildDialogLabel('Ảnh trong nội dung'),
                const SizedBox(height: 6),
                TextField(
                  controller: inlineImagesCtrl,
                  keyboardType: TextInputType.multiline,
                  maxLines: 2,
                  decoration: _dialogInputDeco(
                    'Dán nhiều URL ảnh, cách nhau bằng dấu phẩy',
                    Icons.collections_outlined,
                  ),
                ),
                const SizedBox(height: 12),

                // ── Nội dung tóm tắt ──
                _buildDialogLabel('Nội dung tóm tắt', isRequired: true),
                const SizedBox(height: 6),
                TextField(
                  controller: descCtrl,
                  maxLines: 3,
                  decoration: _dialogInputDeco(
                      'Mô tả chi tiết nội dung tin tức...',
                      Icons.notes_rounded),
                ),
                const SizedBox(height: 12),

                // ── Nguồn / Tác giả ──
                _buildDialogLabel('Nguồn / Tác giả'),
                const SizedBox(height: 6),
                TextField(
                  controller: authorCtrl,
                  decoration: _dialogInputDeco(
                      'Ban Biên Tập, Tin Tức 24h...', Icons.person_rounded),
                ),
                const SizedBox(height: 12),

                // ── Link bài gốc ──
                _buildDialogLabel('Link bài viết gốc (tuỳ chọn)'),
                const SizedBox(height: 6),
                TextField(
                  controller: linkCtrl,
                  keyboardType: TextInputType.url,
                  decoration: _dialogInputDeco(
                      'https://vnexpress.net/...', Icons.link_rounded),
                ),
                const SizedBox(height: 20),

                // ── Nút đăng ──
                ElevatedButton.icon(
                  onPressed: () async {
                    if (titleCtrl.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Vui lòng nhập tiêu đề bài viết'),
                            backgroundColor: Colors.red),
                      );
                      return;
                    }

                    final newTitle = titleCtrl.text.trim();
                    final newDesc = [
                      if (subtitleCtrl.text.trim().isNotEmpty)
                        subtitleCtrl.text.trim(),
                      if (descCtrl.text.trim().isNotEmpty) descCtrl.text.trim(),
                    ].join('\n\n').isNotEmpty
                        ? [
                            if (subtitleCtrl.text.trim().isNotEmpty)
                              subtitleCtrl.text.trim(),
                            if (descCtrl.text.trim().isNotEmpty)
                              descCtrl.text.trim(),
                          ].join('\n\n')
                        : newTitle;
                    final newAuthor = authorCtrl.text.trim().isEmpty
                        ? 'Admin / $selectedCatLabel'
                        : authorCtrl.text.trim();
                    final tags = tagsCtrl.text
                        .split(',')
                        .map((tag) => tag.trim())
                        .where((tag) => tag.isNotEmpty)
                        .toSet()
                        .toList();
                    final inlineImageUrls = inlineImagesCtrl.text
                        .split(',')
                        .map((url) => url.trim())
                        .where((url) => url.startsWith('http'))
                        .toSet()
                        .toList();
                    final imgUrl = imageUrlCtrl.text.trim().isNotEmpty
                        ? imageUrlCtrl.text.trim()
                        : null;
                    final link = linkCtrl.text.trim().isNotEmpty
                        ? linkCtrl.text.trim()
                        : 'https://news.google.com';

                    try {
                      await context.read<NewsProvider>().addArticle(
                            Article(
                              title: newTitle,
                              link: link,
                              description: newDesc,
                              imageUrl: imgUrl,
                              source: newAuthor,
                              publishedAt: DateTime.now(),
                              category: selectedCatLabel,
                              tags: tags,
                              inlineImageUrls: inlineImageUrls,
                            ),
                          );
                    } catch (error) {
                      if (!ctx2.mounted) return;
                      ScaffoldMessenger.of(ctx2).showSnackBar(
                        SnackBar(
                          content: Text('Không thể lưu bài viết: $error'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    Navigator.pop(ctx2);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            const Icon(Icons.check_circle_rounded,
                                color: Colors.white, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                                child: Text(
                                    'Đã đăng bài "$newTitle" thành công!')),
                          ],
                        ),
                        backgroundColor: Colors.green,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1654F0),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  icon: const Icon(Icons.send_rounded,
                      color: Colors.white, size: 18),
                  label: const Text('Đăng bài viết ngay',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                ),
                const SizedBox(height: 4),
              ],
            ),
          ),
        ),
      ),
    ).whenComplete(() {
      titleCtrl.dispose();
      subtitleCtrl.dispose();
      descCtrl.dispose();
      authorCtrl.dispose();
      tagsCtrl.dispose();
      inlineImagesCtrl.dispose();
      imageUrlCtrl.dispose();
      linkCtrl.dispose();
    });
  }

  // Helper: label cho form
  Widget _buildDialogLabel(String text, {bool isRequired = false}) {
    return Row(
      children: [
        Text(text,
            style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.bold, color: _textColor)),
        if (isRequired) ...[
          const SizedBox(width: 4),
          const Text('*',
              style: TextStyle(
                  color: Color(0xFFEF4444), fontWeight: FontWeight.bold)),
        ],
      ],
    );
  }

  // Helper: decoration cho TextFiend trong form
  InputDecoration _dialogInputDeco(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 13, color: Color(0xFFCBD5E1)),
      prefixIcon: Icon(icon, size: 18, color: const Color(0xFF94A3B8)),
      filled: true,
      fillColor: _inputFillColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: _borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: _borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF1654F0), width: 1.5),
      ),
    );
  }

  void _showAddCategoryDialog(BuildContext context, NewsProvider news) {
    final labelCtrl = TextEditingController();
    final sourceCtrl = TextEditingController(text: 'VnExpress');
    final urlCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.add_circle_outline_rounded, color: Color(0xFF1E60F2)),
            SizedBox(width: 8),
            Text('Thêm nguồn tin mới',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Tên chuyên mục (Ví dụ: Đời sống, Xe, Pháp luật):',
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              TextField(
                controller: labelCtrl,
                decoration: InputDecoration(
                  hintText: 'Nhập tên chuyên mục...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
              const SizedBox(height: 12),
              const Text('Nguồn báo (Ví dụ: VnExpress, Tuổi Trẻ, Dân Trí):',
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              TextField(
                controller: sourceCtrl,
                decoration: InputDecoration(
                  hintText: 'Tên tòa soạn / trang báo...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
              const SizedBox(height: 12),
              const Text('Đường dẫn RSS URL (Bắt đầu bằng https://):',
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              TextField(
                controller: urlCtrl,
                keyboardType: TextInputType.url,
                decoration: InputDecoration(
                  hintText: 'https://...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E60F2),
              foregroundColor: Colors.white,
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              final label = labelCtrl.text.trim();
              final source = sourceCtrl.text.trim();
              final url = urlCtrl.text.trim();

              if (label.isEmpty || url.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Vui lòng điền đầy đủ tên và đường dẫn RSS URL.')),
                );
                return;
              }

              if (!url.startsWith('https://')) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text(
                          'Đường dẫn RSS phải bắt đầu bằng https:// để đảm bảo bảo mật.')),
                );
                return;
              }

              Navigator.pop(ctx);
              final success = await news.addCategory(
                label: label,
                rssUrl: url,
                source: source.isEmpty ? 'Báo điện tử' : source,
              );

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success
                        ? 'Đã thêm nguồn tin "$label" thành công!'
                        : 'Không thể thêm nguồn tin. Vui lòng kiểm tra lại URL.'),
                    backgroundColor:
                        success ? const Color(0xFF10B981) : Colors.red,
                  ),
                );
              }
            },
            child: const Text('Thêm nguồn'),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════
  // 3. TAB: QUẢN LÝ DANH MỤC THỰC TẾ (Lấy từ NewsService.categories)
  // ══════════════════════════════════════════════════════════════════
  Widget _buildCategoryManagementTab(NewsProvider news) {
    final categories = news.categories;
    final selectedCat = news.selectedCategory;
    final selectedCatIds = news.selectedCategoryIds;
    final isLoading = news.status == NewsStatus.loading;

    // Map icon cho từng danh mục
    IconData catIcon(String id) {
      switch (id) {
        case 'moi-nhat':
          return Icons.fiber_new_rounded;
        case 'thoi-su':
          return Icons.public_rounded;
        case 'the-gioi':
          return Icons.language_rounded;
        case 'kinh-doanh':
          return Icons.trending_up_rounded;
        case 'cong-nghe':
          return Icons.laptop_mac_rounded;
        case 'the-thao':
          return Icons.sports_soccer_rounded;
        case 'giai-tri':
          return Icons.movie_filter_rounded;
        case 'suc-khoe':
          return Icons.favorite_rounded;
        case 'tuoi-tre':
          return Icons.newspaper_rounded;
        case 'thanh-nien':
          return Icons.article_rounded;
        default:
          return Icons.category_rounded;
      }
    }

    Color catColor(String id) {
      switch (id) {
        case 'moi-nhat':
          return const Color(0xFFEF4444);
        case 'thoi-su':
          return const Color(0xFF3B82F6);
        case 'the-gioi':
          return const Color(0xFF8B5CF6);
        case 'kinh-doanh':
          return const Color(0xFFF59E0B);
        case 'cong-nghe':
          return const Color(0xFF06B6D4);
        case 'the-thao':
          return const Color(0xFF10B981);
        case 'giai-tri':
          return const Color(0xFFEC4899);
        case 'suc-khoe':
          return const Color(0xFFEF4444);
        case 'tuoi-tre':
          return const Color(0xFFEA580C);
        case 'thanh-nien':
          return _subTextColor;
        default:
          return const Color(0xFF1E60F2);
      }
    }

    return Scaffold(
      backgroundColor: _bgColor,
      body: categories.isEmpty && !isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.category_outlined,
                      size: 60, color: Color(0xFFCBD5E1)),
                  const SizedBox(height: 14),
                  Text('Chưa tải được danh mục',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: _subTextColor)),
                  const SizedBox(height: 8),
                  const Text('Kiểm tra kết nối internet',
                      style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8))),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () => news.fetchNews(),
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Thử lại'),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1654F0),
                        foregroundColor: Colors.white),
                  ),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // ── Header ──
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Kết nối & Đồng bộ nguồn tin (${selectedCatIds.length}/${categories.length})',
                            style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: _textColor),
                          ),
                          Text(
                            'Bạn có thể tích chọn nhiều danh mục để gom tin tức từ nhiều nguồn cùng lúc',
                            style:
                                TextStyle(fontSize: 12, color: _subTextColor),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (isLoading)
                      const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.5, color: Color(0xFF1654F0)),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(10)),
                        child: const Text('Nguồn: RSS Realtime',
                            style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E60F2))),
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                // ── Thanh tác vụ quản lý nguồn tin & chọn đa nguồn ──
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E60F2),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        icon: const Icon(Icons.add_circle_outline_rounded, size: 17),
                        label: const Text(
                          'Thêm nguồn mới',
                          style: TextStyle(
                              fontSize: 12.5, fontWeight: FontWeight.bold),
                        ),
                        onPressed: () => _showAddCategoryDialog(context, news),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          side: BorderSide(color: _borderColor),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.restore_rounded, size: 16),
                        label: const Text(
                          'Mặc định',
                          style: TextStyle(fontSize: 12),
                        ),
                        onPressed: () async {
                          await news.restoreDefaultCategories();
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Đã khôi phục danh sách nguồn tin mặc định'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          side: BorderSide(
                              color: selectedCatIds.length == categories.length
                                  ? const Color(0xFF1654F0)
                                  : _borderColor),
                          backgroundColor:
                              selectedCatIds.length == categories.length
                                  ? const Color(0xFF1654F0).withOpacity(0.08)
                                  : _surfaceColor,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: Icon(
                          selectedCatIds.length == categories.length
                              ? Icons.check_circle_rounded
                              : Icons.select_all_rounded,
                          size: 17,
                          color: const Color(0xFF1654F0),
                        ),
                        label: Text(
                          selectedCatIds.length == categories.length
                              ? 'Đang gom tất cả nguồn'
                              : 'Chọn tất cả (${categories.length})',
                          style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1654F0)),
                        ),
                        onPressed: () async {
                          if (selectedCatIds.length == categories.length) {
                            await news.selectCategory(categories.first);
                          } else {
                            await news.selectAllCategories();
                          }
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                selectedCatIds.length == categories.length
                                    ? 'Đã chọn đồng bộ tất cả chuyên mục!'
                                    : 'Đã đưa về chuyên mục Mới nhất',
                              ),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // ── Danh sách danh mục với Checkbox Đa Lựa Chọn ──
                ...categories.map((cat) {
                  final isChecked = selectedCatIds.contains(cat.id);
                  final isPrimary = selectedCat.id == cat.id;
                  final color = catColor(cat.id);

                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color:
                          isChecked ? color.withOpacity(0.06) : _surfaceColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isChecked ? color : _borderColor,
                        width: isChecked ? 1.8 : 1.0,
                      ),
                      boxShadow: isChecked
                          ? [
                              BoxShadow(
                                  color: color.withOpacity(0.12),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4))
                            ]
                          : [
                              const BoxShadow(
                                  color: Color(0x08000000),
                                  blurRadius: 4,
                                  offset: Offset(0, 2))
                            ],
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () async {
                        // Tích chọn hoặc bỏ chọn đa chuyên mục
                        await news.toggleCategory(cat);
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                Icon(
                                  news.selectedCategoryIds.contains(cat.id)
                                      ? Icons.check_circle_rounded
                                      : Icons.remove_circle_outline_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    news.selectedCategoryIds.contains(cat.id)
                                        ? 'Đã bật kết nối "${cat.label}"'
                                        : 'Đã tắt kết nối "${cat.label}"',
                                  ),
                                ),
                              ],
                            ),
                            backgroundColor: color,
                            duration: const Duration(seconds: 1),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            // Icon danh mục
                            Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                color:
                                    isChecked ? color : color.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(catIcon(cat.id),
                                  color: isChecked ? Colors.white : color,
                                  size: 22),
                            ),
                            const SizedBox(width: 12),

                            // Thông tin danh mục
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        cat.label,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 15,
                                          color: isChecked ? color : _textColor,
                                        ),
                                      ),
                                      if (isChecked) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 7, vertical: 2),
                                          decoration: BoxDecoration(
                                              color: color,
                                              borderRadius:
                                                  BorderRadius.circular(6)),
                                          child: Text(
                                              isPrimary
                                                  ? 'CHÍNH'
                                                  : 'ĐÃ KẾT NỐI',
                                              style: const TextStyle(
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white)),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    cat.source,
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: isChecked
                                            ? color.withOpacity(0.8)
                                            : _subTextColor,
                                        fontWeight: FontWeight.w500),
                                  ),
                                  Text(
                                    cat.rssUrl,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        fontSize: 11, color: Color(0xFF94A3B8)),
                                  ),
                                ],
                              ),
                            ),

                            // Nút xóa nguồn tin
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded,
                                  color: Color(0xFFEF4444), size: 20),
                              tooltip: 'Xóa nguồn này',
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16)),
                                    title: const Text('Xác nhận xóa nguồn tin',
                                        style: TextStyle(fontWeight: FontWeight.bold)),
                                    content: Text(
                                        'Bạn có chắc muốn xóa nguồn tin "${cat.label}" (${cat.source}) khỏi hệ thống không?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(ctx),
                                        child: const Text('Hủy'),
                                      ),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFFEF4444)),
                                        onPressed: () async {
                                          Navigator.pop(ctx);
                                          await news.deleteCategory(cat.id);
                                          if (!mounted) return;
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('Đã xóa nguồn tin "${cat.label}"'),
                                              backgroundColor: Colors.red,
                                              behavior: SnackBarBehavior.floating,
                                            ),
                                          );
                                        },
                                        child: const Text('Xóa nguồn',
                                            style: TextStyle(color: Colors.white)),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),

                            // Checkbox trực quan
                            const SizedBox(width: 4),
                            Transform.scale(
                              scale: 1.1,
                              child: Checkbox(
                                value: isChecked,
                                activeColor: color,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                onChanged: (val) async {
                                  await news.toggleCategory(cat);
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),

                const SizedBox(height: 8),
              ],
            ),
    );
  }

  // ══════════════════════════════════════════════════════════════════
  // 4. TAB: TÀI KHOẢN NGƯỜI DÙNG THỰC TẾ (Lấy từ AuthProvider)
  // ══════════════════════════════════════════════════════════════════
  Widget _buildUserManagementTab(AuthProvider auth) {
    final user = auth.user;
    final isLoggedIn = auth.isAuthenticated;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _surfaceColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tài khoản đang đăng nhập trong phiên',
                style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.bold,
                    color: _textColor),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: isLoggedIn
                        ? const Color(0xFF1E60F2)
                        : const Color(0xFF94A3B8),
                    child: Text(
                      isLoggedIn && auth.displayName.isNotEmpty
                          ? auth.displayName[0].toUpperCase()
                          : 'K',
                      style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isLoggedIn ? auth.displayName : 'Khách vãng lai',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: _textColor),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isLoggedIn ? auth.email : 'Chưa đăng nhập tài khoản',
                          style: TextStyle(fontSize: 13, color: _subTextColor),
                        ),
                        if (user != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            'UID: ${user.uid}',
                            style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF94A3B8),
                                fontFamily: 'monospace'),
                          ),
                        ] else if (isLoggedIn) ...[
                          const SizedBox(height: 4),
                          Text(
                            'UID: ${auth.uid}',
                            style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF94A3B8),
                                fontFamily: 'monospace'),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isLoggedIn ? const Color(0xFFECFDF5) : _chipColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      isLoggedIn ? 'Quản trị viên' : 'Khách',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isLoggedIn
                            ? const Color(0xFF059669)
                            : _subTextColor,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Danh sách tài khoản đã đăng ký (Tích hợp hợp nhất Email & Google)
        FutureBuilder<List<Map<String, dynamic>>>(
          future: auth.getRegisteredUsersList(),
          builder: (context, snapshot) {
            final users = snapshot.data ?? [];
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _surfaceColor,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: _borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.people_alt_rounded,
                              color: Color(0xFF1E60F2), size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Danh sách tài khoản hệ thống',
                            style: TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.bold,
                              color: _textColor,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E60F2).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${users.length} tài khoản',
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E60F2),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (users.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: Center(
                        child: Text(
                          'Chưa có dữ liệu người dùng đăng ký',
                          style: TextStyle(color: _subTextColor, fontSize: 13),
                        ),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: users.length,
                      separatorBuilder: (_, __) =>
                          Divider(color: _borderColor.withOpacity(0.5)),
                      itemBuilder: (context, index) {
                        final u = users[index];
                        final uEmail = u['email'] as String? ?? '';
                        final uName = u['name'] as String? ?? 'Người dùng';
                        final hasPassword =
                            u['password'] != null || u['hasPassword'] == true;
                        final isGoogleLinked =
                            u['isGoogleLinked'] == true || u['googleId'] != null;
                        final isUserAdmin =
                            u['isAdmin'] == true || uEmail.contains('admin');

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: isUserAdmin
                                    ? const Color(0xFF059669).withOpacity(0.15)
                                    : const Color(0xFF1E60F2).withOpacity(0.15),
                                child: Text(
                                  uName.isNotEmpty
                                      ? uName[0].toUpperCase()
                                      : 'U',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: isUserAdmin
                                        ? const Color(0xFF059669)
                                        : const Color(0xFF1E60F2),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      uName,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: _textColor,
                                      ),
                                    ),
                                    Text(
                                      uEmail,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: _subTextColor,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        if (hasPassword)
                                          Container(
                                            margin: const EdgeInsets.only(right: 4),
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 6, vertical: 1.5),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF2563EB)
                                                  .withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: const Text(
                                              '📧 Email/Mật khẩu',
                                              style: TextStyle(
                                                fontSize: 9.5,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF2563EB),
                                              ),
                                            ),
                                          ),
                                        if (isGoogleLinked)
                                          Container(
                                            margin: const EdgeInsets.only(right: 4),
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 6, vertical: 1.5),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFEA4335)
                                                  .withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: const Text(
                                              '🌐 Google Liên kết',
                                              style: TextStyle(
                                                fontSize: 9.5,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFFEA4335),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: isUserAdmin
                                      ? const Color(0xFFECFDF5)
                                      : _chipColor,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  isUserAdmin ? 'Admin' : 'User',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: isUserAdmin
                                        ? const Color(0xFF059669)
                                        : _subTextColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 16),

        // Hướng dẫn quản trị người dùng qua Firebase Authentication
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _inputFillColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.info_outline_rounded,
                      color: Color(0xFF1E60F2), size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Quản lý người dùng Firebase Auth',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: _textColor),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Text(
                'Hệ thống đang tích hợp xác thực trực tiếp qua Firebase Authentication. Toàn bộ người dùng đăng ký qua Email hoặc Google Sign-In được lưu trữ an toàn trên Google Cloud Console.',
                style: TextStyle(
                    fontSize: 12.5, color: _subTextColor, height: 1.4),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════
  // 5. TAB: PHÁT SÓNG THÔNG BÁO (Lưu vào danh sách thực tế của phiên)
  // ══════════════════════════════════════════════════════════════════
  Widget _buildPushNotificationTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _surfaceColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.campaign_rounded,
                      color: Color(0xFF1654F0), size: 26),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Phát sóng thông báo ứng dụng',
                      style: TextStyle(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w800,
                          color: _textColor),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Gửi thông báo đẩy đến phiên người dùng hiện tại',
                style: TextStyle(fontSize: 12.5, color: _subTextColor),
              ),
              const SizedBox(height: 18),

              const Text('Chủ đề thông báo *',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: ['Tin nóng', 'Thời tiết', 'Hệ thống', 'Khuyến mãi']
                    .map((type) {
                  final isSel = _selectedNotifType == type;
                  return ChoiceChip(
                    label: Text(type),
                    selected: isSel,
                    selectedColor: const Color(0xFF1654F0),
                    labelStyle: TextStyle(
                      color: isSel ? Colors.white : _subTextColor,
                      fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 12.5,
                    ),
                    onSelected: (_) => _setSelectedNotifType(type),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),

              const Text('Tiêu đề *',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              TextField(
                controller: _notifTitleController,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Ví dụ: Cập nhật tin bão mới nhất hôm nay...',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
              const SizedBox(height: 14),

              const Text('Nội dung chi tiết *',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              TextField(
                controller: _notifBodyController,
                maxLines: 3,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Nội dung thông báo gửi đến người dùng...',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
              const SizedBox(height: 18),

              // Xem trước Live Preview
              Text(
                'Xem trước thông báo (Live Preview):',
                style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: _subTextColor),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _inputFillColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFCBD5E1)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset(
                        'assets/images/app_icon.jpg',
                        width: 38,
                        height: 38,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 38,
                          height: 38,
                          color: const Color(0xFF1E60F2),
                          child: const Icon(Icons.public,
                              color: Colors.white, size: 22),
                        ),
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
                              Text(
                                'DAILY NEWS • $_selectedNotifType',
                                style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF1E60F2)),
                              ),
                              const Text('Vừa xong',
                                  style: TextStyle(
                                      fontSize: 10, color: Colors.grey)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _notifTitleController.text.trim().isNotEmpty
                                ? _notifTitleController.text.trim()
                                : 'Tiêu đề thông báo...',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: _textColor),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _notifBodyController.text.trim().isNotEmpty
                                ? _notifBodyController.text.trim()
                                : 'Nội dung thông báo...',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style:
                                TextStyle(fontSize: 12, color: _subTextColor),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () {
                    if (_notifTitleController.text.trim().isEmpty ||
                        _notifBodyController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text(
                                'Vui lòng nhập đầy đủ tiêu đề và nội dung thông báo!'),
                            backgroundColor: Colors.red),
                      );
                      return;
                    }

                    _broadcastNotification(
                      _notifTitleController.text.trim(),
                      _notifBodyController.text.trim(),
                      _selectedNotifType,
                    );
                    _notifTitleController.clear();
                    _notifBodyController.clear();

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Đã phát sóng thông báo thành công!'),
                          backgroundColor: Colors.green),
                    );
                  },
                  icon: const Icon(Icons.send_rounded,
                      color: Colors.white, size: 19),
                  label: const Text('Phát sóng thông báo ngay',
                      style: TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w800,
                          color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1654F0),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        if (_broadcastNotifications.isNotEmpty) ...[
          Text('Thông báo đã phát sóng trong phiên:',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: _textColor)),
          const SizedBox(height: 10),
          ..._broadcastNotifications.map((n) {
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _surfaceColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _borderColor),
              ),
              child: Row(
                children: [
                  const Icon(Icons.mark_email_read_rounded,
                      color: Color(0xFF10B981), size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(n['title'] as String,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 13)),
                        Text(n['body'] as String,
                            style:
                                TextStyle(fontSize: 12, color: _subTextColor)),
                      ],
                    ),
                  ),
                  Text(n['sentTime'] as String,
                      style: const TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ),
            );
          }).toList(),
        ],
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════
  // 6. TAB: THỐNG KÊ & BÁO CÁO THỰC TẾ (Tính toán trực tiếp từ dữ liệu)
  // ══════════════════════════════════════════════════════════════════
  Widget _buildReportStatisticsTab(NewsProvider news, FavoritesProvider fav) {
    final articles = news.allArticles;
    final total = articles.length;

    // Đếm số bài thực tế theo nguồn báo
    final vnExpressCount = articles
        .where((a) => a.source.toLowerCase().contains('vnexpress'))
        .length;
    final tuoiTreCount = articles
        .where((a) =>
            a.source.toLowerCase().contains('tuổi trẻ') ||
            a.source.toLowerCase().contains('tuoitre'))
        .length;
    final thanhNienCount = articles
        .where((a) =>
            a.source.toLowerCase().contains('thanh niên') ||
            a.source.toLowerCase().contains('thanhnien'))
        .length;
    final adminCount = total - vnExpressCount - tuoiTreCount - thanhNienCount;

    // Tính tỷ lệ % bài có hình ảnh
    final hasImageCount = articles
        .where((a) => a.imageUrl != null && a.imageUrl!.isNotEmpty)
        .length;
    final imageRatio = total > 0 ? (hasImageCount / total) : 0.0;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Card thống kê nguồn báo thực tế
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: _surfaceColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Phân bổ nguồn báo thực tế',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _textColor),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('Tổng $total bài',
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E60F2))),
                ],
              ),
              const SizedBox(height: 16),
              if (total > 0) ...[
                _buildRealProgressRow('VnExpress RSS', vnExpressCount, total,
                    const Color(0xFF991B1B)),
                const SizedBox(height: 12),
                _buildRealProgressRow('Tuổi Trẻ Online', tuoiTreCount, total,
                    const Color(0xFF0284C7)),
                const SizedBox(height: 12),
                _buildRealProgressRow('Báo Thanh Niên', thanhNienCount, total,
                    const Color(0xFF16A34A)),
                if (adminCount > 0) ...[
                  const SizedBox(height: 12),
                  _buildRealProgressRow('Biên tập Admin', adminCount, total,
                      const Color(0xFF8B5CF6)),
                ],
              ] else
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Text('Chưa có bài viết nào được nạp'),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Card chất lượng nội dung
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: _surfaceColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Chỉ số nội dung & Tương tác thực tế',
                style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.bold,
                    color: _textColor),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _buildRealStatBox(
                      title: 'Bài có hình ảnh',
                      value: '$hasImageCount / $total',
                      percent: '${(imageRatio * 100).toStringAsFixed(1)}%',
                      icon: Icons.image_rounded,
                      color: const Color(0xFF2563EB),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildRealStatBox(
                      title: 'Đã lưu yêu thích',
                      value: '${fav.favorites.length} bài',
                      percent: total > 0
                          ? '${((fav.favorites.length / total) * 100).toStringAsFixed(1)}%'
                          : '0%',
                      icon: Icons.favorite_rounded,
                      color: const Color(0xFFEF4444),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRealProgressRow(String name, int count, int total, Color color) {
    final ratio = total > 0 ? (count / total) : 0.0;
    final percent = (ratio * 100).toStringAsFixed(1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('$name ($count bài)',
                style:
                    const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
            Text('$percent%',
                style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w800, color: color)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 8,
            backgroundColor: _bgColor,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  Widget _buildRealStatBox({
    required String title,
    required String value,
    required String percent,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _inputFillColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _subTextColor)),
              ),
              const SizedBox(width: 4),
              Icon(icon, color: color, size: 20),
            ],
          ),
          const SizedBox(height: 8),
          Text(value,
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: _textColor)),
          const SizedBox(height: 2),
          Text('Tỷ lệ: $percent',
              style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subText,
    required IconData icon,
    required Color color,
    required List<Color> bgGradient,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: bgGradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: color)),
              ),
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.all(5),
                decoration: const BoxDecoration(
                    color: Colors.white, shape: BoxShape.circle),
                child: Icon(icon, color: color, size: 16),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(value,
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: color,
                  letterSpacing: -0.5)),
          const SizedBox(height: 4),
          Text(subText,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color.withOpacity(0.85))),
        ],
      ),
    );
  }

  Widget _buildQuickActionBtn({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 17, color: color),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    fontSize: 12.5, fontWeight: FontWeight.w700, color: color)),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// CUSTOM PAINTER: VẼ BIỂU ĐỒ TỪ SỐ LƯỢNG BÀI VIẾT THỰC TẾ
// ══════════════════════════════════════════════════════════════════
class _RealNewsDistributionChartPainter extends CustomPainter {
  final List<Article> articles;

  _RealNewsDistributionChartPainter({required this.articles});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Đếm số lượng bài viết thật theo 7 ngày trong tuần (1: T2 -> 7: CN)
    final dayCounts = List<int>.filled(7, 0);

    for (final a in articles) {
      if (a.publishedAt != null) {
        final weekday = a.publishedAt!.weekday; // 1 = Mon, 7 = Sun
        if (weekday >= 1 && weekday <= 7) {
          dayCounts[weekday - 1]++;
        }
      }
    }

    final maxVal = dayCounts.reduce((curr, next) => curr > next ? curr : next);
    final divisor = maxVal > 0 ? maxVal.toDouble() : 1.0;

    final dx = w / 6;
    final coords = <Offset>[];

    for (int i = 0; i < 7; i++) {
      final x = i * dx;
      final normalized = maxVal > 0 ? (dayCounts[i] / divisor) : 0.2;
      final y = h - (normalized * (h - 30) + 15);
      coords.add(Offset(x, y));
    }

    // Vẽ lưới ngang
    final gridPaint = Paint()
      ..color = const Color(0xFFF1F5F9)
      ..strokeWidth = 1.0;
    for (int i = 1; i <= 3; i++) {
      final y = h * i / 4;
      canvas.drawLine(Offset(0, y), Offset(w, y), gridPaint);
    }

    // Vẽ đường cong spline
    final path = Path();
    final fillPath = Path();

    path.moveTo(coords[0].dx, coords[0].dy);
    fillPath.moveTo(coords[0].dx, h);
    fillPath.lineTo(coords[0].dx, coords[0].dy);

    for (int i = 0; i < coords.length - 1; i++) {
      final p0 = coords[i];
      final p1 = coords[i + 1];
      final ctrl1 = Offset(p0.dx + (p1.dx - p0.dx) / 2, p0.dy);
      final ctrl2 = Offset(p0.dx + (p1.dx - p0.dx) / 2, p1.dy);
      path.cubicTo(ctrl1.dx, ctrl1.dy, ctrl2.dx, ctrl2.dy, p1.dx, p1.dy);
      fillPath.cubicTo(ctrl1.dx, ctrl1.dy, ctrl2.dx, ctrl2.dy, p1.dx, p1.dy);
    }

    fillPath.lineTo(coords.last.dx, h);
    fillPath.close();

    // Fill gradient
    final fillPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          const Color(0xFF1E60F2).withOpacity(0.25),
          const Color(0xFF1E60F2).withOpacity(0.01),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    canvas.drawPath(fillPath, fillPaint);

    // Line stroke
    final linePaint = Paint()
      ..color = const Color(0xFF1654F0)
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, linePaint);

    // Dots & số lượng thật
    final dotPaint = Paint()..color = const Color(0xFF1654F0);
    final dotInner = Paint()..color = Colors.white;

    for (int i = 0; i < coords.length; i++) {
      final pt = coords[i];
      canvas.drawCircle(pt, 5, dotPaint);
      canvas.drawCircle(pt, 2.5, dotInner);
    }
  }

  @override
  bool shouldRepaint(covariant _RealNewsDistributionChartPainter oldDelegate) {
    return oldDelegate.articles != articles;
  }
}
