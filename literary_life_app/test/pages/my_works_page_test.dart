import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:literary_life_app/pages/my_works_page.dart';
import 'package:literary_life_app/providers/auth_provider.dart';
import 'package:literary_life_app/providers/notification_provider.dart';
import 'package:literary_life_app/providers/work_provider.dart';
import 'package:provider/provider.dart';

import '../support/fake_app_api_client.dart';

void main() {
  Map<String, dynamic> buildWork({required bool isPublished}) {
    return <String, dynamic>{
      'id': 1,
      'user_id': 1,
      'cycle_id': null,
      'title': '測試作品',
      'genre': '散文',
      'content': '內容內容內容',
      'is_published': isPublished,
      'visibility': isPublished ? 'public' : 'private',
      'created_at': DateTime(2026).toIso8601String(),
      'updated_at': DateTime(2026).toIso8601String(),
      'author_nickname': 'Felix',
      'response_count': 0,
    };
  }

  testWidgets('share action opens the work share sheet', (tester) async {
    final workProvider = WorkProvider(
      apiClient: FakeAppApiClient(
        getListHandler: (url) async => <Map<String, dynamic>>[
          buildWork(isPublished: true),
        ],
      ),
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider.value(value: workProvider),
          ChangeNotifierProvider(
            create: (_) => NotificationProvider(apiClient: FakeAppApiClient()),
          ),
        ],
        child: const MaterialApp(home: MyWorksPage()),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.text('分享'));
    await tester.pumpAndSettle();

    expect(find.text('分享「測試作品」'), findsOneWidget);
  });

  testWidgets('publish action turns into unpublish without changing layout', (
    tester,
  ) async {
    final workProvider = WorkProvider(
      apiClient: FakeAppApiClient(
        getListHandler: (url) async => <Map<String, dynamic>>[
          buildWork(isPublished: false),
        ],
        postHandler: (url, {body}) async => buildWork(isPublished: true),
      ),
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider.value(value: workProvider),
          ChangeNotifierProvider(
            create: (_) => NotificationProvider(apiClient: FakeAppApiClient()),
          ),
        ],
        child: const MaterialApp(home: MyWorksPage()),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('發布'), findsOneWidget);

    await tester.tap(find.text('發布'));
    await tester.pumpAndSettle();

    expect(find.text('取消發布'), findsOneWidget);
    expect(find.text('分享'), findsOneWidget);
  });
}
