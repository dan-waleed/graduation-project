import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../shared/widgets/hb_custom_button.dart';
import '../../../../shared/widgets/hb_custom_card.dart';
import '../../../../shared/widgets/hb_custom_input.dart';
import '../../../../shared/widgets/hb_university_brand.dart';
import '../controller/auth_controller.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  static const routeName = 'login';
  static const routePath = '/login';

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _errorMessage;

  static const _demoAccounts = [
    _DemoAccount(
      role: 'مدير النظام',
      username: 'admin_demo',
      password: 'admin12345',
      description: 'إدارة المستخدمين والإحصاءات العامة.',
    ),
    _DemoAccount(
      role: 'الطبيب',
      username: 'doctor_demo',
      password: 'demo12345',
      description: 'إنشاء وصفات ومراجعة المرضى.',
    ),
    _DemoAccount(
      role: 'الموظف الجامعي',
      username: 'employee_demo',
      password: 'demo12345',
      description: 'استعراض الطلبات الطبية والرمز الدوائي واختيار مقدم الخدمة.',
    ),
    _DemoAccount(
      role: 'الصيدلي',
      username: 'pharmacist_demo',
      password: 'demo12345',
      description: 'البحث عن الوصفات وتأكيد الصرف.',
    ),
    _DemoAccount(
      role: 'موظف التأمين',
      username: 'insurance_demo',
      password: 'demo12345',
      description: 'مراجعة طلبات التأمين ومتابعة حالة التغطية.',
    ),
  ];

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _errorMessage = null);

    try {
      await context.read<AuthController>().login(
            username: _usernameController.text.trim(),
            password: _passwordController.text,
          );
    } on AppException catch (error) {
      setState(() => _errorMessage = error.message);
    } catch (_) {
      setState(() => _errorMessage = 'تعذر تسجيل الدخول حاليًا. يرجى المحاولة مرة أخرى.');
    }
  }

  void _fillDemoAccount(_DemoAccount account) {
    setState(() => _errorMessage = null);
    _usernameController.text = account.username;
    _passwordController.text = account.password;
  }

  @override
  Widget build(BuildContext context) {
    final authController = context.watch<AuthController>();

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: SvgPicture.asset(
              'assets/images/login-background.svg',
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.background.withValues(alpha: 0.78),
                    Colors.white.withValues(alpha: 0.90),
                    AppTheme.background.withValues(alpha: 0.92),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.74),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.85)),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primary.withValues(alpha: 0.10),
                              blurRadius: 30,
                              offset: const Offset(0, 18),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            const HbUniversityLogo(size: 92),
                            const SizedBox(height: 18),
                            Text(
                              'HealthBridge',
                              textDirection: TextDirection.ltr,
                              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                                    letterSpacing: 0.4,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'نظام الوصفات الطبية الإلكترونية\nجامعة بوليتكنك فلسطين',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppTheme.muted,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'نظام إدارة الوصفات والخدمات الطبية المؤمّنة لموظفي جامعة بوليتكنك فلسطين',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppTheme.primaryDark,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      HbCustomCard(
                        child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'تسجيل الدخول',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'أدخل بيانات الحساب للوصول إلى الخدمات المرتبطة بدورك.',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            const SizedBox(height: 18),
                            HbCustomInput(
                              controller: _usernameController,
                              label: 'اسم المستخدم أو البريد الإلكتروني',
                              hint: 'أدخل اسم المستخدم أو البريد الإلكتروني',
                              prefixIcon: Icons.person_outline_rounded,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'يرجى إدخال اسم المستخدم أو البريد الإلكتروني';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),
                            HbCustomInput(
                              controller: _passwordController,
                              label: 'كلمة المرور',
                              hint: 'أدخل كلمة المرور',
                              prefixIcon: Icons.lock_outline_rounded,
                              obscureText: true,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'يرجى إدخال كلمة المرور';
                                }
                                return null;
                              },
                            ),
                            if (_errorMessage != null) ...[
                              const SizedBox(height: 14),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppTheme.error.withValues(alpha: 0.10),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Text(
                                  _errorMessage!,
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: AppTheme.error,
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                              ),
                            ],
                            const SizedBox(height: 18),
                            HbCustomButton(
                              label: 'تسجيل الدخول',
                              icon: Icons.login_rounded,
                              isLoading: authController.isBusy,
                              onPressed: _submit,
                            ),
                            const SizedBox(height: 14),
                            Text(
                              'ملاحظة: يختلف محتوى التطبيق حسب نوع الحساب مثل الطبيب أو الموظف الجامعي أو الصيدلي أو موظف التأمين أو مدير النظام.',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            const SizedBox(height: 18),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppTheme.border),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'حسابات جاهزة للاختبار',
                                    style: Theme.of(context).textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'اضغط على أي حساب لتعبئة بياناته مباشرة. تعمل هذه الحسابات أيضًا كتجربة محلية في وضع التطوير.',
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                  const SizedBox(height: 12),
                                  ..._demoAccounts.map(
                                    (account) => Padding(
                                      padding: const EdgeInsets.only(bottom: 10),
                                      child: InkWell(
                                        onTap: () => _fillDemoAccount(account),
                                        borderRadius: BorderRadius.circular(14),
                                        child: Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF8FBFF),
                                            borderRadius: BorderRadius.circular(14),
                                            border: Border.all(color: AppTheme.border),
                                          ),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                account.role,
                                                style: Theme.of(context).textTheme.titleSmall,
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                '${account.username} / ${account.password}',
                                                textDirection: TextDirection.ltr,
                                                style: Theme.of(context).textTheme.bodyMedium,
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                account.description,
                                                style: Theme.of(context).textTheme.bodySmall,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DemoAccount {
  const _DemoAccount({
    required this.role,
    required this.username,
    required this.password,
    required this.description,
  });

  final String role;
  final String username;
  final String password;
  final String description;
}
