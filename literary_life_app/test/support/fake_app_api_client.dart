import 'package:literary_life_app/models/group.dart';
import 'package:literary_life_app/models/notification.dart';
import 'package:literary_life_app/services/app_api_client.dart';

typedef MapHandler =
    Future<Map<String, dynamic>> Function(
      String url, {
      Map<String, dynamic>? body,
    });
typedef ListHandler = Future<List<dynamic>> Function(String url);

class FakeAppApiClient implements AppApiClient {
  FakeAppApiClient({
    this.token,
    MapHandler? getHandler,
    ListHandler? getListHandler,
    MapHandler? postHandler,
    MapHandler? putHandler,
    Future<void> Function(String url)? deleteHandler,
    Future<List<Group>> Function()? groupsHandler,
    Future<Group?> Function(String name, String description)?
    createGroupHandler,
    Future<bool> Function(String inviteCode)? joinGroupHandler,
    Future<List<AppNotification>> Function()? notificationsHandler,
    Future<void> Function(int notificationId)? markNotificationReadHandler,
    Future<void> Function()? markAllNotificationsReadHandler,
    Future<Map<String, dynamic>> Function({String? nickname, String? bio})?
    updateProfileHandler,
  }) : _getHandler = getHandler,
       _getListHandler = getListHandler,
       _postHandler = postHandler,
       _putHandler = putHandler,
       _deleteHandler = deleteHandler,
       _groupsHandler = groupsHandler,
       _createGroupHandler = createGroupHandler,
       _joinGroupHandler = joinGroupHandler,
       _notificationsHandler = notificationsHandler,
       _markNotificationReadHandler = markNotificationReadHandler,
       _markAllNotificationsReadHandler = markAllNotificationsReadHandler,
       _updateProfileHandler = updateProfileHandler;

  String? token;
  final MapHandler? _getHandler;
  final ListHandler? _getListHandler;
  final MapHandler? _postHandler;
  final MapHandler? _putHandler;
  final Future<void> Function(String url)? _deleteHandler;
  final Future<List<Group>> Function()? _groupsHandler;
  final Future<Group?> Function(String name, String description)?
  _createGroupHandler;
  final Future<bool> Function(String inviteCode)? _joinGroupHandler;
  final Future<List<AppNotification>> Function()? _notificationsHandler;
  final Future<void> Function(int notificationId)? _markNotificationReadHandler;
  final Future<void> Function()? _markAllNotificationsReadHandler;
  final Future<Map<String, dynamic>> Function({String? nickname, String? bio})?
  _updateProfileHandler;

  @override
  Future<void> clearToken() async {
    token = null;
  }

  @override
  Future<Group?> createGroup(String name, String description) async {
    return _createGroupHandler?.call(name, description);
  }

  @override
  Future<Map<String, dynamic>> get(String url) async {
    if (_getHandler == null) return <String, dynamic>{};
    return _getHandler(url);
  }

  @override
  Future<List<dynamic>> getList(String url) async {
    if (_getListHandler == null) return <dynamic>[];
    return _getListHandler(url);
  }

  @override
  Future<List<Group>> getGroups() async {
    if (_groupsHandler == null) return <Group>[];
    return _groupsHandler();
  }

  @override
  Future<List<AppNotification>> getNotifications() async {
    if (_notificationsHandler == null) return <AppNotification>[];
    return _notificationsHandler();
  }

  @override
  Future<String?> getToken() async => token;

  @override
  Future<bool> joinGroupByCode(String inviteCode) async {
    return _joinGroupHandler?.call(inviteCode) ?? false;
  }

  @override
  Future<void> markAllNotificationsRead() async {
    if (_markAllNotificationsReadHandler != null) {
      await _markAllNotificationsReadHandler();
    }
  }

  @override
  Future<void> markNotificationRead(int notificationId) async {
    if (_markNotificationReadHandler != null) {
      await _markNotificationReadHandler(notificationId);
    }
  }

  @override
  Future<Map<String, dynamic>> post(
    String url, {
    Map<String, dynamic>? body,
  }) async {
    if (_postHandler == null) return <String, dynamic>{};
    return _postHandler(url, body: body);
  }

  @override
  Future<Map<String, dynamic>> put(
    String url, {
    Map<String, dynamic>? body,
  }) async {
    if (_putHandler == null) return <String, dynamic>{};
    return _putHandler(url, body: body);
  }

  @override
  Future<void> delete(String url) async {
    if (_deleteHandler != null) {
      await _deleteHandler(url);
    }
  }

  @override
  Future<void> setToken(String token) async {
    this.token = token;
  }

  @override
  Future<Map<String, dynamic>> updateProfile({
    String? nickname,
    String? bio,
  }) async {
    if (_updateProfileHandler == null) return <String, dynamic>{};
    return _updateProfileHandler(nickname: nickname, bio: bio);
  }
}
