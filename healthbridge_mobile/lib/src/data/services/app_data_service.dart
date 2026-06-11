import 'package:flutter/foundation.dart';

import '../../core/config/app_config.dart';
import '../../core/errors/app_exception.dart';
import '../../core/network/api_client.dart';
import '../../shared/utils/app_roles.dart';
import '../models/app_models.dart';
import '../models/user_model.dart';

class AppDataService {
  AppDataService({
    required ApiClient apiClient,
    bool enableLocalDemoMode = AppConfig.enableLocalDemoMode,
  }) : _apiClient = apiClient,
       _enableLocalDemoMode = enableLocalDemoMode;

  ApiClient _apiClient;
  final bool _enableLocalDemoMode;
  final List<NotificationModel> _debugNotifications =
      List<NotificationModel>.from(_buildDebugNotifications());
  final List<EmployeeModel> _debugEmployees = List<EmployeeModel>.from(
    _buildDebugEmployees(),
  );
  final List<MedicationModel> _debugMedications = List<MedicationModel>.from(
    _buildDebugMedications(),
  );
  final List<CoverageCatalogItemModel> _debugCoverageCatalog =
      List<CoverageCatalogItemModel>.from(_buildDebugCoverageCatalog());
  final List<PrescriptionModel> _debugPrescriptions =
      List<PrescriptionModel>.from(_buildDebugPrescriptions());
  final List<DependentModel> _debugDependents = List<DependentModel>.from(
    _buildDebugDependents(),
  );
  final List<DoctorDirectoryModel> _debugDoctors =
      List<DoctorDirectoryModel>.from(_buildDebugDoctors());
  final List<InsuranceRequestModel> _debugInsuranceRequests =
      List<InsuranceRequestModel>.from(_buildDebugInsuranceRequests());
  final List<DispenseModel> _debugDispenses = List<DispenseModel>.from(
    _buildDebugDispenses(),
  );
  final List<UserModel> _debugUsers = List<UserModel>.from(_buildDebugUsers());

  void rebind(ApiClient apiClient) {
    _apiClient = apiClient;
  }

  bool get _shouldUseDemoMode => _enableLocalDemoMode && _apiClient.isDemoToken;
  bool get _allowLocalDemoFallback => _enableLocalDemoMode && kDebugMode;

  double _roundToScale(double value, {int scale = 2}) {
    final factor = switch (scale) {
      0 => 1,
      1 => 10,
      2 => 100,
      3 => 1000,
      4 => 10000,
      _ => 100,
    };
    return (value * factor).round() / factor;
  }

  Map<String, dynamic> _normalizedDemoUserPayload(
    Map<String, dynamic> payload,
  ) {
    final nestedUser = payload['user'];
    if (nestedUser is Map<String, dynamic>) {
      return nestedUser;
    }
    return payload;
  }

  List<Map<String, dynamic>> _normalizedDemoDependentsPayload(
    Map<String, dynamic> payload,
  ) {
    final rawDependents = payload['dependents'];
    if (rawDependents is List) {
      return rawDependents.whereType<Map<String, dynamic>>().toList();
    }
    return const <Map<String, dynamic>>[];
  }

  void _replaceEmployeeDependents(
    int employeeId,
    List<DependentModel> dependents,
  ) {
    final employeeIndex = _debugEmployees.indexWhere(
      (item) => item.id == employeeId,
    );
    if (employeeIndex == -1) return;

    final current = _debugEmployees[employeeIndex];
    _debugEmployees[employeeIndex] = EmployeeModel(
      id: current.id,
      fullName: current.fullName,
      username: current.username,
      email: current.email,
      phoneNumber: current.phoneNumber,
      medicalRecordNumber: current.medicalRecordNumber,
      insuranceProvider: current.insuranceProvider,
      address: current.address,
      dependents: dependents,
      dateOfBirth: current.dateOfBirth,
      nationalId: current.nationalId,
      universityId: current.universityId,
      insuranceNumber: current.insuranceNumber,
      gender: current.gender,
    );
  }

  void _attachDependentToEmployee(int employeeId, DependentModel dependent) {
    final employeeIndex = _debugEmployees.indexWhere(
      (item) => item.id == employeeId,
    );
    if (employeeIndex == -1) return;

    final current = _debugEmployees[employeeIndex];
    final updatedDependents = [...current.dependents, dependent];
    _replaceEmployeeDependents(employeeId, updatedDependents);
  }

  void _replaceDependentInEmployees(DependentModel updatedDependent) {
    for (final employee in _debugEmployees) {
      final hasDependent = employee.dependents.any(
        (item) => item.id == updatedDependent.id,
      );
      if (!hasDependent) continue;

      final updatedDependents = employee.dependents
          .map(
            (item) => item.id == updatedDependent.id ? updatedDependent : item,
          )
          .toList();
      _replaceEmployeeDependents(employee.id, updatedDependents);
      break;
    }
  }

  void _removeDependentFromEmployees(int dependentId) {
    for (final employee in _debugEmployees) {
      final hasDependent = employee.dependents.any(
        (item) => item.id == dependentId,
      );
      if (!hasDependent) continue;

      final updatedDependents = employee.dependents
          .where((item) => item.id != dependentId)
          .toList();
      _replaceEmployeeDependents(employee.id, updatedDependents);
      break;
    }
  }

  Future<List<NotificationModel>> getNotifications() async {
    if (_shouldUseDemoMode) {
      return List<NotificationModel>.from(_debugNotifications);
    }

    try {
      final response = await _apiClient.getList('notifications/');
      final notifications = response
          .whereType<Map<String, dynamic>>()
          .map(NotificationModel.fromJson)
          .toList();
      return _mergeWithDebugNotifications(notifications);
    } catch (_) {
      if (_allowLocalDemoFallback) {
        return const <NotificationModel>[];
      }
      rethrow;
    }
  }

  Future<List<NotificationModel>> getUnreadNotifications() async {
    if (_shouldUseDemoMode) {
      return _debugNotifications.where((item) => !item.isRead).toList();
    }

    try {
      final response = await _apiClient.getList('notifications/?is_read=false');
      final notifications = response
          .whereType<Map<String, dynamic>>()
          .map(NotificationModel.fromJson)
          .toList();
      return _mergeWithDebugNotifications(
        notifications.where((item) => !item.isRead).toList(),
      );
    } catch (_) {
      if (_allowLocalDemoFallback) {
        return const <NotificationModel>[];
      }
      rethrow;
    }
  }

  Future<int> getUnreadNotificationCount() async {
    if (_shouldUseDemoMode) {
      return _debugNotifications.where((item) => !item.isRead).length;
    }

    try {
      final response = await _apiClient.get('notifications/unread-count/');
      return response['count'] as int? ?? 0;
    } catch (_) {
      if (_allowLocalDemoFallback) {
        return 0;
      }
      rethrow;
    }
  }

  Future<NotificationModel> markNotificationRead(int id) async {
    final debugIndex = _debugNotifications.indexWhere((item) => item.id == id);
    if (debugIndex != -1) {
      final current = _debugNotifications[debugIndex];
      final updated = NotificationModel(
        id: current.id,
        title: current.title,
        message: current.message,
        notificationType: current.notificationType,
        isRead: true,
        relatedEntityType: current.relatedEntityType,
        relatedEntityId: current.relatedEntityId,
        createdAt: current.createdAt,
        readAt: DateTime.now(),
      );
      _debugNotifications[debugIndex] = updated;
      return updated;
    }

    final response = await _apiClient.post(
      'notifications/$id/mark-read/',
      body: const {},
    );
    return NotificationModel.fromJson(response);
  }

  Future<void> markAllNotificationsRead() async {
    for (var index = 0; index < _debugNotifications.length; index++) {
      final current = _debugNotifications[index];
      _debugNotifications[index] = NotificationModel(
        id: current.id,
        title: current.title,
        message: current.message,
        notificationType: current.notificationType,
        isRead: true,
        relatedEntityType: current.relatedEntityType,
        relatedEntityId: current.relatedEntityId,
        createdAt: current.createdAt,
        readAt: DateTime.now(),
      );
    }

    try {
      await _apiClient.post('notifications/mark-all-read/', body: const {});
    } catch (_) {
      if (!_allowLocalDemoFallback) rethrow;
    }
  }

