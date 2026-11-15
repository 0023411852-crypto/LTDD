import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../utils/app_colors.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  // Demo items — clearly labeled as local/demo, not server-delivered
  final List<Map<String, dynamic>> _notifications = [
    {
      'id': '1',
      'title': 'Dự báo thời tiết hôm nay',
      'body':
          'Thời tiết nhiều mây, có mưa rải rác buổi chiều. Hãy mang theo áo mưa.',
      'time': '15 phút trước',
      'type': 'weather',
      'read': false,
    },
    {
      'id': '2',
      'title': 'Tin nổi bật buổi sáng',
      'body':
          'Tổng hợp sự kiện kinh tế và xã hội đáng chú ý trong ngày đã sẵn sàng.',
      'time': '2 giờ trước',
      'type': 'news',
      'read': false,
    },
    {
      'id': '3',
      'title': 'Chào mừng đến Daily News & Weather Portal',
      'body':
          'Khám phá tin tức từ các báo lớn và theo dõi thời tiết chuẩn xác.',
      'time': 'Hôm qua',
      'type': 'system',
      'read': true,
    },
  ];

  void _markAllRead() {
    setState(() {
      for (final n in _notifications) {
        n['read'] = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final unread = _notifications.where((n) => n['read'] == false).length;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
            unread > 0 ? 'Thông báo ($unread chưa đọc)' : 'Thông báo'),
        actions: [
          if (unread > 0)
            TextButton(
              onPressed: _markAllRead,
              child: const Text('Đọc tất cả'),
            ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          // Label rõ ràng: đây là demo local, không phải server push
          Container(
            width: double.infinity,
            color: cs.surfaceContainerHighest,
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded,
                    size: 14, color: cs.onSurfaceVariant),
                const SizedBox(width: 6),
                Text(
                  'Thông báo demo — chưa kết nối server push',
                  style: TextStyle(
                      fontSize: 11.5, color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
          Expanded(
            child: _notifications.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.notifications_none_outlined,
                            size: 56, color: cs.outline),
                        const SizedBox(height: 16),
                        Text('Không có thông báo',
                            style: Theme.of(context).textTheme.titleMedium),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    itemCount: _notifications.length,
                    separatorBuilder: (_, __) =>
                        Divider(height: 1, color: cs.outlineVariant),
                    itemBuilder: (context, index) {
                      final item = _notifications[index];
                      return _NotifTile(
                        item: item,
                        onTap: () => setState(() => item['read'] = true),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _NotifTile extends StatelessWidget {
  final Map<String, dynamic> item;
  final VoidCallback onTap;

  const _NotifTile({required this.item, required this.onTap});

  IconData _typeIcon(String type) => switch (type) {
        'weather' => Icons.wb_sunny_outlined,
        'news' => Icons.newspaper_outlined,
        _ => Icons.notifications_outlined,
      };

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isRead = item['read'] as bool;
    final type = item['type'] as String;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Dot unread
            Padding(
              padding: const EdgeInsets.only(top: 6, right: 8),
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isRead ? Colors.transparent : cs.primary,
                ),
              ),
            ),
            // Icon
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: type == 'weather'
                    ? Colors.orange.shade50
                    : cs.primaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _typeIcon(type),
                size: 18,
                color: type == 'weather'
                    ? Colors.orange.shade700
                    : cs.primary,
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
                        item['title'] as String,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isRead
                              ? FontWeight.w500
                              : FontWeight.w700,
                          color: cs.onSurface,
                        ),
                      ),
                      Text(
                        item['time'] as String,
                        style: TextStyle(
                            fontSize: 11, color: cs.onSurfaceVariant),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item['body'] as String,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 13, color: cs.onSurfaceVariant, height: 1.4),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
