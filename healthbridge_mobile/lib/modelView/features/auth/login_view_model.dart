import 'package:flutter/material.dart';

import 'package:healthbridge_mobile/model/core/errors/app_exception.dart';
import 'package:healthbridge_mobile/modelView/features/auth/auth_view_model.dart';

class LoginViewModel extends ChangeNotifier {
  final formKey = GlobalKey<FormState>();
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();

  String? _errorMessage;

  String? get errorMessage => _errorMessage;

  String? validateUsername(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'يرجى إدخال اسم المستخدم أو البريد الإلكتروني';
    }
    return null;
  }

  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'يرجى إدخال كلمة المرور';
    }
    return null;
  }

  void clearError() {
    if (_errorMessage == null) return;
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> submit(AuthViewModel authViewModel) async {
    if (!formKey.currentState!.validate()) return;

    clearError();

    try {
      await authViewModel.login(
        username: usernameController.text.trim(),
        password: passwordController.text,
      );
    } on AppException {
      _errorMessage = 'بيانات تسجيل الدخول غير صحيحة.';
      notifyListeners();
    } catch (_) {
      _errorMessage = 'تعذر تسجيل الدخول حاليًا. يرجى المحاولة مرة أخرى.';
      notifyListeners();
    }
  }

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}
