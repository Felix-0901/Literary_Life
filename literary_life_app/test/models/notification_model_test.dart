import 'package:flutter_test/flutter_test.dart';
import 'package:literary_life_app/models/notification.dart';

void main() {
  test('AppNotification parses related work id from backend payload', () {
    final notification = AppNotification.fromJson({
      'id': 7,
      'user_id': 3,
      'type': 'share',
      'title': '收到文章分享',
      'body': 'Alice 分享了文章給你',
      'related_work_id': 42,
      'is_read': false,
      'created_at': '2026-03-13T12:00:00Z',
    });

    expect(notification.id, 7);
    expect(notification.type, 'share');
    expect(notification.relatedWorkId, 42);
    expect(notification.message, contains('收到文章分享'));
  });
}
