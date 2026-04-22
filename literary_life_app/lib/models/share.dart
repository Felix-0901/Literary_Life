import 'work.dart';

class WorkShare {
  final int id;
  final int workId;
  final String targetType;
  final int? targetId;
  final String message;
  final DateTime createdAt;

  WorkShare({
    required this.id,
    required this.workId,
    required this.targetType,
    this.targetId,
    this.message = '',
    required this.createdAt,
  });

  factory WorkShare.fromJson(Map<String, dynamic> json) {
    return WorkShare(
      id: json['id'],
      workId: json['work_id'],
      targetType: json['target_type'],
      targetId: json['target_id'],
      message: json['message'] ?? '',
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class ShareFeedItem {
  final int id;
  final int workId;
  final String targetType;
  final int? targetId;
  final String message;
  final DateTime createdAt;
  final String workTitle;
  final String workContent;
  final String workGenre;
  final String workType;
  final bool workIsPublished;
  final int authorId;
  final String authorNickname;
  final int responseCount;

  ShareFeedItem({
    required this.id,
    required this.workId,
    required this.targetType,
    this.targetId,
    this.message = '',
    required this.createdAt,
    required this.workTitle,
    required this.workContent,
    required this.workGenre,
    this.workType = 'literary',
    required this.workIsPublished,
    required this.authorId,
    required this.authorNickname,
    this.responseCount = 0,
  });

  factory ShareFeedItem.fromJson(Map<String, dynamic> json) {
    return ShareFeedItem(
      id: json['id'],
      workId: json['work_id'],
      targetType: json['target_type'],
      targetId: json['target_id'],
      message: json['message'] ?? '',
      createdAt: DateTime.parse(json['created_at']),
      workTitle: json['work_title'],
      workContent: json['work_content'],
      workGenre: json['work_genre'],
      workType: json['work_type'] ?? 'literary',
      workIsPublished: json['work_is_published'],
      authorId: json['author_id'],
      authorNickname: json['author_nickname'],
      responseCount: json['response_count'] ?? 0,
    );
  }

  LiteraryWork toLiteraryWork() {
    return LiteraryWork(
      id: workId,
      userId: authorId,
      title: workTitle,
      workType: workType,
      genre: workGenre,
      content: workContent,
      visibility: workIsPublished ? 'public' : 'private',
      isPublished: workIsPublished,
      createdAt: createdAt,
      updatedAt: createdAt,
      authorNickname: authorNickname,
      responseCount: responseCount,
    );
  }
}
