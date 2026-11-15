class Article {
  final String title;
  final String link;
  final String description;
  final String? imageUrl;
  final String source;
  final DateTime? publishedAt;

  const Article({
    required this.title,
    required this.link,
    required this.description,
    this.imageUrl,
    required this.source,
    this.publishedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'link': link,
      'description': description,
      'imageUrl': imageUrl,
      'source': source,
      'publishedAt': publishedAt?.toIso8601String(),
    };
  }

  factory Article.fromJson(Map<String, dynamic> json) {
    return Article(
      title: json['title'] as String? ?? '',
      link: json['link'] as String? ?? '',
      description: json['description'] as String? ?? '',
      imageUrl: json['imageUrl'] as String?,
      source: json['source'] as String? ?? '',
      publishedAt: json['publishedAt'] != null
          ? DateTime.tryParse(json['publishedAt'] as String)
          : null,
    );
  }

  /// Parse 1 item trong RSS feed (VnExpress, Tuổi Trẻ, Thanh Niên...)
  factory Article.fromRssItem({
    required String title,
    required String link,
    required String description,
    required String source,
    DateTime? publishedAt,
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
    );
  }
}
