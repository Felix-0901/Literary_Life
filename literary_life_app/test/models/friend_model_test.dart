import 'package:flutter_test/flutter_test.dart';
import 'package:literary_life_app/models/friend.dart';

void main() {
  test('Friend parses backend requester/addressee payload', () {
    final friend = Friend.fromJson({
      'id': 12,
      'requester_id': 3,
      'addressee_id': 9,
      'status': 'pending',
      'created_at': '2026-03-13T12:00:00Z',
      'friend_nickname': 'Alice',
    });

    expect(friend.id, 12);
    expect(friend.requesterId, 3);
    expect(friend.addresseeId, 9);
    expect(friend.userId, 3);
    expect(friend.friendId, 9);
    expect(friend.friendNickname, 'Alice');
  });
}
