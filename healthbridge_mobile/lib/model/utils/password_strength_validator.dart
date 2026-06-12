class PasswordStrengthValidator {
  static const int minLength = 8;

  static final RegExp _uppercasePattern = RegExp(r'[A-Z]');
  static final RegExp _lowercasePattern = RegExp(r'[a-z]');
  static final RegExp _digitPattern = RegExp(r'\d');
  static final RegExp _specialCharacterPattern = RegExp(
    r'[!@#$%^&*(),.?":{}|<>_\-\\/\[\]=+;'
    '`~]',
  );

  static String? validate(String? value, {required bool isRequired}) {
    final password = value?.trim() ?? '';

    if (password.isEmpty) {
      return isRequired ? 'يرجى إدخال كلمة المرور' : null;
    }

    if (password.length < minLength) {
      return 'يجب أن تتكون كلمة المرور من 8 أحرف على الأقل';
    }
    if (!_uppercasePattern.hasMatch(password)) {
      return 'يجب أن تحتوي كلمة المرور على حرف كبير واحد على الأقل';
    }
    if (!_lowercasePattern.hasMatch(password)) {
      return 'يجب أن تحتوي كلمة المرور على حرف صغير واحد على الأقل';
    }
    if (!_digitPattern.hasMatch(password)) {
      return 'يجب أن تحتوي كلمة المرور على رقم واحد على الأقل';
    }
    if (!_specialCharacterPattern.hasMatch(password)) {
      return 'يجب أن تحتوي كلمة المرور على رمز خاص واحد على الأقل';
    }

    return null;
  }
}
