import '../models/group.dart';
import '../models/notification.dart';
import '../services/api_service.dart';

abstract class AppApiClient {
  Future<String?> getToken();
  Future<void> setToken(String token);
  Future<void> clearToken();
  Future<Map<String, dynamic>> get(String url);
  Future<List<dynamic>> getList(String url);
  Future<Map<String, dynamic>> post(String url, {Map<String, dynamic>? body});
  Future<Map<String, dynamic>> put(String url, {Map<String, dynamic>? body});
  Future<void> delete(String url);
  Future<Map<String, dynamic>> updateProfile({String? nickname, String? bio});
  Future<List<Group>> getGroups();
  Future<Group?> createGroup(String name, String description);
  Future<bool> joinGroupByCode(String inviteCode);
  Future<List<AppNotification>> getNotifications();
  Future<void> markNotificationRead(int notificationId);
  Future<void> markAllNotificationsRead();
}

class DefaultAppApiClient implements AppApiClient {
  const DefaultAppApiClient();

  @override
  Future<void> clearToken() => ApiService.clearToken();

  @override
  Future<void> delete(String url) => ApiService.delete(url);

  @override
  Future<Map<String, dynamic>> get(String url) => ApiService.get(url);

  @override
  Future<List<dynamic>> getList(String url) => ApiService.getList(url);

  @override
  Future<List<Group>> getGroups() => ApiService.getGroups();

  @override
  Future<List<AppNotification>> getNotifications() =>
      ApiService.getNotifications();

  @override
  Future<String?> getToken() => ApiService.getToken();

  @override
  Future<bool> joinGroupByCode(String inviteCode) =>
      ApiService.joinGroupByCode(inviteCode);

  @override
  Future<void> markAllNotificationsRead() =>
      ApiService.markAllNotificationsRead();

  @override
  Future<void> markNotificationRead(int notificationId) =>
      ApiService.markNotificationRead(notificationId);

  @override
  Future<Map<String, dynamic>> post(String url, {Map<String, dynamic>? body}) =>
      ApiService.post(url, body: body);

  @override
  Future<void> setToken(String token) => ApiService.setToken(token);

  @override
  Future<Map<String, dynamic>> updateProfile({String? nickname, String? bio}) =>
      ApiService.updateProfile(nickname: nickname, bio: bio);

  @override
  Future<Map<String, dynamic>> put(String url, {Map<String, dynamic>? body}) =>
      ApiService.put(url, body: body);

  @override
  Future<Group?> createGroup(String name, String description) =>
      ApiService.createGroup(name, description);
}
