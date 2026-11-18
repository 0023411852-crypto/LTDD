import 'package:flutter/material.dart';
import '../../../../models/article.dart';
import '../controllers/admin_dashboard_controller.dart';

class AdminDashboardTab extends StatelessWidget {
  final AdminDashboardController controller;
  final Function(int tabIndex) onNavigateTab;
  final VoidCallback onOpenAddArticleDialog;
  final Color surfaceColor;
  final Color textColor;
  final Color subTextColor;
  final Color borderColor;

  const AdminDashboardTab({
    super.key,
    required this.controller,
    required this.onNavigateTab,
    required this.onOpenAddArticleDialog,
    required this.surfaceColor,
    required this.textColor,
    required this.subTextColor,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final articleCount = controller.totalArticles;
    final categoryCount = controller.totalCategories;
    final favCount = controller.totalFavorites;
    final temp = controller.currentTemperature;
    final city = controller.currentCity;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Admin Profile Card
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
                    controller.isOnline
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
                            controller.adminDisplayName,
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
                            color: controller.isOnline
                                ? const Color(0xFF10B981)
                                : Colors.amber.shade700,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            controller.isOnline ? 'ONLINE' : 'GUEST',
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
                      controller.adminEmail,
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
            color: surfaceColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tác vụ quản trị nhanh',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: textColor),
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
                      onNavigateTab(1);
                      onOpenAddArticleDialog();
                    },
                  ),
                  _buildQuickActionBtn(
                    label: 'Xem danh sách tin',
                    icon: Icons.newspaper_rounded,
                    color: const Color(0xFF10B981),
                    onTap: () => onNavigateTab(1),
                  ),
                  _buildQuickActionBtn(
                    label: 'Phát sóng thông báo',
                    icon: Icons.send_rounded,
                    color: const Color(0xFFEC4899),
                    onTap: () => onNavigateTab(4),
                  ),
                  _buildQuickActionBtn(
                    label: 'Báo cáo nguồn tin',
                    icon: Icons.pie_chart_rounded,
                    color: const Color(0xFF8B5CF6),
                    onTap: () => onNavigateTab(5),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Biểu đồ phân bổ bài viết
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: borderColor),
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
                              color: textColor),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Đếm số lượng bài viết theo ngày đăng (publishedAt)',
                          style: TextStyle(fontSize: 12, color: subTextColor),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
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
              SizedBox(
                height: 150,
                width: double.infinity,
                child: CustomPaint(
                  painter: _NewsDistributionChartPainter(
                    articles: controller.allArticles,
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
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: bgGradient),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              Icon(Icons.trending_up_rounded,
                  color: Colors.green.shade600, size: 16),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: textColor,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.bold, color: textColor),
          ),
          const SizedBox(height: 2),
          Text(
            subText,
            style: TextStyle(fontSize: 10.5, color: subTextColor),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
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
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w700, color: color),
            ),
          ],
        ),
      ),
    );
  }
}

class _NewsDistributionChartPainter extends CustomPainter {
  final List<Article> articles;
  _NewsDistributionChartPainter({required this.articles});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final dayCounts = List<int>.filled(7, 0);

    for (final a in articles) {
      if (a.publishedAt != null) {
        final weekday = a.publishedAt!.weekday;
        if (weekday >= 1 && weekday <= 7) {
          dayCounts[weekday - 1]++;
        }
      }
    }

    final maxVal = dayCounts.reduce((curr, next) => curr > next ? curr : next);
    final divisor = maxVal > 0 ? maxVal.toDouble() : 1.0;

    final barWidth = (w / 7) * 0.45;
    final step = w / 7;

    for (int i = 0; i < 7; i++) {
      final ratio = (dayCounts[i] / divisor).clamp(0.08, 1.0);
      final barH = (h - 25) * ratio;
      final x = (i * step) + (step - barWidth) / 2;
      final y = (h - 20) - barH;

      final rrect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, barWidth, barH),
        const Radius.circular(6),
      );

      final paint = Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFF38BDF8), Color(0xFF1E60F2)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(Rect.fromLTWH(x, y, barWidth, barH));

      canvas.drawRRect(rrect, paint);

      final tp = TextPainter(
        text: TextSpan(
          text: '${dayCounts[i]}',
          style: const TextStyle(
            color: Color(0xFF64748B),
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(x + (barWidth - tp.width) / 2, y - 16));
    }
  }

  @override
  bool shouldRepaint(covariant _NewsDistributionChartPainter oldDelegate) {
    return oldDelegate.articles != articles;
  }
}
