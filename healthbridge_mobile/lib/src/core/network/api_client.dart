import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

import '../config/app_config.dart';
import '../errors/app_exception.dart';

class ApiClient {
  static const Duration _requestTimeout = Duration(seconds: 4);

  String? _token;
  String? get token => _token;
  bool get isDemoToken => _token != null && _token!.startsWith('demo-token-');

  void updateToken(String? token) {
    _token = token;
  }

  Map<String, String> get _headers {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (_token != null && _token!.isNotEmpty) {
      headers['Authorization'] = 'Token $_token';
    }
    return headers;
  }

  Future<Map<String, dynamic>> post(
    String endpoint, {
    required Map<String, dynamic> body,
  }) async {
    final response = await _sendWithFallback(
      (baseUrl) => http.post(
        _buildUri(baseUrl, endpoint),
        headers: _headers,
        body: jsonEncode(body),
      ),
    );

    return _decodeMap(response);
  }

  Future<Map<String, dynamic>> get(String endpoint) async {
    final response = await _sendWithFallback(
      (baseUrl) => http.get(_buildUri(baseUrl, endpoint), headers: _headers),
    );

    return _decodeMap(response);
  }

  Future<List<dynamic>> getList(String endpoint) async {
    final response = await _sendWithFallback(
      (baseUrl) => http.get(_buildUri(baseUrl, endpoint), headers: _headers),
    );

    return _decodeList(response);
  }

  Future<String> getText(String endpoint) async {
    final response = await _sendWithFallback(
      (baseUrl) => http.get(_buildUri(baseUrl, endpoint), headers: _headers),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return response.body;
    }

    throw AppException(_extractErrorMessage(response));
  }

  Future<Map<String, dynamic>> patch(
    String endpoint, {
    required Map<String, dynamic> body,
  }) async {
    final response = await _sendWithFallback(
      (baseUrl) => http.patch(
        _buildUri(baseUrl, endpoint),
        headers: _headers,
        body: jsonEncode(body),
      ),
    );

    return _decodeMap(response);
  }

  Future<void> delete(String endpoint) async {
    final response = await _sendWithFallback(
      (baseUrl) => http.delete(_buildUri(baseUrl, endpoint), headers: _headers),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }

    throw AppException(_extractErrorMessage(response));
  }

  Future<http.Response> _sendWithFallback(
    Future<http.Response> Function(String baseUrl) action,
  ) async {
    AppException? lastError;

    for (final candidate in AppConfig.candidateBaseUrls.map(
      _normalizeBaseUrl,
    )) {
      try {
        return await action(candidate).timeout(_requestTimeout);
      } on TimeoutException {
        lastError = AppException(
          'انتهت مهلة الاتصال بالخادم. يرجى المحاولة مرة أخرى.',
        );
      } on http.ClientException {
        lastError = AppException(_buildConnectionHelpMessage());
      }
    }

    throw lastError ?? const AppException('تعذر الاتصال بخادم النظام.');
  }

  Map<String, dynamic> _decodeMap(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) {
        return <String, dynamic>{};
      }
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      throw const AppException('صيغة الاستجابة من الخادم غير متوقعة.');
    }

    throw AppException(_extractErrorMessage(response));
  }

  List<dynamic> _decodeList(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) {
        return const [];
      }

      final decoded = jsonDecode(response.body);
      if (decoded is List) {
        return decoded;
      }
      if (decoded is Map<String, dynamic> && decoded['results'] is List) {
        return decoded['results'] as List;
      }
      throw const AppException('صيغة القائمة المستلمة من الخادم غير متوقعة.');
    }

    throw AppException(_extractErrorMessage(response));
  }

  String _extractErrorMessage(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        if (decoded['detail'] is String) {
          return decoded['detail'] as String;
        }
        final buffer = StringBuffer();
        decoded.forEach((key, value) {
          if (buffer.isNotEmpty) {
            buffer.write('\n');
          }
          buffer.write('$key: ${value is List ? value.join(", ") : value}');
        });
        if (buffer.isNotEmpty) {
          return buffer.toString();
        }
      }
    } catch (_) {
      // Fallback below.
    }

    return 'فشل الطلب برمز الحالة ${response.statusCode}.';
  }

  Uri _buildUri(String baseUrl, String endpoint) {
    final normalizedEndpoint = endpoint.startsWith('/')
        ? endpoint.substring(1)
        : endpoint;
    return Uri.parse('${_normalizeBaseUrl(baseUrl)}/$normalizedEndpoint');
  }

  String _normalizeBaseUrl(String baseUrl) {
    final trimmed = baseUrl.trim();
    final withScheme =
        trimmed.startsWith('http://') || trimmed.startsWith('https://')
        ? trimmed
        : 'http://$trimmed';
    return withScheme.endsWith('/')
        ? withScheme.substring(0, withScheme.length - 1)
        : withScheme;
  }

  String _buildConnectionHelpMessage() {
    final candidates = AppConfig.candidateBaseUrls
        .map(_normalizeBaseUrl)
        .toList();
    final attemptedHosts = candidates.join(' ، ');

    if (kIsWeb) {
      return 'تعذر الوصول إلى الخادم عبر: $attemptedHosts. تأكد من تشغيل الخادم والسماح للمتصفح بالوصول إلى عنوان الـ API الصحيح.';
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
        return 'تعذر الوصول إلى الخادم عبر: $attemptedHosts. على iPhone الحقيقي لا يعمل localhost. شغّل التطبيق مع --dart-define=DEV_LAN_API_BASE_URL=http://<your-lan-ip>:8000/api أو حدّد API_BASE_URL مباشرة.';
      case TargetPlatform.android:
        return 'تعذر الوصول إلى الخادم عبر: $attemptedHosts. إذا كنت تستخدم هاتف Android حقيقي فمرّر DEV_LAN_API_BASE_URL بعنوان الشبكة المحلية، أما المحاكي فيستخدم 10.0.2.2.';
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
        return 'تعذر الوصول إلى الخادم عبر: $attemptedHosts. تأكد من تشغيل الـ backend على هذا الجهاز أو مرّر API_BASE_URL / DEV_LAN_API_BASE_URL بعنوان صحيح.';
      case TargetPlatform.fuchsia:
        return 'تعذر الوصول إلى الخادم عبر: $attemptedHosts. تأكد من إعداد عنوان API الصحيح.';
    }
  }
}
