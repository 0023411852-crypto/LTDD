import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../favorites/providers/favorites_provider.dart';
import '../../news/providers/news_provider.dart';
import '../../notifications/providers/notifications_provider.dart';
import '../../settings/providers/settings_provider.dart';
import '../../weather/providers/weather_provider.dart';
import '../categories/controllers/admin_categories_controller.dart';
import '../categories/presentation/admin_categories_tab.dart';
import '../dashboard/controllers/admin_dashboard_controller.dart';
import '../dashboard/presentation/admin_dashboard_tab.dart';
import '../news/controllers/admin_news_controller.dart';
import '../news/presentation/admin_news_tab.dart';
import '../notifications/controllers/admin_notifications_controller.dart';
import '../notifications/presentation/admin_notifications_tab.dart';
import '../providers/admin_provider.dart';
import '../statistics/controllers/admin_statistics_controller.dart';
import '../statistics/presentation/admin_statistics_tab.dart';
import '../users/controllers/admin_users_controller.dart';
import '../users/presentation/admin_users_tab.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  late final AdminStatisticsController _statsController;
  final GlobalKey _newsTabKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _statsController = AdminStatisticsController();
  }

  @override
  void dispose() {
    _statsController.dispose();
    super.dispose();
  }

  int get _currentTab => context.read<AdminProvider>().currentTab;
  void _setTab(int tab) => context.read<AdminProvider>().setTab(tab);

  // Theme getters
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
    final authProvider = context.watch<AuthProvider>();
    final newsProvider = context.watch<NewsProvider>();
    final favProvider = context.watch<FavoritesProvider>();
    final weatherProvider = context.watch<WeatherProvider>();
    final notifProvider = context.watch<NotificationsProvider>();
    final adminProvider = context.watch<AdminProvider>();
    final settingsProvider = context.watch<SettingsProvider>();

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

    // Khởi tạo các controllers cho từng sub-module
    final dashboardController = AdminDashboardController(
      newsProvider: newsProvider,
      authProvider: authProvider,
      favoritesProvider: favProvider,
      weatherProvider: weatherProvider,
    );

    final newsController = AdminNewsController(
      newsProvider: newsProvider,
      adminProvider: adminProvider,
    );

    final categoriesController = AdminCategoriesController(
      newsProvider: newsProvider,
    );

    final usersController = AdminUsersController(
      authProvider: authProvider,
    );

    final notificationsController = AdminNotificationsController(
      adminProvider: adminProvider,
      notificationsProvider: notifProvider,
      settingsProvider: settingsProvider,
    );

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
                  backgroundColor: Colors.green,
                ),
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
                    AdminDashboardTab(
                      controller: dashboardController,
                      onNavigateTab: (idx) => _setTab(idx),
                      onOpenAddArticleDialog: () {
                        _setTab(1);
                      },
                      surfaceColor: _surfaceColor,
                      textColor: _textColor,
                      subTextColor: _subTextColor,
                      borderColor: _borderColor,
                    ),
                    AdminNewsTab(
                      key: _newsTabKey,
                      controller: newsController,
                      surfaceColor: _surfaceColor,
                      textColor: _textColor,
                      subTextColor: _subTextColor,
                      borderColor: _borderColor,
                      chipColor: _chipColor,
                      inputFillColor: _inputFillColor,
                    ),
                    AdminCategoriesTab(
                      controller: categoriesController,
                      bgColor: _bgColor,
                      surfaceColor: _surfaceColor,
                      textColor: _textColor,
                      subTextColor: _subTextColor,
                      borderColor: _borderColor,
                    ),
                    AdminUsersTab(
                      controller: usersController,
                      surfaceColor: _surfaceColor,
                      textColor: _textColor,
                      subTextColor: _subTextColor,
                      borderColor: _borderColor,
                      chipColor: _chipColor,
                      inputFillColor: _inputFillColor,
                    ),
                    AdminNotificationsTab(
                      controller: notificationsController,
                      surfaceColor: _surfaceColor,
                      textColor: _textColor,
                      subTextColor: _subTextColor,
                      borderColor: _borderColor,
                      chipColor: _chipColor,
                      inputFillColor: _inputFillColor,
                    ),
                    AdminStatisticsTab(
                      controller: _statsController,
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
                    color: isSelected
                        ? const Color(0xFF1654F0)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF1654F0)
                          : _borderColor,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        tabs[idx]['icon'] as IconData,
                        size: 16,
                        color: isSelected ? Colors.white : _subTextColor,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        tabs[idx]['label'] as String,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: isSelected ? Colors.white : _textColor,
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
}
