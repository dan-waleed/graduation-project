import 'package:flutter/foundation.dart';

import '../../core/config/app_config.dart';
import '../../core/network/api_client.dart';
import '../models/session_model.dart';
import '../models/user_model.dart';
import '../storage/token_storage.dart';
import '../../shared/utils/app_roles.dart';

class AuthService {
  AuthService({
    required ApiClient apiClient,
    required TokenStorage tokenStorage,
    bool enableLocalDemoMode = AppConfig.enableLocalDemoMode,
  })  : _apiClient = apiClient,
        _tokenStorage = tokenStorage,
        _enableLocalDemoMode = enableLocalDemoMode;

  ApiClient _apiClient;
  TokenStorage _tokenStorage;
  final bool _enableLocalDemoMode;

  void rebind({
    required ApiClient apiClient,
    required TokenStorage tokenStorage,
  }) {
    _apiClient = apiClient;
    _tokenStorage = tokenStorage;
  }

  Future<SessionModel> login({
    required String username,
    required String password,
  }) async {
    try {
      final response = await _apiClient.post(
        'auth/login/',
        body: {
          'username': username,
          'password': password,
        },
      );

      final session = SessionModel(
        token: response['token'] as String,
        user: UserModel.fromJson(response['user'] as Map<String, dynamic>),
      );

      _apiClient.updateToken(session.token);
      await _tokenStorage.saveSession(session);
      return session;
    } catch (_) {
      final demoSession = _tryDemoLogin(username: username, password: password);
      if (demoSession != null) {
        _apiClient.updateToken(demoSession.token);
        await _tokenStorage.saveSession(demoSession);
        return demoSession;
      }
      rethrow;
    }
  }

  Future<SessionModel?> restoreSession() async {
    final session = await _tokenStorage.restoreSession();
    if (session == null) {
      return null;
    }

    if (_isDemoToken(session.token)) {
      _apiClient.updateToken(session.token);
      return session;
    }

    _apiClient.updateToken(session.token);
    try {
      final me = await _apiClient.get('auth/me/');
      final refreshed = SessionModel(
        token: session.token,
        user: UserModel.fromJson(me),
      );
      await _tokenStorage.saveSession(refreshed);
      return refreshed;
    } catch (_) {
      await logout();
      return null;
    }
  }

  Future<void> logout() async {
    if (_isDemoToken(_apiClient.token)) {
      _apiClient.updateToken(null);
      await _tokenStorage.clear();
      return;
    }

    try {
      await _apiClient.post('auth/logout/', body: const {});
    } catch (_) {
      // Continue local cleanup even if the network call fails.
    }
    _apiClient.updateToken(null);
    await _tokenStorage.clear();
  }

  SessionModel? _tryDemoLogin({
    required String username,
    required String password,
  }) {
    if (!_enableLocalDemoMode || !kDebugMode) return null;

    final normalizedUsername = username.trim().toLowerCase();
    for (final account in _demoAccounts) {
      final matchesUser = account.user.username.toLowerCase() == normalizedUsername ||
          account.user.email.toLowerCase() == normalizedUsername;
      if (matchesUser && account.password == password) {
        return SessionModel(
          token: 'demo-token-${account.user.role.toLowerCase()}-${account.user.id}',
          user: account.user,
        );
      }
    }
    return null;
  }

  bool _isDemoToken(String? token) => token != null && token.startsWith('demo-token-');
}

class _DemoAuthAccount {
  const _DemoAuthAccount({
    required this.user,
    required this.password,
  });

  final UserModel user;
  final String password;
}

const List<_DemoAuthAccount> _demoAccounts = [
  _DemoAuthAccount(
    user: UserModel(
      id: 9001,
      username: 'admin_demo',
      email: 'admin@healthbridge.test',
      role: AppRoles.admin,
      firstName: 'System',
      lastName: 'Admin',
      phoneNumber: '0599000001',
      isActive: true,
    ),
    password: 'admin12345',
  ),
  _DemoAuthAccount(
    user: UserModel(
      id: 9002,
      username: 'doctor_demo',
      email: 'doctor@healthbridge.test',
      role: AppRoles.doctor,
      firstName: 'Ahmad',
      lastName: 'Khalil',
      phoneNumber: '0599000002',
      isActive: true,
    ),
    password: 'demo12345',
  ),
  _DemoAuthAccount(
    user: UserModel(
      id: 9003,
      username: 'employee_demo',
      email: 'employee@healthbridge.test',
      role: AppRoles.employee,
      firstName: 'Mona',
      lastName: 'Saleh',
      phoneNumber: '0599000003',
      isActive: true,
    ),
    password: 'demo12345',
  ),
  _DemoAuthAccount(
    user: UserModel(
      id: 9004,
      username: 'pharmacist_demo',
      email: 'pharmacist@healthbridge.test',
      role: AppRoles.pharmacist,
      firstName: 'Rami',
      lastName: 'Nassar',
      phoneNumber: '0599000004',
      isActive: true,
    ),
    password: 'demo12345',
  ),
  _DemoAuthAccount(
    user: UserModel(
      id: 9005,
      username: 'insurance_demo',
      email: 'insurance@healthbridge.test',
      role: AppRoles.insuranceOfficer,
      firstName: 'Lina',
      lastName: 'Hamdan',
      phoneNumber: '0599000005',
      isActive: true,
    ),
    password: 'demo12345',
  ),
];
