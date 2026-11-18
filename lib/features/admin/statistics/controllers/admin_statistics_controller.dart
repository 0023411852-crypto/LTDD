import 'package:flutter/material.dart';
import '../../../../models/article.dart';

class AdminStatisticsController extends ChangeNotifier {
  AdminStatisticsController();

  Map<String, int> getSourceBreakdown(List<Article> articles) {
    int vnExpress = 0;
    int tuoiTre = 0;
    int thanhNien = 0;

    for (final a in articles) {
      final s = a.source.toLowerCase();
      if (s.contains('vnexpress')) {
        vnExpress++;
      } else if (s.contains('tuổi trẻ') || s.contains('tuoitre')) {
        tuoiTre++;
      } else if (s.contains('thanh niên') || s.contains('thanhnien')) {
        thanhNien++;
      }
    }

    final int adminCount = articles.length - vnExpress - tuoiTre - thanhNien;

    return {
      'VnExpress RSS': vnExpress,
      'Tuổi Trẻ Online': tuoiTre,
      'Báo Thanh Niên': thanhNien,
      'Biên tập Admin': adminCount < 0 ? 0 : adminCount,
    };
  }

  int getArticlesWithImageCount(List<Article> articles) {
    return articles.where((a) => a.imageUrl != null && a.imageUrl!.isNotEmpty).length;
  }
}
