class LiteraryResponse {
  final int id;
  final int workId;
  final int userId;
  final String content;
  final DateTime createdAt;
  final String? authorNickname;

  LiteraryResponse({
    required this.id,
    required this.workId,
    required this.userId,
    required this.content,
    required this.createdAt,
    this.authorNickname,
  });

  factory LiteraryResponse.fromJson(Map<String, dynamic> json) {
    return LiteraryResponse(
      id: json['id'],
      workId: json['work_id'],
      userId: json['user_id'],
      content: json['content'],
      createdAt: DateTime.parse(json['created_at']),
      authorNickname: json['author_nickname'],
    );
  }
}
