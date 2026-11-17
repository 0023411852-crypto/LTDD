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
    return Article(
      id: json['id'] as String?,
      title: json['title'] as String? ?? '',
      link: json['link'] as String? ?? '',
      description: json['description'] as String? ?? '',
      imageUrl: json['imageUrl'] as String?,
      source: json['source'] as String? ?? '',
      publishedAt: json['publishedAt'] != null
          ? DateTime.tryParse(json['publishedAt'] as String)
          : null,
      category: json['category'] as String? ?? 'Tin tức',
      tags: (json['tags'] as List<dynamic>? ?? const []).cast<String>(),
      inlineImageUrls: (json['inlineImageUrls'] as List<dynamic>? ?? const [])
          .cast<String>(),
    );
  }

  /// Parse 1 item trong RSS feed (VnExpress, Tuổi Trẻ, Thanh Niên...)
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
    // VnExpress để ảnh trong thẻ <description> dạng HTML: <a><img src="..."></a>Mô tả
    String? img;
    final imgMatch = RegExp(r'src="([^"]+)"').firstMatch(description);
    if (imgMatch != null) img = imgMatch.group(1);

    final cleanDesc = description
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&nbsp;', ' ')
        .trim();

    return Article(
      title: title.trim(),
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
}
