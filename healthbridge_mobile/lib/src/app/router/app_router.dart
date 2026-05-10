import 'package:go_router/go_router.dart';

import '../../features/admin/presentation/screens/admin_home_screen.dart';
import '../../features/auth/presentation/controller/auth_controller.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/common/presentation/screens/notifications_screen.dart';
import '../../features/common/presentation/screens/profile_screen.dart';
import '../../features/doctor/presentation/screens/doctor_home_screen.dart';
import '../../features/insurance_officer/presentation/screens/insurance_officer_home_screen.dart';
import '../../features/patient/presentation/screens/patient_home_screen.dart';
import '../../features/pharmacist/presentation/screens/pharmacist_home_screen.dart';
import '../../features/provider_roles/presentation/screens/provider_roles_screens.dart';
import '../../features/splash/presentation/screens/splash_screen.dart';

class AppRouter {
  AppRouter(this.authController);

  final AuthController authController;

  late final GoRouter router = GoRouter(
    initialLocation: SplashScreen.routePath,
    refreshListenable: authController,
    routes: [
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
        path: PatientHomeScreen.routePath,
        name: PatientHomeScreen.routeName,
        builder: (_, __) => const PatientHomeScreen(),
      ),
      GoRoute(
        path: PatientPrescriptionsScreen.routePath,
        name: PatientPrescriptionsScreen.routeName,
        builder: (_, __) => const PatientPrescriptionsScreen(),
      ),
      GoRoute(
        path: PatientPrescriptionDetailScreen.routePath,
        name: PatientPrescriptionDetailScreen.routeName,
        builder: (_, state) => PatientPrescriptionDetailScreen(
          prescriptionId: int.tryParse(state.uri.queryParameters['id'] ?? ''),
        ),
      ),
      GoRoute(
        path: PatientQrScreen.routePath,
        name: PatientQrScreen.routeName,
        builder: (_, state) => PatientQrScreen(
          prescriptionId: int.tryParse(state.uri.queryParameters['id'] ?? ''),
        ),
      ),
      GoRoute(
        path: PatientMedicationHistoryScreen.routePath,
        name: PatientMedicationHistoryScreen.routeName,
        builder: (_, __) => const PatientMedicationHistoryScreen(),
      ),
      GoRoute(
        path: PatientDependentsScreen.routePath,
        name: PatientDependentsScreen.routeName,
        builder: (_, __) => const PatientDependentsScreen(),
      ),
      GoRoute(
        path: EmployeeDoctorSearchScreen.routePath,
        name: EmployeeDoctorSearchScreen.routeName,
        builder: (_, __) => const EmployeeDoctorSearchScreen(),
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
        path: InsuranceDecisionScreen.routePath,
        name: InsuranceDecisionScreen.routeName,
        builder: (_, state) => InsuranceDecisionScreen(
          decision: state.uri.queryParameters['decision'] ?? 'موافقة',
          requestId: int.tryParse(state.uri.queryParameters['id'] ?? ''),
        ),
      ),
      GoRoute(
        path: InsuranceCoverageCatalogScreen.routePath,
        name: InsuranceCoverageCatalogScreen.routeName,
        builder: (_, __) => const InsuranceCoverageCatalogScreen(),
      ),
      GoRoute(
        path: LaboratoryHomeScreen.routePath,
        name: LaboratoryHomeScreen.routeName,
        builder: (_, __) => const LaboratoryHomeScreen(),
      ),
      GoRoute(
        path: LaboratoryRequestsScreen.routePath,
        name: LaboratoryRequestsScreen.routeName,
        builder: (_, __) => const LaboratoryRequestsScreen(),
      ),
      GoRoute(
        path: LaboratoryRequestDetailScreen.routePath,
        name: LaboratoryRequestDetailScreen.routeName,
        builder: (_, state) => LaboratoryRequestDetailScreen(
          orderId: int.tryParse(state.uri.queryParameters['id'] ?? ''),
        ),
      ),
      GoRoute(
        path: MedicalImagingCenterHomeScreen.routePath,
        name: MedicalImagingCenterHomeScreen.routeName,
        builder: (_, __) => const MedicalImagingCenterHomeScreen(),
      ),
      GoRoute(
        path: ImagingRequestsScreen.routePath,
        name: ImagingRequestsScreen.routeName,
        builder: (_, __) => const ImagingRequestsScreen(),
      ),
      GoRoute(
        path: ImagingRequestDetailScreen.routePath,
        name: ImagingRequestDetailScreen.routeName,
        builder: (_, state) => ImagingRequestDetailScreen(
          orderId: int.tryParse(state.uri.queryParameters['id'] ?? ''),
        ),
      ),
      GoRoute(
        path: MedicalCenterHomeScreen.routePath,
        name: MedicalCenterHomeScreen.routeName,
        builder: (_, __) => const MedicalCenterHomeScreen(),
      ),
      GoRoute(
        path: MedicalCenterRequestsScreen.routePath,
        name: MedicalCenterRequestsScreen.routeName,
        builder: (_, __) => const MedicalCenterRequestsScreen(),
      ),
      GoRoute(
        path: MedicalCenterRequestDetailScreen.routePath,
        name: MedicalCenterRequestDetailScreen.routeName,
        builder: (_, state) => MedicalCenterRequestDetailScreen(
          orderId: int.tryParse(state.uri.queryParameters['id'] ?? ''),
        ),
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
        path: AdminSettingsScreen.routePath,
        name: AdminSettingsScreen.routeName,
        builder: (_, __) => const AdminSettingsScreen(),
      ),
    ],
    redirect: (_, state) {
      final authState = authController.state;
      final currentPath = state.matchedLocation;

      if (authState == AuthFlowState.bootstrapping) {
        return currentPath == SplashScreen.routePath ? null : SplashScreen.routePath;
      }

      if (!authController.isAuthenticated) {
        return currentPath == LoginScreen.routePath ? null : LoginScreen.routePath;
      }

      if (currentPath == SplashScreen.routePath || currentPath == LoginScreen.routePath) {
        return _routeForRole(authController.currentUser?.role);
      }

      final allowedRoutes = _allowedRoutesForRole(authController.currentUser?.role);
      if (!allowedRoutes.contains(currentPath)) {
        return _routeForRole(authController.currentUser?.role);
      }

      return null;
    },
  );

  String _routeForRole(String? role) {
    switch (role) {
      case 'Doctor':
        return DoctorHomeScreen.routePath;
      case 'Employee':
      case 'Patient':
        return PatientHomeScreen.routePath;
      case 'Pharmacist':
        return PharmacistHomeScreen.routePath;
      case 'Laboratory':
        return LaboratoryHomeScreen.routePath;
      case 'ImagingCenter':
        return MedicalImagingCenterHomeScreen.routePath;
      case 'MedicalCenter':
        return MedicalCenterHomeScreen.routePath;
      case 'InsuranceOfficer':
        return InsuranceOfficerHomeScreen.routePath;
      case 'Admin':
      default:
        return AdminHomeScreen.routePath;
    }
  }

  Set<String> _allowedRoutesForRole(String? role) {
    const commonRoutes = {
      ProfileScreen.routePath,
      NotificationsScreen.routePath,
    };

    switch (role) {
      case 'Doctor':
        return {
          ...commonRoutes,
          DoctorHomeScreen.routePath,
          DoctorPatientSearchScreen.routePath,
          DoctorPatientDetailScreen.routePath,
          DoctorPrescriptionCreateScreen.routePath,
          DoctorMedicationAddScreen.routePath,
          DoctorPrescriptionHistoryScreen.routePath,
          DoctorPrescriptionDetailScreen.routePath,
        };
      case 'Employee':
      case 'Patient':
        return {
          ...commonRoutes,
          PatientHomeScreen.routePath,
          PatientPrescriptionsScreen.routePath,
          PatientPrescriptionDetailScreen.routePath,
          PatientQrScreen.routePath,
          PatientMedicationHistoryScreen.routePath,
          PatientDependentsScreen.routePath,
          EmployeeDoctorSearchScreen.routePath,
        };
      case 'Pharmacist':
        return {
          ...commonRoutes,
          PharmacistHomeScreen.routePath,
          PharmacistSearchPrescriptionScreen.routePath,
          PharmacistQrLookupScreen.routePath,
          PharmacistPrescriptionDetailScreen.routePath,
          PharmacistDispenseConfirmScreen.routePath,
          PharmacistDispenseHistoryScreen.routePath,
        };
      case 'Laboratory':
        return {
          ...commonRoutes,
          LaboratoryHomeScreen.routePath,
          LaboratoryRequestsScreen.routePath,
          LaboratoryRequestDetailScreen.routePath,
        };
      case 'ImagingCenter':
        return {
          ...commonRoutes,
          MedicalImagingCenterHomeScreen.routePath,
          ImagingRequestsScreen.routePath,
          ImagingRequestDetailScreen.routePath,
        };
      case 'MedicalCenter':
        return {
          ...commonRoutes,
          MedicalCenterHomeScreen.routePath,
          MedicalCenterRequestsScreen.routePath,
          MedicalCenterRequestDetailScreen.routePath,
        };
      case 'InsuranceOfficer':
        return {
          ...commonRoutes,
          InsuranceOfficerHomeScreen.routePath,
          InsuranceRequestsScreen.routePath,
          InsuranceReviewScreen.routePath,
          InsuranceDecisionScreen.routePath,
          InsuranceCoverageCatalogScreen.routePath,
        };
      case 'Admin':
      default:
        return {
          ...commonRoutes,
          AdminHomeScreen.routePath,
          AdminUserManagementScreen.routePath,
          AdminUserCreateScreen.routePath,
          AdminUserEditScreen.routePath,
          AdminStatisticsScreen.routePath,
          AdminSettingsScreen.routePath,
        };
    }
  }
}
