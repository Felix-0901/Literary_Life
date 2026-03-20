import 'package:flutter/foundation.dart';

class DirectusConfig {
  static const String _overrideBaseUrl = String.fromEnvironment(
    'DIRECTUS_BASE_URL',
    defaultValue: '',
  );

  static const String accessToken = String.fromEnvironment(
    'DIRECTUS_ACCESS_TOKEN',
    defaultValue: '',
  );

  static String get baseUrl {
    if (_overrideBaseUrl.isNotEmpty) {
      return _overrideBaseUrl;
    }

    if (kIsWeb) {
      return 'http://localhost:8055';
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'http://10.0.2.2:8055';
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        return 'http://localhost:8055';
      case TargetPlatform.fuchsia:
        return 'http://localhost:8055';
    }
  }

  static Uri itemsUri(
    String collection, {
    Map<String, String>? queryParameters,
  }) {
    return Uri.parse('$baseUrl/items/$collection').replace(
      queryParameters: queryParameters,
    );
  }
}

