class Inspiration {
  final int id;
  final int userId;
  final int? cycleId;
  final DateTime eventTime;
  final String location;
  final String objectOrEvent;
  final String detailText;
  final String feeling;
  final String keywords;
  final DateTime createdAt;

  Inspiration({
    required this.id,
    required this.userId,
    this.cycleId,
    required this.eventTime,
    this.location = '',
    this.objectOrEvent = '',
    this.detailText = '',
    this.feeling = '',
    this.keywords = '',
    required this.createdAt,
  });

  factory Inspiration.fromJson(Map<String, dynamic> json) {
    return Inspiration(
      id: json['id'],
      userId: json['user_id'],
      cycleId: json['cycle_id'],
      eventTime: DateTime.parse(json['event_time']),
      location: json['location'] ?? '',
      objectOrEvent: json['object_or_event'] ?? '',
      detailText: json['detail_text'] ?? '',
      feeling: json['feeling'] ?? '',
      keywords: json['keywords'] ?? '',
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toCreateJson({int? cycleId}) {
    return {
      if (cycleId != null) 'cycle_id': cycleId,
      'event_time': eventTime.toIso8601String(),
      'location': location,
      'object_or_event': objectOrEvent,
      'detail_text': detailText,
      'feeling': feeling,
      'keywords': keywords,
    };
  }
}
