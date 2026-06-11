import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../data/models/app_models.dart';
import '../../../../data/repositories/app_repository.dart';
import '../../../../features/auth/presentation/viewmodels/auth_view_model.dart';
import '../../../../features/common/presentation/views/notifications_screen.dart';
import '../../../../features/common/presentation/views/profile_screen.dart';
import '../../../../shared/utils/status_label.dart';
import '../../../../shared/widgets/hb_custom_button.dart';
import '../../../../shared/widgets/hb_custom_card.dart';
import '../../../../shared/widgets/hb_dashboard_overview.dart';
import '../../../../shared/widgets/hb_custom_input.dart';
import '../../../../shared/widgets/hb_empty_state.dart';
import '../../../../shared/widgets/hb_filter_bar.dart';
import '../../../../shared/widgets/hb_info_row.dart';
import '../../../../shared/widgets/hb_notification_action.dart';
import '../../../../shared/widgets/hb_primary_button_row.dart';
import '../../../../shared/widgets/hb_quick_action_card.dart';
import '../../../../shared/widgets/hb_scaffold.dart';
import '../../../../shared/widgets/hb_section_card.dart';
import '../../../../shared/widgets/hb_status_chip.dart';

class DoctorHomeScreen extends StatelessWidget {
  const DoctorHomeScreen({super.key});

  static const routeName = 'doctor-home';
  static const routePath = '/doctor';

