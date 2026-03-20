class Announcement {
  final int id;
  final String title;
  final String content;
  final bool isActive;
  final DateTime? startsAt;
  final DateTime? endsAt;
  final DateTime? updatedAt;

  const Announcement({
    required this.id,
    required this.title,
    required this.content,
    required this.isActive,
    required this.startsAt,
    required this.endsAt,
    required this.updatedAt,
  });

  factory Announcement.fromDirectusJson(Map<String, dynamic> json) {
    return Announcement(
      id: json['id'] is int ? json['id'] as int : int.parse('${json['id']}'),
      title: (json['title'] ?? '').toString(),
      content: (json['content'] ?? '').toString(),
      isActive: json['is_active'] == true,
      startsAt: _parseDateTime(json['starts_at']),
      endsAt: _parseDateTime(json['ends_at']),
      updatedAt: _parseDateTime(json['date_updated'] ?? json['date_created']),
    );
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    final s = value.toString().trim();
    if (s.isEmpty) return null;
    return DateTime.tryParse(s);
  }

  String get signature {
    final stamp = updatedAt?.toUtc().toIso8601String() ?? '';
    return '$id@$stamp';
  }
}

