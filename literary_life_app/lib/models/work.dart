class LiteraryWork {
  final int id;
  final int userId;
  final int? cycleId;
  final int? completedCycleId;
  final String title;
  final String workType;
  final String genre;
  final String content;
  final bool isPublished;
  final String visibility;
  final String hashtags;
  final DateTime? completedCycleStartDate;
  final DateTime? completedCycleEndDate;
  final int? completedCycleType;
  final String? completedCycleStatus;
  final List<int> inspirationIds;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? authorNickname;
  final int responseCount;

  LiteraryWork({
    required this.id,
    required this.userId,
    this.cycleId,
    this.completedCycleId,
    required this.title,
    this.workType = 'literary',
    this.genre = '散文',
    required this.content,
    this.isPublished = false,
    this.visibility = 'private',
    this.hashtags = '',
    this.completedCycleStartDate,
    this.completedCycleEndDate,
    this.completedCycleType,
    this.completedCycleStatus,
    this.inspirationIds = const [],
    required this.createdAt,
    required this.updatedAt,
    this.authorNickname,
    this.responseCount = 0,
  });

  factory LiteraryWork.fromJson(Map<String, dynamic> json) {
    return LiteraryWork(
      id: json['id'],
      userId: json['user_id'],
      cycleId: json['cycle_id'],
      completedCycleId: json['completed_cycle_id'],
      title: json['title'],
      workType: json['work_type'] ?? 'literary',
      genre: json['genre'] ?? '散文',
      content: json['content'],
      isPublished: json['is_published'] ?? false,
      visibility: json['visibility'] ?? 'private',
      hashtags: json['hashtags'] ?? '',
      completedCycleStartDate: json['completed_cycle_start_date'] == null
          ? null
          : DateTime.parse(json['completed_cycle_start_date']),
      completedCycleEndDate: json['completed_cycle_end_date'] == null
          ? null
          : DateTime.parse(json['completed_cycle_end_date']),
      completedCycleType: json['completed_cycle_type'],
      completedCycleStatus: json['completed_cycle_status'],
      inspirationIds: (json['inspiration_ids'] as List<dynamic>?)
              ?.map((e) => e as int)
              .toList() ??
          const [],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      authorNickname: json['author_nickname'],
      responseCount: json['response_count'] ?? 0,
    );
  }

  LiteraryWork copyWith({
    int? id,
    int? userId,
    int? cycleId,
    int? completedCycleId,
    String? title,
    String? workType,
    String? genre,
    String? content,
    bool? isPublished,
    String? visibility,
    String? hashtags,
    DateTime? completedCycleStartDate,
    DateTime? completedCycleEndDate,
    int? completedCycleType,
    String? completedCycleStatus,
    List<int>? inspirationIds,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? authorNickname,
    int? responseCount,
  }) {
    return LiteraryWork(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      cycleId: cycleId ?? this.cycleId,
      completedCycleId: completedCycleId ?? this.completedCycleId,
      title: title ?? this.title,
      workType: workType ?? this.workType,
      genre: genre ?? this.genre,
      content: content ?? this.content,
      isPublished: isPublished ?? this.isPublished,
      visibility: visibility ?? this.visibility,
      hashtags: hashtags ?? this.hashtags,
      completedCycleStartDate:
          completedCycleStartDate ?? this.completedCycleStartDate,
      completedCycleEndDate: completedCycleEndDate ?? this.completedCycleEndDate,
      completedCycleType: completedCycleType ?? this.completedCycleType,
      completedCycleStatus: completedCycleStatus ?? this.completedCycleStatus,
      inspirationIds: inspirationIds ?? this.inspirationIds,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      authorNickname: authorNickname ?? this.authorNickname,
      responseCount: responseCount ?? this.responseCount,
    );
  }
}
