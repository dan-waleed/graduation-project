import 'package:flutter/foundation.dart';

class AppConfig {
  static const String envApiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  static const String devLanApiBaseUrl = String.fromEnvironment(
    'DEV_LAN_API_BASE_URL',
    defaultValue: '',
  );

  static List<String> get _optionalLanUrls =>
      devLanApiBaseUrl.isEmpty ? const [] : [devLanApiBaseUrl];

  static List<String> get candidateBaseUrls {
    if (envApiBaseUrl.isNotEmpty) {
      return [envApiBaseUrl];
    }
    if (kIsWeb) {
      return [
        'http://localhost:8000/api',
        'http://127.0.0.1:8000/api',
        ..._optionalLanUrls,
      ];
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return [
          'http://10.0.2.2:8000/api',
          ..._optionalLanUrls,
        ];
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
        return [
          'http://localhost:8000/api',
          'http://127.0.0.1:8000/api',
          ..._optionalLanUrls,
        ];
      case TargetPlatform.fuchsia:
        return [
          'http://127.0.0.1:8000/api',
          'http://localhost:8000/api',
          ..._optionalLanUrls,
        ];
    }
  }
}
