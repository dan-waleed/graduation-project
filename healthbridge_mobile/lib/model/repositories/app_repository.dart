import 'package:healthbridge_mobile/model/models/app_models.dart';
import 'package:healthbridge_mobile/model/models/user_model.dart';
import 'package:healthbridge_mobile/model/services/app_data_service.dart';

class AppRepository {
  AppRepository({required AppDataService appDataService})
    : _appDataService = appDataService;

  AppDataService _appDataService;

  void rebind(AppDataService appDataService) {
    _appDataService = appDataService;
  }

  Future<List<NotificationModel>> getNotifications() =>
      _appDataService.getNotifications();
  Future<List<NotificationModel>> getUnreadNotifications() =>
      _appDataService.getUnreadNotifications();
  Future<int> getUnreadNotificationCount() =>
      _appDataService.getUnreadNotificationCount();
  Future<NotificationModel> markNotificationRead(int id) =>
      _appDataService.markNotificationRead(id);
  Future<void> markAllNotificationsRead() =>
      _appDataService.markAllNotificationsRead();
  Future<List<AuditLogModel>> getAuditLogs() => _appDataService.getAuditLogs();
  Future<SystemSettingsModel> getSystemSettings() =>
      _appDataService.getSystemSettings();
  Future<SystemSettingsModel> updateSystemSettings(
    SystemSettingsModel settings,
  ) => _appDataService.updateSystemSettings(settings);
  Future<List<EmployeeModel>> getEmployees() => _appDataService.getEmployees();
  Future<EmployeeModel> getEmployee(int id) => _appDataService.getEmployee(id);
  Future<EmployeeModel> createEmployee(Map<String, dynamic> payload) =>
      _appDataService.createEmployee(payload);
  Future<EmployeeModel> updateEmployee(int id, Map<String, dynamic> payload) =>
      _appDataService.updateEmployee(id, payload);
  Future<EmployeeModel?> getEmployeeByUser({
    required String username,
    required String email,
  }) => _appDataService.getEmployeeByUser(username: username, email: email);
  Future<List<DependentModel>> getDependents({
    int? employeeId,
    int? patientId,
  }) => _appDataService.getDependents(
    employeeId: employeeId,
    patientId: patientId,
  );
  Future<DependentModel> createDependent(Map<String, dynamic> payload) =>
      _appDataService.createDependent(payload);
  Future<DependentModel> updateDependent(
    int id,
    Map<String, dynamic> payload,
  ) => _appDataService.updateDependent(id, payload);
  Future<void> deleteDependent(int id) => _appDataService.deleteDependent(id);
  Future<List<DoctorDirectoryModel>> searchDoctors({
    String name = '',
    String specialty = '',
    String city = '',
    String providerName = '',
    bool activeOnly = false,
  }) => _appDataService.searchDoctors(
    name: name,
    specialty: specialty,
    city: city,
    providerName: providerName,
    activeOnly: activeOnly,
  );
  Future<int> getDoctorProfileIdForUser(int userId) =>
      _appDataService.getDoctorProfileIdForUser(userId);
  Future<List<PrescriptionModel>> getPrescriptions({String? status}) =>
      _appDataService.getPrescriptions(status: status);
  Future<List<PrescriptionModel>> searchPrescriptions(String query) =>
      _appDataService.searchPrescriptions(query);
  Future<PrescriptionModel> getPrescription(int id) =>
      _appDataService.getPrescription(id);
  Future<PrescriptionModel> createPrescription({
    int? employeeId,
    int? patientId,
    required int doctorId,
    int? dependentId,
    required String diagnosis,
    required String notes,
    required String status,
    required List<Map<String, dynamic>> items,
    String serviceType = 'Medication',
    String providerName = '',
    String serviceName = '',
    double coveragePercentage = 0,
    double coveredAmount = 0,
    double employeeShare = 0,
    double finalPrice = 0,
    bool requiresInsuranceApproval = false,
  }) => _appDataService.createPrescription(
    employeeId: employeeId,
    patientId: patientId,
    doctorId: doctorId,
    dependentId: dependentId,
    diagnosis: diagnosis,
    notes: notes,
    status: status,
    items: items,
    serviceType: serviceType,
    providerName: providerName,
    serviceName: serviceName,
    coveragePercentage: coveragePercentage,
    coveredAmount: coveredAmount,
    employeeShare: employeeShare,
    finalPrice: finalPrice,
    requiresInsuranceApproval: requiresInsuranceApproval,
  );
  Future<PrescriptionModel> updatePrescriptionStatus({
    required int id,
    required String status,
    String? providerNotes,
    double? finalPrice,
  }) => _appDataService.updatePrescriptionStatus(
    id: id,
    status: status,
    providerNotes: providerNotes,
    finalPrice: finalPrice,
  );
  Future<List<MedicationModel>> getMedications({bool serverOnly = false}) =>
      _appDataService.getMedications(serverOnly: serverOnly);
  Future<MedicationModel> ensureMedicationExists(MedicationModel medication) =>
      _appDataService.ensureMedicationExists(medication);
  Future<List<CoverageCatalogItemModel>> getCoverageCatalog({
    String? category,
    String? providerType,
    bool activeOnly = true,
  }) => _appDataService.getCoverageCatalog(
    category: category,
    providerType: providerType,
    activeOnly: activeOnly,
  );
  CoverageCatalogItemModel? findCoverageForMedication(
    MedicationModel medication,
  ) => _appDataService.findCoverageForMedication(medication);
  Future<CoverageCatalogItemModel> createCoverageCatalogItem({
    required CoverageCatalogItemModel item,
  }) => _appDataService.createCoverageCatalogItem(item: item);
  Future<CoverageCatalogItemModel> updateCoverageCatalogItem({
    required CoverageCatalogItemModel item,
  }) => _appDataService.updateCoverageCatalogItem(item: item);
  Future<List<InsuranceRequestModel>> getInsuranceRequests() =>
      _appDataService.getInsuranceRequests();
  Future<InsuranceRequestModel> createInsuranceRequest({
    required int prescriptionId,
  }) => _appDataService.createInsuranceRequest(prescriptionId: prescriptionId);
  Future<InsuranceRequestModel> updateInsuranceRequest({
    required int id,
    required String status,
    required String notes,
  }) => _appDataService.updateInsuranceRequest(
    id: id,
    status: status,
    notes: notes,
  );
  Future<List<DispenseModel>> getDispenses() => _appDataService.getDispenses();
  Future<DispenseModel> createDispense({
    required int prescriptionId,
    required String dispenseNumber,
    required String status,
    required String notes,
  }) => _appDataService.createDispense(
    prescriptionId: prescriptionId,
    dispenseNumber: dispenseNumber,
    status: status,
    notes: notes,
  );
  Future<List<UserModel>> getUsers() => _appDataService.getUsers();
  Future<UserModel> createUser(Map<String, dynamic> payload) =>
      _appDataService.createUser(payload);
  Future<UserModel> updateUser(int id, Map<String, dynamic> payload) =>
      _appDataService.updateUser(id, payload);
  Future<void> deleteUser(int id) => _appDataService.deleteUser(id);
}
