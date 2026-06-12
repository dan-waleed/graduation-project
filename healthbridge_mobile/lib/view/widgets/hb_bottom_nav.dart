import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:healthbridge_mobile/view/theme/app_theme.dart';
import 'package:healthbridge_mobile/view/features/admin/admin_views.dart';
import 'package:healthbridge_mobile/modelView/features/auth/auth_view_model.dart';
import 'package:healthbridge_mobile/view/features/common/notifications_screen.dart';
import 'package:healthbridge_mobile/view/features/common/profile_screen.dart';
import 'package:healthbridge_mobile/view/features/doctor/doctor_views.dart';
import 'package:healthbridge_mobile/view/features/employee/employee_views.dart';
import 'package:healthbridge_mobile/view/features/insurance_officer/insurance_officer_views.dart';
import 'package:healthbridge_mobile/view/features/pharmacist/pharmacist_views.dart';
import 'package:healthbridge_mobile/model/utils/app_roles.dart';

class HbBottomNav extends StatelessWidget {
  const HbBottomNav({super.key});

  @override
  Widget build(BuildContext context) {
    final role = context.watch<AuthViewModel>().currentUser?.role;
    final items = _itemsForRole(role);
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    final currentPath = GoRouterState.of(context).matchedLocation;
    final selectedIndex = _selectedIndex(items, currentPath);
    if (selectedIndex == -1) {
      return const SizedBox.shrink();
    }

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: AppTheme.border),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primary.withValues(alpha: 0.10),
                blurRadius: 28,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: Row(
              children: [
                for (var i = 0; i < items.length; i++)
                  Expanded(
                    child: _BottomNavButton(
                      item: items[i],
                      isSelected: i == selectedIndex,
                      onTap: () {
                        final target = items[i].routePath;
                        if (target != currentPath) {
                          context.go(target);
                        }
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  int _selectedIndex(List<_NavItem> items, String currentPath) {
    var bestIndex = -1;
    var bestMatchLength = -1;

    for (var i = 0; i < items.length; i++) {
      final matchLength = items[i].matchLength(currentPath);
      if (matchLength > bestMatchLength) {
        bestMatchLength = matchLength;
        bestIndex = i;
      }
    }

    if (bestIndex != -1) {
      return bestIndex;
    }

    if (currentPath == ProfileScreen.routePath) {
      final profileIndex = items.indexWhere(
        (item) => item.routePath == ProfileScreen.routePath,
      );
      if (profileIndex != -1) {
        return profileIndex;
      }
    }

    if (currentPath == NotificationsScreen.routePath) {
      return 0;
    }

    return items.isEmpty ? -1 : 0;
  }

  List<_NavItem> _itemsForRole(String? role) {
    switch (role) {
      case AppRoles.doctor:
        return const [
          _NavItem(
            'الرئيسية',
            DoctorHomeScreen.routePath,
            Icons.home_outlined,
            Icons.home_rounded,
          ),
          _NavItem(
            'الموظفون',
            DoctorPatientSearchScreen.routePath,
            Icons.people_outline_rounded,
            Icons.people_rounded,
            matchPaths: [
              DoctorPatientSearchScreen.routePath,
              DoctorPatientDetailScreen.routePath,
            ],
          ),
          _NavItem(
            'إنشاء',
            DoctorPrescriptionCreateScreen.routePath,
            Icons.add_circle_outline_rounded,
            Icons.add_circle_rounded,
            matchPaths: [
              DoctorPrescriptionCreateScreen.routePath,
              DoctorMedicationAddScreen.routePath,
            ],
          ),
          _NavItem(
            'السجل',
            DoctorPrescriptionHistoryScreen.routePath,
            Icons.receipt_long_outlined,
            Icons.receipt_long_rounded,
            matchPaths: [
              DoctorPrescriptionHistoryScreen.routePath,
              DoctorPrescriptionDetailScreen.routePath,
            ],
          ),
        ];
      case AppRoles.employee:
      case 'Patient':
        return const [
          _NavItem(
            'الرئيسية',
            EmployeeHomeScreen.routePath,
            Icons.home_outlined,
            Icons.home_rounded,
          ),
          _NavItem(
            'الوصفات',
            EmployeePrescriptionsView.routePath,
            Icons.receipt_long_outlined,
            Icons.receipt_long_rounded,
            matchPaths: [
              EmployeePrescriptionsView.routePath,
              EmployeePrescriptionDetailView.routePath,
              EmployeeQrView.routePath,
              EmployeeMedicationHistoryView.routePath,
            ],
          ),
          _NavItem(
            'المستفيدون',
            EmployeeDependentsView.routePath,
            Icons.family_restroom_outlined,
            Icons.family_restroom_rounded,
          ),
        ];
      case AppRoles.insuranceOfficer:
        return const [
          _NavItem(
            'الرئيسية',
            InsuranceOfficerHomeScreen.routePath,
            Icons.home_outlined,
            Icons.home_rounded,
          ),
          _NavItem(
            'الطلبات',
            InsuranceRequestsScreen.routePath,
            Icons.assignment_outlined,
            Icons.assignment_rounded,
            matchPaths: [
              InsuranceRequestsScreen.routePath,
              InsuranceReviewScreen.routePath,
            ],
          ),
          _NavItem(
            'الحساب',
            ProfileScreen.routePath,
            Icons.person_outline_rounded,
            Icons.person_rounded,
          ),
        ];
      case AppRoles.pharmacist:
        return const [
          _NavItem(
            'الرئيسية',
            PharmacistHomeScreen.routePath,
            Icons.home_outlined,
            Icons.home_rounded,
          ),
          _NavItem(
            'البحث',
            PharmacistSearchPrescriptionScreen.routePath,
            Icons.search_outlined,
            Icons.search_rounded,
            matchPaths: [
              PharmacistSearchPrescriptionScreen.routePath,
              PharmacistPrescriptionDetailScreen.routePath,
            ],
          ),
          _NavItem(
            'QR',
            PharmacistQrLookupScreen.routePath,
            Icons.qr_code_scanner_outlined,
            Icons.qr_code_scanner_rounded,
            matchPaths: [
              PharmacistQrLookupScreen.routePath,
              PharmacistDispenseConfirmScreen.routePath,
            ],
          ),
          _NavItem(
            'السجل',
            PharmacistDispenseHistoryScreen.routePath,
            Icons.receipt_long_outlined,
            Icons.receipt_long_rounded,
          ),
        ];
      case AppRoles.admin:
      default:
        return const [
          _NavItem(
            'الرئيسية',
            AdminHomeScreen.routePath,
            Icons.home_outlined,
            Icons.home_rounded,
          ),
          _NavItem(
            'المستخدمون',
            AdminUserManagementScreen.routePath,
            Icons.groups_outlined,
            Icons.groups_rounded,
            matchPaths: [
              AdminUserManagementScreen.routePath,
              AdminUserCreateScreen.routePath,
              AdminUserEditScreen.routePath,
            ],
          ),
          _NavItem(
            'الإحصاءات',
            AdminStatisticsScreen.routePath,
            Icons.bar_chart_outlined,
            Icons.bar_chart_rounded,
          ),
          _NavItem(
            'الإعدادات',
            AdminSettingsScreen.routePath,
            Icons.settings_outlined,
            Icons.settings_rounded,
          ),
        ];
    }
  }
}

class _NavItem {
  const _NavItem(
    this.label,
    this.routePath,
    this.icon,
    this.activeIcon, {
    this.matchPaths,
  });

  final String label;
  final String routePath;
  final IconData icon;
  final IconData activeIcon;
  final List<String>? matchPaths;

  int matchLength(String currentPath) {
    final paths = matchPaths ?? [routePath];
    var bestLength = -1;

    for (final path in paths) {
      if (currentPath == path || currentPath.startsWith('$path/')) {
        if (path.length > bestLength) {
          bestLength = path.length;
        }
      }
    }

    return bestLength;
  }
}

class _BottomNavButton extends StatelessWidget {
  const _BottomNavButton({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  final _NavItem item;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Material(
        color: isSelected
            ? AppTheme.primary.withValues(alpha: 0.12)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isSelected ? item.activeIcon : item.icon,
                  color: isSelected ? AppTheme.primary : AppTheme.muted,
                  size: 24,
                ),
                const SizedBox(height: 6),
                Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodySmall?.copyWith(
                    color: isSelected ? AppTheme.primaryDark : AppTheme.muted,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
