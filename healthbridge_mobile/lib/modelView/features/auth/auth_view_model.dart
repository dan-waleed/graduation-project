import 'package:flutter/foundation.dart';

import 'package:healthbridge_mobile/model/repositories/auth_repository.dart';
import 'package:healthbridge_mobile/model/models/session_model.dart';
import 'package:healthbridge_mobile/model/models/user_model.dart';

enum AuthFlowState { bootstrapping, unauthenticated, authenticated }

class AuthViewModel extends ChangeNotifier {
  AuthViewModel({required AuthRepository authRepository})
    : _authRepository = authRepository;

  AuthRepository _authRepository;
  AuthFlowState _state = AuthFlowState.bootstrapping;
  UserModel? _currentUser;
  String? _token;
  bool _isBusy = false;

  AuthFlowState get state => _state;
  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated =>
      _state == AuthFlowState.authenticated && _token != null;
  bool get isBusy => _isBusy;
  String? get token => _token;

  void rebind(AuthRepository authRepository) {
    _authRepository = authRepository;
  }

  Future<void> bootstrap() async {
    _state = AuthFlowState.bootstrapping;
    notifyListeners();

    final session = await _authRepository.restoreSession();
    if (session == null) {
      _state = AuthFlowState.unauthenticated;
      _currentUser = null;
      _token = null;
    } else {
      _applySession(session);
    }

    notifyListeners();
  }

  Future<void> login({
    required String username,
    required String password,
  }) async {
    _isBusy = true;
    notifyListeners();

    try {
      final session = await _authRepository.login(
        username: username,
        password: password,
      );
      _applySession(session);
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _isBusy = true;
    notifyListeners();

    try {
      await _authRepository.logout();
      _state = AuthFlowState.unauthenticated;
      _currentUser = null;
      _token = null;
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  void _applySession(SessionModel session) {
    _state = AuthFlowState.authenticated;
    _currentUser = session.user;
    _token = session.token;
  }
}
