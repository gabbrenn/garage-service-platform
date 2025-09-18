class AppNotification {
  final int id;
  final String title;
  final String message;
  final bool read;
  final DateTime createdAt;

  AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.read,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: (json['id'] ?? 0) as int,
      title: json['title']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      read: json['read'] == true,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  AppNotification copyWith({bool? read}) => AppNotification(
    id: id,
    title: title,
    message: message,
    read: read ?? this.read,
    createdAt: createdAt,
  );
}
