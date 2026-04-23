import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/api_config.dart';
import '../models/inspiration.dart';
import '../models/friend.dart';
import '../models/group.dart';
import '../models/notification.dart';
import '../models/response.dart';
import '../models/share.dart';
import '../models/work.dart';
import 'maintenance_controller.dart';

class ApiService {
  static const _storage = FlutterSecureStorage();
  static String? _token;

  static Future<void> setToken(String token) async {
    _token = token;
    await _storage.write(key: 'auth_token', value: token);
  }

  static Future<String?> getToken() async {
    _token ??= await _storage.read(key: 'auth_token');
    return _token;
  }

  static Future<void> clearToken() async {
    _token = null;
    await _storage.delete(key: 'auth_token');
  }

  static Map<String, String> _headers() {
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (_token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  static Future<void> refreshMaintenanceStatus() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.maintenanceUrl}/active'),
        headers: _headers(),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (response.body.isEmpty) {
          MaintenanceController.instance.deactivate();
          return;
        }
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        if (data is Map<String, dynamic>) {
          MaintenanceController.instance.updateFromJson(data);
          return;
        }
        MaintenanceController.instance.deactivate();
        return;
      }

      if (response.statusCode == 404) {
        MaintenanceController.instance.deactivate();
        return;
      }
    } catch (_) {}
  }

  // ── Auth ──
  static Future<Map<String, dynamic>> updateProfile({
    String? nickname,
    String? bio,
  }) async {
    final body = <String, dynamic>{};
    if (nickname != null) body['nickname'] = nickname;
    if (bio != null) body['bio'] = bio;
    return await put('${ApiConfig.authUrl}/me', body: body);
  }

  // ── Inspirations ──
  static Future<Inspiration?> createInspiration({
    int? cycleId,
    required DateTime eventTime,
    String location = '',
    String objectOrEvent = '',
    String detailText = '',
    String feeling = '',
    String keywords = '',
  }) async {
    final payload = {
      if (cycleId != null) 'cycle_id': cycleId,
      'event_time': eventTime.toUtc().toIso8601String(),
      'location': location,
      'object_or_event': objectOrEvent,
      'detail_text': detailText,
      'feeling': feeling,
      'keywords': keywords,
    };
    final data = await post('${ApiConfig.inspirationsUrl}/', body: payload);
    if (data.isNotEmpty) {
      return Inspiration.fromJson(data);
    }
    return null;
  }

  static Future<Inspiration?> updateInspiration(
    int inspirationId, {
    DateTime? eventTime,
    String? location,
    String? objectOrEvent,
    String? detailText,
    String? feeling,
    String? keywords,
  }) async {
    final payload = <String, dynamic>{};
    if (eventTime != null) {
      payload['event_time'] = eventTime.toUtc().toIso8601String();
    }
    if (location != null) payload['location'] = location;
    if (objectOrEvent != null) payload['object_or_event'] = objectOrEvent;
    if (detailText != null) payload['detail_text'] = detailText;
    if (feeling != null) payload['feeling'] = feeling;
    if (keywords != null) payload['keywords'] = keywords;

    final data = await put(
      '${ApiConfig.inspirationsUrl}/$inspirationId',
      body: payload,
    );
    if (data.isNotEmpty) {
      return Inspiration.fromJson(data);
    }
    return null;
  }

  // ── Friends ──
  static Future<List<Friend>> getFriends() async {
    final data = await getList('${ApiConfig.friendsUrl}/');
    return data.map((json) => Friend.fromJson(json)).toList();
  }

  static Future<List<Friend>> getPendingFriendRequests() async {
    final data = await getList('${ApiConfig.friendsUrl}/pending');
    return data.map((json) => Friend.fromJson(json)).toList();
  }

  static Future<List<FriendSearchUser>> searchUsers(String keyword) async {
    final data = await getList('${ApiConfig.friendsUrl}/search?q=$keyword');
    return data.map((json) => FriendSearchUser.fromJson(json)).toList();
  }

  static Future<bool> requestFriend(int friendId) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/api/friends/request'),
      headers: _headers(),
      body: jsonEncode({'addressee_id': friendId}),
    );
    return response.statusCode >= 200 && response.statusCode < 300;
  }

  static Future<bool> acceptFriend(int requestId) async {
    final response = await http.put(
      Uri.parse('${ApiConfig.friendsUrl}/$requestId/accept'),
      headers: _headers(),
    );
    return response.statusCode >= 200 && response.statusCode < 300;
  }

  // ── Groups ──
  static Future<List<Group>> getGroups() async {
    final data = await getList('${ApiConfig.groupsUrl}/');
    return data.map((json) => Group.fromJson(json)).toList();
  }

  static Future<Group?> createGroup(String name, String description) async {
    final data = await post(
      '${ApiConfig.groupsUrl}/',
      body: {'name': name, 'description': description},
    );
    if (data.isNotEmpty) {
      return Group.fromJson(data);
    }
    return null;
  }

  static Future<bool> joinGroupByCode(String inviteCode) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.groupsUrl}/join'),
      headers: _headers(),
      body: jsonEncode({'invite_code': inviteCode}),
    );
    return response.statusCode >= 200 && response.statusCode < 300;
  }

  static Future<List<LiteraryWork>> getGroupWorks(int groupId) async {
    final data = await getList('${ApiConfig.groupsUrl}/$groupId/works');
    return data.map((json) => LiteraryWork.fromJson(json)).toList();
  }

  // ── Works (Publishing) ──
  static Future<LiteraryWork?> publishWork(int workId) async {
    final data = await post('${ApiConfig.baseUrl}/api/works/$workId/publish');
    if (data.isNotEmpty) {
      return LiteraryWork.fromJson(data);
    }
    return null;
  }

  static Future<LiteraryWork?> unpublishWork(int workId) async {
    final data = await post('${ApiConfig.baseUrl}/api/works/$workId/unpublish');
    if (data.isNotEmpty) {
      return LiteraryWork.fromJson(data);
    }
    return null;
  }

  static Future<LiteraryWork?> updateWork(
    int workId, {
    String? title,
    String? content,
    String? genre,
    String? visibility,
  }) async {
    final body = <String, dynamic>{};
    if (title != null) body['title'] = title;
    if (content != null) body['content'] = content;
    if (genre != null) body['genre'] = genre;
    if (visibility != null) body['visibility'] = visibility;

    final data = await put(
      '${ApiConfig.baseUrl}/api/works/$workId',
      body: body,
    );
    if (data.isNotEmpty) {
      return LiteraryWork.fromJson(data);
    }
    return null;
  }

  // ── Shares ──
  static Future<WorkShare?> shareWork({
    required int workId,
    required String targetType,
    int? targetId,
    List<int>? targetIds,
    String message = '',
  }) async {
    final data = await post(
      '${ApiConfig.sharesUrl}/',
      body: {
        'work_id': workId,
        'target_type': targetType,
        if (targetId != null) 'target_id': targetId,
        if (targetIds != null && targetIds.isNotEmpty) 'target_ids': targetIds,
        'message': message,
      },
    );
    if (data.isNotEmpty) {
      return WorkShare.fromJson(data);
    }
    return null;
  }

  static Future<List<WorkShare>> getSharedFeed() async {
    final data = await getList('${ApiConfig.sharesUrl}/feed');
    return data.map((json) => WorkShare.fromJson(json)).toList();
  }

  static Future<LiteraryWork?> getWorkById(int workId) async {
    final data = await get('${ApiConfig.baseUrl}/api/works/$workId');
    if (data.isNotEmpty) {
      return LiteraryWork.fromJson(data);
    }
    return null;
  }

  // ── Responses ──
  static Future<LiteraryResponse?> createResponse({
    required int workId,
    required String content,
  }) async {
    final data = await post(
      '${ApiConfig.responsesUrl}/',
      body: {'work_id': workId, 'content': content},
    );
    if (data.isNotEmpty) {
      return LiteraryResponse.fromJson(data);
    }
    return null;
  }

  static Future<List<LiteraryResponse>> getWorkResponses(int workId) async {
    final data = await getList('${ApiConfig.responsesUrl}/work/$workId');
    return data.map((json) => LiteraryResponse.fromJson(json)).toList();
  }

  // ── Notifications ──
  static Future<List<AppNotification>> getNotifications() async {
    final data = await getList('${ApiConfig.notificationsUrl}/');
    return data.map((json) => AppNotification.fromJson(json)).toList();
  }

  static Future<void> markNotificationRead(int notificationId) async {
    await put('${ApiConfig.notificationsUrl}/$notificationId/read');
  }

  static Future<void> markAllNotificationsRead() async {
    await put('${ApiConfig.notificationsUrl}/read-all');
  }

  // ── AI ──
  static Future<Map<String, dynamic>> analyzeInspirations(int cycleId) async {
    return await post(
      '${ApiConfig.aiUrl}/analyze',
      body: {'cycle_id': cycleId},
    );
  }

  static Future<String> getWritingHelp(
    String helpType,
    String context, {
    required String workType,
    String? genre,
  }) async {
    final data = await post(
      '${ApiConfig.aiUrl}/help',
      body: {
        'help_type': helpType,
        'context': context,
        'work_type': workType,
        'genre': genre,
      },
    );
    return data['result'] ?? '';
  }

  static Future<({String title, String content})>
  generateDraftFromInspirations({
    required String workType,
    String? genre,
    required List<Map<String, dynamic>> inspirations,
  }) async {
    final data = await post(
      '${ApiConfig.aiUrl}/generate-draft',
      body: {
        'work_type': workType,
        'genre': genre,
        'inspirations': inspirations,
      },
    );
    return (
      title: (data['title'] ?? '') as String,
      content: (data['content'] ?? '') as String,
    );
  }

  static Future<({String title, String transcript})> transcribeInspiration(
    Uint8List audioBytes, {
    String filename = 'voice.m4a',
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${ApiConfig.aiUrl}/transcribe-inspiration'),
    );
    if (_token != null) {
      request.headers['Authorization'] = 'Bearer $_token';
    }
    request.files.add(
      http.MultipartFile.fromBytes('audio', audioBytes, filename: filename),
    );
    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    if (response.statusCode == 401) {
      await clearToken();
      throw ApiException(response.statusCode, _parseError(response));
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(response.statusCode, _parseError(response));
    }
    final data =
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    return (
      title: (data['title'] ?? '') as String,
      transcript: (data['transcript'] ?? '') as String,
    );
  }

  // ── Generic HTTP helpers ──
  static Future<Map<String, dynamic>> get(String url) async {
    final response = await http.get(Uri.parse(url), headers: _headers());
    return _handleResponse(response);
  }

  static Future<List<dynamic>> getList(String url) async {
    final response = await http.get(Uri.parse(url), headers: _headers());
    if (response.statusCode == 401) {
      await clearToken();
      throw ApiException(response.statusCode, _parseError(response));
    }
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(utf8.decode(response.bodyBytes));
    }
    throw ApiException(response.statusCode, _parseError(response));
  }

  static Future<Map<String, dynamic>> post(
    String url, {
    Map<String, dynamic>? body,
  }) async {
    final response = await http.post(
      Uri.parse(url),
      headers: _headers(),
      body: body != null ? jsonEncode(body) : null,
    );
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> put(
    String url, {
    Map<String, dynamic>? body,
  }) async {
    final response = await http.put(
      Uri.parse(url),
      headers: _headers(),
      body: body != null ? jsonEncode(body) : null,
    );
    return _handleResponse(response);
  }

  static Future<void> delete(String url) async {
    final response = await http.delete(Uri.parse(url), headers: _headers());
    if (response.statusCode == 401) {
      await clearToken();
      throw ApiException(response.statusCode, _parseError(response));
    }
    if (response.statusCode >= 300) {
      throw ApiException(response.statusCode, _parseError(response));
    }
  }

  static Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return {};
      return jsonDecode(utf8.decode(response.bodyBytes));
    }
    if (response.statusCode == 503) {
      String message = '';
      try {
        final body = jsonDecode(utf8.decode(response.bodyBytes));
        message = (body['message'] ?? body['detail'] ?? '') as String;
        MaintenanceController.instance.activate(message: message);
      } catch (_) {
        MaintenanceController.instance.activate();
      }
      throw ApiException(
        response.statusCode,
        message.trim().isEmpty ? '服務維護中' : message,
      );
    }
    if (response.statusCode == 401) {
      clearToken();
      throw ApiException(response.statusCode, _parseError(response));
    }
    throw ApiException(response.statusCode, _parseError(response));
  }

  static String _parseError(http.Response response) {
    try {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      return body['detail'] ?? '未知錯誤';
    } catch (_) {
      return '伺服器錯誤 (${response.statusCode})';
    }
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String message;

  ApiException(this.statusCode, this.message);

  @override
  String toString() => message;
}
