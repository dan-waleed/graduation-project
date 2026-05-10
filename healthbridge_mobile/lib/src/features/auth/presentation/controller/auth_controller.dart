import 'package:flutter/foundation.dart';

import '../../../../data/models/session_model.dart';
import '../../../../data/models/user_model.dart';
import '../../../../data/services/auth_service.dart';

enum AuthFlowState {
  bootstrapping,
  unauthenticated,
  authenticated,
}

class AuthController extends ChangeNotifier {
  AuthController({
    required AuthService authService,
  }) : _authService = authService;

  AuthService _authService;
  AuthFlowState _state = AuthFlowState.bootstrapping;
  UserModel? _currentUser;
  String? _token;
  bool _isBusy = false;

  AuthFlowState get state => _state;
  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _state == AuthFlowState.authenticated && _token != null;
  bool get isBusy => _isBusy;
  String? get token => _token;

  void rebind(AuthService authService) {
    _authService = authService;
  }

  Future<void> bootstrap() async {
    _state = AuthFlowState.bootstrapping;
    notifyListeners();

    final session = await _authService.restoreSession();
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
      final session = await _authService.login(
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
      await _authService.logout();
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
