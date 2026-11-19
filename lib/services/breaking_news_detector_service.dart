import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/article.dart';
import '../models/weather.dart';
import '../features/news/presentation/article_detail_screen.dart';
import '../features/notifications/providers/notifications_provider.dart';
import '../features/settings/providers/settings_provider.dart';

/// ============================================================================
/// DỊCH VỤ NHẬN DIỆN VÀ PHÁT CẢNH BÁO TIN NÓNG & THỜI TIẾT KHẨN CẤP
/// (Breaking News & Weather Emergency Detection Service)
/// ============================================================================
/// 
/// [MỤC ĐÍCH & TÁC DỤNG]:
/// 1. Tự động rà soát nội dung các bài báo RSS (VnExpress, Tuổi Trẻ, Thanh Niên...)
///    để phát hiện ngay lập tức các sự kiện chấn động, bão lũ, thiên tai, hỏa hoạn...
/// 2. Phân loại chuẩn xác "Tin nóng & khẩn cấp" mà không cần đợi Admin phát sóng thủ công.
/// 3. Kiểm tra cài đặt người dùng (SettingsProvider): Tôn trọng lựa chọn bật/tắt của người dùng.
/// 4. Chống trùng lặp (Anti-Spam): Mỗi tin nóng chỉ phát thông báo đúng 1 lần duy nhất,
///    ghi nhớ qua SharedPreferences để khi làm mới trang không bị báo lại liên tục.
/// 5. Hiển thị Banner nổi khẩn cấp (Emergency Floating Banner) kèm nút bấm "Xem ngay"
///    để người dùng đọc trực tiếp chi tiết tin tức.
/// ============================================================================
class BreakingNewsDetectorService {
  // Khóa lưu danh sách ID/Link các bài viết đã từng được gửi thông báo
  static const String _keyNotifiedBreakingIds = 'notified_breaking_article_links';
  
  // Khóa lưu thời điểm gửi cảnh báo thời tiết gần nhất (tránh gửi lặp nhiều lần trong ngày)
  static const String _keyLastWeatherAlertDate = 'last_weather_alert_date';

  // [BỘ ĐỆM RAM - IN-MEMORY THROTTLE]:
  // Giúp hàm quét không chạy lại SharedPreferences liên tục khi người dùng cuộn lướt màn hình
  static String? _lastCheckedTopLink;
  static int? _lastCheckedArticlesCount;
  static DateTime? _lastCheckTime;

  static String? _lastCheckedCity;
  static int? _lastCheckedWeatherCode;
  static DateTime? _lastWeatherCheckTime;

  /// --------------------------------------------------------------------------
  /// BỘ TỪ KHÓA NHẬN DIỆN TIN TỨC NÓNG & KHẨN CẤP (Breaking News Keywords)
  /// 
  /// [TÁC DỤNG]:
  /// Khi một bài báo có tiêu đề chứa bất kỳ từ khóa nào trong danh sách này,
  /// hệ thống sẽ ngay lập tức xếp vào diện "Tin khẩn cấp cần chú ý".
  /// --------------------------------------------------------------------------
  static const List<String> _emergencyKeywords = [
    // 1. Thiên tai & Khí hậu cực đoan
    'khẩn cấp',
    'bão số',
    'siêu bão',
    'áp thấp nhiệt đới',
    'lũ quét',
    'sạt lở đất',
    'ngập lụt lịch sử',
    'triều cường kỷ lục',
    'động đất',
    'sóng thần',
    'vỡ đê',
    'sơ tán dân',

    // 2. An toàn, Cứu nạn & Hỏa hoạn nghiêm trọng
    'hỏa hoạn lớn',
    'cháy lớn',
    'cháy dữ dội',
    'cứu hộ cứu nạn',
    'tai nạn nghiêm trọng',
    'chìm tàu',
    'rơi máy bay',
    'sập cầu',
    'sập công trình',

    // 3. Y tế, An ninh & Tình huống chấn động
    'báo động đỏ',
    'chấn động',
    'phong tỏa khẩn',
    'ngộ độc hàng loạt',
    'cảnh báo đặc biệt nguy hiểm',
  ];

  /// --------------------------------------------------------------------------
  /// HÀM 1: KIỂM TRA BÀI BÁO CÓ PHẢI LÀ TIN NÓNG KHẨN CẤP HAY KHÔNG
  /// 
  /// [TÁC DỤNG]:
  /// Chuẩn hóa chữ thường (lowercase) tiêu đề bài viết và so sánh với danh mục từ khóa.
  /// Trả về `true` nếu bài viết thỏa mãn tiêu chí tin khẩn cấp.
  /// --------------------------------------------------------------------------
  static bool isBreakingArticle(Article article) {
    final title = article.title.trim().toLowerCase();
    final description = article.description.trim().toLowerCase();

    for (final keyword in _emergencyKeywords) {
      if (title.contains(keyword) || description.contains(keyword)) {
        return true;
      }
    }
    return false;
  }

