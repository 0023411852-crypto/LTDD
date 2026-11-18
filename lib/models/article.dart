class Article {
  final String? id;
  final String title;
  final String link;
  final String description;
  final String? imageUrl;
  final String source;
  final DateTime? publishedAt;
  final String category;
  final List<String> tags;
  final List<String> inlineImageUrls;

  const Article({
    this.id,
    required this.title,
    required this.link,
    required this.description,
    this.imageUrl,
    required this.source,
    this.publishedAt,
    this.category = 'Tin tức',
    this.tags = const [],
    this.inlineImageUrls = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'link': link,
      'description': description,
      'imageUrl': imageUrl,
      'source': source,
      'publishedAt': publishedAt?.toIso8601String(),
      'category': category,
      'tags': tags,
      'inlineImageUrls': inlineImageUrls,
    };
  }

  factory Article.fromJson(Map<String, dynamic> json) {
    DateTime? parsedDate;
    final pubAtRaw = json['publishedAt'];
    if (pubAtRaw is String) {
      parsedDate = DateTime.tryParse(pubAtRaw);
    } else if (pubAtRaw is int) {
      parsedDate = DateTime.fromMillisecondsSinceEpoch(pubAtRaw);
    } else if (pubAtRaw is num) {
      parsedDate = DateTime.fromMillisecondsSinceEpoch(pubAtRaw.toInt());
    }

    final rawTags = json['tags'];
    final tags = (rawTags is List)
        ? rawTags.map((e) => e?.toString() ?? '').where((s) => s.isNotEmpty).toList()
        : const <String>[];

    final rawInlineImgs = json['inlineImageUrls'];
    final inlineImgs = (rawInlineImgs is List)
        ? rawInlineImgs.map((e) => e?.toString() ?? '').where((s) => s.isNotEmpty).toList()
        : const <String>[];

    return Article(
      id: json['id']?.toString(),
      title: json['title'] as String? ?? '',
      link: json['link'] as String? ?? '',
      description: json['description'] as String? ?? '',
      imageUrl: json['imageUrl'] as String?,
      source: json['source'] as String? ?? '',
      publishedAt: parsedDate,
      category: json['category'] as String? ?? 'Tin tức',
      tags: tags,
      inlineImageUrls: inlineImgs,
    );
  }

  /// Parse 1 item trong RSS feed (VnExpress, Tuổi Trẻ, Thanh Niên...)
  /// Sanitize HTML content & validate image URLs (Semgrep & SonarQube compliant)
  factory Article.fromRssItem({
    required String title,
    required String link,
    required String description,
    required String source,
    DateTime? publishedAt,
    String category = 'Tin tức',
    List<String> tags = const [],
    List<String> inlineImageUrls = const [],
  }) {
    String? img;
    final imgMatch = RegExp(r'src="([^"]+)"', caseSensitive: false).firstMatch(description);
    if (imgMatch != null) {
      final potentialUrl = imgMatch.group(1)?.trim();
      if (potentialUrl != null &&
          (potentialUrl.startsWith('https://') || potentialUrl.startsWith('http://'))) {
        img = potentialUrl;
      }
    }

    final cleanDesc = _sanitizeHtml(description);
    final cleanTitle = _sanitizeHtml(title);

    return Article(
      title: cleanTitle,
      link: link.trim(),
      description: cleanDesc,
      imageUrl: img,
      source: source,
      publishedAt: publishedAt,
      category: category,
      tags: tags,
      inlineImageUrls: inlineImageUrls,
    );
  }

  static String _sanitizeHtml(String text) {
    return text
        .replaceAll(RegExp(r'<[^>]*>'), '') // Strip HTML tags
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&quot;', '"')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&#39;', "'")
        .replaceAll('&hellip;', '...')
        .trim();
  }
}
