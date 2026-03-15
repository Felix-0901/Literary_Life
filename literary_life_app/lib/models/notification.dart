class AppNotification {
  final int id;
  final int userId;
  final String type;
  final String message;
  final int? relatedWorkId;
  final bool isRead;
  final DateTime createdAt;

  AppNotification({
    required this.id,
    required this.userId,
    required this.type,
    required this.message,
    this.relatedWorkId,
    this.isRead = false,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    final title = json['title']?.toString().trim() ?? '';
    final body = json['body']?.toString().trim() ?? '';
    final message = json['message']?.toString().trim();

    return AppNotification(
      id: json['id'],
      userId: json['user_id'],
      type: json['type'] ?? '',
      message: message?.isNotEmpty == true
          ? message!
          : [title, body].where((value) => value.isNotEmpty).join('\n'),
      relatedWorkId: json['related_work_id'],
      isRead: json['is_read'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
