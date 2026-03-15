class User {
  final int id;
  final String nickname;
  final String email;
  final String userCode;
  final String bio;
  final DateTime createdAt;

  User({
    required this.id,
    required this.nickname,
    required this.email,
    required this.userCode,
    this.bio = '',
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      nickname: json['nickname'],
      email: json['email'],
      userCode: json['user_code'] ?? '000000',
      bio: json['bio'] ?? '',
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