  /// --------------------------------------------------------------------------
  /// HÀM 2: TỰ ĐỘNG QUÉT VÀ PHÁT THÔNG BÁO TIN NÓNG
  /// 
  /// [TÁC DỤNG]:
  /// - Chạy sau khi app tải xong danh sách tin tức RSS mới nhất.
  /// - Kiểm tra xem công tắc "Tin tức nóng & khẩn cấp" trong Cài đặt có bật không.
  /// - Lọc các bài viết khẩn cấp và kiểm tra xem đã báo cho người dùng chưa.
  /// - Nếu là tin mới: Thêm vào hộp thư thông báo (chuông) và hiện Banner nổi trên màn hình.
  /// --------------------------------------------------------------------------
  static Future<void> checkAndNotifyBreakingNews({
    required BuildContext context,
    required List<Article> articles,
  }) async {
    if (articles.isEmpty) return;

    // Kiểm tra bộ đệm RAM: nếu danh sách bài báo không đổi và vừa quét dưới 10 giây trước, bỏ qua để mượt mà 60/120fps
    final now = DateTime.now();
    if (_lastCheckTime != null &&
        now.difference(_lastCheckTime!).inSeconds < 10 &&
        _lastCheckedTopLink == articles.first.link &&
        _lastCheckedArticlesCount == articles.length) {
      return;
    }
    _lastCheckTime = now;
    _lastCheckedTopLink = articles.first.link;
    _lastCheckedArticlesCount = articles.length;

    try {
      final settings = context.read<SettingsProvider>();
      // [BƯỚC 1]: Kiểm tra cấu hình Cài đặt của người dùng
      // Nếu người dùng đã chủ động tắt "Tin tức nóng & khẩn cấp", ta tôn trọng và không gửi
      if (!settings.breakingNewsNotif) return;

      final prefs = await SharedPreferences.getInstance();
      final notifiedLinks = (prefs.getStringList(_keyNotifiedBreakingIds) ?? []).toSet();

      // [BƯỚC 2]: Quét tối đa 15 bài báo mới nhất để tìm tin khẩn cấp
      final recentArticles = articles.take(15).toList();
      Article? breakingToNotify;

      for (final article in recentArticles) {
        final link = article.link.trim();
        // Bỏ qua nếu tin này đã từng được thông báo rồi (chống spam chuông)
        if (notifiedLinks.contains(link)) continue;

        if (isBreakingArticle(article)) {
          breakingToNotify = article;
          notifiedLinks.add(link);
          break; // Mỗi lần chỉ phát thông báo 1 tin khẩn cấp nổi bật nhất
        }
      }

      if (breakingToNotify == null) return;

      // [BƯỚC 3]: Lưu lại link đã thông báo vào bộ nhớ máy SharedPreferences
      // Giới hạn lưu 100 tin gần nhất để tiết kiệm bộ nhớ
      final updatedList = notifiedLinks.toList();
      if (updatedList.length > 100) {
        updatedList.removeRange(0, updatedList.length - 100);
      }
      await prefs.setStringList(_keyNotifiedBreakingIds, updatedList);

      if (!context.mounted) return;

      // [BƯỚC 4]: Đưa vào danh sách thông báo của ứng dụng (Tab Chuông thông báo)
      final notificationsProvider = context.read<NotificationsProvider>();
      await notificationsProvider.addNotification(
        title: '🔴 TIN NÓNG KHẨN CẤP: ${breakingToNotify.title}',
        body: breakingToNotify.description.isNotEmpty
            ? breakingToNotify.description
            : 'Cập nhật từ ${breakingToNotify.source}. Bấm để xem chi tiết.',
        type: 'breaking',
      );

      if (!context.mounted) return;

      // [BƯỚC 5]: Hiển thị Banner nổi trực quan ở chân/đỉnh màn hình kèm nút "Xem ngay"
      _showEmergencyBanner(
        context: context,
        title: 'TIN NÓNG KHẨN CẤP',
        message: breakingToNotify.title,
        icon: Icons.campaign_rounded,
        badgeColor: const Color(0xFFEF4444),
        onTapAction: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ArticleDetailScreen(article: breakingToNotify!),
            ),
          );
        },
      );
    } catch (e) {
      debugPrint('BreakingNewsDetectorService error: $e');
    }
  }

  /// --------------------------------------------------------------------------
  /// HÀM 3: TỰ ĐỘNG PHÁT CẢNH BÁO THỜI TIẾT NGUY HIỂM / THỜI TIẾT XẤU
  /// 
  /// [TÁC DỤNG]:
  /// - Kiểm tra điều kiện thời tiết (Dông sét, mưa lớn, gió bão, UV nguy hại).
  /// - Nếu phát hiện thời tiết xấu tại vị trí của người dùng:
  ///   Tự động bắn thông báo và hiện cảnh báo hướng dẫn người dùng phòng tránh.
  /// --------------------------------------------------------------------------
  static Future<void> checkAndNotifyWeatherAlert({
    required BuildContext context,
    required Weather weather,
  }) async {
    final now = DateTime.now();
    if (_lastWeatherCheckTime != null &&
        now.difference(_lastWeatherCheckTime!).inMinutes < 5 &&
        _lastCheckedCity == weather.cityName &&
        _lastCheckedWeatherCode == weather.weatherCode) {
      return;
    }
    _lastWeatherCheckTime = now;
    _lastCheckedCity = weather.cityName;
    _lastCheckedWeatherCode = weather.weatherCode;

    try {
      final settings = context.read<SettingsProvider>();
      // Kiểm tra xem người dùng có bật "Cảnh báo thời tiết nguy hiểm" không
      if (!settings.weatherAlertNotif) return;

      // Nhận diện các mã thời tiết WMO nguy hiểm:
      // 95: Dông kèm mưa rào | 96 & 99: Dông mạnh có mưa đá | 82: Mưa rào cực lớn
      final code = weather.weatherCode;
      final isThunderstorm = (code == 95 || code == 96 || code == 99);
      final isHighWind = weather.windSpeed >= 45.0; // Gió mạnh từ cấp 6 trở lên
      final isExtremeRain = (code == 82 || code == 65); // Mưa rất to

      if (!isThunderstorm && !isHighWind && !isExtremeRain) return;

      // Kiểm tra ngày cảnh báo gần nhất để tránh lặp lại nhiều lần trong cùng 1 ngày
      final prefs = await SharedPreferences.getInstance();
      final todayStr = '${DateTime.now().year}-${DateTime.now().month}-${DateTime.now().day}';
      final lastAlertKey = 'weather_alert_${weather.cityName}_$todayStr';
      if (prefs.getBool(lastAlertKey) == true) return;

      await prefs.setBool(lastAlertKey, true);

      if (!context.mounted) return;

      String warningTitle = 'CẢNH BÁO THỜI TIẾT TẠI ${weather.cityName.toUpperCase()}';
      String warningBody = '';

      if (isThunderstorm) {
        warningBody = 'Khu vực đang có dông sét nguy hiểm & khả năng mưa lớn. Hạn chế ra đường và tìm nơi trú ẩn an toàn.';
      } else if (isHighWind) {
        warningBody = 'Gió giật mạnh (${weather.windSpeed.toStringAsFixed(1)} km/h). Đề phòng cây đổ, biển quảng cáo và vật rơi nguy hiểm.';
      } else {
        warningBody = 'Mưa to cục bộ có thể gây ngập úng các tuyến đường trũng thấp. Chú ý an toàn khi tham gia giao thông.';
      }

      // Đưa vào hộp thư thông báo (chuông)
      final notificationsProvider = context.read<NotificationsProvider>();
      await notificationsProvider.addNotification(
        title: '⚠️ $warningTitle',
        body: warningBody,
        type: 'weather_alert',
      );

      if (!context.mounted) return;

      // Hiển thị thông báo nổi màu cam hổ phách
      _showEmergencyBanner(
        context: context,
        title: warningTitle,
        message: warningBody,
        icon: Icons.thunderstorm_rounded,
        badgeColor: const Color(0xFFF59E0B),
        onTapAction: null,
      );
    } catch (e) {
      debugPrint('BreakingNewsDetectorService.checkAndNotifyWeatherAlert error: $e');
    }
  }

  /// --------------------------------------------------------------------------
  /// HÀM NỘI BỘ: HIỂN THỊ BANNER NỔI CẢNH BÁO (Emergency Floating Banner)
  /// 
  /// [TÁC DỤNG]:
  /// Tạo một hộp thông báo nổi cao cấp ở cạnh trên/dưới của màn hình:
  /// - Thiết kế viền bo tròn, bóng đổ, màu sắc cảnh báo bắt mắt.
  /// - Có nút "Xem ngay" để mở ngay bài viết liên quan.
  /// --------------------------------------------------------------------------
  static void _showEmergencyBanner({
    required BuildContext context,
    required String title,
    required String message,
    required IconData icon,
    required Color badgeColor,
    VoidCallback? onTapAction,
  }) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        elevation: 8,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(bottom: 24, left: 16, right: 16),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        backgroundColor: const Color(0xFF1E293B), // Xanh đen sang trọng
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: badgeColor.withOpacity(0.5), width: 1.2),
        ),
        duration: const Duration(seconds: 8),
        content: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: badgeColor.withOpacity(0.18),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: badgeColor, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: badgeColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    message,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            if (onTapAction != null) ...[
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  messenger.hideCurrentSnackBar();
                  onTapAction();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: badgeColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'Xem ngay',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