  Future<List<AuditLogModel>> getAuditLogs() async {
    if (_shouldUseDemoMode) {
      return const [];
    }

    final logs = <AuditLogModel>[];
    var page = 1;

    while (true) {
      final response = await _apiClient.get(
        'audit-logs/?page=$page&page_size=100',
      );
      final pageResults = (response['results'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(AuditLogModel.fromJson)
          .toList();
      logs.addAll(pageResults);

      final nextPage = response['next'] as String?;
      if (nextPage == null || nextPage.isEmpty || pageResults.isEmpty) {
        break;
      }
      page += 1;
    }

    return logs;
  }

  Future<SystemSettingsModel> getSystemSettings() async {
    if (_shouldUseDemoMode) {
      return const SystemSettingsModel(
        systemName: 'هيلث بريدج',
        organizationName: 'جامعة بوليتكنك فلسطين',
        shortDescription: 'نظام إلكتروني لإدارة الوصفات الطبية والتأمين والصرف',
        notificationsEnabled: true,
        insuranceWorkflowEnabled: true,
        pharmacistNotesRequired: false,
        interfaceLanguage: 'العربية',
        sessionTimeoutMinutes: 30,
        adminNotes: '',
      );
    }

    final response = await _apiClient.get('system-settings/');
    return SystemSettingsModel.fromJson(response);
  }

  Future<SystemSettingsModel> updateSystemSettings(
    SystemSettingsModel settings,
  ) async {
    if (_shouldUseDemoMode) {
      return settings;
    }

    final response = await _apiClient.patch(
      'system-settings/',
      body: settings.toPatchPayload(),
    );
    return SystemSettingsModel.fromJson(response);
  }

  List<NotificationModel> _mergeWithDebugNotifications(
    List<NotificationModel> notifications,
  ) {
    return notifications;
  }

  static List<NotificationModel> _buildDebugNotifications() {
    if (!kDebugMode) {
      return <NotificationModel>[];
    }

    final now = DateTime.now();
    return <NotificationModel>[
      NotificationModel(
        id: -1,
        title: 'طلب تأمين جديد للاختبار',
        message:
            'هذه رسالة تجريبية للتأكد من أن شاشة الإشعارات تعمل بشكل صحيح.',
        notificationType: 'Test',
        isRead: false,
        relatedEntityType: '',
        relatedEntityId: '',
        createdAt: now.subtract(const Duration(minutes: 5)),
      ),
      NotificationModel(
        id: -2,
        title: 'تحديث حالة وصفة',
        message:
            'تم اعتماد الوصفة رقم TEST-102 ويمكنك فتح الإشعار لتجربة التنقل.',
        notificationType: 'Prescription',
        isRead: false,
        relatedEntityType: '',
        relatedEntityId: '',
        createdAt: now.subtract(const Duration(hours: 1)),
      ),
      NotificationModel(
        id: -3,
        title: 'تنبيه صرف دواء',
        message:
            'هذا إشعار وهمي لاختبار القراءة والتحديث بدون الاعتماد على الخادم.',
        notificationType: 'Dispense',
        isRead: true,
        relatedEntityType: '',
        relatedEntityId: '',
        createdAt: now.subtract(const Duration(hours: 3)),
        readAt: now.subtract(const Duration(hours: 2)),
      ),
      NotificationModel(
        id: -4,
        title: 'مراجعة إشعارات الواجهة',
        message:
            'يمكنك استخدام هذا العنصر لاختبار التبديل بين كل الإشعارات وغير المقروءة.',
        notificationType: 'UI Test',
        isRead: false,
        relatedEntityType: '',
        relatedEntityId: '',
        createdAt: now.subtract(const Duration(days: 1)),
      ),
    ];
  }

  Future<List<EmployeeModel>> getEmployees() async {
    if (_shouldUseDemoMode) {
      return List<EmployeeModel>.from(_debugEmployees);
    }

    try {
      final response = await _apiClient.getList('employees/');
      final employees = response
          .whereType<Map<String, dynamic>>()
          .map(EmployeeModel.fromJson)
          .toList();
      return _mergeWithDebugEmployees(employees);
    } catch (_) {
      if (_allowLocalDemoFallback) {
        return List<EmployeeModel>.from(_debugEmployees);
      }
      rethrow;
    }
  }

  Future<List<EmployeeModel>> getPatients() => getEmployees();

  Future<EmployeeModel> getEmployee(int id) async {
    final debugMatch = _debugEmployees
        .where((employee) => employee.id == id)
        .toList();
    if (_shouldUseDemoMode && debugMatch.isNotEmpty) {
      return debugMatch.first;
    }

    final response = await _apiClient.get('employees/$id/');
    return EmployeeModel.fromJson(response);
  }

  Future<EmployeeModel> getPatient(int id) => getEmployee(id);

  Future<EmployeeModel?> getEmployeeByUser({
    required String username,
    required String email,
  }) async {
    final employees = await getEmployees();
    for (final employee in employees) {
      if (employee.username == username ||
          (email.isNotEmpty && employee.email == email)) {
        return employee;
      }
    }
    return null;
  }

  Future<EmployeeModel?> getPatientByUser({
    required String username,
    required String email,
  }) => getEmployeeByUser(username: username, email: email);

  Future<EmployeeModel> createEmployee(Map<String, dynamic> payload) async {
    if (_shouldUseDemoMode) {
      final userPayload = _normalizedDemoUserPayload(payload);
      final dependentPayloads = _normalizedDemoDependentsPayload(payload);
      final createdDependents = dependentPayloads.map((dependentPayload) {
        return DependentModel(
          id:
              DateTime.now().microsecondsSinceEpoch +
              dependentPayloads.indexOf(dependentPayload),
          fullName: dependentPayload['full_name'] as String? ?? 'مستفيد تجريبي',
          relation:
              dependentPayload['relation'] as String? ??
              dependentPayload['relationship'] as String? ??
              '',
          relationship:
              dependentPayload['relationship'] as String? ??
              dependentPayload['relation'] as String? ??
              '',
          notes: dependentPayload['notes'] as String? ?? '',
          isActive: dependentPayload['is_active'] as bool? ?? true,
          nationalId: dependentPayload['national_id'] as String? ?? '',
          dateOfBirth: dependentPayload['date_of_birth'] == null
              ? null
              : DateTime.tryParse(dependentPayload['date_of_birth'] as String),
        );
      }).toList();
      final employee = EmployeeModel(
        id: DateTime.now().millisecondsSinceEpoch,
        fullName:
            userPayload['full_name'] as String? ??
            userPayload['username'] as String? ??
            payload['full_name'] as String? ??
            'مستخدم تجريبي',
        username:
            userPayload['username'] as String? ??
            payload['username'] as String? ??
            'demo_employee',
        email:
            userPayload['email'] as String? ??
            payload['email'] as String? ??
            '',
        phoneNumber:
            userPayload['phone_number'] as String? ??
            userPayload['phone'] as String? ??
            payload['phone_number'] as String? ??
            '',
        medicalRecordNumber:
            payload['medical_record_number'] as String? ?? 'MRN-DEMO',
        insuranceProvider: payload['insurance_provider'] as String? ?? 'تجريبي',
        address: payload['address'] as String? ?? '',
        dependents: createdDependents,
        dateOfBirth: payload['date_of_birth'] == null
            ? null
            : DateTime.tryParse(payload['date_of_birth'] as String),
        nationalId: payload['national_id'] as String? ?? '',
        universityId: payload['university_id'] as String? ?? '',
        insuranceNumber: payload['insurance_number'] as String? ?? '',
        gender: payload['gender'] as String? ?? '',
      );
      _debugDependents.addAll(createdDependents);
      _debugEmployees.add(employee);
      return employee;
    }

    final response = await _apiClient.post('employees/', body: payload);
    return EmployeeModel.fromJson(response);
  }

  Future<EmployeeModel> createPatient(Map<String, dynamic> payload) =>
      createEmployee(payload);

  Future<EmployeeModel> updateEmployee(
    int id,
    Map<String, dynamic> payload,
  ) async {
    final debugIndex = _debugEmployees.indexWhere((item) => item.id == id);
    if (_shouldUseDemoMode && debugIndex != -1) {
      final current = _debugEmployees[debugIndex];
      final updated = EmployeeModel(
        id: current.id,
        fullName: payload['full_name'] as String? ?? current.fullName,
        username: payload['username'] as String? ?? current.username,
        email: payload['email'] as String? ?? current.email,
        phoneNumber: payload['phone_number'] as String? ?? current.phoneNumber,
        medicalRecordNumber:
            payload['medical_record_number'] as String? ??
            current.medicalRecordNumber,
        insuranceProvider:
            payload['insurance_provider'] as String? ??
            current.insuranceProvider,
        address: payload['address'] as String? ?? current.address,
        dependents: current.dependents,
        dateOfBirth: current.dateOfBirth,
        nationalId: payload['national_id'] as String? ?? current.nationalId,
        universityId:
            payload['university_id'] as String? ?? current.universityId,
        insuranceNumber:
            payload['insurance_number'] as String? ?? current.insuranceNumber,
        gender: payload['gender'] as String? ?? current.gender,
      );
      _debugEmployees[debugIndex] = updated;
      return updated;
    }

    final response = await _apiClient.patch('employees/$id/', body: payload);
    return EmployeeModel.fromJson(response);
  }

  Future<EmployeeModel> updatePatient(int id, Map<String, dynamic> payload) =>
      updateEmployee(id, payload);

  Future<List<DependentModel>> getDependents({
    int? employeeId,
    int? patientId,
  }) async {
    final selectedEmployeeId = employeeId ?? patientId;
    if (_shouldUseDemoMode) {
      if (selectedEmployeeId == null) {
        return List<DependentModel>.from(_debugDependents);
      }
      final employee = _debugEmployees
          .where((item) => item.id == selectedEmployeeId)
          .toList();
      if (employee.isNotEmpty) {
        return List<DependentModel>.from(employee.first.dependents);
      }
      return const <DependentModel>[];
    }

    final endpoint = selectedEmployeeId == null
        ? 'dependents/'
        : 'dependents/?employee=$selectedEmployeeId';
    try {
      final response = await _apiClient.getList(endpoint);
      return response
          .whereType<Map<String, dynamic>>()
          .map(DependentModel.fromJson)
          .toList();
    } catch (_) {
      if (_allowLocalDemoFallback) {
        if (selectedEmployeeId == null) {
          return List<DependentModel>.from(_debugDependents);
        }
        final employee = _debugEmployees
            .where((item) => item.id == selectedEmployeeId)
            .toList();
        return employee.isEmpty
            ? const <DependentModel>[]
            : List<DependentModel>.from(employee.first.dependents);
      }
      rethrow;
    }
  }

  Future<DependentModel> createDependent(Map<String, dynamic> payload) async {
    if (_shouldUseDemoMode) {
      final dependent = DependentModel(
        id: DateTime.now().millisecondsSinceEpoch,
        fullName: payload['full_name'] as String? ?? 'مستفيد تجريبي',
        relation:
            payload['relation'] as String? ??
            payload['relationship'] as String? ??
            '',
        relationship:
            payload['relationship'] as String? ??
            payload['relation'] as String? ??
            '',
        notes: payload['notes'] as String? ?? '',
        isActive: payload['is_active'] as bool? ?? true,
        nationalId: payload['national_id'] as String? ?? '',
        dateOfBirth: payload['date_of_birth'] == null
            ? null
            : DateTime.tryParse(payload['date_of_birth'] as String),
      );
      _debugDependents.add(dependent);
      final employeeId =
          payload['employee'] as int? ?? payload['patient'] as int?;
      if (employeeId != null) {
        _attachDependentToEmployee(employeeId, dependent);
      }
      return dependent;
    }

    final response = await _apiClient.post('dependents/', body: payload);
    return DependentModel.fromJson(response);
  }

  Future<DependentModel> updateDependent(
    int id,
    Map<String, dynamic> payload,
  ) async {
    final debugIndex = _debugDependents.indexWhere((item) => item.id == id);
    if (_shouldUseDemoMode && debugIndex != -1) {
      final current = _debugDependents[debugIndex];
      final updated = DependentModel(
        id: current.id,
        fullName: payload['full_name'] as String? ?? current.fullName,
        relation: payload['relation'] as String? ?? current.relation,
        relationship:
            payload['relationship'] as String? ?? current.relationship,
        notes: payload['notes'] as String? ?? current.notes,
        isActive: payload['is_active'] as bool? ?? current.isActive,
        nationalId: payload['national_id'] as String? ?? current.nationalId,
        dateOfBirth: payload['date_of_birth'] == null
            ? current.dateOfBirth
            : DateTime.tryParse(payload['date_of_birth'] as String),
      );
      _debugDependents[debugIndex] = updated;
      _replaceDependentInEmployees(updated);
      return updated;
    }

    final response = await _apiClient.patch('dependents/$id/', body: payload);
    return DependentModel.fromJson(response);
  }

  Future<void> deleteDependent(int id) {
    if (_shouldUseDemoMode) {
      _debugDependents.removeWhere((item) => item.id == id);
      _removeDependentFromEmployees(id);
      return Future.value();
    }
    return _apiClient.delete('dependents/$id/');
  }

  Future<List<MedicationModel>> getMedications() async {
    if (_shouldUseDemoMode) {
      return List<MedicationModel>.from(_debugMedications);
    }

    try {
      final response = await _apiClient.getList('medications/');
      final medications = response
          .whereType<Map<String, dynamic>>()
          .map(MedicationModel.fromJson)
          .toList();
      return _mergeWithDebugMedications(medications);
    } catch (_) {
      if (_allowLocalDemoFallback) {
        return List<MedicationModel>.from(_debugMedications);
      }
      rethrow;
    }
  }

  Future<List<CoverageCatalogItemModel>> getCoverageCatalog({
    String? category,
    String? providerType,
    bool activeOnly = true,
  }) async {
    final normalizedCategory = category?.trim().toLowerCase();
    final normalizedProviderType = providerType?.trim().toLowerCase();
    final normalizedCoverage = _normalizedDebugCoverageCatalog();

    return normalizedCoverage.where((item) {
      final matchesCategory =
          normalizedCategory == null ||
          normalizedCategory.isEmpty ||
          item.category.toLowerCase() == normalizedCategory;
      final matchesProviderType =
          normalizedProviderType == null ||
          normalizedProviderType.isEmpty ||
          item.providerType.toLowerCase() == normalizedProviderType;
      final matchesActive = !activeOnly || item.isActive;
      return matchesCategory && matchesProviderType && matchesActive;
    }).toList();
  }

  CoverageCatalogItemModel? findCoverageForMedication(
    MedicationModel medication,
  ) {
    final medicationName = medication.name.trim().toLowerCase();
    final genericName = medication.genericName.trim().toLowerCase();

    for (final item in _normalizedDebugCoverageCatalog()) {
      if (item.category != 'Medication') continue;
      final itemTitle = item.title.trim().toLowerCase();
      final itemGeneric = item.genericName.trim().toLowerCase();
      if (itemTitle == medicationName ||
          (genericName.isNotEmpty && itemGeneric == genericName) ||
          itemTitle.contains(medicationName) ||
          (genericName.isNotEmpty && itemTitle.contains(genericName))) {
        return item;
      }
    }

    return CoverageCatalogItemModel(
      id: 7000 + medication.id,
      code: 'MED-${medication.id}',
      title: medication.name.isEmpty ? medication.genericName : medication.name,
      category: 'Medication',
      providerType: 'Pharmacy',
      providerName: 'شبكة الصيدليات المتعاقدة',
      unitPrice: _debugMedicationPrice(medication),
      coveragePercentage: 70,
      maxQuantity: 3,
      requiresInsuranceApproval: medication.dosageForm == 'Injection',
      isActive: true,
      description: 'تغطية تلقائية لهذا الدواء.',
      notes: 'تم تعيين سعر افتراضي ونسبة تغطية 70٪.',
      genericName: medication.genericName,
      strength: medication.strength,
    );
  }

  List<CoverageCatalogItemModel> _normalizedDebugCoverageCatalog() {
    final normalized = _debugCoverageCatalog.map((item) {
      if (item.category == 'Medication' && item.providerType == 'Pharmacy') {
        return _copyCoverageItem(item, coveragePercentage: 70);
      }
      return item;
    }).toList();

    final existingMedicationNames = normalized
        .where((item) => item.category == 'Medication')
        .map((item) => item.title.trim().toLowerCase())
        .toSet();

    for (final medication in _debugMedications) {
      if (existingMedicationNames.contains(
        medication.name.trim().toLowerCase(),
      )) {
        continue;
      }
      normalized.add(
        CoverageCatalogItemModel(
          id: 7000 + medication.id,
          code: 'MED-${medication.id}',
          title: medication.name,
          category: 'Medication',
          providerType: 'Pharmacy',
          providerName: 'شبكة الصيدليات المتعاقدة',
          unitPrice: _debugMedicationPrice(medication),
          coveragePercentage: 70,
          maxQuantity: 3,
          requiresInsuranceApproval: medication.dosageForm == 'Injection',
          isActive: true,
          description: 'تغطية دوائية افتراضية لهذا الصنف.',
          notes: 'نسبة التغطية الموحدة للأدوية 70٪.',
          genericName: medication.genericName,
          strength: medication.strength,
        ),
      );
    }

    return normalized;
  }

  CoverageCatalogItemModel _copyCoverageItem(
    CoverageCatalogItemModel item, {
    double? coveragePercentage,
  }) {
    return CoverageCatalogItemModel(
      id: item.id,
      code: item.code,
      title: item.title,
      category: item.category,
      providerType: item.providerType,
      providerName: item.providerName,
      unitPrice: item.unitPrice,
      coveragePercentage: coveragePercentage ?? item.coveragePercentage,
      maxQuantity: item.maxQuantity,
      requiresInsuranceApproval: item.requiresInsuranceApproval,
      isActive: item.isActive,
      description: item.description,
      notes: item.notes,
      genericName: item.genericName,
      strength: item.strength,
    );
  }

  double _debugMedicationPrice(MedicationModel medication) {
    switch (medication.dosageForm.trim()) {
      case 'Injection':
        return 45;
      case 'Inhaler':
        return 38;
      case 'Capsule':
        return 24;
      case 'Tablet':
        return 18;
      default:
        return 20;
    }
  }

  Future<CoverageCatalogItemModel> createCoverageCatalogItem({
    required CoverageCatalogItemModel item,
  }) async {
    _debugCoverageCatalog.add(item);
    return item;
  }

  Future<CoverageCatalogItemModel> updateCoverageCatalogItem({
    required CoverageCatalogItemModel item,
  }) async {
    final index = _debugCoverageCatalog.indexWhere(
      (current) => current.id == item.id,
    );
    if (index != -1) {
      _debugCoverageCatalog[index] = item;
    } else {
      _debugCoverageCatalog.add(item);
    }
    return item;
  }

  List<EmployeeModel> _mergeWithDebugEmployees(List<EmployeeModel> employees) {
    if (!_allowLocalDemoFallback) return employees;
    return [..._debugEmployees, ...employees];
  }

  List<MedicationModel> _mergeWithDebugMedications(
    List<MedicationModel> medications,
  ) {
    if (!_allowLocalDemoFallback) return medications;
    return [..._debugMedications, ...medications];
  }

  static List<EmployeeModel> _buildDebugEmployees() {
    if (!kDebugMode) {
      return <EmployeeModel>[];
    }

    return <EmployeeModel>[
      EmployeeModel(
        id: 9101,
        fullName: 'منى صالح',
        username: 'employee_demo',
        email: 'employee@healthbridge.test',
        phoneNumber: '0599000003',
        medicalRecordNumber: 'MRN-1001',
        insuranceProvider: 'جامعة بوليتكنك فلسطين',
        address: 'الخليل - عين سارة',
        dependents: const [
          DependentModel(
            id: 9201,
            fullName: 'ليان صالح',
            relation: 'ابنة',
            relationship: 'Daughter',
            notes: 'مشمولة بالتأمين العائلي',
            isActive: true,
            nationalId: '401234567',
          ),
        ],
        dateOfBirth: DateTime(1991, 4, 12),
        nationalId: '401111111',
        universityId: 'EMP-2024-001',
        insuranceNumber: 'INS-1001',
        gender: 'أنثى',
      ),
      EmployeeModel(
        id: 9102,
        fullName: 'باسل الجعبري',
        username: 'employee_test_2',
        email: 'basel@healthbridge.test',
        phoneNumber: '0599001002',
        medicalRecordNumber: 'MRN-1002',
        insuranceProvider: 'شركة التكافل الطبية',
        address: 'الخليل - الجامعة',
        dependents: const [],
        dateOfBirth: DateTime(1988, 9, 20),
        nationalId: '401111112',
        universityId: 'EMP-2024-002',
        insuranceNumber: 'INS-1002',
        gender: 'ذكر',
      ),
      EmployeeModel(
        id: 9103,
        fullName: 'آية حماد',
        username: 'employee_test_3',
        email: 'aya@healthbridge.test',
        phoneNumber: '0599001003',
        medicalRecordNumber: 'MRN-1003',
        insuranceProvider: 'جامعة بوليتكنك فلسطين',
        address: 'الخليل - الحاووز',
        dependents: const [],
        dateOfBirth: DateTime(1994, 1, 9),
        nationalId: '401111113',
        universityId: 'EMP-2024-003',
        insuranceNumber: 'INS-1003',
        gender: 'أنثى',
      ),
      EmployeeModel(
        id: 9106,
        fullName: 'رامي نصار',
        username: 'pharmacist_demo',
        email: 'pharmacy@healthbridge.test',
        phoneNumber: '0599000004',
        medicalRecordNumber: 'MRN-1006',
        insuranceProvider: 'صيدلية الجامعة',
        address: 'الخليل - شارع السلام',
        dependents: const [],
        dateOfBirth: DateTime(1987, 8, 17),
        nationalId: '401111116',
        universityId: 'PROV-003',
        insuranceNumber: 'INS-1006',
        gender: 'ذكر',
      ),
    ];
  }

  static List<MedicationModel> _buildDebugMedications() {
    if (!kDebugMode) {
      return <MedicationModel>[];
    }

    return const <MedicationModel>[
      MedicationModel(
        id: 8001,
        name: 'Panadol',
        genericName: 'Paracetamol',
        strength: '500 mg',
        dosageForm: 'Tablet',
        manufacturer: 'GSK',
      ),
      MedicationModel(
        id: 8002,
        name: 'Augmentin',
        genericName: 'Amoxicillin/Clavulanate',
        strength: '1 g',
        dosageForm: 'Tablet',
        manufacturer: 'GSK',
      ),
      MedicationModel(
        id: 8003,
        name: 'Brufen',
        genericName: 'Ibuprofen',
        strength: '400 mg',
        dosageForm: 'Tablet',
        manufacturer: 'Abbott',
      ),
      MedicationModel(
        id: 8004,
        name: 'Voltaren',
        genericName: 'Diclofenac Potassium',
        strength: '50 mg',
        dosageForm: 'Tablet',
        manufacturer: 'Novartis',
      ),
      MedicationModel(
        id: 8005,
        name: 'Cataflam',
        genericName: 'Diclofenac Potassium',
        strength: '50 mg',
        dosageForm: 'Tablet',
        manufacturer: 'Novartis',
      ),
      MedicationModel(
        id: 8006,
        name: 'Flagyl',
        genericName: 'Metronidazole',
        strength: '500 mg',
        dosageForm: 'Tablet',
        manufacturer: 'Sanofi',
      ),
      MedicationModel(
        id: 8007,
        name: 'Zithromax',
        genericName: 'Azithromycin',
        strength: '500 mg',
        dosageForm: 'Tablet',
        manufacturer: 'Pfizer',
      ),
      MedicationModel(
        id: 8008,
        name: 'Ciproxin',
        genericName: 'Ciprofloxacin',
        strength: '500 mg',
        dosageForm: 'Tablet',
        manufacturer: 'Bayer',
      ),
      MedicationModel(
        id: 8009,
        name: 'Nexium',
        genericName: 'Esomeprazole',
        strength: '40 mg',
        dosageForm: 'Capsule',
        manufacturer: 'AstraZeneca',
      ),
      MedicationModel(
        id: 8010,
        name: 'Losec',
        genericName: 'Omeprazole',
        strength: '20 mg',
        dosageForm: 'Capsule',
        manufacturer: 'AstraZeneca',
      ),
      MedicationModel(
        id: 8011,
        name: 'Glucophage',
        genericName: 'Metformin',
        strength: '850 mg',
        dosageForm: 'Tablet',
        manufacturer: 'Merck',
      ),
      MedicationModel(
        id: 8012,
        name: 'Amaryl',
        genericName: 'Glimepiride',
        strength: '2 mg',
        dosageForm: 'Tablet',
        manufacturer: 'Sanofi',
      ),
      MedicationModel(
        id: 8013,
        name: 'Norvasc',
        genericName: 'Amlodipine',
        strength: '5 mg',
        dosageForm: 'Tablet',
        manufacturer: 'Pfizer',
      ),
      MedicationModel(
        id: 8014,
        name: 'Cozaar',
        genericName: 'Losartan',
        strength: '50 mg',
        dosageForm: 'Tablet',
        manufacturer: 'MSD',
      ),
      MedicationModel(
        id: 8015,
        name: 'Micardis',
        genericName: 'Telmisartan',
        strength: '40 mg',
        dosageForm: 'Tablet',
        manufacturer: 'Boehringer Ingelheim',
      ),
      MedicationModel(
        id: 8016,
        name: 'Atacand',
        genericName: 'Candesartan',
        strength: '16 mg',
        dosageForm: 'Tablet',
        manufacturer: 'AstraZeneca',
      ),
      MedicationModel(
        id: 8017,
        name: 'Lipitor',
        genericName: 'Atorvastatin',
        strength: '20 mg',
        dosageForm: 'Tablet',
        manufacturer: 'Pfizer',
      ),
      MedicationModel(
        id: 8018,
        name: 'Crestor',
        genericName: 'Rosuvastatin',
        strength: '10 mg',
        dosageForm: 'Tablet',
        manufacturer: 'AstraZeneca',
      ),
      MedicationModel(
        id: 8019,
        name: 'Plavix',
        genericName: 'Clopidogrel',
        strength: '75 mg',
        dosageForm: 'Tablet',
        manufacturer: 'Sanofi',
      ),
      MedicationModel(
        id: 8020,
        name: 'Aspirin Protect',
        genericName: 'Acetylsalicylic Acid',
        strength: '100 mg',
        dosageForm: 'Tablet',
        manufacturer: 'Bayer',
      ),
      MedicationModel(
        id: 8021,
        name: 'Ventolin',
        genericName: 'Salbutamol',
        strength: '100 mcg',
        dosageForm: 'Inhaler',
        manufacturer: 'GSK',
      ),
      MedicationModel(
        id: 8022,
        name: 'Symbicort',
        genericName: 'Budesonide/Formoterol',
        strength: '160/4.5 mcg',
        dosageForm: 'Inhaler',
        manufacturer: 'AstraZeneca',
      ),
      MedicationModel(
        id: 8023,
        name: 'Seretide',
        genericName: 'Salmeterol/Fluticasone',
        strength: '25/125 mcg',
        dosageForm: 'Inhaler',
        manufacturer: 'GSK',
      ),
      MedicationModel(
        id: 8024,
        name: 'Telfast',
        genericName: 'Fexofenadine',
        strength: '180 mg',
        dosageForm: 'Tablet',
        manufacturer: 'Sanofi',
      ),
      MedicationModel(
        id: 8025,
        name: 'Clarinase',
        genericName: 'Loratadine/Pseudoephedrine',
        strength: '5/120 mg',
        dosageForm: 'Tablet',
        manufacturer: 'Schering-Plough',
      ),
      MedicationModel(
        id: 8026,
        name: 'Zyrtec',
        genericName: 'Cetirizine',
        strength: '10 mg',
        dosageForm: 'Tablet',
        manufacturer: 'UCB',
      ),
      MedicationModel(
        id: 8027,
        name: 'Curam',
        genericName: 'Amoxicillin/Clavulanate',
        strength: '625 mg',
        dosageForm: 'Tablet',
        manufacturer: 'Sandoz',
      ),
      MedicationModel(
        id: 8028,
        name: 'Rocephin',
        genericName: 'Ceftriaxone',
        strength: '1 g',
        dosageForm: 'Injection',
        manufacturer: 'Roche',
      ),
      MedicationModel(
        id: 8029,
        name: 'Tavanic',
        genericName: 'Levofloxacin',
        strength: '500 mg',
        dosageForm: 'Tablet',
        manufacturer: 'Sanofi',
      ),
      MedicationModel(
        id: 8030,
        name: 'Diflucan',
        genericName: 'Fluconazole',
        strength: '150 mg',
        dosageForm: 'Capsule',
        manufacturer: 'Pfizer',
      ),
    ];
  }

  static List<CoverageCatalogItemModel> _buildDebugCoverageCatalog() {
    return <CoverageCatalogItemModel>[
      const CoverageCatalogItemModel(
        id: 6001,
        code: 'MED-001',
        title: 'Panadol',
        category: 'Medication',
        providerType: 'Pharmacy',
        providerName: 'شبكة الصيدليات المتعاقدة',
        unitPrice: 12,
        coveragePercentage: 90,
        maxQuantity: 3,
        requiresInsuranceApproval: false,
        isActive: true,
        genericName: 'Paracetamol',
        strength: '500 mg',
        description: 'مسكن وخافض حرارة',
        notes: 'حتى 3 علب لكل وصفة.',
      ),
      const CoverageCatalogItemModel(
        id: 6002,
        code: 'MED-002',
        title: 'Augmentin',
        category: 'Medication',
        providerType: 'Pharmacy',
        providerName: 'شبكة الصيدليات المتعاقدة',
        unitPrice: 34,
        coveragePercentage: 80,
        maxQuantity: 2,
        requiresInsuranceApproval: true,
        isActive: true,
        genericName: 'Amoxicillin/Clavulanate',
        strength: '1 g',
        description: 'مضاد حيوي واسع الطيف',
        notes: 'يتطلب موافقة عند التكرار خلال شهر.',
      ),
      const CoverageCatalogItemModel(
        id: 6003,
        code: 'MED-003',
        title: 'Brufen',
        category: 'Medication',
        providerType: 'Pharmacy',
        providerName: 'شبكة الصيدليات المتعاقدة',
        unitPrice: 16,
        coveragePercentage: 85,
        maxQuantity: 2,
        requiresInsuranceApproval: false,
        isActive: true,
        genericName: 'Ibuprofen',
        strength: '400 mg',
        description: 'مضاد التهاب ومسكن',
        notes: 'يغطى للحالات الحادة فقط.',
      ),
      const CoverageCatalogItemModel(
        id: 6004,
        code: 'MED-004',
        title: 'Ventolin',
        category: 'Medication',
        providerType: 'Pharmacy',
        providerName: 'صيدليات الربو المعتمدة',
        unitPrice: 28,
        coveragePercentage: 95,
        maxQuantity: 2,
        requiresInsuranceApproval: false,
        isActive: true,
        genericName: 'Salbutamol',
        strength: '100 mcg',
        description: 'بخاخ موسع للقصبات',
        notes: 'يغطى بالكامل تقريبًا لمرضى الربو المثبتين.',
      ),
      const CoverageCatalogItemModel(
        id: 6005,
        code: 'MED-005',
        title: 'Symbicort',
        category: 'Medication',
        providerType: 'Pharmacy',
        providerName: 'صيدليات الأمراض المزمنة',
        unitPrice: 96,
        coveragePercentage: 75,
        maxQuantity: 1,
        requiresInsuranceApproval: true,
        isActive: true,
        genericName: 'Budesonide/Formoterol',
        strength: '160/4.5 mcg',
        description: 'علاج وقائي للربو المزمن',
        notes: 'يتطلب اعتمادًا أوليًا من التأمين.',
      ),
      const CoverageCatalogItemModel(
        id: 6006,
        code: 'MED-006',
        title: 'Glucophage',
        category: 'Medication',
        providerType: 'Pharmacy',
        providerName: 'برنامج الأمراض المزمنة',
        unitPrice: 22,
        coveragePercentage: 95,
        maxQuantity: 3,
        requiresInsuranceApproval: false,
        isActive: true,
        genericName: 'Metformin',
        strength: '850 mg',
        description: 'سكري نوع ثاني',
        notes: 'تغطية ممتازة لمريض السكري المعتمد.',
      ),
      const CoverageCatalogItemModel(
        id: 6007,
        code: 'MED-007',
        title: 'Norvasc',
        category: 'Medication',
        providerType: 'Pharmacy',
        providerName: 'برنامج الضغط والقلب',
        unitPrice: 26,
        coveragePercentage: 90,
        maxQuantity: 3,
        requiresInsuranceApproval: false,
        isActive: true,
        genericName: 'Amlodipine',
        strength: '5 mg',
        description: 'ضغط الدم',
        notes: 'يغطي حتى 3 علب شهريًا.',
      ),
      const CoverageCatalogItemModel(
        id: 6008,
        code: 'MED-008',
        title: 'Lipitor',
        category: 'Medication',
        providerType: 'Pharmacy',
        providerName: 'برنامج القلب والشرايين',
        unitPrice: 58,
        coveragePercentage: 80,
        maxQuantity: 2,
        requiresInsuranceApproval: false,
        isActive: true,
        genericName: 'Atorvastatin',
        strength: '20 mg',
        description: 'خفض الكوليسترول',
        notes: 'تغطية شهرية للمصابين بفرط الدهون.',
      ),
    ];
  }

  static List<DependentModel> _buildDebugDependents() {
    if (!kDebugMode) {
      return <DependentModel>[];
    }

    return const <DependentModel>[
      DependentModel(
        id: 9201,
        fullName: 'ليان صالح',
        relation: 'ابنة',
        relationship: 'Daughter',
        notes: 'مشمولة بالتأمين العائلي',
        isActive: true,
        nationalId: '401234567',
      ),
      DependentModel(
        id: 9202,
        fullName: 'سيف الجعبري',
        relation: 'ابن',
        relationship: 'Son',
        notes: 'مراجعة دورية للأطفال',
        isActive: true,
        nationalId: '401234568',
      ),
    ];
  }

  static List<DoctorDirectoryModel> _buildDebugDoctors() {
    if (!kDebugMode) {
      return <DoctorDirectoryModel>[];
    }

    return const <DoctorDirectoryModel>[
      DoctorDirectoryModel(
        id: 9301,
        fullName: 'د. أحمد خليل',
        specialty: 'طب باطني',
        clinicName: 'العيادة التخصصية',
        providerName: 'العيادة التخصصية',
        city: 'الخليل',
        address: 'عين سارة',
        phoneNumber: '022222222',
        consultationPrice: 120,
        contractStatus: 'Active',
      ),
    ];
  }

  static List<InsuranceRequestModel> _buildDebugInsuranceRequests() {
    if (!kDebugMode) {
      return <InsuranceRequestModel>[];
    }

    final now = DateTime.now();
    return <InsuranceRequestModel>[
      InsuranceRequestModel(
        id: 9401,
        prescriptionId: 7002,
        prescriptionNumber: 'RX-2026-002',
        employeeName: 'باسل الجعبري',
        doctorName: 'د. أحمد خليل',
        status: 'Pending',
        requestNumber: 'INS-2026-001',
        responseNotes: '',
        providerName: 'شبكة الصيدليات المتعاقدة',
        serviceName: 'Augmentin',
        serviceType: 'Medication',
        totalPrice: 34,
        coveragePercentage: 80,
        coveredAmount: 27.2,
        employeeShare: 6.8,
        prescriptionStatus: 'PendingInsuranceApproval',
        beneficiaryName: 'باسل الجعبري',
        submittedAt: now.subtract(const Duration(hours: 4)),
      ),
      InsuranceRequestModel(
        id: 9402,
        prescriptionId: 7003,
        prescriptionNumber: 'RX-2026-003',
        employeeName: 'منى صالح',
        doctorName: 'د. أحمد خليل',
        status: 'Approved',
        requestNumber: 'INS-2026-002',
        responseNotes: 'تمت الموافقة على الطلب.',
        providerName: 'صيدليات الأمراض المزمنة',
        serviceName: 'Symbicort',
        serviceType: 'Medication',
        totalPrice: 96,
        coveragePercentage: 75,
        coveredAmount: 72,
        employeeShare: 24,
        prescriptionStatus: 'Approved',
        beneficiaryName: 'منى صالح',
        submittedAt: now.subtract(const Duration(days: 1)),
      ),
    ];
  }

  static List<DispenseModel> _buildDebugDispenses() {
    if (!kDebugMode) {
      return <DispenseModel>[];
    }

    final now = DateTime.now();
    return <DispenseModel>[
      DispenseModel(
        id: 9501,
        prescriptionId: 7001,
        prescriptionNumber: 'RX-2026-1001',
        employeeName: 'منى صالح',
        pharmacistName: 'رامي نصار',
        dispenseNumber: 'DSP-001',
        status: 'Completed',
        notes: 'تم صرف العلاج كاملًا.',
        dispensedAt: now.subtract(const Duration(hours: 6)),
      ),
      DispenseModel(
        id: 9502,
        prescriptionId: 7005,
        prescriptionNumber: 'RX-2026-1002',
        employeeName: 'باسل الجعبري',
        pharmacistName: 'رامي نصار',
        dispenseNumber: 'DSP-002',
        status: 'Partial',
        notes: 'تم صرف جزء من المتوفر.',
        dispensedAt: now.subtract(const Duration(days: 1)),
      ),
    ];
  }

  static List<UserModel> _buildDebugUsers() {
    if (!kDebugMode) {
      return <UserModel>[];
    }

    return const <UserModel>[
      UserModel(
        id: 9001,
        username: 'admin_demo',
        email: 'admin@healthbridge.test',
        role: AppRoles.admin,
        firstName: 'System',
        lastName: 'Admin',
        phoneNumber: '0599000001',
        isActive: true,
      ),
      UserModel(
        id: 9002,
        username: 'doctor_demo',
        email: 'doctor@healthbridge.test',
        role: AppRoles.doctor,
        firstName: 'Ahmad',
        lastName: 'Khalil',
        phoneNumber: '0599000002',
        isActive: true,
      ),
      UserModel(
        id: 9003,
        username: 'employee_demo',
        email: 'employee@healthbridge.test',
        role: AppRoles.employee,
        firstName: 'Mona',
        lastName: 'Saleh',
        phoneNumber: '0599000003',
        isActive: true,
      ),
      UserModel(
        id: 9005,
        username: 'insurance_demo',
        email: 'insurance@healthbridge.test',
        role: AppRoles.insuranceOfficer,
        firstName: 'Lina',
        lastName: 'Hamdan',
        phoneNumber: '0599000005',
        isActive: true,
      ),
    ];
  }

  Future<List<DoctorDirectoryModel>> searchDoctors({
    String name = '',
    String specialty = '',
    String city = '',
    String providerName = '',
    bool activeOnly = false,
  }) async {
    if (_shouldUseDemoMode) {
      final normalizedName = name.trim().toLowerCase();
      final normalizedSpecialty = specialty.trim().toLowerCase();
      final normalizedCity = city.trim().toLowerCase();
      final normalizedProvider = providerName.trim().toLowerCase();
      return _debugDoctors.where((doctor) {
        final matchesName =
            normalizedName.isEmpty ||
            doctor.fullName.toLowerCase().contains(normalizedName);
        final matchesSpecialty =
            normalizedSpecialty.isEmpty ||
            doctor.specialty.toLowerCase().contains(normalizedSpecialty);
        final matchesCity =
            normalizedCity.isEmpty ||
            doctor.city.toLowerCase().contains(normalizedCity);
        final matchesProvider =
            normalizedProvider.isEmpty ||
            doctor.providerName.toLowerCase().contains(normalizedProvider);
        final matchesActive =
            !activeOnly || doctor.contractStatus.toLowerCase() == 'active';
        return matchesName &&
            matchesSpecialty &&
            matchesCity &&
            matchesProvider &&
            matchesActive;
      }).toList();
    }

    final params = <String>[
      if (name.trim().isNotEmpty)
        'search=${Uri.encodeQueryComponent(name.trim())}',
      if (specialty.trim().isNotEmpty)
        'specialization=${Uri.encodeQueryComponent(specialty.trim())}',
      if (city.trim().isNotEmpty)
        'city=${Uri.encodeQueryComponent(city.trim())}',
      if (providerName.trim().isNotEmpty)
        'provider_name=${Uri.encodeQueryComponent(providerName.trim())}',
      if (activeOnly) 'contract_status=active',
    ];
    final endpoint = params.isEmpty
        ? 'doctors/'
        : 'doctors/?${params.join('&')}';
    final response = await _apiClient.getList(endpoint);
    return response
        .whereType<Map<String, dynamic>>()
        .map(DoctorDirectoryModel.fromJson)
        .toList();
  }

  Future<int> getDoctorProfileIdForUser(int userId) async {
    if (_shouldUseDemoMode) {
      if (userId == 9002 && _debugDoctors.isNotEmpty) {
        return _debugDoctors.first.id;
      }
      throw const AppException('تعذر تحديد ملف الطبيب الحالي.');
    }

    final response = await _apiClient.getList('doctors/?user=$userId');
    final doctors = response.whereType<Map<String, dynamic>>().toList();
    if (doctors.isEmpty) {
      throw const AppException('تعذر تحديد ملف الطبيب الحالي.');
    }
    return doctors.first['id'] as int;
  }

  Future<List<PrescriptionModel>> getPrescriptions({String? status}) async {
    if (_shouldUseDemoMode) {
      return _filterDebugPrescriptions(status: status);
    }

    final endpoint = status == null
        ? 'prescriptions/'
        : 'prescriptions/?status=$status';
    try {
      final response = await _apiClient.getList(endpoint);
      return response
          .whereType<Map<String, dynamic>>()
          .map(PrescriptionModel.fromJson)
          .toList();
    } catch (_) {
      if (_allowLocalDemoFallback) {
        return _filterDebugPrescriptions(status: status);
      }
      rethrow;
    }
  }

  Future<List<PrescriptionModel>> searchPrescriptions(String query) async {
    if (_shouldUseDemoMode) {
      final normalizedQuery = query.trim().toLowerCase();
      return _debugPrescriptions.where((item) {
        if (normalizedQuery.isEmpty) return true;
        return item.prescriptionNumber.toLowerCase().contains(
              normalizedQuery,
            ) ||
            item.employeeName.toLowerCase().contains(normalizedQuery) ||
            item.doctorName.toLowerCase().contains(normalizedQuery) ||
            item.serviceName.toLowerCase().contains(normalizedQuery);
      }).toList();
    }

    final normalizedQuery = query.trim();
    final endpoint = normalizedQuery.isEmpty
        ? 'prescriptions/'
        : 'prescriptions/?search=${Uri.encodeQueryComponent(normalizedQuery)}';
    final response = await _apiClient.getList(endpoint);
    return response
        .whereType<Map<String, dynamic>>()
        .map(PrescriptionModel.fromJson)
        .toList();
  }

  Future<PrescriptionModel> getPrescription(int id) async {
    final debugMatch = _debugPrescriptions
        .where((item) => item.id == id)
        .toList();
    if (_shouldUseDemoMode && debugMatch.isNotEmpty) {
      return debugMatch.first;
    }

    final response = await _apiClient.get('prescriptions/$id/');
    return PrescriptionModel.fromJson(response);
  }

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
  }) async {
    final selectedEmployeeId = employeeId ?? patientId;
    if (selectedEmployeeId == null) {
      throw ArgumentError('employeeId is required');
    }

    final normalizedCoveragePercentage = _roundToScale(coveragePercentage);
    final normalizedCoveredAmount = _roundToScale(coveredAmount);
    final normalizedEmployeeShare = _roundToScale(employeeShare);
    final normalizedFinalPrice = _roundToScale(finalPrice);

    if (_shouldUseDemoMode) {
      final employee = _debugEmployees.firstWhere(
        (item) => item.id == selectedEmployeeId,
        orElse: () => _debugEmployees.first,
      );
      final dependent = _debugDependents
          .where((item) => item.id == dependentId)
          .toList();
      final prescription = PrescriptionModel(
        id: DateTime.now().millisecondsSinceEpoch,
        prescriptionNumber: 'RX-${DateTime.now().millisecondsSinceEpoch}',
        employeeId: employee.id,
        employeeName: employee.fullName,
        employeeRecordNumber: employee.medicalRecordNumber,
        doctorId: doctorId,
        doctorName: 'د. أحمد خليل',
        status: status == 'Sent' ? 'Approved' : status,
        diagnosis: diagnosis,
        notes: notes,
        items: items.map((item) {
          final medicationId = item['medication'] as int? ?? 0;
          final medication = _debugMedications
              .where((entry) => entry.id == medicationId)
              .toList();
          return PrescriptionItemModel(
            id: DateTime.now().millisecondsSinceEpoch,
            medicationId: medicationId,
            medicationName: medication.isEmpty
                ? 'خدمة طبية'
                : medication.first.name,
            dosageInstructions: item['dosage_instructions'] as String? ?? '',
            quantity: item['quantity'] as String? ?? '',
            duration: item['duration'] as String? ?? '',
            substitutionAllowed: item['substitution_allowed'] as bool? ?? false,
          );
        }).toList(),
        serviceType: serviceType,
        providerName: providerName,
        serviceName: serviceName,
        coveragePercentage: normalizedCoveragePercentage,
        coveredAmount: normalizedCoveredAmount,
        employeeShare: normalizedEmployeeShare,
        finalPrice: normalizedFinalPrice,
        requiresInsuranceApproval: requiresInsuranceApproval,
        providerNotes: '',
        reportAttachmentUrl: '',
        beneficiaryId: dependentId,
        beneficiaryName: dependent.isEmpty ? null : dependent.first.fullName,
        issuedAt: DateTime.now(),
        validUntil: DateTime.now().add(const Duration(days: 14)),
      );
      _debugPrescriptions.insert(0, prescription);
      if (status == 'Sent') {
        _upsertAutoApprovedDebugInsuranceRequest(prescription);
      }
      return prescription;
    }

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final response = await _apiClient.post(
      'prescriptions/',
      body: {
        'prescription_number': 'RX-$timestamp',
        'employee': selectedEmployeeId,
        'doctor': doctorId,
        'beneficiary': dependentId,
        'service_type': serviceType,
        'status': status,
        'requires_insurance_approval': requiresInsuranceApproval,
        'coverage_percentage': normalizedCoveragePercentage,
        'covered_amount': normalizedCoveredAmount,
        'employee_share': normalizedEmployeeShare,
        'final_price': normalizedFinalPrice,
        'diagnosis': diagnosis,
        'notes': notes,
        'issued_at': DateTime.now().toIso8601String(),
        'items': items,
      },
    );
    return PrescriptionModel.fromJson(response);
  }

