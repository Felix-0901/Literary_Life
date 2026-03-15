class Group {
  final int id;
  final String name;
  final String description;
  final String inviteCode;
  final int creatorId;
  final DateTime createdAt;
  final String? creatorNickname;
  final int memberCount;

  Group({
    required this.id,
    required this.name,
    required this.description,
    required this.inviteCode,
    required this.creatorId,
    required this.createdAt,
    this.creatorNickname,
    this.memberCount = 1,
  });

  factory Group.fromJson(Map<String, dynamic> json) {
    return Group(
      id: json['id'],
      name: json['name'],
      description: json['description'] ?? '',
      inviteCode: json['invite_code'],
      creatorId: json['owner_id'],
      createdAt: DateTime.parse(json['created_at']),
      creatorNickname: json['creator_nickname'],
      memberCount: json['member_count'] ?? 1,
    );
  }
}
