class AppNotification {
  final String id;
  final String title;
  final String body;
  final String type;
  final DateTime createdAt;
  final bool isRead;

  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.createdAt,
    required this.isRead,
  });

  factory AppNotification.fromJson(String id, Map<String, dynamic> json) {
    return AppNotification(
      id: id,
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      type: json['type'] as String? ?? 'system',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      isRead: json['isRead'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'body': body,
        'type': type,
        'createdAt': createdAt.toIso8601String(),
        'isRead': isRead,
      };

  AppNotification copyWith({bool? isRead}) => AppNotification(
        id: id,
        title: title,
        body: body,
        type: type,
        createdAt: createdAt,
        isRead: isRead ?? this.isRead,
      );
}