  Future<PrescriptionModel> updatePrescriptionStatus({
    required int id,
    required String status,
    String? providerNotes,
    double? finalPrice,
  }) async {
    final normalizedFinalPrice = finalPrice == null
        ? null
        : _roundToScale(finalPrice);
    final debugIndex = _debugPrescriptions.indexWhere((item) => item.id == id);
    if (_shouldUseDemoMode && debugIndex != -1) {
      final current = _debugPrescriptions[debugIndex];
      final updated = PrescriptionModel(
        id: current.id,
        prescriptionNumber: current.prescriptionNumber,
        employeeId: current.employeeId,
        employeeName: current.employeeName,
        employeeRecordNumber: current.employeeRecordNumber,
        doctorId: current.doctorId,
        doctorName: current.doctorName,
        status: status == 'Sent' ? 'Approved' : status,
        diagnosis: current.diagnosis,
        notes: current.notes,
        items: current.items,
        serviceType: current.serviceType,
        providerName: current.providerName,
        serviceName: current.serviceName,
        coveragePercentage: current.coveragePercentage,
        coveredAmount: current.coveredAmount,
        employeeShare: current.employeeShare,
        finalPrice: normalizedFinalPrice ?? current.finalPrice,
        requiresInsuranceApproval: current.requiresInsuranceApproval,
        providerNotes: providerNotes ?? current.providerNotes,
        reportAttachmentUrl: current.reportAttachmentUrl,
        beneficiaryId: current.beneficiaryId,
        beneficiaryName: current.beneficiaryName,
        issuedAt: current.issuedAt,
        validUntil: current.validUntil,
        performedAt: status == 'Performed'
            ? DateTime.now()
            : current.performedAt,
      );
      _debugPrescriptions[debugIndex] = updated;
      if (status == 'Sent') {
        _upsertAutoApprovedDebugInsuranceRequest(updated);
      }
      return updated;
    }

    final body = <String, dynamic>{'status': status};
    if (providerNotes != null) {
      body['provider_notes'] = providerNotes;
    }
    if (normalizedFinalPrice != null) {
      body['final_price'] = normalizedFinalPrice;
    }
    final response = await _apiClient.patch('prescriptions/$id/', body: body);
    return PrescriptionModel.fromJson(response);
  }

