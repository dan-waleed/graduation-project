double _parseDouble(dynamic value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0;
  return 0;
}

class NotificationModel {
  const NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.notificationType,
    required this.isRead,
    required this.relatedEntityType,
    required this.relatedEntityId,
    this.createdAt,
    this.readAt,
  });

  final int id;
  final String title;
  final String message;
  final String notificationType;
  final bool isRead;
  final String relatedEntityType;
  final String relatedEntityId;
  final DateTime? createdAt;
  final DateTime? readAt;

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as int,
      title: json['title'] as String? ?? '',
      message: json['message'] as String? ?? '',
      notificationType: json['notification_type'] as String? ?? '',
      isRead: json['is_read'] as bool? ?? false,
      relatedEntityType: json['related_entity_type'] as String? ?? '',
      relatedEntityId: json['related_entity_id'] as String? ?? '',
      createdAt: json['created_at'] == null
          ? null
          : DateTime.tryParse(json['created_at'] as String),
      readAt: json['read_at'] == null
          ? null
          : DateTime.tryParse(json['read_at'] as String),
    );
  }
}

class AuditLogModel {
  const AuditLogModel({
    required this.id,
    required this.actorUsername,
    required this.action,
    required this.targetModel,
    required this.targetId,
    required this.details,
    this.createdAt,
  });

  final int id;
  final String actorUsername;
  final String action;
  final String targetModel;
  final String targetId;
  final String details;
  final DateTime? createdAt;

  factory AuditLogModel.fromJson(Map<String, dynamic> json) {
    return AuditLogModel(
      id: json['id'] as int,
      actorUsername: json['actor_username'] as String? ?? '',
      action: json['action'] as String? ?? '',
      targetModel: json['target_model'] as String? ?? '',
      targetId: json['target_id'] as String? ?? '',
      details: json['details'] as String? ?? '',
      createdAt: json['created_at'] == null
          ? null
          : DateTime.tryParse(json['created_at'] as String),
    );
  }
}

class SystemSettingsModel {
  const SystemSettingsModel({
    required this.systemName,
    required this.organizationName,
    required this.shortDescription,
    required this.notificationsEnabled,
    required this.insuranceWorkflowEnabled,
    required this.pharmacistNotesRequired,
    required this.interfaceLanguage,
    required this.sessionTimeoutMinutes,
    required this.adminNotes,
    this.updatedAt,
  });

  final String systemName;
  final String organizationName;
  final String shortDescription;
  final bool notificationsEnabled;
  final bool insuranceWorkflowEnabled;
  final bool pharmacistNotesRequired;
  final String interfaceLanguage;
  final int sessionTimeoutMinutes;
  final String adminNotes;
  final DateTime? updatedAt;

