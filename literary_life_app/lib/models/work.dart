class LiteraryWork {
  final int id;
  final int userId;
  final int? cycleId;
  final String title;
  final String genre;
  final String content;
  final bool isPublished;
  final String visibility;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? authorNickname;
  final int responseCount;

  LiteraryWork({
    required this.id,
    required this.userId,
    this.cycleId,
    required this.title,
    this.genre = '散文',
    required this.content,
    this.isPublished = false,
    this.visibility = 'private',
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
      title: json['title'],
      genre: json['genre'] ?? '散文',
      content: json['content'],
      isPublished: json['is_published'] ?? false,
      visibility: json['visibility'] ?? 'private',
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
    String? title,
    String? genre,
    String? content,
    bool? isPublished,
    String? visibility,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? authorNickname,
    int? responseCount,
  }) {
    return LiteraryWork(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      cycleId: cycleId ?? this.cycleId,
      title: title ?? this.title,
      genre: genre ?? this.genre,
      content: content ?? this.content,
      isPublished: isPublished ?? this.isPublished,
      visibility: visibility ?? this.visibility,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      authorNickname: authorNickname ?? this.authorNickname,
      responseCount: responseCount ?? this.responseCount,
    );
  }
}
