import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/directus_config.dart';
import '../models/announcement.dart';

class AnnouncementService {
  static Future<Announcement?> fetchActiveAnnouncement() async {
    final now = DateTime.now().toUtc().toIso8601String();
    final uri = DirectusConfig.itemsUri(
      'announcements',
      queryParameters: {
        'fields': 'id,title,content,is_active,starts_at,ends_at,date_updated,date_created',
        'limit': '1',
        'sort': '-date_updated,-date_created',
        'filter[_and][0][is_active][_eq]': 'true',
        'filter[_and][1][_or][0][starts_at][_null]': 'true',
        'filter[_and][1][_or][1][starts_at][_lte]': now,
        'filter[_and][2][_or][0][ends_at][_null]': 'true',
        'filter[_and][2][_or][1][ends_at][_gte]': now,
      },
    );

    final headers = <String, String>{'Content-Type': 'application/json'};
    if (DirectusConfig.accessToken.isNotEmpty) {
      headers['Authorization'] = 'Bearer ${DirectusConfig.accessToken}';
    }

    final response = await http.get(uri, headers: headers);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      return null;
    }

    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    final data = decoded is Map<String, dynamic> ? decoded['data'] : null;
    if (data is List && data.isNotEmpty) {
      final item = data.first;
      if (item is Map<String, dynamic>) {
        final announcement = Announcement.fromDirectusJson(item);
        if (announcement.content.trim().isEmpty) return null;
        return announcement;
      }
    }
    if (data is Map<String, dynamic>) {
      final announcement = Announcement.fromDirectusJson(data);
      if (announcement.content.trim().isEmpty) return null;
      return announcement;
    }
    return null;
  }
}

