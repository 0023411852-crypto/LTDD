import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:xml/xml.dart';
import '../models/article.dart';

class NewsCategory {
  final String id;
  final String label;
  final String rssUrl;
  final String source;
  const NewsCategory(this.id, this.label, this.rssUrl, this.source);
}

/// Nguồn tin: RSS chính thức của các báo Việt Nam - miễn phí, không cần API key
class NewsService {
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

  Future<List<Article>> fetchCategory(NewsCategory category) async {
    final res = await http
        .get(Uri.parse(category.rssUrl))
        .timeout(const Duration(seconds: 15));
    if (res.statusCode != 200) {
      throw Exception('Không tải được tin (${res.statusCode})');
    }
    final doc = XmlDocument.parse(res.body);
    final items = doc.findAllElements('item');
    return items
        .map((item) {
          DateTime? pub;
          final pubStr = item.getElement('pubDate')?.innerText;
          if (pubStr != null) {
            try {
              pub = HttpDateParser.parse(pubStr);
            } catch (_) {}
          }
          return Article.fromRssItem(
            title: item.getElement('title')?.innerText ?? '',
            link: item.getElement('link')?.innerText ?? '',
            description: item.getElement('description')?.innerText ?? '',
            source: category.source,
            publishedAt: pub,
          );
        })
        .where((a) => a.title.isNotEmpty && a.link.isNotEmpty)
        .toList();
  }
}

/// Parser cho pubDate dạng RFC822 của RSS, ví dụ: Sat, 14 Nov 2026 07:30:00 +0700
class HttpDateParser {
  static DateTime parse(String input) {
    final cleaned = input.trim().replaceAll(' GMT', ' +0000');
    for (final pattern in [
      'EEE, dd MMM yyyy HH:mm:ss Z',
      'EEE, dd MMM yyyy HH:mm:ss zzz',
      'dd MMM yyyy HH:mm:ss Z',
    ]) {
      try {
        return DateFormat(pattern, 'en_US').parse(cleaned);
      } catch (_) {}
    }
    final parsed = DateTime.tryParse(cleaned);
    if (parsed != null) return parsed;
    throw FormatException('Không parse được ngày RSS: $input');
  }
}
