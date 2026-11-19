import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:xml/xml.dart';
import '../models/article.dart';

class NewsCategory {
  final String id;
  final String label;
  final String rssUrl;
  final String source;
  final int maxArticles; // Số lượng bài tối đa giữ lại cho nguồn này (mặc định 30, 0 là không giới hạn)
  final int retentionDays; // Thời gian giữ lại bài tin tính theo ngày (mặc định 7 ngày, 0 là vĩnh viễn không xóa)

  const NewsCategory(
    this.id,
    this.label,
    this.rssUrl,
    this.source, {
    this.maxArticles = 30,
    this.retentionDays = 7,
  });

  NewsCategory copyWith({
    String? id,
    String? label,
    String? rssUrl,
    String? source,
    int? maxArticles,
    int? retentionDays,
  }) {
    return NewsCategory(
      id ?? this.id,
      label ?? this.label,
      rssUrl ?? this.rssUrl,
      source ?? this.source,
      maxArticles: maxArticles ?? this.maxArticles,
      retentionDays: retentionDays ?? this.retentionDays,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'rssUrl': rssUrl,
        'source': source,
        'maxArticles': maxArticles,
        'retentionDays': retentionDays,
      };

  factory NewsCategory.fromJson(Map<String, dynamic> json) => NewsCategory(
        json['id'] as String? ?? '',
        json['label'] as String? ?? '',
        json['rssUrl'] as String? ?? '',
        json['source'] as String? ?? '',
        maxArticles: json['maxArticles'] as int? ?? 30,
        retentionDays: json['retentionDays'] as int? ?? 7,
      );
}

/// Abstract contract for Clean Architecture / Dependency Inversion
abstract class INewsService {
  Future<List<Article>> fetchCategory(NewsCategory category, {bool forceRefresh = false});
}

/// News Service: RSS aggregator with in-memory TTL cache and resilience
class NewsService implements INewsService {
  static const categories = <NewsCategory>[
    NewsCategory('moi-nhat', 'Mới nhất',
        'https://vnexpress.net/rss/tin-moi-nhat.rss', 'VnExpress'),
    NewsCategory('thoi-su', 'Thời sự', 'https://vnexpress.net/rss/thoi-su.rss',
        'VnExpress'),
    NewsCategory('the-gioi', 'Thế giới',
        'https://vnexpress.net/rss/the-gioi.rss', 'VnExpress'),
    NewsCategory('kinh-doanh', 'Kinh doanh',
        'https://vnexpress.net/rss/kinh-doanh.rss', 'VnExpress'),
    NewsCategory('cong-nghe', 'Công nghệ',
        'https://vnexpress.net/rss/khoa-hoc-cong-nghe.rss', 'VnExpress'),
    NewsCategory('the-thao', 'Thể thao',
        'https://vnexpress.net/rss/the-thao.rss', 'VnExpress'),
    NewsCategory('giai-tri', 'Giải trí',
        'https://vnexpress.net/rss/giai-tri.rss', 'VnExpress'),
    NewsCategory('suc-khoe', 'Sức khỏe',
        'https://vnexpress.net/rss/suc-khoe.rss', 'VnExpress'),
    NewsCategory('tuoi-tre', 'Tuổi Trẻ',
        'https://tuoitre.vn/rss/tin-moi-nhat.rss', 'Tuổi Trẻ'),
    NewsCategory('thanh-nien', 'Thanh Niên',
        'https://thanhnien.vn/rss/home.rss', 'Thanh Niên'),
  ];

  static const Duration _cacheTtl = Duration(minutes: 5);
  static const Duration _requestTimeout = Duration(seconds: 15);

  final Map<String, (DateTime timestamp, List<Article> data)> _cache = {};

  @override
  Future<List<Article>> fetchCategory(NewsCategory category, {bool forceRefresh = false}) async {
    final now = DateTime.now();
    final cached = _cache[category.id];

    if (!forceRefresh && cached != null && now.difference(cached.$1) < _cacheTtl) {
      return cached.$2;
    }

    // Security check (Semgrep): Enforce valid HTTPS URI
    final uri = Uri.tryParse(category.rssUrl);
    if (uri == null || !uri.hasScheme || uri.scheme != 'https') {
      throw const FormatException('URL nguồn tin không an toàn hoặc không hợp lệ.');
    }

    try {
      final res = await http.get(uri).timeout(_requestTimeout);
      if (res.statusCode != 200) {
        throw Exception('Không tải được tin (${res.statusCode})');
      }

      final doc = XmlDocument.parse(res.body);
      final items = doc.findAllElements('item');
      var articles = items
          .map((item) => _parseRssItem(item, category))
          .where((a) => a.title.isNotEmpty && a.link.isNotEmpty)
          .toList();

      // [LỌC THEO THỜI GIAN LƯU TRỮ CHO TỪNG NGUỒN (RETENTION DAYS)]:
      // Nếu category.retentionDays > 0, tự động loại bỏ các bài viết xuất bản trước mốc thời gian này
      if (category.retentionDays > 0) {
        final cutoff = now.subtract(Duration(days: category.retentionDays));
        articles = articles.where((a) {
          if (a.publishedAt == null) return true;
          return a.publishedAt!.isAfter(cutoff);
        }).toList();
      }

      // [GIỚI HẠN SỐ LƯỢNG TIN CHO TỪNG NGUỒN (MAX ARTICLES)]:
      // Nếu category.maxArticles > 0, chỉ giữ lại số bài tối đa theo cấu hình Admin
      if (category.maxArticles > 0 && articles.length > category.maxArticles) {
        articles = articles.take(category.maxArticles).toList();
      }

      _cache[category.id] = (now, articles);
      return articles;
    } catch (e) {
      // Circuit-breaker / Graceful Degradation: return stale cache if available on network failure
      if (cached != null && cached.$2.isNotEmpty) {
        return cached.$2;
      }
      rethrow;
    }
  }

  Article _parseRssItem(XmlElement item, NewsCategory category) {
    DateTime? pub;
    final pubStr = item.getElement('pubDate')?.innerText;
    if (pubStr != null && pubStr.trim().isNotEmpty) {
      try {
        pub = HttpDateParser.parse(pubStr);
      } catch (_) {}
    }

    DateTime? expires;
    if (category.retentionDays > 0) {
      final baseDate = pub ?? DateTime.now();
      expires = baseDate.add(Duration(days: category.retentionDays));
    }

    return Article.fromRssItem(
      title: item.getElement('title')?.innerText ?? '',
      link: item.getElement('link')?.innerText ?? '',
      description: item.getElement('description')?.innerText ?? '',
      source: category.source,
      publishedAt: pub,
      expiresAt: expires,
      category: category.label,
    );
  }

  void clearCache() {
    _cache.clear();
  }
}

/// Parser cho pubDate dạng RFC822 của RSS - Refactored for low cognitive complexity
class HttpDateParser {
  static const List<String> _datePatterns = [
    'EEE, dd MMM yyyy HH:mm:ss Z',
    'EEE, dd MMM yyyy HH:mm:ss zzz',
    'dd MMM yyyy HH:mm:ss Z',
  ];

  static DateTime parse(String input) {
    final cleaned = input.trim().replaceAll(' GMT', ' +0000');

    for (final pattern in _datePatterns) {
      try {
        return DateFormat(pattern, 'en_US').parse(cleaned);
      } catch (_) {
        // Try next pattern
      }
    }

    final parsed = DateTime.tryParse(cleaned);
    if (parsed != null) return parsed;

    throw FormatException('Không parse được ngày RSS: $input');
  }
}
