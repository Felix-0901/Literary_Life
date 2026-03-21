import 'package:flutter/foundation.dart';

class ApiConfig {
  static const String _overrideBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );
  static const String apiPrefix = '/api';

  static String get baseUrl {
    if (_overrideBaseUrl.isNotEmpty) {
      return _overrideBaseUrl;
    }

    if (kIsWeb) {
      return 'http://localhost:8000';
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'http://10.0.2.2:8000';
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        return 'http://localhost:8000';
      case TargetPlatform.fuchsia:
        return 'http://localhost:8000';
    }
  }

  static String get authUrl => '$baseUrl$apiPrefix/auth';
  static String get quotesUrl => '$baseUrl$apiPrefix/quotes';
  static String get inspirationsUrl => '$baseUrl$apiPrefix/inspirations';
  static String get cyclesUrl => '$baseUrl$apiPrefix/cycles';
  static String get worksUrl => '$baseUrl$apiPrefix/works';
  static String get friendsUrl => '$baseUrl$apiPrefix/friends';
  static String get groupsUrl => '$baseUrl$apiPrefix/groups';
  static String get sharesUrl => '$baseUrl$apiPrefix/shares';
  static String get responsesUrl => '$baseUrl$apiPrefix/responses';
  static String get notificationsUrl => '$baseUrl$apiPrefix/notifications';
  static String get announcementsUrl => '$baseUrl$apiPrefix/announcements';
  static String get maintenanceUrl => '$baseUrl$apiPrefix/maintenance';
  static String get aiUrl => '$baseUrl$apiPrefix/ai';
}