  @override
  Widget build(BuildContext context) {
    return HbScaffold(
      title: 'الصفحة الرئيسية للطبيب',
      actions: _commonActions(context),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final actionWidth = constraints.maxWidth > 960
              ? (constraints.maxWidth - 24) / 3
              : constraints.maxWidth > 620
              ? (constraints.maxWidth - 12) / 2
              : constraints.maxWidth;

          return ListView(
            children: [
              const HbDashboardOverview(
                recentTitle: 'آخر الوصفات',
                emptyMessage:
                    'ستظهر هنا الوصفات الحديثة التي قمت بإنشائها أو إرسالها.',
              ),
              const SizedBox(height: 16),
              Text(
                'الإجراءات السريعة',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  SizedBox(
                    width: actionWidth,
                    child: HbQuickActionCard(
                      title: 'البحث عن مريض',
                      subtitle:
                          'الوصول السريع إلى بيانات الموظفين الجامعيين والمستفيدين',
                      icon: Icons.search_rounded,
                      onTap: () =>
                          context.push(DoctorPatientSearchScreen.routePath),
                    ),
                  ),
                  SizedBox(
                    width: actionWidth,
                    child: HbQuickActionCard(
                      title: 'إنشاء وصفة جديدة',
                      subtitle: 'بدء وصفة طبية إلكترونية جديدة',
                      icon: Icons.note_add_rounded,
                      onTap: () => context.push(
                        DoctorPrescriptionCreateScreen.routePath,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: actionWidth,
                    child: HbQuickActionCard(
                      title: 'الوصفات السابقة',
                      subtitle: 'استعراض سجل الوصفات السابقة',
                      icon: Icons.history_rounded,
                      onTap: () => context.push(
                        DoctorPrescriptionHistoryScreen.routePath,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: actionWidth,
                    child: HbQuickActionCard(
                      title: 'الإشعارات',
                      subtitle: 'مراجعة أحدث التنبيهات الطبية',
                      icon: Icons.notifications_active_outlined,
                      onTap: () => context.push(NotificationsScreen.routePath),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class DoctorPatientSearchScreen extends StatefulWidget {
  const DoctorPatientSearchScreen({super.key});

  static const routeName = 'doctor-patient-search';
  static const routePath = '/doctor/patients';

  @override
  State<DoctorPatientSearchScreen> createState() =>
      _DoctorPatientSearchScreenState();
}

class _DoctorPatientSearchScreenState extends State<DoctorPatientSearchScreen> {
  static const _patientFilterOptions = [
    HbFilterOption(value: 'الكل', label: 'الكل'),
  ];

  final _searchController = TextEditingController();
  String _query = '';
  String _selectedFilter = 'الكل';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return HbScaffold(
      title: 'البحث عن الموظفين الجامعيين',
      actions: _commonActions(context),
      body: FutureBuilder<List<EmployeeModel>>(
        future: context.read<AppRepository>().getEmployees(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return HbEmptyState(
              title: 'تعذر تحميل الموظفين الجامعيين',
              message: snapshot.error.toString(),
              icon: Icons.cloud_off_rounded,
            );
          }

          final patients = snapshot.data ?? const [];
          final normalizedQuery = _query.trim().toLowerCase();
          final filteredPatients = patients.where((patient) {
            final matchesSearch =
                normalizedQuery.isEmpty ||
                patient.fullName.toLowerCase().contains(normalizedQuery) ||
                patient.medicalRecordNumber.toLowerCase().contains(
                  normalizedQuery,
                );

            return matchesSearch;
          }).toList();

          return ListView(
            children: [
              HbCustomInput(
                controller: _searchController,
                label: 'البحث عن موظف جامعي',
                hint: 'ابحث بالاسم أو رقم الملف الطبي',
                prefixIcon: Icons.search_rounded,
                onChanged: (value) {
                  setState(() => _query = value);
                },
              ),
              const SizedBox(height: 12),
              HbFilterBar(
                options: _patientFilterOptions,
                selectedValue: _selectedFilter,
                onChanged: (value) {
                  setState(() => _selectedFilter = value);
                },
              ),
              const SizedBox(height: 16),
              if (filteredPatients.isEmpty)
                const HbEmptyState(
                  title: 'لا توجد نتائج',
                  message:
                      'لم يتم العثور على موظفين جامعيين مطابقين للبحث أو الفلتر الحالي.',
                )
              else
                ...filteredPatients.map(
                  (patient) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: HbCustomCard(
                      onTap: () => context.push(
                        '${DoctorPatientDetailScreen.routePath}?id=${patient.id}',
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: const Color(0x122D8CFF),
                            child: Text(
                              patient.fullName.isEmpty
                                  ? '-'
                                  : patient.fullName.characters.first,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(color: const Color(0xFF2D8CFF)),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  patient.fullName,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'رقم الملف الطبي: ${patient.medicalRecordNumber}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class DoctorPatientDetailScreen extends StatelessWidget {
  const DoctorPatientDetailScreen({super.key, this.patientId});

  static const routeName = 'doctor-patient-detail';
  static const routePath = '/doctor/patient-detail';

  final int? patientId;

  @override
  Widget build(BuildContext context) {
    return HbScaffold(
      title: 'بيانات الموظف الجامعي',
      actions: _commonActions(context),
      body: patientId == null
          ? const HbEmptyState(
              title: 'لا يوجد موظف محدد',
              message: 'يرجى اختيار موظف جامعي أولًا.',
            )
          : FutureBuilder<List<dynamic>>(
              future: Future.wait([
                context.read<AppRepository>().getEmployee(patientId!),
                context.read<AppRepository>().getDependents(
                  employeeId: patientId,
                ),
                context.read<AppRepository>().getPrescriptions(),
              ]),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return HbEmptyState(
                    title: 'تعذر تحميل بيانات الموظف الجامعي',
                    message: snapshot.error.toString(),
                    icon: Icons.cloud_off_rounded,
                  );
                }

                final patient = snapshot.data![0] as EmployeeModel;
                final dependents = snapshot.data![1] as List<DependentModel>;
                final prescriptions =
                    (snapshot.data![2] as List<PrescriptionModel>)
                        .where((item) => item.patientId == patient.id)
                        .take(3)
                        .toList();

                return ListView(
                  children: [
                    HbSectionCard(
                      title: 'معلومات الموظف الجامعي',
                      subtitle: patient.fullName,
                      child: Column(
                        children: [
                          HbInfoRow(
                            label: 'رقم الملف الطبي',
                            value: patient.medicalRecordNumber,
                          ),
                          HbInfoRow(
                            label: 'البريد الإلكتروني',
                            value: patient.email.isEmpty
                                ? 'غير متوفر'
                                : patient.email,
                          ),
                          HbInfoRow(
                            label: 'رقم الهاتف',
                            value: patient.phoneNumber.isEmpty
                                ? 'غير متوفر'
                                : patient.phoneNumber,
                          ),
                          HbInfoRow(
                            label: 'تاريخ الميلاد',
                            value: _formatDate(
                              patient.dateOfBirth,
                              fallback: 'غير محدد',
                            ),
                          ),
                          HbInfoRow(
                            label: 'العنوان',
                            value: patient.address.isEmpty
                                ? 'غير متوفر'
                                : patient.address,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    HbSectionCard(
                      title: 'الوصفات السابقة',
                      subtitle: 'آخر الطلبات الطبية المسجلة للموظف داخل النظام',
                      child: prescriptions.isEmpty
                          ? const Text(
                              'لا توجد طلبات طبية سابقة لهذا الموظف الجامعي.',
                            )
                          : Column(
                              children: prescriptions.map((prescription) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: HbCustomCard(
                                    onTap: () => context.push(
                                      '${DoctorPrescriptionDetailScreen.routePath}?id=${prescription.id}',
                                    ),
                                    padding: const EdgeInsets.all(14),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.description_outlined,
                                          color: Color(0xFF2D8CFF),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                prescription.diagnosis.isEmpty
                                                    ? 'وصفة طبية'
                                                    : prescription.diagnosis,
                                                style: Theme.of(
                                                  context,
                                                ).textTheme.titleMedium,
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                _formatDate(
                                                  prescription.issuedAt,
                                                ),
                                                style: Theme.of(
                                                  context,
                                                ).textTheme.bodySmall,
                                              ),
                                            ],
                                          ),
                                        ),
                                        HbStatusChip(
                                          statusLabel(prescription.status),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                    ),
                    const SizedBox(height: 16),
                    HbSectionCard(
                      title: 'المستفيدون / المعالون',
                      child: dependents.isEmpty
                          ? const Text(
                              'لا يوجد مستفيدون مسجلون لهذا الموظف الجامعي.',
                            )
                          : Column(
                              children: dependents.map((dependent) {
                                return ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(dependent.fullName),
                                  subtitle: Text(
                                    '${dependent.relationship} • ${_formatDate(dependent.dateOfBirth, fallback: "غير محدد")}',
                                  ),
                                  trailing: const HbStatusChip('فعّال'),
                                );
                              }).toList(),
                            ),
                    ),
                    const SizedBox(height: 16),
                    HbPrimaryButtonRow(
                      primaryLabel: 'إنشاء وصفة جديدة',
                      onPrimaryPressed: () => context.push(
                        '${DoctorPrescriptionCreateScreen.routePath}?patientId=${patient.id}',
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }
}

class DoctorPrescriptionCreateScreen extends StatelessWidget {
  const DoctorPrescriptionCreateScreen({super.key, this.patientId});

  static const routeName = 'doctor-prescription-create';
  static const routePath = '/doctor/prescriptions/create';

  final int? patientId;

  @override
  Widget build(BuildContext context) {
    return _DoctorPrescriptionCreateForm(patientId: patientId);
  }
}

class _DraftPrescriptionItem {
  const _DraftPrescriptionItem({
    required this.medicationId,
    required this.medicationName,
    required this.serviceName,
    required this.strength,
    required this.dosageForm,
    required this.dosageInstructions,
    required this.quantity,
    required this.duration,
    required this.requestedUnits,
    required this.unitPrice,
    required this.totalPrice,
    required this.coveragePercentage,
    required this.coveredAmount,
    required this.employeeShare,
    required this.requiresInsuranceApproval,
    required this.providerName,
    required this.coverageCode,
    required this.coverageNotes,
  });

  final int medicationId;
  final String medicationName;
  final String serviceName;
  final String strength;
  final String dosageForm;
  final String dosageInstructions;
  final String quantity;
  final String duration;
  final int requestedUnits;
  final double unitPrice;
  final double totalPrice;
  final double coveragePercentage;
  final double coveredAmount;
  final double employeeShare;
  final bool requiresInsuranceApproval;
  final String providerName;
  final String coverageCode;
  final String coverageNotes;

  Map<String, dynamic> toPayload() {
    return {
      'medication': medicationId,
      'dosage_instructions': dosageInstructions,
      'quantity': quantity,
      'duration': duration,
      'substitution_allowed': false,
    };
  }
}

class _PrescriptionCoverageSummary {
  const _PrescriptionCoverageSummary({
    required this.totalPrice,
    required this.coveredAmount,
    required this.employeeShare,
    required this.coveragePercentage,
    required this.requiresInsuranceApproval,
    required this.providerName,
    required this.serviceName,
    required this.coverageNotes,
  });

  final double totalPrice;
  final double coveredAmount;
  final double employeeShare;
  final double coveragePercentage;
  final bool requiresInsuranceApproval;
  final String providerName;
  final String serviceName;
  final String coverageNotes;
}

class _DoctorPrescriptionCreateForm extends StatefulWidget {
  const _DoctorPrescriptionCreateForm({required this.patientId});

  final int? patientId;

  @override
  State<_DoctorPrescriptionCreateForm> createState() =>
      _DoctorPrescriptionCreateFormState();
}

class _DoctorPrescriptionCreateFormState
    extends State<_DoctorPrescriptionCreateForm> {
  final _diagnosisController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isSubmitting = false;
  int? _selectedPatientId;
  int? _selectedDependentId;
  List<DependentModel> _currentDependents = const [];
  final List<_DraftPrescriptionItem> _items = [];
  late final Future<List<dynamic>> _formSetupFuture;
  bool _didLoadInitialDependents = false;

  @override
  void initState() {
    super.initState();
    _selectedPatientId = widget.patientId;
    _formSetupFuture = Future.wait([
      context.read<AppRepository>().getEmployees(),
      context.read<AppRepository>().getCoverageCatalog(category: 'Medication'),
    ]);

    if (widget.patientId != null) {
      _didLoadInitialDependents = true;
      unawaited(_loadDependentsForPatient(widget.patientId));
    }
  }

  @override
  void dispose() {
    _diagnosisController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadDependentsForPatient(int? patientId) async {
    if (patientId == null) {
      setState(() {
        _currentDependents = const [];
        _selectedDependentId = null;
      });
      return;
    }

    final dependents = await context.read<AppRepository>().getDependents(
      employeeId: patientId,
    );
    if (!mounted) return;
    setState(() {
      _currentDependents = dependents;
      final stillValid = dependents.any(
        (item) => item.id == _selectedDependentId,
      );
      if (!stillValid) {
        _selectedDependentId = null;
      }
    });
  }

  _PrescriptionCoverageSummary? _buildMedicationCoverageSummary() {
    if (_items.isEmpty) return null;

    final totalPrice = _items.fold<double>(
      0,
      (sum, item) => sum + item.totalPrice,
    );
    final coveredAmount = _items.fold<double>(
      0,
      (sum, item) => sum + item.coveredAmount,
    );
    final employeeShare = _items.fold<double>(
      0,
      (sum, item) => sum + item.employeeShare,
    );
    final providerNames = _items
        .map((item) => item.providerName.trim())
        .where((name) => name.isNotEmpty)
        .toSet();
    final coverageNotes = _items
        .map((item) => item.coverageNotes.trim())
        .where((note) => note.isNotEmpty)
        .toSet()
        .join(' / ');

    return _PrescriptionCoverageSummary(
      totalPrice: totalPrice,
      coveredAmount: coveredAmount,
      employeeShare: employeeShare,
      coveragePercentage: totalPrice == 0
          ? 0
          : (coveredAmount / totalPrice) * 100,
      requiresInsuranceApproval: _items.any(
        (item) => item.requiresInsuranceApproval,
      ),
      providerName: providerNames.length == 1
          ? providerNames.first
          : 'أكثر من شبكة دوائية',
      serviceName: _items.length == 1
          ? _items.first.serviceName
          : 'وصفة دوائية (${_items.length} أصناف)',
      coverageNotes: coverageNotes,
    );
  }

  Widget _buildCoverageSummaryCard(_PrescriptionCoverageSummary summary) {
    return Card(
      color: const Color(0xFFF8FBFD),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ملخص التغطية',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            HbInfoRow(label: 'الخدمة', value: summary.serviceName),
            HbInfoRow(
              label: 'الجهة المنفذة',
              value: summary.providerName.isEmpty
                  ? 'غير محددة'
                  : summary.providerName,
            ),
            HbInfoRow(
              label: 'السعر الإجمالي',
              value: _formatCurrency(summary.totalPrice),
            ),
            HbInfoRow(
              label: 'نسبة التغطية',
              value: '${summary.coveragePercentage.toStringAsFixed(0)}%',
            ),
            HbInfoRow(
              label: 'حصة التأمين',
              value: _formatCurrency(summary.coveredAmount),
            ),
            HbInfoRow(
              label: 'حصة الموظف',
              value: _formatCurrency(summary.employeeShare),
            ),
            HbInfoRow(
              label: 'موافقة مسبقة',
              value: summary.requiresInsuranceApproval
                  ? 'مطلوبة'
                  : 'غير مطلوبة',
            ),
            if (summary.coverageNotes.trim().isNotEmpty)
              HbInfoRow(label: 'ملاحظات التغطية', value: summary.coverageNotes),
          ],
        ),
      ),
    );
  }

  Future<void> _addMedication() async {
    final item = await context.push<_DraftPrescriptionItem>(
      DoctorMedicationAddScreen.routePath,
    );
    if (item == null || !mounted) return;
    setState(() => _items.add(item));
  }

  Future<void> _savePrescription(String status) async {
    if (_selectedPatientId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى اختيار الموظف الجامعي أولًا')),
      );
      return;
    }

    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى إضافة دواء واحد على الأقل قبل الحفظ أو الإرسال'),
        ),
      );
      return;
    }
    final coverageSummary = _buildMedicationCoverageSummary();
    if (coverageSummary == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر حساب بيانات التغطية لهذا الطلب')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final service = context.read<AppRepository>();
      final currentUser = context.read<AuthViewModel>().currentUser;
      if (currentUser == null) {
        throw Exception('تعذر تحديد المستخدم الحالي.');
      }
      final doctorId = await service.getDoctorProfileIdForUser(currentUser.id);
      await service.createPrescription(
        employeeId: _selectedPatientId!,
        doctorId: doctorId,
        dependentId: _selectedDependentId,
        diagnosis: _diagnosisController.text.trim(),
        notes: _notesController.text.trim(),
        status: status,
        items: _items.map((item) => item.toPayload()).toList(),
        serviceType: 'Medication',
        providerName: coverageSummary.providerName,
        serviceName: coverageSummary.serviceName,
        coveragePercentage: coverageSummary.coveragePercentage,
        coveredAmount: coverageSummary.coveredAmount,
        employeeShare: coverageSummary.employeeShare,
        finalPrice: coverageSummary.totalPrice,
        requiresInsuranceApproval: coverageSummary.requiresInsuranceApproval,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            status == 'Draft'
                ? 'تم حفظ الوصفة كمسودة'
                : 'تم إرسال الوصفة بنجاح',
          ),
        ),
      );
      context.go(DoctorPrescriptionHistoryScreen.routePath);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return HbScaffold(
      title: 'إنشاء طلب طبي',
      actions: _commonActions(context),
      body: FutureBuilder<List<dynamic>>(
        future: _formSetupFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return HbEmptyState(
              title: 'تعذر تحميل نموذج الوصفة',
              message: snapshot.error.toString(),
              icon: Icons.cloud_off_rounded,
            );
          }

          final patients = snapshot.data![0] as List<EmployeeModel>;
          final effectivePatientId =
              _selectedPatientId ??
              widget.patientId ??
              (patients.isNotEmpty ? patients.first.id : null);
          _selectedPatientId = effectivePatientId;
          if (!_didLoadInitialDependents && effectivePatientId != null) {
            _didLoadInitialDependents = true;
            unawaited(_loadDependentsForPatient(effectivePatientId));
          }

          final matchingPatients = widget.patientId == null
              ? patients
              : patients
                    .where((patient) => patient.id == widget.patientId)
                    .toList();
          final selectedPatient = matchingPatients.isNotEmpty
              ? matchingPatients.first
              : null;

          return ListView(
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    children: [
                      DropdownButtonFormField<int>(
                        initialValue: _selectedPatientId ?? selectedPatient?.id,
                        decoration: const InputDecoration(
                          labelText: 'اختيار الموظف الجامعي',
                        ),
                        items: patients
                            .map(
                              (patient) => DropdownMenuItem<int>(
                                value: patient.id,
                                child: Text(patient.fullName),
                              ),
                            )
                            .toList(),
                        onChanged: (value) async {
                          setState(() => _selectedPatientId = value);
                          await _loadDependentsForPatient(value);
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<int?>(
                        initialValue: _selectedDependentId,
                        decoration: const InputDecoration(
                          labelText: 'المستفيد من عائلة الموظف (اختياري)',
                          helperText:
                              'يمكنك اختيار الزوجة أو الأبناء المسجلين لهذا الموظف',
                        ),
                        items: [
                          const DropdownMenuItem<int?>(
                            value: null,
                            child: Text('الموظف نفسه'),
                          ),
                          ..._currentDependents.map(
                            (dependent) => DropdownMenuItem<int?>(
                              value: dependent.id,
                              child: Text(
                                '${dependent.fullName} (${_dependentRelationLabel(dependent)})',
                              ),
                            ),
                          ),
                        ],
                        onChanged: (value) =>
                            setState(() => _selectedDependentId = value),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _diagnosisController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'التشخيص',
                          hintText: 'اكتب التشخيص الطبي هنا',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _notesController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'ملاحظات',
                          hintText: 'ملاحظات إضافية للطبيب أو للموظف الجامعي',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        color: Color(0xFF0E5C4A),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'سيتم حفظ حالة الوصفة تلقائيًا كمسودة عند الإنشاء، ثم تتحول عند الإرسال حسب سير العمل.',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              HbSectionCard(
                title: 'الأدوية المضافة',
                trailing: FilledButton.icon(
                  onPressed: _addMedication,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('إضافة دواء'),
                ),
                child: _items.isEmpty
                    ? const Text('لم تتم إضافة أي دواء بعد.')
                    : Column(
                        children: _items.map((item) {
                          return Card(
                            elevation: 0,
                            color: const Color(0xFFF8FBFD),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              title: Text(item.medicationName),
                              subtitle: Text(
                                '${item.dosageInstructions} • ${item.duration}\n'
                                'التغطية ${item.coveragePercentage.toStringAsFixed(0)}% • '
                                'التأمين ${_formatCurrency(item.coveredAmount)} • '
                                'الموظف ${_formatCurrency(item.employeeShare)}',
                              ),
                              trailing: Text(item.quantity),
                            ),
                          );
                        }).toList(),
                      ),
              ),
              const SizedBox(height: 12),
              if (_buildMedicationCoverageSummary() case final summary?)
                _buildCoverageSummaryCard(summary),
              const SizedBox(height: 16),
              HbPrimaryButtonRow(
                primaryLabel: _isSubmitting
                    ? 'جاري الإرسال...'
                    : 'إرسال الوصفة',
                onPrimaryPressed: _isSubmitting
                    ? null
                    : () => _savePrescription('Sent'),
                secondaryLabel: 'حفظ الوصفة',
                onSecondaryPressed: _isSubmitting
                    ? null
                    : () => _savePrescription('Draft'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class DoctorMedicationAddScreen extends StatefulWidget {
  const DoctorMedicationAddScreen({super.key});

  static const routeName = 'doctor-medication-add';
  static const routePath = '/doctor/prescriptions/add-medication';

  @override
  State<DoctorMedicationAddScreen> createState() =>
      _DoctorMedicationAddScreenState();
}

class _DoctorMedicationAddScreenState extends State<DoctorMedicationAddScreen> {
  int? _selectedMedicationId;
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  final _durationController = TextEditingController();
  String _searchQuery = '';
  Timer? _searchDebounce;

  void _applyMedicationSearch([String? value]) {
    if (!mounted) return;
    setState(() => _searchQuery = (value ?? _searchController.text).trim());
  }

  void _scheduleMedicationSearch(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(
      const Duration(milliseconds: 450),
      () => _applyMedicationSearch(value),
    );
  }

  void _submitMedicationSearch([String? value]) {
    _searchDebounce?.cancel();
    _applyMedicationSearch(value);
    _searchFocusNode.unfocus();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _durationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return HbScaffold(
      title: 'إضافة دواء إلى الوصفة',
      body: FutureBuilder<List<dynamic>>(
        future: Future.wait([
          context.read<AppRepository>().getMedications(),
          context.read<AppRepository>().getCoverageCatalog(
            category: 'Medication',
          ),
        ]),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return HbEmptyState(
              title: 'تعذر تحميل الأدوية',
              message: snapshot.error.toString(),
              icon: Icons.cloud_off_rounded,
            );
          }

          final medications = snapshot.data![0] as List<MedicationModel>;
          final coverageCatalog =
              snapshot.data![1] as List<CoverageCatalogItemModel>;
          if (medications.isEmpty) {
            return const HbEmptyState(
              title: 'لا توجد أدوية',
              message: 'يرجى إضافة الأدوية من لوحة الإدارة أو قاعدة البيانات.',
            );
          }

          final normalizedQuery = _searchQuery.trim().toLowerCase();
          final filteredMedications = medications.where((item) {
            if (normalizedQuery.isEmpty) return true;
            return item.name.toLowerCase().contains(normalizedQuery) ||
                item.genericName.toLowerCase().contains(normalizedQuery) ||
                item.strength.toLowerCase().contains(normalizedQuery) ||
                item.manufacturer.toLowerCase().contains(normalizedQuery);
          }).toList();

          if (filteredMedications.isEmpty) {
            return ListView(
              children: [
                HbCustomCard(
                  child: Column(
                    children: [
                      TextField(
                        controller: _searchController,
                        focusNode: _searchFocusNode,
                        decoration: const InputDecoration(
                          labelText: 'البحث عن دواء',
                          hintText: 'ابحث بالاسم أو الاسم العلمي أو التركيز',
                          prefixIcon: Icon(Icons.search_rounded),
                        ),
                        textInputAction: TextInputAction.search,
                        onChanged: _scheduleMedicationSearch,
                        onEditingComplete: _submitMedicationSearch,
                        onSubmitted: _submitMedicationSearch,
                        onTapOutside: (_) => _submitMedicationSearch(),
                      ),
                      const SizedBox(height: 16),
                      const HbEmptyState(
                        title: 'لا توجد نتائج',
                        message: 'لم يتم العثور على دواء مطابق لعبارة البحث.',
                        icon: Icons.search_off_rounded,
                      ),
                    ],
                  ),
                ),
              ],
            );
          }

          if (_selectedMedicationId == null ||
              !filteredMedications.any(
                (item) => item.id == _selectedMedicationId,
              )) {
            _selectedMedicationId = filteredMedications.first.id;
          }

          final selectedMedication = filteredMedications
              .cast<MedicationModel?>()
              .firstWhere(
                (item) => item?.id == _selectedMedicationId,
                orElse: () => filteredMedications.first,
              );
          _selectedMedicationId =
              selectedMedication?.id ?? filteredMedications.first.id;
          final coverageItem = selectedMedication == null
              ? null
              : coverageCatalog.cast<CoverageCatalogItemModel?>().firstWhere(
                  (item) =>
                      item != null &&
                      (item.title.toLowerCase() ==
                              selectedMedication.name.toLowerCase() ||
                          (selectedMedication.genericName.isNotEmpty &&
                              item.genericName.toLowerCase() ==
                                  selectedMedication.genericName
                                      .toLowerCase())),
                  orElse: () => context
                      .read<AppRepository>()
                      .findCoverageForMedication(selectedMedication),
                );
          final fixedUsageCount = _fixedUsageCount(selectedMedication);
          final fixedQuantity = _fixedQuantity(selectedMedication);
          final fixedInstructions = _fixedInstructions(selectedMedication);

          return ListView(
            children: [
              HbCustomCard(
                child: Column(
                  children: [
                    TextField(
                      controller: _searchController,
                      focusNode: _searchFocusNode,
                      decoration: const InputDecoration(
                        labelText: 'البحث عن دواء',
                        hintText: 'ابحث بالاسم أو الاسم العلمي أو التركيز',
                        prefixIcon: Icon(Icons.search_rounded),
                      ),
                      textInputAction: TextInputAction.search,
                      onChanged: _scheduleMedicationSearch,
                      onEditingComplete: _submitMedicationSearch,
                      onSubmitted: _submitMedicationSearch,
                      onTapOutside: (_) => _submitMedicationSearch(),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int>(
                      key: ValueKey(_selectedMedicationId),
                      initialValue: _selectedMedicationId,
                      decoration: const InputDecoration(
                        labelText: 'اختيار الدواء من قائمة',
                      ),
                      items: filteredMedications
                          .map(
                            (item) => DropdownMenuItem<int>(
                              value: item.id,
                              child: Text('${item.name} • ${item.strength}'),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() => _selectedMedicationId = value);
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: TextEditingController(
                        text: selectedMedication?.name ?? '',
                      ),
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'اسم الدواء',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: TextEditingController(
                        text: selectedMedication?.genericName ?? '',
                      ),
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'الاسم العلمي',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: TextEditingController(
                        text: selectedMedication?.strength ?? '',
                      ),
                      readOnly: true,
                      decoration: const InputDecoration(labelText: 'التركيز'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: TextEditingController(
                        text: selectedMedication?.dosageForm ?? '',
                      ),
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'الشكل الدوائي',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: TextEditingController(text: fixedUsageCount),
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'عدد مرات الاستخدام',
                      ),
                    ),
                    const SizedBox(height: 12),
                    HbCustomInput(
                      controller: _durationController,
                      label: 'مدة الاستخدام',
                      hint: 'مثال: 5 أيام',
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: TextEditingController(text: fixedQuantity),
                      readOnly: true,
                      decoration: const InputDecoration(labelText: 'الكمية'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: TextEditingController(
                        text: fixedInstructions,
                      ),
                      readOnly: true,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'التعليمات الثابتة',
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (coverageItem != null)
                      Card(
                        elevation: 0,
                        color: const Color(0xFFF8FBFD),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'بيانات التغطية التأمينية',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 10),
                              HbInfoRow(
                                label: 'كود التغطية',
                                value: coverageItem.code,
                              ),
                              HbInfoRow(
                                label: 'الشبكة',
                                value: coverageItem.providerName,
                              ),
                              HbInfoRow(
                                label: 'سعر الوحدة',
                                value: _formatCurrency(coverageItem.unitPrice),
                              ),
                              HbInfoRow(
                                label: 'نسبة التغطية',
                                value:
                                    '${coverageItem.coveragePercentage.toStringAsFixed(0)}%',
                              ),
                              HbInfoRow(
                                label: 'الحد الأعلى',
                                value: '${coverageItem.maxQuantity} عبوة/وحدة',
                              ),
                              HbInfoRow(
                                label: 'موافقة مسبقة',
                                value: coverageItem.requiresInsuranceApproval
                                    ? 'مطلوبة'
                                    : 'غير مطلوبة',
                              ),
                              if (coverageItem.notes.trim().isNotEmpty)
                                HbInfoRow(
                                  label: 'ملاحظات',
                                  value: coverageItem.notes,
                                ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              HbPrimaryButtonRow(
                primaryLabel: 'حفظ والعودة',
                onPrimaryPressed: () {
                  final medication = selectedMedication;
                  if (medication == null) {
                    return;
                  }
                  final selectedCoverageItem =
                      coverageItem ??
                      context.read<AppRepository>().findCoverageForMedication(
                        medication,
                      );
                  final requestedUnits = _firstNumberInText(
                    fixedQuantity,
                    fallback: 1,
                  );
                  final unitPrice = selectedCoverageItem?.unitPrice ?? 0;
                  final totalPrice = unitPrice * requestedUnits;
                  final coveragePercentage =
                      selectedCoverageItem?.coveragePercentage ?? 0;
                  final coveredAmount =
                      selectedCoverageItem?.coveredAmountFor(totalPrice) ?? 0;
                  final employeeShare =
                      selectedCoverageItem?.employeeShareFor(totalPrice) ??
                      totalPrice;
                  Navigator.of(context).pop(
                    _DraftPrescriptionItem(
                      medicationId: medication.id,
                      medicationName: medication.name,
                      serviceName: medication.name,
                      strength: medication.strength,
                      dosageForm: medication.dosageForm,
                      dosageInstructions:
                          '$fixedUsageCount • $fixedInstructions',
                      quantity: fixedQuantity,
                      duration: _durationController.text.trim().isEmpty
                          ? 'غير محدد'
                          : _durationController.text.trim(),
                      requestedUnits: requestedUnits,
                      unitPrice: unitPrice,
                      totalPrice: totalPrice,
                      coveragePercentage: coveragePercentage,
                      coveredAmount: coveredAmount,
                      employeeShare: employeeShare,
                      requiresInsuranceApproval:
                          selectedCoverageItem?.requiresInsuranceApproval ??
                          false,
                      providerName:
                          selectedCoverageItem?.providerName ?? 'غير محدد',
                      coverageCode: selectedCoverageItem?.code ?? '',
                      coverageNotes: selectedCoverageItem?.notes ?? '',
                    ),
                  );
                },
                secondaryLabel: 'إعادة تعيين المدة',
                onSecondaryPressed: () {
                  _durationController.clear();
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

String _fixedUsageCount(MedicationModel? medication) {
  if (medication == null) return 'مرتان يوميًا';
  switch (medication.dosageForm.trim()) {
    case 'Injection':
    case 'حقن':
      return 'مرة واحدة يوميًا';
    case 'Syrup':
    case 'شراب':
      return 'ثلاث مرات يوميًا';
    default:
      return 'مرتان يوميًا';
  }
}

String _fixedQuantity(MedicationModel? medication) {
  if (medication == null) return '1';
  switch (medication.dosageForm.trim()) {
    case 'Syrup':
    case 'شراب':
      return '1';
    default:
      return '1';
  }
}

String _fixedInstructions(MedicationModel? medication) {
  if (medication == null) return 'حسب الإرشادات الطبية المعتمدة.';
  switch (medication.dosageForm.trim()) {
    case 'Injection':
    case 'حقن':
      return 'يستخدم تحت إشراف طبي.';
    case 'Tablet':
    case 'Capsule':
    case 'أقراص':
    case 'كبسولات':
      return 'يؤخذ بعد الطعام مع كمية كافية من الماء.';
    default:
      return 'حسب الإرشادات الطبية المعتمدة.';
  }
}

class DoctorPrescriptionHistoryScreen extends StatefulWidget {
  const DoctorPrescriptionHistoryScreen({super.key});

  static const routeName = 'doctor-prescription-history';
  static const routePath = '/doctor/prescriptions/history';

  @override
  State<DoctorPrescriptionHistoryScreen> createState() =>
      _DoctorPrescriptionHistoryScreenState();
}

class _DoctorPrescriptionHistoryScreenState
    extends State<DoctorPrescriptionHistoryScreen> {
  static const _filterOptions = [
    HbFilterOption(value: 'الكل', label: 'الكل'),
    HbFilterOption(value: 'Draft', label: 'مسودة'),
    HbFilterOption(value: 'Sent', label: 'مرسل'),
    HbFilterOption(value: 'PendingInsuranceApproval', label: 'قيد المراجعة'),
    HbFilterOption(value: 'Approved', label: 'معتمدة'),
    HbFilterOption(value: 'Dispensed', label: 'تم الصرف'),
  ];
  String _selectedFilter = 'الكل';
  late Future<List<PrescriptionModel>> _prescriptionsFuture;

  @override
  void initState() {
    super.initState();
    _prescriptionsFuture = _loadPrescriptions();
  }

  Future<List<PrescriptionModel>> _loadPrescriptions() {
    return context.read<AppRepository>().getPrescriptions();
  }

  void _refresh() {
    setState(() {
      _prescriptionsFuture = _loadPrescriptions();
    });
  }

  @override
  Widget build(BuildContext context) {
    return HbScaffold(
      title: 'الوصفات السابقة',
      actions: _commonActions(context),
      body: FutureBuilder<List<PrescriptionModel>>(
        future: _prescriptionsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return HbEmptyState(
              title: 'تعذر تحميل الوصفات',
              message: snapshot.error.toString(),
              icon: Icons.cloud_off_rounded,
            );
          }

          final prescriptions = snapshot.data ?? const [];
          final filteredPrescriptions = _selectedFilter == 'الكل'
              ? prescriptions
              : prescriptions
                    .where((item) => item.status == _selectedFilter)
                    .toList();
          return ListView.separated(
            itemCount: 1,
            separatorBuilder: (_, __) => const SizedBox.shrink(),
            itemBuilder: (context, index) {
              return Column(
                children: [
                  HbFilterBar(
                    options: _filterOptions,
                    selectedValue: _selectedFilter,
                    onChanged: (value) =>
                        setState(() => _selectedFilter = value),
                  ),
                  const SizedBox(height: 16),
                  if (filteredPrescriptions.isEmpty)
                    const HbEmptyState(
                      title: 'لا توجد وصفات ضمن هذا الفلتر',
                      message: 'جرّب اختيار حالة أخرى.',
                      icon: Icons.filter_alt_off_rounded,
                    )
                  else
                    ...filteredPrescriptions.map((prescription) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _RecordActionTile(
                          title: prescription.employeeName,
                          subtitle: _prescriptionHistorySubtitle(prescription),
                          status: statusLabel(prescription.status),
                          actionLabel: 'فتح التفاصيل',
                          onPressed: () async {
                            await context.push(
                              '${DoctorPrescriptionDetailScreen.routePath}?id=${prescription.id}',
                            );
                            if (!context.mounted) return;
                            unawaited(Future<void>.microtask(_refresh));
                          },
                        ),
                      );
                    }),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _RecordActionTile extends StatelessWidget {
  const _RecordActionTile({
    required this.title,
    required this.subtitle,
    required this.status,
    required this.actionLabel,
    required this.onPressed,
  });

  final String title;
  final String subtitle;
  final String status;
  final String actionLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                HbStatusChip(status),
              ],
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(onPressed: onPressed, child: Text(actionLabel)),
            ),
          ],
        ),
      ),
    );
  }
}

class DoctorPrescriptionDetailScreen extends StatefulWidget {
  const DoctorPrescriptionDetailScreen({super.key, this.prescriptionId});

  static const routeName = 'doctor-prescription-detail';
  static const routePath = '/doctor/prescriptions/detail';

  final int? prescriptionId;

  @override
  State<DoctorPrescriptionDetailScreen> createState() =>
      _DoctorPrescriptionDetailScreenState();
}

class _DoctorPrescriptionDetailScreenState
    extends State<DoctorPrescriptionDetailScreen> {
  bool _isSubmitting = false;

  Future<void> _submitPrescription(PrescriptionModel prescription) async {
    setState(() => _isSubmitting = true);
    final service = context.read<AppRepository>();
    try {
      final nextStatus = 'Sent';
      await service.updatePrescriptionStatus(
        id: prescription.id,
        status: nextStatus,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('تم إرسال الطلب الطبي بنجاح')));
      context.go(DoctorPrescriptionHistoryScreen.routePath);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return HbScaffold(
      title: 'تفاصيل الوصفة',
      actions: _commonActions(context),
      body: widget.prescriptionId == null
          ? const HbEmptyState(
              title: 'لا توجد وصفة محددة',
              message: 'يرجى اختيار وصفة أولًا.',
            )
          : FutureBuilder<PrescriptionModel>(
              future: context.read<AppRepository>().getPrescription(
                widget.prescriptionId!,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return HbEmptyState(
                    title: 'تعذر تحميل تفاصيل الوصفة',
                    message: snapshot.error.toString(),
                    icon: Icons.cloud_off_rounded,
                  );
                }

                final prescription = snapshot.data;
                if (prescription == null) {
                  return const HbEmptyState(
                    title: 'الوصفة غير متوفرة',
                    message: 'تعذر العثور على الوصفة المطلوبة.',
                  );
                }

                final canSubmit =
                    !_isSubmitting && prescription.status == 'Draft';
                final submitLabel = _isSubmitting
                    ? 'جاري الإرسال...'
                    : canSubmit
                    ? (prescription.requiresInsuranceApproval
                          ? 'إرسال لمراجعة التأمين'
                          : 'إرسال الطلب الطبي')
                    : 'تم إرسال الوصفة';

                return ListView(
                  children: [
                    HbSectionCard(
                      title: 'بيانات الوصفة',
                      child: Column(
                        children: [
                          HbInfoRow(
                            label: 'اسم الموظف الجامعي',
                            value: prescription.employeeName,
                          ),
                          HbInfoRow(
                            label: 'اسم المستفيد',
                            value: prescription.dependentName ?? 'لا يوجد',
                          ),
                          HbInfoRow(
                            label: 'اسم الطبيب',
                            value: prescription.doctorName,
                          ),
                          if (prescription.serviceType != 'Medication')
                            HbInfoRow(
                              label: 'نوع الطلب',
                              value: _requestTypeLabel(
                                prescription.serviceType,
                              ),
                            ),
                          HbInfoRow(
                            label: 'الخدمة',
                            value: prescription.serviceName.isEmpty
                                ? 'وصفة دوائية'
                                : prescription.serviceName,
                          ),
                          HbInfoRow(
                            label: 'الجهة المنفذة',
                            value: prescription.providerName.isEmpty
                                ? 'غير محددة'
                                : prescription.providerName,
                          ),
                          HbInfoRow(
                            label: 'التشخيص',
                            value: prescription.diagnosis.isEmpty
                                ? 'غير محدد'
                                : prescription.diagnosis,
                          ),
                          HbInfoRow(
                            label: 'الملاحظات',
                            value: prescription.notes.isEmpty
                                ? 'لا توجد ملاحظات'
                                : prescription.notes,
                          ),
                          HbInfoRow(
                            label: 'تاريخ الوصفة',
                            value: _formatDate(prescription.issuedAt),
                          ),
                          HbInfoRow(
                            label: 'حالة الوصفة',
                            value: statusLabel(prescription.status),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    HbSectionCard(
                      title: prescription.serviceType == 'Medication'
                          ? 'الأدوية'
                          : 'تفاصيل الخدمة',
                      child: prescription.serviceType == 'Medication'
                          ? Column(
                              children: prescription.items.map((item) {
                                return Card(
                                  elevation: 0,
                                  color: const Color(0xFFF9FBFC),
                                  child: Padding(
                                    padding: const EdgeInsets.all(14),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.medicationName,
                                          style: Theme.of(
                                            context,
                                          ).textTheme.titleMedium,
                                        ),
                                        const SizedBox(height: 8),
                                        Text('الكمية: ${item.quantity}'),
                                        Text('المدة: ${item.duration}'),
                                        Text(
                                          'التعليمات: ${item.dosageInstructions}',
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            )
                          : Column(
                              children: [
                                HbInfoRow(
                                  label: 'اسم الخدمة',
                                  value: prescription.serviceName.isEmpty
                                      ? _requestTypeLabel(
                                          prescription.serviceType,
                                        )
                                      : prescription.serviceName,
                                ),
                                HbInfoRow(
                                  label: 'موافقة مسبقة',
                                  value: prescription.requiresInsuranceApproval
                                      ? 'مطلوبة'
                                      : 'غير مطلوبة',
                                ),
                                if (prescription.providerNotes
                                    .trim()
                                    .isNotEmpty)
                                  HbInfoRow(
                                    label: 'ملاحظات الجهة',
                                    value: prescription.providerNotes,
                                  ),
                              ],
                            ),
                    ),
                    const SizedBox(height: 16),
                    HbSectionCard(
                      title: 'البيانات المالية والتغطية',
                      child: Column(
                        children: [
                          HbInfoRow(
                            label: 'السعر الإجمالي',
                            value: _formatCurrency(prescription.finalPrice),
                          ),
                          HbInfoRow(
                            label: 'نسبة التغطية',
                            value:
                                '${prescription.coveragePercentage.toStringAsFixed(0)}%',
                          ),
                          HbInfoRow(
                            label: 'حصة التأمين',
                            value: _formatCurrency(prescription.coveredAmount),
                          ),
                          HbInfoRow(
                            label: 'حصة الموظف',
                            value: _formatCurrency(prescription.employeeShare),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    HbCustomButton(
                      label: submitLabel,
                      icon: Icons.send_rounded,
                      onPressed: canSubmit
                          ? () => _submitPrescription(prescription)
                          : null,
                    ),
                    const SizedBox(height: 12),
                    HbCustomButton(
                      label: 'إنشاء طلب جديد لنفس الموظف',
                      icon: Icons.note_add_rounded,
                      onPressed: () => context.push(
                        '${DoctorPrescriptionCreateScreen.routePath}?patientId=${prescription.patientId}',
                      ),
                      variant: HbButtonVariant.outline,
                    ),
                  ],
                );
              },
            ),
    );
  }
}

String _formatDate(DateTime? value, {String fallback = 'غير محدد'}) {
  if (value == null) return fallback;
  return DateFormat('yyyy/MM/dd').format(value.toLocal());
}

String _formatCurrency(num value) {
  return '${NumberFormat('#,##0.00').format(value)} شيكل';
}

int _firstNumberInText(String rawValue, {int fallback = 1}) {
  final normalized = rawValue.trim();
  if (normalized.isEmpty) return fallback;

  final match = RegExp(r'\d+').firstMatch(normalized);
  final parsed = int.tryParse(match?.group(0) ?? '');
  if (parsed == null || parsed <= 0) {
    return fallback;
  }
  return parsed;
}

String _requestTypeLabel(String value) {
  switch (value) {
    case 'Medication':
      return 'دواء';
    default:
      return value;
  }
}

String _dependentRelationLabel(DependentModel dependent) {
  final relation = dependent.relation.trim().toLowerCase();
  switch (relation) {
    case 'son':
      return 'ابن';
    case 'daughter':
      return 'ابنة';
    case 'wife':
      return 'زوجة';
    default:
      return dependent.relationship.trim().isEmpty
          ? 'مستفيد'
          : dependent.relationship;
  }
}

String _prescriptionHistorySubtitle(PrescriptionModel prescription) {
  if (prescription.serviceType == 'Medication') {
    return '${_formatDate(prescription.issuedAt)} • ${prescription.items.length} أصناف دوائية';
  }

  final serviceLabel = prescription.serviceName.isEmpty
      ? _requestTypeLabel(prescription.serviceType)
      : prescription.serviceName;
  return '${_formatDate(prescription.issuedAt)} • ${_requestTypeLabel(prescription.serviceType)} • $serviceLabel';
}

List<Widget> _commonActions(BuildContext context) {
  return [
    const HbNotificationAction(),
    IconButton(
      onPressed: () => context.push(ProfileScreen.routePath),
      icon: const Icon(Icons.person_outline_rounded),
      tooltip: 'الملف الشخصي',
    ),
  ];
}
