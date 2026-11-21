import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:daily_news_weather_portal/models/app_notification.dart';
import 'package:daily_news_weather_portal/models/article.dart';
import 'package:daily_news_weather_portal/features/auth/providers/auth_provider.dart';
import 'package:daily_news_weather_portal/features/news/presentation/article_detail_screen.dart';
import 'package:daily_news_weather_portal/features/news/providers/news_provider.dart';
import 'package:daily_news_weather_portal/features/weather/presentation/weather_screen.dart';
import 'package:daily_news_weather_portal/features/notifications/providers/notifications_provider.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      if (auth.uid.isNotEmpty) {
        context.read<NotificationsProvider>().load(auth.uid);
      }
    });
  }

  void _handleNotificationTap(
    BuildContext context,
    AppNotification item,
    NotificationsProvider provider,
  ) {
    provider.markRead(item);

    if (item.type == 'weather') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const WeatherScreen()),
      );
    } else {
      final newsProvider = context.read<NewsProvider>();
      final allArticles = newsProvider.allArticles;

      Article? matchedArticle;
      final cleanNotifTitle = item.title
          .replaceAll('🔴 TIN NÓNG KHẨN CẤP: ', '')
          .replaceAll('🔴 TIN NÓNG: ', '')
          .trim();

      for (final article in allArticles) {
        if (article.title == cleanNotifTitle ||
            cleanNotifTitle.contains(article.title) ||
            article.title.contains(cleanNotifTitle)) {
          matchedArticle = article;
          break;
        }
      }

      final targetArticle = matchedArticle ??
          Article(
            title: cleanNotifTitle,
            link: 'https://vnexpress.net',
            description: item.body,
            source: 'Tin tức',
            publishedAt: item.createdAt,
          );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ArticleDetailScreen(article: targetArticle),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotificationsProvider>();
    final cs = Theme.of(context).colorScheme;
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          provider.unreadCount > 0
              ? 'Thông báo (${provider.unreadCount})'
              : 'Thông báo',
        ),
        actions: [
          if (provider.unreadCount > 0)
            TextButton(
              onPressed: provider.markAllRead,
              child: const Text('Đọc tất cả'),
            ),
        ],
      ),
      body: !auth.isAuthenticated
          ? const _EmptyState(
              icon: Icons.lock_outline_rounded,
              title: 'Đăng nhập để xem thông báo',
              subtitle: 'Thông báo cá nhân sẽ được đồng bộ trên các thiết bị.',
            )
          : Column(
              children: [
                if (provider.notifications.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          cs.primary.withOpacity(0.14),
                          cs.primary.withOpacity(0.04),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.mark_email_unread_rounded,
                            color: cs.primary, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          provider.unreadCount == 0
                              ? 'Bạn đã xem hết thông báo'
                              : '${provider.unreadCount} thông báo mới',
                          style: TextStyle(
                            color: cs.onSurface,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                Expanded(child: _buildBody(context, provider, cs)),
              ],
            ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    NotificationsProvider provider,
    ColorScheme cs,
  ) {
    if (provider.status == NotificationsStatus.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.status == NotificationsStatus.error) {
      return _EmptyState(
        icon: Icons.cloud_off_rounded,
        title: 'Không tải được thông báo',
        subtitle: provider.errorMessage,
        action: FilledButton(
          onPressed: () {
            final uid = context.read<AuthProvider>().uid;
            context.read<NotificationsProvider>().load(uid);
          },
          child: const Text('Thử lại'),
        ),
      );
    }
    if (provider.notifications.isEmpty) {
      return const _EmptyState(
        icon: Icons.notifications_none_rounded,
        title: 'Chưa có thông báo',
        subtitle: 'Các cập nhật mới sẽ xuất hiện tại đây.',
      );
    }

    return RefreshIndicator(
      onRefresh: () => provider.load(context.read<AuthProvider>().uid),
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: provider.notifications.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final item = provider.notifications[index];
          return _NotificationCard(
            notification: item,
            onTap: () => _handleNotificationTap(context, item, provider),
            colorScheme: cs,
          );
        },
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback onTap;
  final ColorScheme colorScheme;

  const _NotificationCard({
    required this.notification,
    required this.onTap,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    final icon = switch (notification.type) {
      'weather' => Icons.wb_sunny_outlined,
      'news' => Icons.newspaper_outlined,
      _ => Icons.notifications_outlined,
    };
    return Material(
      color: notification.isRead
          ? colorScheme.surface
          : colorScheme.primaryContainer.withOpacity(0.5),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: colorScheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.title,
                      style: TextStyle(
                        fontWeight: notification.isRead
                            ? FontWeight.w600
                            : FontWeight.w800,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.body,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              if (!notification.isRead)
                Padding(
                  padding: const EdgeInsets.only(left: 8, top: 5),
                  child: CircleAvatar(
                    radius: 4,
                    backgroundColor: colorScheme.primary,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? action;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 56, color: cs.primary),
            const SizedBox(height: 16),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(color: cs.onSurfaceVariant),
            ),
            if (action != null) ...[
              const SizedBox(height: 16),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