  factory SystemSettingsModel.fromJson(Map<String, dynamic> json) {
    return SystemSettingsModel(
      systemName: json['system_name'] as String? ?? '',
      organizationName: json['organization_name'] as String? ?? '',
      shortDescription: json['short_description'] as String? ?? '',
      notificationsEnabled: json['notifications_enabled'] as bool? ?? true,
      insuranceWorkflowEnabled:
          json['insurance_workflow_enabled'] as bool? ?? true,
      pharmacistNotesRequired:
          json['pharmacist_notes_required'] as bool? ?? false,
      interfaceLanguage: json['interface_language'] as String? ?? 'العربية',
      sessionTimeoutMinutes: json['session_timeout_minutes'] as int? ?? 30,
      adminNotes: json['admin_notes'] as String? ?? '',
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.tryParse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toPatchPayload() {
    return {
      'system_name': systemName,
      'organization_name': organizationName,
      'short_description': shortDescription,
      'notifications_enabled': notificationsEnabled,
      'insurance_workflow_enabled': insuranceWorkflowEnabled,
      'pharmacist_notes_required': pharmacistNotesRequired,
      'interface_language': interfaceLanguage,
      'session_timeout_minutes': sessionTimeoutMinutes,
      'admin_notes': adminNotes,
    };
  }
}

class EmployeeModel {
  const EmployeeModel({
    required this.id,
    required this.fullName,
    required this.username,
    required this.email,
    required this.phoneNumber,
    required this.medicalRecordNumber,
    required this.insuranceProvider,
    required this.address,
    required this.dependents,
    this.dateOfBirth,
    this.nationalId = '',
    this.universityId = '',
    this.insuranceNumber = '',
    this.gender = '',
  });

  final int id;
  final String fullName;
  final String username;
  final String email;
  final String phoneNumber;
  final String medicalRecordNumber;
  final String insuranceProvider;
  final String address;
  final List<DependentModel> dependents;
  final DateTime? dateOfBirth;
  final String nationalId;
  final String universityId;
  final String insuranceNumber;
  final String gender;

  factory EmployeeModel.fromJson(Map<String, dynamic> json) {
    return EmployeeModel(
      id: json['id'] as int,
      fullName:
          json['full_name'] as String? ?? json['username'] as String? ?? '',
      username: json['username'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phoneNumber: json['phone_number'] as String? ?? '',
      medicalRecordNumber: json['medical_record_number'] as String? ?? '',
      insuranceProvider: json['insurance_provider'] as String? ?? '',
      address: json['address'] as String? ?? '',
      dependents: (json['dependents'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(DependentModel.fromJson)
          .toList(),
      dateOfBirth: json['date_of_birth'] == null
          ? null
          : DateTime.tryParse(json['date_of_birth'] as String),
      nationalId: json['national_id'] as String? ?? '',
      universityId: json['university_id'] as String? ?? '',
      insuranceNumber: json['insurance_number'] as String? ?? '',
      gender: json['gender'] as String? ?? '',
    );
  }
}

typedef PatientModel = EmployeeModel;

class DependentModel {
  const DependentModel({
    required this.id,
    required this.fullName,
    required this.relation,
    required this.relationship,
    required this.notes,
    required this.isActive,
    this.nationalId = '',
    this.dateOfBirth,
  });

  final int id;
  final String fullName;
  final String relation;
  final String relationship;
  final String notes;
  final bool isActive;
  final String nationalId;
  final DateTime? dateOfBirth;

  factory DependentModel.fromJson(Map<String, dynamic> json) {
    return DependentModel(
      id: json['id'] as int,
      fullName: json['full_name'] as String? ?? '',
      relation:
          json['relation'] as String? ?? json['relationship'] as String? ?? '',
      relationship: json['relationship'] as String? ?? '',
      notes: json['notes'] as String? ?? '',
      isActive: json['is_active'] as bool? ?? true,
      nationalId: json['national_id'] as String? ?? '',
      dateOfBirth: json['date_of_birth'] == null
          ? null
          : DateTime.tryParse(json['date_of_birth'] as String),
    );
  }
}

class MedicationModel {
  const MedicationModel({
    required this.id,
    required this.name,
    required this.genericName,
    required this.strength,
    required this.dosageForm,
    required this.manufacturer,
  });

  final int id;
  final String name;
  final String genericName;
  final String strength;
  final String dosageForm;
  final String manufacturer;

  factory MedicationModel.fromJson(Map<String, dynamic> json) {
    return MedicationModel(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      genericName: json['generic_name'] as String? ?? '',
      strength: json['strength'] as String? ?? '',
      dosageForm: json['dosage_form'] as String? ?? '',
      manufacturer: json['manufacturer'] as String? ?? '',
    );
  }
}

class CoverageCatalogItemModel {
  const CoverageCatalogItemModel({
    required this.id,
    required this.code,
    required this.title,
    required this.category,
    required this.providerType,
    required this.providerName,
    required this.unitPrice,
    required this.coveragePercentage,
    required this.maxQuantity,
    required this.requiresInsuranceApproval,
    required this.isActive,
    this.description = '',
    this.notes = '',
    this.genericName = '',
    this.strength = '',
  });

  final int id;
  final String code;
  final String title;
  final String category;
  final String providerType;
  final String providerName;
  final double unitPrice;
  final double coveragePercentage;
  final int maxQuantity;
  final bool requiresInsuranceApproval;
  final bool isActive;
  final String description;
  final String notes;
  final String genericName;
  final String strength;

  double get employeeSharePercentage => 100 - coveragePercentage;

  double coveredAmountFor(double totalPrice) {
    return totalPrice * (coveragePercentage / 100);
  }

  double employeeShareFor(double totalPrice) {
    return totalPrice - coveredAmountFor(totalPrice);
  }

  factory CoverageCatalogItemModel.fromJson(Map<String, dynamic> json) {
    return CoverageCatalogItemModel(
      id: json['id'] as int,
      code: json['code'] as String? ?? '',
      title: json['title'] as String? ?? '',
      category: json['category'] as String? ?? 'Medication',
      providerType: json['provider_type'] as String? ?? '',
      providerName: json['provider_name'] as String? ?? '',
      unitPrice: _parseDouble(json['unit_price']),
      coveragePercentage: _parseDouble(json['coverage_percentage']),
      maxQuantity: json['max_quantity'] as int? ?? 1,
      requiresInsuranceApproval:
          json['requires_insurance_approval'] as bool? ?? false,
      isActive: json['is_active'] as bool? ?? true,
      description: json['description'] as String? ?? '',
      notes: json['notes'] as String? ?? '',
      genericName: json['generic_name'] as String? ?? '',
      strength: json['strength'] as String? ?? '',
    );
  }
}

class PrescriptionItemModel {
  const PrescriptionItemModel({
    required this.id,
    required this.medicationId,
    required this.medicationName,
    required this.dosageInstructions,
    required this.quantity,
    required this.duration,
    required this.substitutionAllowed,
  });

  final int id;
  final int medicationId;
  final String medicationName;
  final String dosageInstructions;
  final String quantity;
  final String duration;
  final bool substitutionAllowed;

  factory PrescriptionItemModel.fromJson(Map<String, dynamic> json) {
    return PrescriptionItemModel(
      id: json['id'] as int? ?? 0,
      medicationId: json['medication'] as int? ?? 0,
      medicationName: json['medication_name'] as String? ?? '',
      dosageInstructions: json['dosage_instructions'] as String? ?? '',
      quantity: json['quantity'] as String? ?? '',
      duration: json['duration'] as String? ?? '',
      substitutionAllowed: json['substitution_allowed'] as bool? ?? false,
    );
  }
}

class PrescriptionModel {
  const PrescriptionModel({
    required this.id,
    required this.prescriptionNumber,
    required this.employeeId,
    required this.employeeName,
    required this.employeeRecordNumber,
    required this.doctorId,
    required this.doctorName,
    required this.status,
    required this.diagnosis,
    required this.notes,
    required this.items,
    required this.serviceType,
    required this.providerName,
    required this.serviceName,
    required this.coveragePercentage,
    required this.coveredAmount,
    required this.employeeShare,
    required this.finalPrice,
    required this.requiresInsuranceApproval,
    required this.providerNotes,
    required this.reportAttachmentUrl,
    this.beneficiaryId,
    this.beneficiaryName,
    this.issuedAt,
    this.validUntil,
    this.performedAt,
  });

  final int id;
  final String prescriptionNumber;
  final int employeeId;
  final String employeeName;
  final String employeeRecordNumber;
  final int doctorId;
  final String doctorName;
  final String status;
  final String diagnosis;
  final String notes;
  final List<PrescriptionItemModel> items;
  final String serviceType;
  final String providerName;
  final String serviceName;
  final double coveragePercentage;
  final double coveredAmount;
  final double employeeShare;
  final double finalPrice;
  final bool requiresInsuranceApproval;
  final String providerNotes;
  final String reportAttachmentUrl;
  final int? beneficiaryId;
  final String? beneficiaryName;
  final DateTime? issuedAt;
  final DateTime? validUntil;
  final DateTime? performedAt;

  int get patientId => employeeId;
  String get patientName => employeeName;
  String get patientRecordNumber => employeeRecordNumber;
  int? get dependentId => beneficiaryId;
  String? get dependentName => beneficiaryName;

  factory PrescriptionModel.fromJson(Map<String, dynamic> json) {
    return PrescriptionModel(
      id: json['id'] as int,
      prescriptionNumber: json['prescription_number'] as String? ?? '',
      employeeId: json['employee'] as int? ?? json['patient'] as int? ?? 0,
      employeeName:
          json['employee_name'] as String? ??
          json['patient_name'] as String? ??
          '',
      employeeRecordNumber:
          json['employee_record_number'] as String? ??
          json['patient_record_number'] as String? ??
          '',
      doctorId: json['doctor'] as int? ?? 0,
      doctorName: json['doctor_name'] as String? ?? '',
      status: json['status'] as String? ?? '',
      diagnosis: json['diagnosis'] as String? ?? '',
      notes: json['notes'] as String? ?? '',
      items: ((json['items'] as List?) ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(PrescriptionItemModel.fromJson)
          .toList(),
      beneficiaryId: json['beneficiary'] as int? ?? json['dependent'] as int?,
      beneficiaryName:
          json['beneficiary_name'] as String? ??
          json['dependent_name'] as String?,
      serviceType: json['service_type'] as String? ?? 'Medication',
      providerName: json['provider_name'] as String? ?? '',
      serviceName: json['service_name'] as String? ?? '',
      coveragePercentage: _parseDouble(json['coverage_percentage']),
      coveredAmount: _parseDouble(json['covered_amount']),
      employeeShare: _parseDouble(json['employee_share']),
      finalPrice: _parseDouble(json['final_price']),
      requiresInsuranceApproval:
          json['requires_insurance_approval'] as bool? ?? false,
      providerNotes: json['provider_notes'] as String? ?? '',
      reportAttachmentUrl: json['report_attachment_url'] as String? ?? '',
      issuedAt: json['issued_at'] == null
          ? null
          : DateTime.tryParse(json['issued_at'] as String),
      validUntil: json['valid_until'] == null
          ? null
          : DateTime.tryParse(json['valid_until'] as String),
      performedAt: json['performed_at'] == null
          ? null
          : DateTime.tryParse(json['performed_at'] as String),
    );
  }
}

class InsuranceRequestModel {
  const InsuranceRequestModel({
    required this.id,
    required this.prescriptionId,
    required this.prescriptionNumber,
    required this.employeeName,
    required this.doctorName,
    required this.status,
    required this.requestNumber,
    required this.responseNotes,
    required this.providerName,
    required this.serviceName,
    required this.serviceType,
    required this.totalPrice,
    required this.coveragePercentage,
    required this.coveredAmount,
    required this.employeeShare,
    required this.prescriptionStatus,
    this.beneficiaryName,
    this.submittedAt,
  });

  final int id;
  final int prescriptionId;
  final String prescriptionNumber;
  final String employeeName;
  final String doctorName;
  final String status;
  final String requestNumber;
  final String responseNotes;
  final String providerName;
  final String serviceName;
  final String serviceType;
  final double totalPrice;
  final double coveragePercentage;
  final double coveredAmount;
  final double employeeShare;
  final String prescriptionStatus;
  final String? beneficiaryName;
  final DateTime? submittedAt;

  String get patientName => employeeName;
  String? get dependentName => beneficiaryName;

  factory InsuranceRequestModel.fromJson(Map<String, dynamic> json) {
    return InsuranceRequestModel(
      id: json['id'] as int,
      prescriptionId: json['prescription'] as int? ?? 0,
      prescriptionNumber: json['prescription_number'] as String? ?? '',
      employeeName:
          json['employee_name'] as String? ??
          json['patient_name'] as String? ??
          '',
      doctorName: json['doctor_name'] as String? ?? '',
      status: json['status'] as String? ?? '',
      requestNumber: json['request_number'] as String? ?? '',
      responseNotes: json['response_notes'] as String? ?? '',
      providerName: json['provider_name'] as String? ?? '',
      serviceName: json['service_name'] as String? ?? '',
      serviceType: json['service_type'] as String? ?? '',
      totalPrice: _parseDouble(json['total_price']),
      coveragePercentage: _parseDouble(json['coverage_percentage']),
      coveredAmount: _parseDouble(json['covered_amount']),
      employeeShare: _parseDouble(json['employee_share']),
      prescriptionStatus: json['prescription_status'] as String? ?? '',
      beneficiaryName:
          json['beneficiary_name'] as String? ??
          json['dependent_name'] as String?,
      submittedAt: json['submitted_at'] == null
          ? null
          : DateTime.tryParse(json['submitted_at'] as String),
    );
  }
}

class DispenseModel {
  const DispenseModel({
    required this.id,
    required this.prescriptionId,
    required this.prescriptionNumber,
    required this.employeeName,
    required this.pharmacistName,
    required this.dispenseNumber,
    required this.status,
    required this.notes,
    this.dispensedAt,
  });

  final int id;
  final int prescriptionId;
  final String prescriptionNumber;
  final String employeeName;
  final String pharmacistName;
  final String dispenseNumber;
  final String status;
  final String notes;
  final DateTime? dispensedAt;

  String get patientName => employeeName;

  factory DispenseModel.fromJson(Map<String, dynamic> json) {
    return DispenseModel(
      id: json['id'] as int,
      prescriptionId: json['prescription'] as int? ?? 0,
      prescriptionNumber: json['prescription_number'] as String? ?? '',
      employeeName:
          json['employee_name'] as String? ??
          json['patient_name'] as String? ??
          '',
      pharmacistName: json['pharmacist_name'] as String? ?? '',
      dispenseNumber: json['dispense_number'] as String? ?? '',
      status: json['status'] as String? ?? '',
      notes: json['notes'] as String? ?? '',
      dispensedAt: json['dispensed_at'] == null
          ? null
          : DateTime.tryParse(json['dispensed_at'] as String),
    );
  }
}

class DoctorDirectoryModel {
  const DoctorDirectoryModel({
    required this.id,
    required this.fullName,
    required this.specialty,
    required this.clinicName,
    required this.providerName,
    required this.city,
    required this.address,
    required this.phoneNumber,
    required this.consultationPrice,
    required this.contractStatus,
  });

  final int id;
  final String fullName;
  final String specialty;
  final String clinicName;
  final String providerName;
  final String city;
  final String address;
  final String phoneNumber;
  final double consultationPrice;
  final String contractStatus;

  factory DoctorDirectoryModel.fromJson(Map<String, dynamic> json) {
    final userDetails =
        json['user_details'] as Map<String, dynamic>? ?? const {};
    final firstName = userDetails['first_name'] as String? ?? '';
    final lastName = userDetails['last_name'] as String? ?? '';
    final displayName = '$firstName $lastName'.trim();
    return DoctorDirectoryModel(
      id: json['id'] as int,
      fullName: displayName.isEmpty
          ? (userDetails['username'] as String? ?? '')
          : displayName,
      specialty: json['specialization'] as String? ?? '',
      clinicName: json['clinic_name'] as String? ?? '',
      providerName: json['provider_name'] as String? ?? '',
      city: (json['provider_city'] ?? json['city'] ?? '') as String,
      address:
          (json['clinic_address'] ?? json['provider_address'] ?? '') as String,
      phoneNumber: (userDetails['phone_number'] ?? '') as String,
      consultationPrice: _parseDouble(json['consultation_price']),
      contractStatus: json['contract_status'] as String? ?? '',
    );
  }
}
