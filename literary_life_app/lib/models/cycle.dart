class WritingCycle {
  final int id;
  final int userId;
  final int cycleType;
  final DateTime startDate;
  final DateTime endDate;
  final String status;
  final DateTime createdAt;

  WritingCycle({
    required this.id,
    required this.userId,
    required this.cycleType,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.createdAt,
  });

  factory WritingCycle.fromJson(Map<String, dynamic> json) {
    return WritingCycle(
      id: json['id'],
      userId: json['user_id'],
      cycleType: json['cycle_type'],
      startDate: DateTime.parse(json['start_date']),
      endDate: DateTime.parse(json['end_date']),
      status: json['status'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  int get daysRemaining {
    final now = DateTime.now();
    final pureEnd = DateTime(endDate.year, endDate.month, endDate.day);
    final pureNow = DateTime(now.year, now.month, now.day);
    final diff = pureEnd.difference(pureNow).inDays;
    return diff > 0 ? diff : 0;
  }

  bool get isActive => status == 'active';
}
