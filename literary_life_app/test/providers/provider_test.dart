import 'package:flutter_test/flutter_test.dart';
import 'package:literary_life_app/config/api_config.dart';
import 'package:literary_life_app/models/group.dart';
import 'package:literary_life_app/models/notification.dart';
import 'package:literary_life_app/providers/auth_provider.dart';
import 'package:literary_life_app/providers/group_provider.dart';
import 'package:literary_life_app/providers/notification_provider.dart';
import 'package:literary_life_app/providers/work_provider.dart';

import '../support/fake_app_api_client.dart';

void main() {
  test('AuthProvider logs in and stores user data', () async {
    final client = FakeAppApiClient(
      postHandler: (url, {body}) async => <String, dynamic>{
        'access_token': 'token-123',
        'user': <String, dynamic>{
          'id': 1,
          'nickname': 'Felix',
          'email': 'felix@example.com',
          'user_code': '123456',
          'bio': '',
          'created_at': DateTime(2026).toIso8601String(),
        },
      },
    );
    final provider = AuthProvider(apiClient: client);

    final success = await provider.login('felix@example.com', 'secret123');

    expect(success, isTrue);
    expect(provider.isLoggedIn, isTrue);
    expect(provider.user?.nickname, 'Felix');
    expect(client.token, 'token-123');
  });

  test(
    'WorkProvider exposes fetch errors instead of swallowing them',
    () async {
      final client = FakeAppApiClient(
        getListHandler: (url) async => throw Exception('network down'),
      );
      final provider = WorkProvider(apiClient: client);

      await provider.fetchWorks();

      expect(provider.error, contains('network down'));
      expect(provider.works, isEmpty);
    },
  );

  test('GroupProvider adds newly created group to the local cache', () async {
    final provider = GroupProvider(
      apiClient: FakeAppApiClient(
        createGroupHandler: (name, description) async => Group(
          id: 1,
          name: name,
          description: description,
          inviteCode: 'ABC123',
          creatorId: 1,
          createdAt: DateTime(2026),
          memberCount: 1,
        ),
      ),
    );

    final success = await provider.createGroup('Night Writers', 'poetry');

    expect(success, isTrue);
    expect(provider.groups.single.name, 'Night Writers');
  });

  test(
    'NotificationProvider marks all notifications as read locally',
    () async {
      final provider = NotificationProvider(
        apiClient: FakeAppApiClient(
          notificationsHandler: () async => <AppNotification>[
            AppNotification(
              id: 1,
              userId: 1,
              type: 'response',
              message: 'new response',
              isRead: false,
              createdAt: DateTime(2026),
            ),
          ],
        ),
      );

      await provider.fetchNotifications();
      await provider.markAllRead();

      expect(provider.unreadCount, 0);
      expect(provider.notifications.single.isRead, isTrue);
    },
  );

  test('WorkProvider publish updates the cached work immediately', () async {
    const publishedWork = <String, dynamic>{
      'id': 1,
      'user_id': 1,
      'cycle_id': null,
      'title': 'Draft',
      'genre': '散文',
      'content': 'content',
      'is_published': true,
      'visibility': 'public',
      'created_at': '2026-01-01T00:00:00.000',
      'updated_at': '2026-01-01T00:00:00.000',
      'author_nickname': 'Felix',
      'response_count': 0,
    };
    final client = FakeAppApiClient(
      getListHandler: (url) async => <Map<String, dynamic>>[
        <String, dynamic>{
          'id': 1,
          'user_id': 1,
          'cycle_id': null,
          'title': 'Draft',
          'genre': '散文',
          'content': 'content',
          'is_published': false,
          'visibility': 'private',
          'created_at': DateTime(2026).toIso8601String(),
          'updated_at': DateTime(2026).toIso8601String(),
          'author_nickname': 'Felix',
          'response_count': 0,
        },
      ],
      postHandler: (url, {body}) async {
        expect(url, '${ApiConfig.worksUrl}/1/publish');
        return publishedWork;
      },
    );
    final provider = WorkProvider(apiClient: client);

    await provider.fetchWorks();
    final work = await provider.publishWork(1);

    expect(work, isNotNull);
    expect(provider.works.single.isPublished, isTrue);
  });

  test('WorkProvider unpublish updates public and private caches', () async {
    const draftWork = <String, dynamic>{
      'id': 1,
      'user_id': 1,
      'cycle_id': null,
      'title': 'Draft',
      'genre': '散文',
      'content': 'content',
      'is_published': false,
      'visibility': 'private',
      'created_at': '2026-01-01T00:00:00.000',
      'updated_at': '2026-01-01T00:00:00.000',
      'author_nickname': 'Felix',
      'response_count': 0,
    };
    var listCalls = 0;
    final client = FakeAppApiClient(
      getListHandler: (url) async {
        listCalls += 1;
        return <Map<String, dynamic>>[
          <String, dynamic>{
            ...draftWork,
            'is_published': true,
            'visibility': 'public',
          },
        ];
      },
      postHandler: (url, {body}) async {
        expect(url, '${ApiConfig.worksUrl}/1/unpublish');
        return draftWork;
      },
    );
    final provider = WorkProvider(apiClient: client);

    await provider.fetchWorks();
    await provider.fetchPublicWorks();

    final work = await provider.unpublishWork(1);

    expect(work, isNotNull);
    expect(provider.works.single.isPublished, isFalse);
    expect(provider.publicWorks, isEmpty);
    expect(listCalls, 2);
  });
}