  List<PrescriptionModel> _filterDebugPrescriptions({String? status}) {
    if (status == null || status.isEmpty) {
      return List<PrescriptionModel>.from(_debugPrescriptions);
    }
    return _debugPrescriptions.where((item) => item.status == status).toList();
  }

  void _upsertAutoApprovedDebugInsuranceRequest(
    PrescriptionModel prescription,
  ) {
    final existingIndex = _debugInsuranceRequests.indexWhere(
      (item) => item.prescriptionId == prescription.id,
    );
    final request = InsuranceRequestModel(
      id: existingIndex == -1
          ? DateTime.now().millisecondsSinceEpoch
          : _debugInsuranceRequests[existingIndex].id,
      prescriptionId: prescription.id,
      prescriptionNumber: prescription.prescriptionNumber,
      employeeName: prescription.employeeName,
      doctorName: prescription.doctorName,
      status: 'Approved',
      requestNumber: existingIndex == -1
          ? 'INS-${prescription.prescriptionNumber}'
          : _debugInsuranceRequests[existingIndex].requestNumber,
      responseNotes: 'تمت الموافقة تلقائيًا من النظام.',
      providerName: prescription.providerName,
      serviceName: prescription.serviceName,
      serviceType: prescription.serviceType,
      totalPrice: prescription.finalPrice,
      coveragePercentage: prescription.coveragePercentage,
      coveredAmount: prescription.coveredAmount,
      employeeShare: prescription.employeeShare,
      prescriptionStatus: 'Approved',
      beneficiaryName: prescription.beneficiaryName,
      submittedAt: DateTime.now(),
    );

    if (existingIndex == -1) {
      _debugInsuranceRequests.insert(0, request);
    } else {
      _debugInsuranceRequests[existingIndex] = request;
    }
  }

