import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../data/models/app_models.dart';
import '../../../../data/services/app_data_service.dart';
import '../../../../features/common/presentation/screens/notifications_screen.dart';
import '../../../../features/common/presentation/screens/profile_screen.dart';
import '../../../../shared/utils/status_label.dart';
import '../../../../shared/widgets/hb_custom_button.dart';
import '../../../../shared/widgets/hb_custom_card.dart';
import '../../../../shared/widgets/hb_dashboard_overview.dart';
import '../../../../shared/widgets/hb_empty_state.dart';
import '../../../../shared/widgets/hb_filter_bar.dart';
import '../../../../shared/widgets/hb_info_row.dart';
import '../../../../shared/widgets/hb_quick_action_card.dart';
import '../../../../shared/widgets/hb_notification_action.dart';
import '../../../../shared/widgets/hb_scaffold.dart';
import '../../../../shared/widgets/hb_section_card.dart';
import '../../../../shared/widgets/hb_status_chip.dart';

class PatientHomeScreen extends StatelessWidget {
  const PatientHomeScreen({super.key});

  static const routeName = 'patient-home';
  static const routePath = '/patient';

  @override
  Widget build(BuildContext context) {
    return HbScaffold(
      title: 'الصفحة الرئيسية للموظف الجامعي',
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
                emptyMessage: 'ستظهر هنا الوصفات والتنبيهات الحديثة المرتبطة بحسابك.',
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
                      title: 'الوصفات الطبية',
                      subtitle: 'مراجعة جميع الطلبات الطبية الحالية والسابقة',
                      icon: Icons.medical_information_outlined,
                      onTap: () => context.push(PatientPrescriptionsScreen.routePath),
                    ),
                  ),
                  SizedBox(
                    width: actionWidth,
                    child: HbQuickActionCard(
                      title: 'السجل الدوائي',
                      subtitle: 'متابعة الأدوية والطلبات السابقة',
                      icon: Icons.menu_book_rounded,
                      onTap: () => context.push(PatientMedicationHistoryScreen.routePath),
                    ),
                  ),
                  SizedBox(
                    width: actionWidth,
                    child: HbQuickActionCard(
                      title: 'المستفيدون',
                      subtitle: 'عرض المستفيدين المرتبطين بالحساب',
                      icon: Icons.family_restroom_rounded,
                      onTap: () => context.push(PatientDependentsScreen.routePath),
                    ),
                  ),
                  SizedBox(
                    width: actionWidth,
                    child: HbQuickActionCard(
                      title: 'البحث عن الأطباء',
                      subtitle: 'استعراض الأطباء المتعاقدين والبحث حسب التخصص والمنطقة',
                      icon: Icons.medical_services_outlined,
                      onTap: () => context.push(EmployeeDoctorSearchScreen.routePath),
                    ),
                  ),
                  SizedBox(
                    width: actionWidth,
                    child: HbQuickActionCard(
                      title: 'الإشعارات',
                      subtitle: 'التنبيهات المرتبطة بالوصفات والتغطية',
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

class PatientPrescriptionsScreen extends StatefulWidget {
  const PatientPrescriptionsScreen({super.key});

  static const routeName = 'patient-prescriptions';
  static const routePath = '/patient/prescriptions';

  @override
  State<PatientPrescriptionsScreen> createState() => _PatientPrescriptionsScreenState();
}

class _PatientPrescriptionsScreenState extends State<PatientPrescriptionsScreen> {
  static const _filterOptions = [
    HbFilterOption(value: 'الكل', label: 'الكل'),
    HbFilterOption(value: 'Approved', label: 'معتمد'),
    HbFilterOption(value: 'PendingInsuranceApproval', label: 'قيد المراجعة'),
    HbFilterOption(value: 'Dispensed', label: 'تم الصرف'),
    HbFilterOption(value: 'Performed', label: 'تم التنفيذ'),
  ];
  String _selectedFilter = 'الكل';
  late Future<List<PrescriptionModel>> _prescriptionsFuture;

  @override
  void initState() {
    super.initState();
    _prescriptionsFuture = _loadPrescriptions();
  }

  Future<List<PrescriptionModel>> _loadPrescriptions() {
    return context.read<AppDataService>().getPrescriptions();
  }

  void _refresh() {
    setState(() {
      _prescriptionsFuture = _loadPrescriptions();
    });
  }

  @override
  Widget build(BuildContext context) {
    return HbScaffold(
      title: 'طلباتي الطبية',
      actions: _commonActions(context),
      body: FutureBuilder<List<PrescriptionModel>>(
        future: _prescriptionsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
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
              : prescriptions.where((item) => item.status == _selectedFilter).toList();
          if (prescriptions.isEmpty) {
            return const HbEmptyState(
              title: 'لا توجد طلبات طبية',
              message: 'ستظهر هنا وصفاتك وطلباتك الطبية الحالية والسابقة.',
              icon: Icons.medical_information_outlined,
            );
          }

          return ListView(
            children: [
              HbFilterBar(
                options: _filterOptions,
                selectedValue: _selectedFilter,
                onChanged: (value) {
                  setState(() => _selectedFilter = value);
                },
              ),
              const SizedBox(height: 16),
              if (filteredPrescriptions.isEmpty)
                const HbEmptyState(
                  title: 'لا توجد نتائج ضمن هذا الفلتر',
                  message: 'جرّب تغيير حالة الوصفة لعرض نتائج أخرى.',
                  icon: Icons.filter_alt_off_rounded,
                )
              else
              ...filteredPrescriptions.map((prescription) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _PatientRecordActionTile(
                    title: prescription.doctorName,
                    subtitle:
                        '${_formatDate(prescription.issuedAt)} • ${prescription.serviceType} • ${prescription.providerName.isEmpty ? "لم يتم اختيار جهة بعد" : prescription.providerName}',
                    status: statusLabel(prescription.status),
                    actionLabel: 'عرض التفاصيل',
                    onPressed: () async {
                      await context.push(
                        '${PatientPrescriptionDetailScreen.routePath}?id=${prescription.id}',
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
      ),
    );
  }
}

class PatientPrescriptionDetailScreen extends StatelessWidget {
  const PatientPrescriptionDetailScreen({
    super.key,
    this.prescriptionId,
  });

  static const routeName = 'patient-prescription-detail';
  static const routePath = '/patient/prescriptions/detail';

  final int? prescriptionId;

  void _returnToPrescriptions(BuildContext context) {
    if (Navigator.of(context).canPop()) {
      context.pop();
      return;
    }
    context.go(PatientPrescriptionsScreen.routePath);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _returnToPrescriptions(context);
      },
      child: HbScaffold(
        title: 'تفاصيل الطلب الطبي',
        actions: _commonActions(context),
        leading: IconButton(
          onPressed: () => _returnToPrescriptions(context),
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'رجوع',
        ),
        body: prescriptionId == null
            ? const HbEmptyState(
                title: 'لا توجد وصفة محددة',
                message: 'يرجى اختيار وصفة أولًا من القائمة.',
              )
            : FutureBuilder<PrescriptionModel>(
                future: context.read<AppDataService>().getPrescription(prescriptionId!),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return HbEmptyState(
                      title: 'تعذر تحميل الوصفة',
                      message: snapshot.error.toString(),
                      icon: Icons.cloud_off_rounded,
                    );
                  }

                  final prescription = snapshot.data;
                  if (prescription == null) {
                    return const HbEmptyState(
                      title: 'الوصفة غير متوفرة',
                      message: 'تعذر العثور على بيانات الوصفة المطلوبة.',
                    );
                  }

                  return ListView(
                    children: [
                      HbSectionCard(
                        title: 'معلومات الطلب الطبي',
                        child: Column(
                          children: [
                            HbInfoRow(label: 'اسم الطبيب', value: prescription.doctorName),
                            HbInfoRow(label: 'اسم الموظف صاحب التأمين', value: prescription.employeeName),
                            HbInfoRow(
                              label: 'اسم المستفيد',
                              value: prescription.beneficiaryName ?? prescription.employeeName,
                            ),
                            HbInfoRow(label: 'نوع الطلب', value: prescription.serviceType),
                            HbInfoRow(
                              label: 'الجهة المختارة',
                              value: prescription.providerName.isEmpty ? 'لم يتم اختيار جهة بعد' : prescription.providerName,
                            ),
                            HbInfoRow(
                              label: 'الخدمة',
                              value: prescription.serviceName.isEmpty ? 'دواء / وصفة' : prescription.serviceName,
                            ),
                            HbInfoRow(label: 'تاريخ الطلب', value: _formatDate(prescription.issuedAt)),
                            HbInfoRow(label: 'الحالة', value: statusLabel(prescription.status)),
                            HbInfoRow(label: 'نسبة التغطية', value: '${prescription.coveragePercentage.toStringAsFixed(0)}%'),
                            HbInfoRow(label: 'السعر الأصلي', value: prescription.finalPrice.toStringAsFixed(2)),
                            HbInfoRow(label: 'المبلغ المغطى', value: prescription.coveredAmount.toStringAsFixed(2)),
                            HbInfoRow(label: 'حصة الموظف', value: prescription.employeeShare.toStringAsFixed(2)),
                            HbInfoRow(label: 'التشخيص', value: prescription.diagnosis.isEmpty ? 'غير محدد' : prescription.diagnosis),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      HbSectionCard(
                        title: prescription.serviceType == 'Medication' ? 'الأدوية والتعليمات' : 'تفاصيل التنفيذ والتعليمات',
                        child: Column(
                          children: prescription.items.isEmpty
                              ? [
                                  HbInfoRow(label: 'ملاحظات الطلب', value: prescription.notes.isEmpty ? 'لا توجد ملاحظات إضافية' : prescription.notes),
                                ]
                              : prescription.items.map((item) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: HbCustomCard(
                                padding: const EdgeInsets.all(14),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 42,
                                      height: 42,
                                      decoration: BoxDecoration(
                                        color: AppTheme.primary.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: const Icon(Icons.medication_outlined, color: AppTheme.primary),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(item.medicationName, style: Theme.of(context).textTheme.titleMedium),
                                          const SizedBox(height: 6),
                                          Text(
                                            '${item.quantity} • ${item.duration}',
                                            style: Theme.of(context).textTheme.bodySmall,
                                          ),
                                          const SizedBox(height: 6),
                                          Text(item.dosageInstructions),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      HbCustomButton(
                        label: 'عرض رمز QR',
                        onPressed: () => context.push(
                          '${PatientQrScreen.routePath}?id=${prescription.id}',
                        ),
                        icon: Icons.qr_code_2_rounded,
                      ),
                      const SizedBox(height: 12),
                      HbCustomCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'الحالة الحالية',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            const SizedBox(height: 6),
                            HbStatusChip(statusLabel(prescription.status)),
                            const SizedBox(height: 8),
                            Text(
                              'يمكن للجهة الطبية البحث عن هذا الطلب باستخدام رقمه أو من خلال رمز QR المعروض أعلاه.',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
      ),
    );
  }
}

class PatientQrScreen extends StatelessWidget {
  const PatientQrScreen({
    super.key,
    this.prescriptionId,
  });

  static const routeName = 'patient-qr';
  static const routePath = '/patient/prescriptions/qr';

  final int? prescriptionId;

  void _returnToDetails(BuildContext context) {
    if (prescriptionId == null) {
      if (Navigator.of(context).canPop()) {
        context.pop();
      } else {
        context.go(PatientPrescriptionsScreen.routePath);
      }
      return;
    }

    if (Navigator.of(context).canPop()) {
      context.pop();
      return;
    }

    context.go('${PatientPrescriptionDetailScreen.routePath}?id=$prescriptionId');
  }

  @override
  Widget build(BuildContext context) {
    if (prescriptionId == null) {
      return const HbScaffold(
        title: 'رمز QR للطلب الطبي',
        body: HbEmptyState(
          title: 'لا توجد وصفة محددة',
          message: 'يرجى اختيار وصفة أولًا.',
        ),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _returnToDetails(context);
      },
      child: HbScaffold(
        title: 'رمز QR للطلب الطبي',
        leading: IconButton(
          onPressed: () => _returnToDetails(context),
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'رجوع',
        ),
        body: FutureBuilder<PrescriptionModel>(
          future: context.read<AppDataService>().getPrescription(prescriptionId!),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return HbEmptyState(
                title: 'تعذر تحميل رمز QR',
                message: snapshot.error.toString(),
                icon: Icons.cloud_off_rounded,
              );
            }

            final prescription = snapshot.data;
            if (prescription == null) {
              return const HbEmptyState(
                title: 'الوصفة غير متوفرة',
                message: 'تعذر تحميل بيانات الرمز لهذه الوصفة.',
                icon: Icons.qr_code_2_rounded,
              );
            }

            return ListView(
              children: [
                HbCustomCard(
                  child: Column(
                    children: [
                      Text(
                        'يرجى إبراز هذا الرمز للجهة الطبية عند تنفيذ الطلب',
                        style: Theme.of(context).textTheme.titleMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFDFEFF),
                          borderRadius: BorderRadius.circular(26),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primary.withValues(alpha: 0.08),
                              blurRadius: 22,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: QrImageView(
                          data: prescription.prescriptionNumber,
                          size: 220,
                          version: QrVersions.auto,
                          backgroundColor: Colors.white,
                          eyeStyle: const QrEyeStyle(
                            eyeShape: QrEyeShape.square,
                            color: AppTheme.primaryDark,
                          ),
                          dataModuleStyle: const QrDataModuleStyle(
                            dataModuleShape: QrDataModuleShape.square,
                            color: AppTheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(prescription.prescriptionNumber, style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 12),
                      const Text(
                        'يمكن للصيدلي إدخال رقم الوصفة نفسه من شاشة التحقق إذا لم يستخدم قارئ QR.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      HbInfoRow(label: 'اسم الموظف الجامعي', value: prescription.employeeName),
                      HbInfoRow(
                        label: 'اسم المستفيد',
                        value: prescription.beneficiaryName ?? prescription.employeeName,
                      ),
                      HbInfoRow(label: 'اسم الطبيب', value: prescription.doctorName),
                      HbInfoRow(label: 'نوع الخدمة', value: prescription.serviceType),
                      HbInfoRow(label: 'الجهة المختارة', value: prescription.providerName.isEmpty ? 'لم يتم اختيار جهة بعد' : prescription.providerName),
                      HbInfoRow(label: 'تاريخ الطلب', value: _formatDate(prescription.issuedAt)),
                      HbInfoRow(label: 'حالة الطلب', value: statusLabel(prescription.status)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                HbCustomButton(
                  label: 'الرجوع للتفاصيل',
                  onPressed: () => _returnToDetails(context),
                  variant: HbButtonVariant.outline,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class PatientMedicationHistoryScreen extends StatelessWidget {
  const PatientMedicationHistoryScreen({super.key});

  static const routeName = 'patient-medication-history';
  static const routePath = '/patient/history';

  @override
  Widget build(BuildContext context) {
    return HbScaffold(
      title: 'السجل الدوائي',
      actions: _commonActions(context),
      body: FutureBuilder<List<PrescriptionModel>>(
        future: context.read<AppDataService>().getPrescriptions(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return HbEmptyState(
              title: 'تعذر تحميل السجل الدوائي',
              message: snapshot.error.toString(),
              icon: Icons.cloud_off_rounded,
            );
          }

          final prescriptions = snapshot.data ?? const [];
          final items = prescriptions.expand((p) => p.items.map((item) => (p, item))).toList();
          if (items.isEmpty) {
            return const HbEmptyState(
              title: 'لا يوجد سجل طبي سابق',
              message: 'ستظهر هنا الأدوية والطلبات التي تم إنشاؤها لك سابقًا.',
            );
          }

          return ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final prescription = items[index].$1;
              final item = items[index].$2;
              return _PatientRecordActionTile(
                title: item.medicationName,
                subtitle: '${_formatDate(prescription.issuedAt)} • ${prescription.doctorName}',
                status: statusLabel(prescription.status),
                actionLabel: 'عرض التفاصيل',
                onPressed: () => context.push(
                  '${PatientPrescriptionDetailScreen.routePath}?id=${prescription.id}',
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _PatientRecordActionTile extends StatelessWidget {
  const _PatientRecordActionTile({
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
                      Text(title, style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 6),
                      Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
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
              child: TextButton(
                onPressed: onPressed,
                child: Text(actionLabel),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PatientDependentsScreen extends StatelessWidget {
  const PatientDependentsScreen({super.key});

  static const routeName = 'patient-dependents';
  static const routePath = '/patient/dependents';

  @override
  Widget build(BuildContext context) {
    return HbScaffold(
      title: 'المستفيدون',
      actions: _commonActions(context),
      body: FutureBuilder<List<DependentModel>>(
        future: context.read<AppDataService>().getDependents(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return HbEmptyState(
              title: 'تعذر تحميل المستفيدين',
              message: snapshot.error.toString(),
              icon: Icons.cloud_off_rounded,
            );
          }

          final dependents = snapshot.data ?? const [];
          if (dependents.isEmpty) {
            return const Center(child: Text('لا يوجد مستفيدون مسجلون حاليًا'));
          }

          return ListView.separated(
            itemCount: dependents.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final dependent = dependents[index];
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              dependent.fullName,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          const HbStatusChip('فعّال'),
                        ],
                      ),
                      const SizedBox(height: 10),
                      HbInfoRow(label: 'صلة القرابة', value: dependent.relationship),
                      HbInfoRow(label: 'ملاحظات', value: dependent.notes.isEmpty ? 'لا توجد ملاحظات' : dependent.notes),
                      HbInfoRow(label: 'تاريخ الميلاد', value: _formatDate(dependent.dateOfBirth, fallback: 'غير محدد')),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class EmployeeDoctorSearchScreen extends StatefulWidget {
  const EmployeeDoctorSearchScreen({super.key});

  static const routeName = 'employee-doctor-search';
  static const routePath = '/patient/doctors';

  @override
  State<EmployeeDoctorSearchScreen> createState() => _EmployeeDoctorSearchScreenState();
}

class _EmployeeDoctorSearchScreenState extends State<EmployeeDoctorSearchScreen> {
  final _nameController = TextEditingController();
  final _specialtyController = TextEditingController();
  final _cityController = TextEditingController();
  late Future<List<DoctorDirectoryModel>> _doctorsFuture;

  @override
  void initState() {
    super.initState();
    _doctorsFuture = _searchDoctors();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _specialtyController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<List<DoctorDirectoryModel>> _searchDoctors() {
    return context.read<AppDataService>().searchDoctors(
          name: _nameController.text,
          specialty: _specialtyController.text,
          city: _cityController.text,
          activeOnly: true,
        );
  }

  void _refresh() {
    setState(() {
      _doctorsFuture = _searchDoctors();
    });
  }

  @override
  Widget build(BuildContext context) {
    return HbScaffold(
      title: 'البحث عن الأطباء',
      actions: _commonActions(context),
      body: FutureBuilder<List<DoctorDirectoryModel>>(
        future: _doctorsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return HbEmptyState(
              title: 'تعذر تحميل قائمة الأطباء',
              message: snapshot.error.toString(),
              icon: Icons.cloud_off_rounded,
            );
          }

          final doctors = snapshot.data ?? const [];
          return ListView(
            children: [
              HbSectionCard(
                title: 'عوامل البحث',
                subtitle: 'سيتم البحث ضمن الأطباء المتعاقدين مع النظام فقط.',
                child: Column(
                  children: [
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'اسم الطبيب',
                        prefixIcon: Icon(Icons.search_rounded),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _specialtyController,
                      decoration: const InputDecoration(
                        labelText: 'التخصص',
                        prefixIcon: Icon(Icons.medical_services_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _cityController,
                      decoration: const InputDecoration(
                        labelText: 'المدينة / المنطقة',
                        prefixIcon: Icon(Icons.location_on_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    HbCustomButton(
                      label: 'بحث',
                      icon: Icons.search_rounded,
                      onPressed: _refresh,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (doctors.isEmpty)
                const HbEmptyState(
                  title: 'لا يوجد أطباء مطابقون',
                  message: 'جرّب تعديل اسم الطبيب أو التخصص أو المدينة.',
                  icon: Icons.person_search_rounded,
                )
              else
                ...doctors.map((doctor) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: HbCustomCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  doctor.fullName,
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                              ),
                              HbStatusChip(
                                doctor.contractStatus.toLowerCase() == 'active'
                                    ? 'متعاقد'
                                    : 'غير متعاقد',
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          HbInfoRow(label: 'التخصص', value: doctor.specialty.isEmpty ? 'غير محدد' : doctor.specialty),
                          HbInfoRow(
                            label: 'العيادة / الجهة',
                            value: doctor.providerName.isEmpty
                                ? (doctor.clinicName.isEmpty ? 'غير محدد' : doctor.clinicName)
                                : doctor.providerName,
                          ),
                          HbInfoRow(label: 'المدينة', value: doctor.city.isEmpty ? 'غير محدد' : doctor.city),
                          HbInfoRow(label: 'العنوان', value: doctor.address.isEmpty ? 'غير متوفر' : doctor.address),
                          HbInfoRow(label: 'الهاتف', value: doctor.phoneNumber.isEmpty ? 'غير متوفر' : doctor.phoneNumber),
                          HbInfoRow(label: 'سعر الاستشارة', value: doctor.consultationPrice.toStringAsFixed(2)),
                          const HbInfoRow(label: 'نسبة التغطية', value: 'تُعرض بعد اختيار الجهة والخدمة'),
                          const HbInfoRow(label: 'حصة الموظف', value: 'تُحسب بعد تأكيد مقدم الخدمة'),
                        ],
                      ),
                    ),
                  );
                }),
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
