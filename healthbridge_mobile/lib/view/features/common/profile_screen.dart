import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:healthbridge_mobile/view/theme/app_theme.dart';
import 'package:healthbridge_mobile/modelView/features/auth/auth_view_model.dart';
import 'package:healthbridge_mobile/model/utils/role_label.dart';
import 'package:healthbridge_mobile/view/widgets/hb_custom_button.dart';
import 'package:healthbridge_mobile/view/widgets/hb_custom_card.dart';
import 'package:healthbridge_mobile/view/widgets/hb_empty_state.dart';
import 'package:healthbridge_mobile/view/widgets/hb_info_row.dart';
import 'package:healthbridge_mobile/view/widgets/hb_scaffold.dart';
import 'package:healthbridge_mobile/view/widgets/hb_status_chip.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  static const routeName = 'profile';
  static const routePath = '/profile';

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    final authController = context.watch<AuthViewModel>();
    final user = authController.currentUser;

    return HbScaffold(
      title: 'الملف الشخصي',
      body: user == null
          ? const HbEmptyState(
              title: 'لا تتوفر بيانات المستخدم',
              message:
                  'تعذر تحميل بيانات الحساب الحالي. يرجى تسجيل الدخول مرة أخرى.',
              icon: Icons.person_off_outlined,
            )
          : ListView(
              children: [
                Center(
                  child: Container(
                    width: 92,
                    height: 92,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [AppTheme.primary, AppTheme.primaryDark],
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primary.withValues(alpha: 0.22),
                          blurRadius: 26,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.person_rounded,
                      color: Colors.white,
                      size: 42,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                HbCustomCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user.displayName,
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  roleLabel(user.role),
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(color: AppTheme.muted),
                                ),
                              ],
                            ),
                          ),
                          HbStatusChip(user.isActive ? 'فعّال' : 'غير فعّال'),
                        ],
                      ),
                      const SizedBox(height: 18),
                      HbInfoRow(label: 'اسم المستخدم', value: user.username),
                      HbInfoRow(label: 'الدور', value: roleLabel(user.role)),
                      HbInfoRow(label: 'البريد الإلكتروني', value: user.email),
                      HbInfoRow(
                        label: 'رقم الهاتف',
                        value: user.phoneNumber.isEmpty
                            ? 'غير متوفر'
                            : user.phoneNumber,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                HbCustomButton(
                  label: 'تسجيل الخروج',
                  variant: HbButtonVariant.outline,
                  isDestructive: true,
                  icon: Icons.logout_rounded,
                  onPressed: () => context.read<AuthViewModel>().logout(),
                ),
              ],
            ),
    );
  }
}
