import 'package:flutter_test/flutter_test.dart';

import 'package:healthbridge_mobile/src/core/network/api_client.dart';
import 'package:healthbridge_mobile/src/data/models/app_models.dart';
import 'package:healthbridge_mobile/src/data/services/app_data_service.dart';

AppDataService _createService() {
  final apiClient = ApiClient()..updateToken('demo-token-test-suite');
  return AppDataService(apiClient: apiClient);
}

void main() {
  group('AppDataService CRUD operations in demo mode', () {
    test('creates and updates an employee from nested admin payload', () async {
      final service = _createService();

      final created = await service.createEmployee({
        'user': {
          'full_name': 'موظف تجريبي جديد',
          'username': 'employee_crud_demo',
          'email': 'employee-crud@test.local',
          'phone': '0599001122',
        },
        'medical_record_number': 'MRN-CRUD-001',
        'insurance_provider': 'جامعة بوليتكنك فلسطين',
        'dependents': [
          {
            'full_name': 'مستفيد أول',
            'relation': 'son',
            'is_active': true,
          },
          {
            'full_name': 'مستفيد ثان',
            'relation': 'daughter',
            'is_active': true,
          },
        ],
      });

      expect(created.fullName, 'موظف تجريبي جديد');
      expect(created.username, 'employee_crud_demo');
      expect(created.dependents, hasLength(2));

      final byUser = await service.getEmployeeByUser(
        username: 'employee_crud_demo',
        email: 'employee-crud@test.local',
      );
      expect(byUser, isNotNull);
      expect(byUser!.id, created.id);

      final dependents = await service.getDependents(employeeId: created.id);
      expect(dependents, hasLength(2));

      final updated = await service.updateEmployee(created.id, {
        'full_name': 'موظف تجريبي بعد التعديل',
        'insurance_provider': 'تأمين محدث',
      });

      expect(updated.fullName, 'موظف تجريبي بعد التعديل');
      expect(updated.insuranceProvider, 'تأمين محدث');
    });

    test('creates, reads, updates, and deletes dependents while keeping employee view in sync', () async {
      final service = _createService();
      final employees = await service.getEmployees();
      final employee = employees.first;

      final created = await service.createDependent({
        'employee': employee.id,
        'full_name': 'مستفيد CRUD',
        'relation': 'wife',
        'national_id': '401999111',
        'date_of_birth': '1995-01-10',
        'is_active': true,
      });

      var dependents = await service.getDependents(employeeId: employee.id);
      expect(dependents.any((item) => item.id == created.id), isTrue);

      final updated = await service.updateDependent(created.id, {
        'full_name': 'مستفيد CRUD بعد التعديل',
        'relation': 'wife',
        'is_active': false,
        'date_of_birth': '1996-02-11',
      });

      expect(updated.fullName, 'مستفيد CRUD بعد التعديل');
      expect(updated.isActive, isFalse);

      dependents = await service.getDependents(employeeId: employee.id);
      final synced = dependents.firstWhere((item) => item.id == created.id);
      expect(synced.fullName, 'مستفيد CRUD بعد التعديل');
      expect(synced.isActive, isFalse);

      await service.deleteDependent(created.id);
      dependents = await service.getDependents(employeeId: employee.id);
      expect(dependents.any((item) => item.id == created.id), isFalse);
    });

    test('reads, creates, and updates coverage catalog items', () async {
      final service = _createService();

      final medications = await service.getCoverageCatalog(category: 'Medication');
      expect(medications, isNotEmpty);

      final created = await service.createCoverageCatalogItem(
        item: const CoverageCatalogItemModel(
          id: 990001,
          code: 'LAB-CRUD-001',
          title: 'CRP Test',
          category: 'Laboratory',
          providerType: 'Laboratory',
          providerName: 'مختبر تجريبي',
          unitPrice: 35,
          coveragePercentage: 80,
          maxQuantity: 1,
          requiresInsuranceApproval: false,
          isActive: true,
          description: 'فحص التهابي',
          notes: 'مخصص لاختبار CRUD',
        ),
      );

      expect(created.code, 'LAB-CRUD-001');

      final updated = await service.updateCoverageCatalogItem(
        item: const CoverageCatalogItemModel(
          id: 990001,
          code: 'LAB-CRUD-001',
          title: 'CRP Test Updated',
          category: 'Laboratory',
          providerType: 'Laboratory',
          providerName: 'مختبر تجريبي',
          unitPrice: 40,
          coveragePercentage: 85,
          maxQuantity: 2,
          requiresInsuranceApproval: true,
          isActive: true,
          description: 'فحص التهابي بعد التعديل',
          notes: 'تم تحديثه من الاختبار',
        ),
      );

      expect(updated.title, 'CRP Test Updated');
      expect(updated.coveragePercentage, 85);

      final labItems = await service.getCoverageCatalog(category: 'Laboratory', activeOnly: false);
      final found = labItems.firstWhere((item) => item.id == 990001);
      expect(found.title, 'CRP Test Updated');
      expect(found.requiresInsuranceApproval, isTrue);
    });

    test('reads, creates, and updates users', () async {
      final service = _createService();
      final initialUsers = await service.getUsers();
      expect(initialUsers, isNotEmpty);

      final created = await service.createUser({
        'username': 'crud_user_demo',
        'email': 'crud-user@test.local',
        'role': 'Employee',
        'first_name': 'Crud',
        'last_name': 'User',
        'phone_number': '0599555666',
        'is_active': true,
      });

      expect(created.username, 'crud_user_demo');

      final updated = await service.updateUser(created.id, {
        'role': 'InsuranceOfficer',
        'first_name': 'Updated',
        'is_active': false,
      });

      expect(updated.role, 'InsuranceOfficer');
      expect(updated.firstName, 'Updated');
      expect(updated.isActive, isFalse);

      final allUsers = await service.getUsers();
      final found = allUsers.firstWhere((item) => item.id == created.id);
      expect(found.role, 'InsuranceOfficer');
    });

    test('creates and updates prescription workflow records', () async {
      final service = _createService();
      final employee = (await service.getEmployees()).first;

      final prescription = await service.createPrescription(
        employeeId: employee.id,
        diagnosis: 'طلب فحص مخبري',
        notes: 'فحص للاختبار',
        status: 'Sent',
        items: const [],
        serviceType: 'Laboratory',
        providerName: 'مختبر الجامعة',
        serviceName: 'CBC',
        coveragePercentage: 80,
        coveredAmount: 32,
        employeeShare: 8,
        finalPrice: 40,
        requiresInsuranceApproval: true,
      );

      expect(prescription.serviceType, 'Laboratory');
      expect(prescription.status, 'PendingInsuranceApproval');

      final fetched = await service.getPrescription(prescription.id);
      expect(fetched.id, prescription.id);

      final updatedStatus = await service.updatePrescriptionStatus(
        id: prescription.id,
        status: 'Approved',
        providerNotes: 'تمت الموافقة',
      );

      expect(updatedStatus.status, 'Approved');
      expect(updatedStatus.providerNotes, 'تمت الموافقة');
    });

    test('creates and updates insurance requests and syncs prescription status', () async {
      final service = _createService();
      final employee = (await service.getEmployees()).first;

      final prescription = await service.createPrescription(
        employeeId: employee.id,
        diagnosis: 'طلب تصوير',
        notes: 'صورة رنين',
        status: 'Sent',
        items: const [],
        serviceType: 'Imaging',
        providerName: 'مركز التصوير الطبي',
        serviceName: 'MRI Knee',
        coveragePercentage: 70,
        coveredAmount: 210,
        employeeShare: 90,
        finalPrice: 300,
        requiresInsuranceApproval: true,
      );

      final createdRequest = await service.createInsuranceRequest(
        prescriptionId: prescription.id,
      );
      expect(createdRequest.prescriptionId, prescription.id);

      final updatedRequest = await service.updateInsuranceRequest(
        id: createdRequest.id,
        status: 'Approved',
        notes: 'موافقة نهائية',
      );
      expect(updatedRequest.status, 'Approved');

      final updatedPrescription = await service.getPrescription(prescription.id);
      expect(updatedPrescription.status, 'Approved');
      expect(updatedPrescription.providerNotes, 'موافقة نهائية');
    });

    test('creates dispense record and updates prescription status to dispensed', () async {
      final service = _createService();
      final employee = (await service.getEmployees()).first;

      final prescription = await service.createPrescription(
        employeeId: employee.id,
        diagnosis: 'صرف علاج',
        notes: 'اختبار صرف',
        status: 'Approved',
        items: const [
          {
            'medication': 8001,
            'dosage_instructions': 'حبة بعد الأكل',
            'quantity': '1',
            'duration': '5 أيام',
            'substitution_allowed': false,
          },
        ],
        serviceType: 'Medication',
        providerName: 'شبكة الصيدليات المتعاقدة',
        serviceName: 'Panadol',
        coveragePercentage: 90,
        coveredAmount: 10.8,
        employeeShare: 1.2,
        finalPrice: 12,
        requiresInsuranceApproval: false,
      );

      final dispense = await service.createDispense(
        prescriptionId: prescription.id,
        dispenseNumber: 'DSP-CRUD-001',
        status: 'Completed',
        notes: 'تم الصرف من الاختبار',
      );

      expect(dispense.prescriptionId, prescription.id);

      final dispenses = await service.getDispenses();
      expect(dispenses.any((item) => item.dispenseNumber == 'DSP-CRUD-001'), isTrue);

      final updatedPrescription = await service.getPrescription(prescription.id);
      expect(updatedPrescription.status, 'Dispensed');
    });

    test('marks notification as read and supports mark all read', () async {
      final service = _createService();

      final notifications = await service.getNotifications();
      final unread = notifications.firstWhere((item) => !item.isRead);

      final updated = await service.markNotificationRead(unread.id);
      expect(updated.isRead, isTrue);

      await service.markAllNotificationsRead();
      final unreadCount = await service.getUnreadNotificationCount();
      expect(unreadCount, 0);
    });
  });
}
