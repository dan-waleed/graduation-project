import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import 'package:healthbridge_mobile/modelView/features/auth/auth_view_model.dart';
import 'package:healthbridge_mobile/modelView/features/auth/login_view_model.dart';
import 'package:healthbridge_mobile/view/theme/app_theme.dart';
import 'package:healthbridge_mobile/view/widgets/hb_custom_button.dart';
import 'package:healthbridge_mobile/view/widgets/hb_custom_card.dart';
import 'package:healthbridge_mobile/view/widgets/hb_custom_input.dart';
import 'package:healthbridge_mobile/view/widgets/hb_university_brand.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  static const routeName = 'login';
  static const routePath = '/login';

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => LoginViewModel(),
      child: const _LoginScreenView(),
    );
  }
}

class _LoginScreenView extends StatelessWidget {
  const _LoginScreenView();

  @override
  Widget build(BuildContext context) {
    final loginViewModel = context.watch<LoginViewModel>();
    final authViewModel = context.watch<AuthViewModel>();

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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 22,
                          vertical: 24,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.74),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
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
                              style: Theme.of(context).textTheme.headlineLarge
                                  ?.copyWith(letterSpacing: 0.4),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'نظام الوصفات الطبية الإلكترونية\nجامعة بوليتكنك فلسطين',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: AppTheme.muted),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'نظام إدارة الوصفات والخدمات الطبية المؤمّنة لموظفي جامعة بوليتكنك فلسطين',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
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
                          key: loginViewModel.formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'تسجيل الدخول',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'أدخل بيانات الحساب الخاصة بك للوصول إلى الخدمات المناسبة لك. .',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              const SizedBox(height: 18),
                              HbCustomInput(
                                controller: loginViewModel.usernameController,
                                label: 'اسم المستخدم أو البريد الإلكتروني',
                                hint: 'أدخل اسم المستخدم أو البريد الإلكتروني',
                                prefixIcon: Icons.person_outline_rounded,
                                validator: loginViewModel.validateUsername,
                                onChanged: (_) => loginViewModel.clearError(),
                              ),
                              const SizedBox(height: 14),
                              HbCustomInput(
                                controller: loginViewModel.passwordController,
                                label: 'كلمة المرور',
                                hint: 'أدخل كلمة المرور',
                                prefixIcon: Icons.lock_outline_rounded,
                                obscureText: true,
                                validator: loginViewModel.validatePassword,
                                onChanged: (_) => loginViewModel.clearError(),
                              ),
                              if (loginViewModel.errorMessage != null) ...[
                                const SizedBox(height: 14),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppTheme.error.withValues(
                                      alpha: 0.10,
                                    ),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Text(
                                    loginViewModel.errorMessage!,
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
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
                                isLoading: authViewModel.isBusy,
                                onPressed: () =>
                                    loginViewModel.submit(authViewModel),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                'ملاحظة: يختلف محتوى التطبيق حسب نوع الحساب مثل الطبيب أو الموظف الجامعي أو الصيدلي أو موظف التأمين أو مدير النظام.',
                                style: Theme.of(context).textTheme.bodySmall,
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
