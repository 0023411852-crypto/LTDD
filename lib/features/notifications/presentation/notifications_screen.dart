import 'package:flutter/material.dart';
import '../../../utils/app_colors.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final List<Map<String, dynamic>> _notifications = [
    {
      'id': '1',
      'title': 'Dự báo thời tiết hôm nay',
      'body':
          'Thời tiết khu vực nhiều mây, có mưa rải rác vào buổi chiều. Hãy mang theo áo mưa khi ra ngoài.',
      'time': '15 phút trước',
      'type': 'Thời tiết',
      'read': false,
    },
    {
      'id': '2',
      'title': 'Tin nổi bật buổi sáng',
      'body':
          'Tổng hợp các sự kiện kinh tế và xã hội đáng chú ý trong ngày đã sẵn sàng.',
      'time': '2 giờ trước',
      'type': 'Tin nóng',
      'read': false,
    },
    {
      'id': '3',
      'title': 'Chào mừng bạn đến với Daily News & Weather Portal!',
      'body':
          'Khám phá ngay tính năng đọc tin tức từ các báo lớn và theo dõi dự báo thời tiết chuẩn xác.',
      'time': 'Hôm qua',
      'type': 'Hệ thống',
      'read': true,
    },
  ];

  void _markAllAsRead() {
    setState(() {
      for (var item in _notifications) {
        item['read'] = true;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã đánh dấu tất cả là đã đọc')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = _notifications.where((n) => n['read'] == false).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông báo'),
        actions: [
          if (unreadCount > 0)
            TextButton(
              onPressed: _markAllAsRead,
              child: const Text('Đã đọc tất cả'),
            ),
        ],
      ),
      body: _notifications.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none,
                      size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  const Text(
                    'Không có thông báo mới',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _notifications.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = _notifications[index];
                final isRead = item['read'] as bool;

                return InkWell(
                  onTap: () {
                    setState(() {
                      item['read'] = true;
                    });
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isRead
                          ? Colors.white
                          : AppColors.primary.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isRead
                            ? Colors.grey.shade200
                            : AppColors.primary.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: item['type'] == 'Thời tiết'
                              ? Colors.orange.shade100
                              : AppColors.primary.withOpacity(0.1),
                          child: Icon(
                            item['type'] == 'Thời tiết'
                                ? Icons.wb_sunny_outlined
                                : Icons.newspaper_outlined,
                            color: item['type'] == 'Thời tiết'
                                ? Colors.orange
                                : AppColors.primary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    item['type'] as String,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  Text(
                                    item['time'] as String,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                item['title'] as String,
                                style: TextStyle(
                                  fontWeight: isRead
                                      ? FontWeight.w600
                                      : FontWeight.bold,
                                  fontSize: 15,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item['body'] as String,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade600,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (!isRead) ...[
                          const SizedBox(width: 8),
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
