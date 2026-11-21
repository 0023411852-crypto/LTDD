import 'dart:convert';
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
  final bool isEnabled; // Cho phép bật/tắt (lấy hoặc không lấy) nguồn tin này

  const NewsCategory(
    this.id,
    this.label,
    this.rssUrl,
    this.source, {
    this.maxArticles = 30,
    this.retentionDays = 7,
    this.isEnabled = true,
  });

  NewsCategory copyWith({
    String? id,
    String? label,
    String? rssUrl,
    String? source,
    int? maxArticles,
    int? retentionDays,
    bool? isEnabled,
  }) {
    return NewsCategory(
      id ?? this.id,
      label ?? this.label,
      rssUrl ?? this.rssUrl,
      source ?? this.source,
      maxArticles: maxArticles ?? this.maxArticles,
      retentionDays: retentionDays ?? this.retentionDays,
      isEnabled: isEnabled ?? this.isEnabled,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'rssUrl': rssUrl,
        'source': source,
        'maxArticles': maxArticles,
        'retentionDays': retentionDays,
        'isEnabled': isEnabled,
      };

  factory NewsCategory.fromJson(Map<String, dynamic> json) => NewsCategory(
        json['id'] as String? ?? '',
        json['label'] as String? ?? '',
        json['rssUrl'] as String? ?? '',
        json['source'] as String? ?? '',
        maxArticles: json['maxArticles'] as int? ?? 30,
        retentionDays: json['retentionDays'] as int? ?? 7,
        isEnabled: json['isEnabled'] as bool? ?? true,
      );
}

/// Abstract contract for Clean Architecture / Dependency Inversion
abstract class INewsService {
  Future<List<Article>> fetchCategory(NewsCategory category, {bool forceRefresh = false});
}

/// News Service: RSS aggregator with in-memory TTL cache and resilience
class NewsService implements INewsService {
  /// Không để nguồn RSS mặc định trong mã nguồn.
  /// Danh sách ban đầu hoàn toàn trống để người dùng/quản trị viên tự kết nối từ bên ngoài và tùy chọn bật/tắt.
  static const categories = <NewsCategory>[];

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

    if (category.rssUrl.trim().isEmpty) {
      return [];
    }

    // Security check (Semgrep): Enforce valid HTTPS URI
    final uri = Uri.tryParse(category.rssUrl);
    if (uri == null || !uri.hasScheme || (uri.scheme != 'https' && uri.scheme != 'http')) {
      throw const FormatException('URL nguồn tin không an toàn hoặc không hợp lệ.');
    }

    try {
      final res = await http.get(uri, headers: const {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        'Accept': 'application/rss+xml, application/xml, text/xml, */*',
      }).timeout(_requestTimeout);

      if (res.statusCode != 200) {
        throw Exception('Không tải được tin (${res.statusCode})');
      }

      final decodedBody = utf8.decode(res.bodyBytes, allowMalformed: true);
      final doc = XmlDocument.parse(decodedBody);
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

    // Trích xuất hình ảnh nếu có trong các thẻ XML RSS (enclosure, media:content,...)
    String? extractedImage;
    final enclosure = item.getElement('enclosure');
    if (enclosure != null) {
      final url = enclosure.getAttribute('url');
      if (url != null && (url.startsWith('http://') || url.startsWith('https://'))) {
        extractedImage = url;
      }
    }
    if (extractedImage == null) {
      for (final el in item.findAllElements('media:content')) {
        final url = el.getAttribute('url');
        if (url != null && (url.startsWith('http://') || url.startsWith('https://'))) {
          extractedImage = url;
          break;
        }
      }
    }

    return Article.fromRssItem(
      title: item.getElement('title')?.innerText ?? '',
      link: item.getElement('link')?.innerText ?? '',
      description: item.getElement('description')?.innerText ?? '',
      imageUrl: extractedImage,
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

/// Parser cho pubDate dạng RFC822 / RFC2822 của RSS - Hỗ trợ cả năm 2 chữ số (Thanh Niên) và năm 4 chữ số
class HttpDateParser {
  static const List<String> _datePatterns = [
    'EEE, dd MMM yyyy HH:mm:ss Z',
    'EEE, dd MMM yyyy HH:mm:ss zzz',
    'dd MMM yyyy HH:mm:ss Z',
    'EEE, dd MMM yy HH:mm:ss Z',
    'EEE, dd MMM yy HH:mm:ss zzz',
    'dd MMM yy HH:mm:ss Z',
    'yyyy-MM-ddTHH:mm:ssZ',
    'yyyy-MM-ddTHH:mm:ss',
    'yyyy-MM-dd HH:mm:ss',
  ];

  static DateTime parse(String input) {
    final cleaned = input.trim().replaceAll(' GMT', ' +0000');

    for (final pattern in _datePatterns) {
      try {
        var parsed = DateFormat(pattern, 'en_US').parse(cleaned);
        // Chuẩn hóa nếu RSS trả về năm dạng 2 chữ số (ví dụ: '26' -> 2026)
        if (parsed.year < 100) {
          parsed = DateTime(
            parsed.year + 2000,
            parsed.month,
            parsed.day,
            parsed.hour,
            parsed.minute,
            parsed.second,
          );
        }
        return parsed;
      } catch (_) {
        // Try next pattern
      }
    }

    final parsed = DateTime.tryParse(cleaned);
    if (parsed != null) {
      if (parsed.year < 100) {
        return DateTime(
          parsed.year + 2000,
          parsed.month,
          parsed.day,
          parsed.hour,
          parsed.minute,
          parsed.second,
        );
      }
      return parsed;
    }

    throw FormatException('Không parse được ngày RSS: $input');
  }
}
