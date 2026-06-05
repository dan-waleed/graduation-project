import '../models/session_model.dart';
import '../services/auth_service.dart';

class AuthRepository {
  AuthRepository({
    required AuthService authService,
  }) : _authService = authService;

  AuthService _authService;

  void rebind(AuthService authService) {
    _authService = authService;
  }

  Future<SessionModel> login({
    required String username,
    required String password,
  }) {
    return _authService.login(username: username, password: password);
  }

  Future<SessionModel?> restoreSession() {
    return _authService.restoreSession();
  }

  Future<void> logout() {
    return _authService.logout();
  }
}