  static List<PrescriptionModel> _buildDebugPrescriptions() {
    if (!kDebugMode) {
      return <PrescriptionModel>[];
    }

    final now = DateTime.now();
    return <PrescriptionModel>[
      PrescriptionModel(
        id: 7001,
        prescriptionNumber: 'RX-2026-001',
        employeeId: 9101,
        employeeName: 'منى صالح',
        employeeRecordNumber: 'MRN-1001',
        doctorId: 9002,
        doctorName: 'د. أحمد خليل',
        status: 'Approved',
        diagnosis: 'صداع وحرارة خفيفة',
        notes: 'مسكن وخافض حرارة لمدة ثلاثة أيام.',
        items: const [
          PrescriptionItemModel(
            id: 1,
            medicationId: 8001,
            medicationName: 'Panadol',
            dosageInstructions: 'حبة واحدة كل 8 ساعات بعد الطعام',
            quantity: '12 قرص',
            duration: '3 أيام',
            substitutionAllowed: false,
          ),
        ],
        serviceType: 'Medication',
        providerName: 'شبكة الصيدليات المتعاقدة',
        serviceName: 'Panadol',
        coveragePercentage: 90,
        coveredAmount: 10.8,
        employeeShare: 1.2,
        finalPrice: 12,
        requiresInsuranceApproval: false,
        providerNotes: '',
        reportAttachmentUrl: '',
        beneficiaryName: 'منى صالح',
        issuedAt: now.subtract(const Duration(hours: 2)),
        validUntil: now.add(const Duration(days: 3)),
      ),
      PrescriptionModel(
        id: 7002,
        prescriptionNumber: 'RX-2026-002',
        employeeId: 9102,
        employeeName: 'باسل الجعبري',
        employeeRecordNumber: 'MRN-1002',
        doctorId: 9002,
        doctorName: 'د. أحمد خليل',
        status: 'PendingInsuranceApproval',
        diagnosis: 'التهاب تنفسي علوي',
        notes: 'مضاد حيوي يحتاج موافقة تأمين قبل الصرف.',
        items: const [
          PrescriptionItemModel(
            id: 2,
            medicationId: 8002,
            medicationName: 'Augmentin',
            dosageInstructions: 'حبة كل 12 ساعة بعد الطعام',
            quantity: '14 حبة',
            duration: '7 أيام',
            substitutionAllowed: false,
          ),
        ],
        serviceType: 'Medication',
        providerName: 'شبكة الصيدليات المتعاقدة',
        serviceName: 'Augmentin',
        coveragePercentage: 80,
        coveredAmount: 27.2,
        employeeShare: 6.8,
        finalPrice: 34,
        requiresInsuranceApproval: true,
        providerNotes: '',
        reportAttachmentUrl: '',
        beneficiaryName: 'باسل الجعبري',
        issuedAt: now.subtract(const Duration(hours: 5)),
        validUntil: now.add(const Duration(days: 2)),
      ),
      PrescriptionModel(
        id: 7003,
        prescriptionNumber: 'RX-2026-003',
        employeeId: 9103,
        employeeName: 'آية حماد',
        employeeRecordNumber: 'MRN-1003',
        doctorId: 9002,
        doctorName: 'د. أحمد خليل',
        status: 'Approved',
        diagnosis: 'ربو تحسسي مزمن',
        notes: 'بخاخ وقائي مع متابعة شهرية.',
        items: const [
          PrescriptionItemModel(
            id: 3,
            medicationId: 8005,
            medicationName: 'Symbicort',
            dosageInstructions: 'بختان صباحًا ومساءً',
            quantity: '1 عبوة',
            duration: '30 يومًا',
            substitutionAllowed: false,
          ),
        ],
        serviceType: 'Medication',
        providerName: 'صيدليات الأمراض المزمنة',
        serviceName: 'Symbicort',
        coveragePercentage: 75,
        coveredAmount: 72,
        employeeShare: 24,
        finalPrice: 96,
        requiresInsuranceApproval: true,
        providerNotes: 'تمت الموافقة على الصرف.',
        reportAttachmentUrl: '',
        beneficiaryName: 'آية حماد',
        issuedAt: now.subtract(const Duration(hours: 1)),
        validUntil: now.add(const Duration(days: 4)),
        performedAt: now.subtract(const Duration(minutes: 30)),
      ),
    ];
  }

