import 'package:go_router/go_router.dart';

import 'package:healthbridge_mobile/view/features/admin/admin_views.dart';
import 'package:healthbridge_mobile/view/features/auth/login_screen.dart';
import 'package:healthbridge_mobile/view/features/common/notifications_screen.dart';
import 'package:healthbridge_mobile/view/features/common/profile_screen.dart';
import 'package:healthbridge_mobile/view/features/doctor/doctor_views.dart';
import 'package:healthbridge_mobile/view/features/employee/employee_views.dart';
import 'package:healthbridge_mobile/view/features/insurance_officer/insurance_officer_views.dart';
import 'package:healthbridge_mobile/view/features/pharmacist/pharmacist_views.dart';
import 'package:healthbridge_mobile/view/features/splash/splash_screen.dart';

class AppRouteRegistry {
  static List<GoRoute> build() {
    return [
      GoRoute(
        path: SplashScreen.routePath,
        name: SplashScreen.routeName,
        builder: (_, __) => const SplashScreen(),
      ),
      GoRoute(
        path: LoginScreen.routePath,
        name: LoginScreen.routeName,
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: ProfileScreen.routePath,
        name: ProfileScreen.routeName,
        builder: (_, __) => const ProfileScreen(),
      ),
      GoRoute(
        path: NotificationsScreen.routePath,
        name: NotificationsScreen.routeName,
        builder: (_, __) => const NotificationsScreen(),
      ),
      GoRoute(
        path: DoctorHomeScreen.routePath,
        name: DoctorHomeScreen.routeName,
        builder: (_, __) => const DoctorHomeScreen(),
      ),
      GoRoute(
        path: DoctorPatientSearchScreen.routePath,
        name: DoctorPatientSearchScreen.routeName,
        builder: (_, __) => const DoctorPatientSearchScreen(),
      ),
      GoRoute(
        path: DoctorPatientDetailScreen.routePath,
        name: DoctorPatientDetailScreen.routeName,
        builder: (_, state) => DoctorPatientDetailScreen(
          patientId: int.tryParse(state.uri.queryParameters['id'] ?? ''),
        ),
      ),
      GoRoute(
        path: DoctorPrescriptionCreateScreen.routePath,
        name: DoctorPrescriptionCreateScreen.routeName,
        builder: (_, state) => DoctorPrescriptionCreateScreen(
          patientId: int.tryParse(state.uri.queryParameters['patientId'] ?? ''),
        ),
      ),
      GoRoute(
        path: DoctorMedicationAddScreen.routePath,
        name: DoctorMedicationAddScreen.routeName,
        builder: (_, __) => const DoctorMedicationAddScreen(),
      ),
      GoRoute(
        path: DoctorPrescriptionHistoryScreen.routePath,
        name: DoctorPrescriptionHistoryScreen.routeName,
        builder: (_, __) => const DoctorPrescriptionHistoryScreen(),
      ),
      GoRoute(
        path: DoctorPrescriptionDetailScreen.routePath,
        name: DoctorPrescriptionDetailScreen.routeName,
        builder: (_, state) => DoctorPrescriptionDetailScreen(
          prescriptionId: int.tryParse(state.uri.queryParameters['id'] ?? ''),
        ),
      ),
      GoRoute(
        path: EmployeeHomeScreen.routePath,
        name: EmployeeHomeScreen.routeName,
        builder: (_, __) => const EmployeeHomeScreen(),
      ),
      GoRoute(
        path: EmployeePrescriptionsView.routePath,
        name: EmployeePrescriptionsView.routeName,
        builder: (_, __) => const EmployeePrescriptionsView(),
      ),
      GoRoute(
        path: EmployeePrescriptionDetailView.routePath,
        name: EmployeePrescriptionDetailView.routeName,
        builder: (_, state) => EmployeePrescriptionDetailView(
          prescriptionId: int.tryParse(state.uri.queryParameters['id'] ?? ''),
        ),
      ),
      GoRoute(
        path: EmployeeQrView.routePath,
        name: EmployeeQrView.routeName,
        builder: (_, state) => EmployeeQrView(
          prescriptionId: int.tryParse(state.uri.queryParameters['id'] ?? ''),
        ),
      ),
      GoRoute(
        path: EmployeeMedicationHistoryView.routePath,
        name: EmployeeMedicationHistoryView.routeName,
        builder: (_, __) => const EmployeeMedicationHistoryView(),
      ),
      GoRoute(
        path: EmployeeDependentsView.routePath,
        name: EmployeeDependentsView.routeName,
        builder: (_, __) => const EmployeeDependentsView(),
      ),
      GoRoute(
        path: InsuranceOfficerHomeScreen.routePath,
        name: InsuranceOfficerHomeScreen.routeName,
        builder: (_, __) => const InsuranceOfficerHomeScreen(),
      ),
      GoRoute(
        path: InsuranceRequestsScreen.routePath,
        name: InsuranceRequestsScreen.routeName,
        builder: (_, __) => const InsuranceRequestsScreen(),
      ),
      GoRoute(
        path: InsuranceReviewScreen.routePath,
        name: InsuranceReviewScreen.routeName,
        builder: (_, state) => InsuranceReviewScreen(
          requestId: int.tryParse(state.uri.queryParameters['id'] ?? ''),
        ),
      ),
      GoRoute(
        path: InsuranceCoverageCatalogScreen.routePath,
        name: InsuranceCoverageCatalogScreen.routeName,
        builder: (_, __) => const InsuranceCoverageCatalogScreen(),
      ),
      GoRoute(
        path: PharmacistHomeScreen.routePath,
        name: PharmacistHomeScreen.routeName,
        builder: (_, __) => const PharmacistHomeScreen(),
      ),
      GoRoute(
        path: PharmacistSearchPrescriptionScreen.routePath,
        name: PharmacistSearchPrescriptionScreen.routeName,
        builder: (_, __) => const PharmacistSearchPrescriptionScreen(),
      ),
      GoRoute(
        path: PharmacistQrLookupScreen.routePath,
        name: PharmacistQrLookupScreen.routeName,
        builder: (_, __) => const PharmacistQrLookupScreen(),
      ),
      GoRoute(
        path: PharmacistPrescriptionDetailScreen.routePath,
        name: PharmacistPrescriptionDetailScreen.routeName,
        builder: (_, state) => PharmacistPrescriptionDetailScreen(
          prescriptionId: int.tryParse(state.uri.queryParameters['id'] ?? ''),
        ),
      ),
      GoRoute(
        path: PharmacistDispenseConfirmScreen.routePath,
        name: PharmacistDispenseConfirmScreen.routeName,
        builder: (_, state) => PharmacistDispenseConfirmScreen(
          prescriptionId: int.tryParse(state.uri.queryParameters['id'] ?? ''),
        ),
      ),
      GoRoute(
        path: PharmacistDispenseHistoryScreen.routePath,
        name: PharmacistDispenseHistoryScreen.routeName,
        builder: (_, __) => const PharmacistDispenseHistoryScreen(),
      ),
      GoRoute(
        path: AdminHomeScreen.routePath,
        name: AdminHomeScreen.routeName,
        builder: (_, __) => const AdminHomeScreen(),
      ),
      GoRoute(
        path: AdminUserManagementScreen.routePath,
        name: AdminUserManagementScreen.routeName,
        builder: (_, __) => const AdminUserManagementScreen(),
      ),
      GoRoute(
        path: AdminUserCreateScreen.routePath,
        name: AdminUserCreateScreen.routeName,
        builder: (_, __) => const AdminUserCreateScreen(),
      ),
      GoRoute(
        path: AdminUserEditScreen.routePath,
        name: AdminUserEditScreen.routeName,
        builder: (_, state) => AdminUserEditScreen(
          userId: int.tryParse(state.uri.queryParameters['id'] ?? ''),
        ),
      ),
      GoRoute(
        path: AdminStatisticsScreen.routePath,
        name: AdminStatisticsScreen.routeName,
        builder: (_, __) => const AdminStatisticsScreen(),
      ),
      GoRoute(
        path: AdminAuditLogScreen.routePath,
        name: AdminAuditLogScreen.routeName,
        builder: (_, __) => const AdminAuditLogScreen(),
      ),
      GoRoute(
        path: AdminSettingsScreen.routePath,
        name: AdminSettingsScreen.routeName,
        builder: (_, __) => const AdminSettingsScreen(),
      ),
    ];
  }
}
