import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../favorites/providers/favorites_provider.dart';
import '../../../news/providers/news_provider.dart';
import '../controllers/admin_statistics_controller.dart';

class AdminStatisticsTab extends StatelessWidget {
  final AdminStatisticsController controller;

  const AdminStatisticsTab({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? Colors.white12 : const Color(0xFFE2E8F0);
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subTextColor = isDark ? Colors.white60 : const Color(0xFF64748B);
    final inputFillColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final bgColor = isDark ? const Color(0xFF0A0F1D) : const Color(0xFFF1F5F9);

    final news = context.watch<NewsProvider>();
    final fav = context.watch<FavoritesProvider>();
    final articles = news.allArticles;
    final total = articles.length;

    final breakdown = controller.getSourceBreakdown(articles);
    final vnExpressCount = breakdown['VnExpress RSS'] ?? 0;
    final tuoiTreCount = breakdown['Tuổi Trẻ Online'] ?? 0;
    final thanhNienCount = breakdown['Báo Thanh Niên'] ?? 0;
    final adminCount = breakdown['Biên tập Admin'] ?? 0;

    final hasImageCount = controller.getArticlesWithImageCount(articles);
    final imageRatio = total > 0 ? (hasImageCount / total) : 0.0;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Card thống kê nguồn báo thực tế
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
                    child: Text(
                      'Phân bổ nguồn báo thực tế',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Tổng $total bài',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E60F2),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (total > 0) ...[
                _buildRealProgressRow(
                  'VnExpress RSS',
                  vnExpressCount,
                  total,
                  const Color(0xFF991B1B),
                  bgColor,
                ),
                const SizedBox(height: 12),
                _buildRealProgressRow(
                  'Tuổi Trẻ Online',
                  tuoiTreCount,
                  total,
                  const Color(0xFF0284C7),
                  bgColor,
                ),
                const SizedBox(height: 12),
                _buildRealProgressRow(
                  'Báo Thanh Niên',
                  thanhNienCount,
                  total,
                  const Color(0xFF16A34A),
                  bgColor,
                ),
                if (adminCount > 0) ...[
                  const SizedBox(height: 12),
                  _buildRealProgressRow(
                    'Biên tập Admin',
                    adminCount,
                    total,
                    const Color(0xFF8B5CF6),
                    bgColor,
                  ),
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
            color: surfaceColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Chỉ số nội dung & Tương tác thực tế',
                style: TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
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
                      inputFillColor: inputFillColor,
                      borderColor: borderColor,
                      subTextColor: subTextColor,
                      textColor: textColor,
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
                      inputFillColor: inputFillColor,
                      borderColor: borderColor,
                      subTextColor: subTextColor,
                      textColor: textColor,
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

  Widget _buildRealProgressRow(
    String name,
    int count,
    int total,
    Color color,
    Color bgColor,
  ) {
    final ratio = total > 0 ? (count / total) : 0.0;
    final percent = (ratio * 100).toStringAsFixed(1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '$name ($count bài)',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
            Text(
              '$percent%',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 8,
            backgroundColor: bgColor,
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
    required Color inputFillColor,
    required Color borderColor,
    required Color subTextColor,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: inputFillColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: subTextColor,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Icon(icon, color: color, size: 20),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: textColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            percent,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