  Future<String> getPrescriptionQrSvg(int id) {
    if (_shouldUseDemoMode) {
      return Future.value(
        '<svg xmlns="http://www.w3.org/2000/svg" width="200" height="200">'
        '<rect width="200" height="200" fill="white"/>'
        '<rect x="20" y="20" width="50" height="50" fill="black"/>'
        '<rect x="130" y="20" width="50" height="50" fill="black"/>'
        '<rect x="20" y="130" width="50" height="50" fill="black"/>'
        '<text x="100" y="110" font-size="14" text-anchor="middle" fill="black">DEMO QR</text>'
        '</svg>',
      );
    }
    return _apiClient.getText('prescriptions/$id/qr-code/');
  }

  Future<List<InsuranceRequestModel>> getInsuranceRequests() async {
    if (_shouldUseDemoMode) {
      return List<InsuranceRequestModel>.from(_debugInsuranceRequests);
    }

    final response = await _apiClient.getList('insurance/');
    return response
        .whereType<Map<String, dynamic>>()
        .map(InsuranceRequestModel.fromJson)
        .toList();
  }

  Future<InsuranceRequestModel> createInsuranceRequest({
    required int prescriptionId,
  }) async {
    if (_shouldUseDemoMode) {
      final prescription = _debugPrescriptions.firstWhere(
        (item) => item.id == prescriptionId,
        orElse: () => _debugPrescriptions.first,
      );
      _upsertAutoApprovedDebugInsuranceRequest(prescription);
      return _debugInsuranceRequests.firstWhere(
        (item) => item.prescriptionId == prescription.id,
      );
    }

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final response = await _apiClient.post(
      'insurance/',
      body: {
        'prescription': prescriptionId,
        'request_number': 'INS-$timestamp',
        'status': 'Pending',
        'submitted_at': DateTime.now().toIso8601String(),
      },
    );
    return InsuranceRequestModel.fromJson(response);
  }

