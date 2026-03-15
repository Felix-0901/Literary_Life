class Friend {
  final int id;
  final int userId;
  final int friendId;
  final int requesterId;
  final int addresseeId;
  final String status;
  final DateTime createdAt;
  final String? friendNickname;

  Friend({
    required this.id,
    required this.userId,
    required this.friendId,
    required this.requesterId,
    required this.addresseeId,
    required this.status,
    required this.createdAt,
    this.friendNickname,
  });

  factory Friend.fromJson(Map<String, dynamic> json) {
    final requesterId = json['requester_id'] ?? json['user_id'];
    final addresseeId = json['addressee_id'] ?? json['friend_id'];
    return Friend(
      id: json['id'],
      userId: json['user_id'] ?? requesterId,
      friendId: json['friend_id'] ?? addresseeId,
      requesterId: requesterId,
      addresseeId: addresseeId,
      status: json['status'],
      createdAt: DateTime.parse(json['created_at']),
      friendNickname: json['friend_nickname'],
    );
  }
}

class FriendSearchUser {
  final int id;
  final String nickname;
  final String userCode;
  final String bio;

  FriendSearchUser({
    required this.id,
    required this.nickname,
    required this.userCode,
    required this.bio,
  });

  factory FriendSearchUser.fromJson(Map<String, dynamic> json) {
    return FriendSearchUser(
      id: json['id'],
      nickname: json['nickname'],
      userCode: json['user_code'] ?? '000000',
      bio: json['bio'] ?? '',
    );
  }
}
