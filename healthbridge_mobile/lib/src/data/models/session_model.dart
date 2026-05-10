import 'user_model.dart';

class SessionModel {
  const SessionModel({
    required this.token,
    required this.user,
  });

  final String token;
  final UserModel user;
}