  Future<InsuranceRequestModel> updateInsuranceRequest({
    required int id,
    required String status,
    required String notes,
  }) async {
    final debugIndex = _debugInsuranceRequests.indexWhere(
      (item) => item.id == id,
    );
    if (_shouldUseDemoMode && debugIndex != -1) {
      final current = _debugInsuranceRequests[debugIndex];
      final updated = InsuranceRequestModel(
        id: current.id,
        prescriptionId: current.prescriptionId,
        prescriptionNumber: current.prescriptionNumber,
        employeeName: current.employeeName,
        doctorName: current.doctorName,
        status: status,
        requestNumber: current.requestNumber,
        responseNotes: notes,
        providerName: current.providerName,
        serviceName: current.serviceName,
        serviceType: current.serviceType,
        totalPrice: current.totalPrice,
        coveragePercentage: current.coveragePercentage,
        coveredAmount: current.coveredAmount,
        employeeShare: current.employeeShare,
        prescriptionStatus: status,
        beneficiaryName: current.beneficiaryName,
        submittedAt: current.submittedAt,
      );
      _debugInsuranceRequests[debugIndex] = updated;

      final prescriptionIndex = _debugPrescriptions.indexWhere(
        (item) => item.id == current.prescriptionId,
      );
      if (prescriptionIndex != -1) {
        final prescription = _debugPrescriptions[prescriptionIndex];
        final updatedPrescription = PrescriptionModel(
          id: prescription.id,
          prescriptionNumber: prescription.prescriptionNumber,
          employeeId: prescription.employeeId,
          employeeName: prescription.employeeName,
          employeeRecordNumber: prescription.employeeRecordNumber,
          doctorId: prescription.doctorId,
          doctorName: prescription.doctorName,
          status: status == 'Approved'
              ? 'Approved'
              : status == 'Rejected'
              ? 'Rejected'
              : 'NeedsUpdate',
          diagnosis: prescription.diagnosis,
          notes: prescription.notes,
          items: prescription.items,
          serviceType: prescription.serviceType,
          providerName: prescription.providerName,
          serviceName: prescription.serviceName,
          coveragePercentage: prescription.coveragePercentage,
          coveredAmount: prescription.coveredAmount,
          employeeShare: prescription.employeeShare,
          finalPrice: prescription.finalPrice,
          requiresInsuranceApproval: prescription.requiresInsuranceApproval,
          providerNotes: notes.isEmpty ? prescription.providerNotes : notes,
          reportAttachmentUrl: prescription.reportAttachmentUrl,
          beneficiaryId: prescription.beneficiaryId,
          beneficiaryName: prescription.beneficiaryName,
          issuedAt: prescription.issuedAt,
          validUntil: prescription.validUntil,
          performedAt: prescription.performedAt,
        );
        _debugPrescriptions[prescriptionIndex] = updatedPrescription;
      }
      return updated;
    }

    final response = await _apiClient.patch(
      'insurance/$id/',
      body: {'status': status, 'response_notes': notes},
    );
    return InsuranceRequestModel.fromJson(response);
  }

