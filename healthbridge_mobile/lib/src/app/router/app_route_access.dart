import '../../features/admin/presentation/views/admin_views.dart';
import '../../features/common/presentation/views/notifications_screen.dart';
import '../../features/common/presentation/views/profile_screen.dart';
import '../../features/doctor/presentation/views/doctor_views.dart';
import '../../features/employee/presentation/views/employee_views.dart';
import '../../features/insurance_officer/presentation/views/insurance_officer_views.dart';
import '../../features/pharmacist/presentation/views/pharmacist_views.dart';
import '../../shared/utils/app_roles.dart';

class AppRouteAccess {
  static const _commonRoutes = <String>{
    ProfileScreen.routePath,
    NotificationsScreen.routePath,
  };

  static String homeForRole(String? role) {
    switch (role) {
      case AppRoles.doctor:
        return DoctorHomeScreen.routePath;
      case AppRoles.employee:
      case 'Patient':
        return EmployeeHomeScreen.routePath;
      case AppRoles.pharmacist:
        return PharmacistHomeScreen.routePath;
      case AppRoles.insuranceOfficer:
        return InsuranceOfficerHomeScreen.routePath;
      case AppRoles.admin:
      default:
        return AdminHomeScreen.routePath;
    }
  }

  static Set<String> allowedRoutesForRole(String? role) {
    switch (role) {
      case AppRoles.doctor:
        return {
          ..._commonRoutes,
          DoctorHomeScreen.routePath,
          DoctorPatientSearchScreen.routePath,
          DoctorPatientDetailScreen.routePath,
          DoctorPrescriptionCreateScreen.routePath,
          DoctorMedicationAddScreen.routePath,
          DoctorPrescriptionHistoryScreen.routePath,
          DoctorPrescriptionDetailScreen.routePath,
        };
      case AppRoles.employee:
      case 'Patient':
        return {
          ..._commonRoutes,
          EmployeeHomeScreen.routePath,
          EmployeePrescriptionsView.routePath,
          EmployeePrescriptionDetailView.routePath,
          EmployeeQrView.routePath,
          EmployeeMedicationHistoryView.routePath,
          EmployeeDependentsView.routePath,
        };
      case AppRoles.insuranceOfficer:
        return {
          ..._commonRoutes,
          InsuranceOfficerHomeScreen.routePath,
          InsuranceRequestsScreen.routePath,
          InsuranceReviewScreen.routePath,
          InsuranceCoverageCatalogScreen.routePath,
        };
      case AppRoles.pharmacist:
        return {
          ..._commonRoutes,
          PharmacistHomeScreen.routePath,
          PharmacistSearchPrescriptionScreen.routePath,
          PharmacistQrLookupScreen.routePath,
          PharmacistPrescriptionDetailScreen.routePath,
          PharmacistDispenseConfirmScreen.routePath,
          PharmacistDispenseHistoryScreen.routePath,
        };
      case AppRoles.admin:
      default:
        return {
          ..._commonRoutes,
          AdminHomeScreen.routePath,
          AdminUserManagementScreen.routePath,
          AdminUserCreateScreen.routePath,
          AdminUserEditScreen.routePath,
          AdminStatisticsScreen.routePath,
          AdminAuditLogScreen.routePath,
          AdminSettingsScreen.routePath,
        };
    }
  }
}
