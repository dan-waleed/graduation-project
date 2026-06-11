import 'package:flutter_test/flutter_test.dart';
import 'package:healthbridge_mobile/src/shared/utils/password_strength_validator.dart';

void main() {
  group('PasswordStrengthValidator', () {
    test('requires password for new users', () {
      expect(
        PasswordStrengthValidator.validate('', isRequired: true),
        'يرجى إدخال كلمة المرور',
      );
    });

    test('allows empty password for editing existing users', () {
      expect(PasswordStrengthValidator.validate('', isRequired: false), isNull);
    });

    test('rejects weak passwords', () {
      expect(
        PasswordStrengthValidator.validate('weakpass', isRequired: true),
        'يجب أن تحتوي كلمة المرور على حرف كبير واحد على الأقل',
      );
      expect(
        PasswordStrengthValidator.validate('Weakpass', isRequired: true),
        'يجب أن تحتوي كلمة المرور على رقم واحد على الأقل',
      );
      expect(
        PasswordStrengthValidator.validate('Weakpass1', isRequired: true),
        'يجب أن تحتوي كلمة المرور على رمز خاص واحد على الأقل',
      );
    });

    test('accepts strong passwords', () {
      expect(
        PasswordStrengthValidator.validate('StrongPass1!', isRequired: true),
        isNull,
      );
    });
  });
}