  Future<List<DispenseModel>> getDispenses() async {
    if (_shouldUseDemoMode) {
      return List<DispenseModel>.from(_debugDispenses);
    }

    final response = await _apiClient.getList('dispenses/');
    return response
        .whereType<Map<String, dynamic>>()
        .map(DispenseModel.fromJson)
        .toList();
  }

  Future<DispenseModel> createDispense({
    required int prescriptionId,
    required String dispenseNumber,
    required String status,
    required String notes,
  }) async {
    if (_shouldUseDemoMode) {
      final prescription = _debugPrescriptions.firstWhere(
        (item) => item.id == prescriptionId,
        orElse: () => _debugPrescriptions.first,
      );
      final dispense = DispenseModel(
        id: DateTime.now().millisecondsSinceEpoch,
        prescriptionId: prescription.id,
        prescriptionNumber: prescription.prescriptionNumber,
        employeeName: prescription.employeeName,
        pharmacistName: 'رامي نصار',
        dispenseNumber: dispenseNumber,
        status: status,
        notes: notes,
        dispensedAt: DateTime.now(),
      );
      _debugDispenses.insert(0, dispense);

      final prescriptionIndex = _debugPrescriptions.indexWhere(
        (item) => item.id == prescriptionId,
      );
      if (prescriptionIndex != -1) {
        final current = _debugPrescriptions[prescriptionIndex];
        _debugPrescriptions[prescriptionIndex] = PrescriptionModel(
          id: current.id,
          prescriptionNumber: current.prescriptionNumber,
          employeeId: current.employeeId,
          employeeName: current.employeeName,
          employeeRecordNumber: current.employeeRecordNumber,
          doctorId: current.doctorId,
          doctorName: current.doctorName,
          status: 'Dispensed',
          diagnosis: current.diagnosis,
          notes: current.notes,
          items: current.items,
          serviceType: current.serviceType,
          providerName: current.providerName,
          serviceName: current.serviceName,
          coveragePercentage: current.coveragePercentage,
          coveredAmount: current.coveredAmount,
          employeeShare: current.employeeShare,
          finalPrice: current.finalPrice,
          requiresInsuranceApproval: current.requiresInsuranceApproval,
          providerNotes: current.providerNotes,
          reportAttachmentUrl: current.reportAttachmentUrl,
          beneficiaryId: current.beneficiaryId,
          beneficiaryName: current.beneficiaryName,
          issuedAt: current.issuedAt,
          validUntil: current.validUntil,
          performedAt: current.performedAt,
        );
      }
      return dispense;
    }

    final response = await _apiClient.post(
      'dispenses/',
      body: {
        'prescription': prescriptionId,
        'dispense_number': dispenseNumber,
        'status': status,
        'notes': notes,
        'dispensed_at': DateTime.now().toIso8601String(),
      },
    );
    return DispenseModel.fromJson(response);
  }

  Future<List<UserModel>> getUsers() async {
    if (_shouldUseDemoMode) {
      return List<UserModel>.from(_debugUsers);
    }

    final users = <UserModel>[];
    var page = 1;

    while (true) {
      final response = await _apiClient.get('users/?page=$page&page_size=100');
      final pageResults = (response['results'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(UserModel.fromJson)
          .toList();
      users.addAll(pageResults);

      final nextPage = response['next'] as String?;
      if (nextPage == null || nextPage.isEmpty || pageResults.isEmpty) {
        break;
      }
      page += 1;
    }

    return users;
  }

  Future<UserModel> createUser(Map<String, dynamic> payload) async {
    if (_shouldUseDemoMode) {
      final user = UserModel(
        id: DateTime.now().millisecondsSinceEpoch,
        username: payload['username'] as String? ?? 'demo_user',
        email: payload['email'] as String? ?? '',
        role: payload['role'] as String? ?? 'Employee',
        firstName: payload['first_name'] as String? ?? '',
        lastName: payload['last_name'] as String? ?? '',
        phoneNumber: payload['phone_number'] as String? ?? '',
        isActive: payload['is_active'] as bool? ?? true,
      );
      _debugUsers.add(user);
      return user;
    }

    final response = await _apiClient.post('users/', body: payload);
    return UserModel.fromJson(response);
  }

  Future<UserModel> updateUser(int id, Map<String, dynamic> payload) async {
    final debugIndex = _debugUsers.indexWhere((item) => item.id == id);
    if (_shouldUseDemoMode && debugIndex != -1) {
      final current = _debugUsers[debugIndex];
      final updated = UserModel(
        id: current.id,
        username: payload['username'] as String? ?? current.username,
        email: payload['email'] as String? ?? current.email,
        role: payload['role'] as String? ?? current.role,
        firstName: payload['first_name'] as String? ?? current.firstName,
        lastName: payload['last_name'] as String? ?? current.lastName,
        phoneNumber: payload['phone_number'] as String? ?? current.phoneNumber,
        isActive: payload['is_active'] as bool? ?? current.isActive,
      );
      _debugUsers[debugIndex] = updated;
      return updated;
    }

    final response = await _apiClient.patch('users/$id/', body: payload);
    return UserModel.fromJson(response);
  }

  Future<void> deleteUser(int id) async {
    final debugIndex = _debugUsers.indexWhere((item) => item.id == id);
    if (_shouldUseDemoMode && debugIndex != -1) {
      _debugUsers.removeAt(debugIndex);
      return;
    }

    await _apiClient.delete('users/$id/');
  }
}
