import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../data/models/app_models.dart';
import '../../../../data/repositories/app_repository.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../features/common/presentation/views/notifications_screen.dart';
import '../../../../features/common/presentation/views/profile_screen.dart';
import '../../../../shared/widgets/hb_custom_button.dart';
import '../../../../shared/widgets/hb_custom_card.dart';
import '../../../../shared/widgets/hb_dashboard_overview.dart';
import '../../../../shared/widgets/hb_empty_state.dart';
import '../../../../shared/widgets/hb_info_row.dart';
import '../../../../shared/widgets/hb_notification_action.dart';
import '../../../../shared/widgets/hb_primary_button_row.dart';
import '../../../../shared/widgets/hb_quick_action_card.dart';
import '../../../../shared/widgets/hb_scaffold.dart';
import '../../../../shared/widgets/hb_section_card.dart';
import '../../../../shared/widgets/hb_status_chip.dart';

class PharmacistHomeScreen extends StatelessWidget {
  const PharmacistHomeScreen({super.key});

  static const routeName = 'pharmacist-home';
  static const routePath = '/pharmacist';

  @override
  Widget build(BuildContext context) {
    return HbScaffold(
      title: 'الصفحة الرئيسية للصيدلي',
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
                recentTitle: 'آخر عمليات الصرف',
                emptyMessage: 'ستظهر هنا أحدث العمليات التي قمت بصرفها أو مراجعتها.',
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
                      title: 'البحث عن وصفة',
                      subtitle: 'البحث برقم الوصفة أو الرمز',
                      icon: Icons.search_rounded,
                      onTap: () => context.push(PharmacistSearchPrescriptionScreen.routePath),
                    ),
                  ),
                  SizedBox(
                    width: actionWidth,
                    child: HbQuickActionCard(
                      title: 'سجل الصرف',
                      subtitle: 'عرض الوصفات التي تم صرفها',
                      icon: Icons.receipt_long_rounded,
                      onTap: () => context.push(PharmacistDispenseHistoryScreen.routePath),
                    ),
                  ),
                  SizedBox(
                    width: actionWidth,
                    child: HbQuickActionCard(
                      title: 'الإشعارات',
                      subtitle: 'تنبيهات الصيدلية والوصفات',
                      icon: Icons.notifications_outlined,
                      onTap: () => context.push(NotificationsScreen.routePath),
                    ),
                  ),
                  SizedBox(
                    width: actionWidth,
                    child: HbQuickActionCard(
                      title: 'التحقق عبر الرمز',
                      subtitle: 'عرض الوصفات الجاهزة للصرف والتحقق من رقمها',
                      icon: Icons.qr_code_scanner_rounded,
                      onTap: () => context.push(PharmacistQrLookupScreen.routePath),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              HbCustomButton(
                label: 'مسح رمز QR',
                icon: Icons.qr_code_scanner_rounded,
                onPressed: () => context.push(PharmacistQrLookupScreen.routePath),
              ),
            ],
          );
        },
      ),
    );
  }
}

class PharmacistSearchPrescriptionScreen extends StatefulWidget {
  const PharmacistSearchPrescriptionScreen({super.key});

  static const routeName = 'pharmacist-search-prescription';
  static const routePath = '/pharmacist/search';

  @override
  State<PharmacistSearchPrescriptionScreen> createState() => _PharmacistSearchPrescriptionScreenState();
}

class _PharmacistSearchPrescriptionScreenState extends State<PharmacistSearchPrescriptionScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  late Future<List<PrescriptionModel>> _prescriptionsFuture;

  @override
  void initState() {
    super.initState();
    _prescriptionsFuture = _loadPrescriptions();
  }

  Future<List<PrescriptionModel>> _loadPrescriptions() {
    return context.read<AppRepository>().searchPrescriptions(_query);
  }

  void _refresh() {
    setState(() {
      _prescriptionsFuture = _loadPrescriptions();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<PrescriptionModel> _visiblePrescriptions(List<PrescriptionModel> prescriptions) {
    final normalizedQuery = _query.trim();
    final showDispensedMatches = normalizedQuery.isNotEmpty;
    return prescriptions.where((item) {
      if (item.serviceType != 'Medication') {
        return false;
      }
      if (item.status == 'Approved') {
        return true;
      }
      return showDispensedMatches && item.status == 'Dispensed';
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return HbScaffold(
      title: 'البحث عن وصفة',
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

          final prescriptions = _visiblePrescriptions(snapshot.data ?? const []);
          return ListView(
            children: [
              HbCustomCard(
                child: Column(
                  children: [
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        labelText: 'رقم الوصفة أو رمزها',
                        hintText: 'مثال: RX-2026-014',
                      ),
                    ),
                    SizedBox(height: 14),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              HbCustomButton(
                label: 'بحث',
                onPressed: () {
                  setState(() => _query = _searchController.text.trim());
                  unawaited(Future<void>.microtask(_refresh));
                },
                icon: Icons.search_rounded,
              ),
              const SizedBox(height: 12),
              const Text('ملاحظة: يمكنك أيضًا استخدام رمز QR للوصول السريع إلى الوصفة.'),
              const SizedBox(height: 12),
              HbCustomButton(
                label: 'عرض وصفة عبر QR',
                onPressed: () => context.push(PharmacistQrLookupScreen.routePath),
                icon: Icons.qr_code_scanner_rounded,
                variant: HbButtonVariant.outline,
              ),
              const SizedBox(height: 16),
              if (prescriptions.isEmpty)
                HbEmptyState(
                  title: 'لا توجد نتائج',
                  message: _query.trim().isEmpty
                      ? 'تظهر هنا فقط الوصفات المعتمدة التي لم يتم صرفها بعد.'
                      : 'لم يتم العثور على وصفة مطابقة لرقم البحث.',
                  icon: Icons.search_off_rounded,
                )
              else
              ...prescriptions.take(5).map((prescription) {
                return Card(
                  child: ListTile(
                    title: Text(prescription.prescriptionNumber),
                    subtitle: Text('${prescription.employeeName} • ${_statusLabel(prescription.status)}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        HbStatusChip(_statusLabel(prescription.status)),
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: () async {
                            await context.push(
                              '${PharmacistPrescriptionDetailScreen.routePath}?id=${prescription.id}',
                            );
                            if (!context.mounted) return;
                            unawaited(Future<void>.microtask(_refresh));
                          },
                          child: const Text('فتح'),
                        ),
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

class PharmacistQrLookupScreen extends StatefulWidget {
  const PharmacistQrLookupScreen({super.key});

  static const routeName = 'pharmacist-qr-lookup';
  static const routePath = '/pharmacist/qr';

  @override
  State<PharmacistQrLookupScreen> createState() => _PharmacistQrLookupScreenState();
}

class _PharmacistQrLookupScreenState extends State<PharmacistQrLookupScreen> {
  final _codeController = TextEditingController();
  String _lookupQuery = '';
  late Future<List<PrescriptionModel>> _prescriptionsFuture;

  @override
  void initState() {
    super.initState();
    _prescriptionsFuture = _loadPrescriptions();
  }

  Future<List<PrescriptionModel>> _loadPrescriptions() {
    return _lookupQuery.isEmpty
        ? context.read<AppRepository>().getPrescriptions(status: 'Approved')
        : context.read<AppRepository>().searchPrescriptions(_lookupQuery);
  }

  void _refresh() {
    setState(() {
      _prescriptionsFuture = _loadPrescriptions();
    });
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return HbScaffold(
      title: 'عرض الوصفة عبر QR',
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

          final prescriptions = (snapshot.data ?? const [])
              .where(
                (item) => item.serviceType == 'Medication' && item.status == 'Approved',
              )
              .toList();

          return ListView(
            children: [
              HbCustomCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'التحقق من طلب الموظف الجامعي',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'يمكنك إدخال رقم الطلب الظاهر بجانب رمز QR عند الموظف ثم فتحه مباشرة.',
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _codeController,
                      decoration: const InputDecoration(
                        labelText: 'رقم الوصفة',
                        hintText: 'مثال: RX-DEMO-001',
                      ),
                    ),
                    const SizedBox(height: 12),
                    HbPrimaryButtonRow(
                      primaryLabel: 'التحقق',
                      onPrimaryPressed: () {
                        setState(() => _lookupQuery = _codeController.text.trim());
                        unawaited(Future<void>.microtask(_refresh));
                      },
                      secondaryLabel: 'فتح البحث المتقدم',
                      onSecondaryPressed: () =>
                          context.push(PharmacistSearchPrescriptionScreen.routePath),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (prescriptions.isEmpty)
                const HbEmptyState(
                  title: 'لا توجد وصفات جاهزة',
                  message: 'جرّب إدخال رقم الوصفة أو افتح البحث المتقدم.',
                  icon: Icons.search_off_rounded,
                )
              else
                ...prescriptions.map((prescription) {
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
                                  prescription.prescriptionNumber,
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                              ),
                              HbStatusChip(_statusLabel(prescription.status)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text('${prescription.employeeName} • ${prescription.doctorName}'),
                          const SizedBox(height: 10),
                          HbCustomButton(
                            label: 'فتح الوصفة',
                            icon: Icons.open_in_new_rounded,
                            onPressed: () async {
                              await context.push(
                                '${PharmacistPrescriptionDetailScreen.routePath}?id=${prescription.id}',
                              );
                              if (!context.mounted) return;
                              unawaited(Future<void>.microtask(_refresh));
                            },
                          ),
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

class PharmacistPrescriptionDetailScreen extends StatefulWidget {
  const PharmacistPrescriptionDetailScreen({
    super.key,
    this.prescriptionId,
  });

  static const routeName = 'pharmacist-prescription-detail';
  static const routePath = '/pharmacist/prescriptions/detail';

  final int? prescriptionId;

  @override
  State<PharmacistPrescriptionDetailScreen> createState() => _PharmacistPrescriptionDetailScreenState();
}

class _PharmacistPrescriptionDetailScreenState extends State<PharmacistPrescriptionDetailScreen> {
  Future<PrescriptionModel>? _prescriptionFuture;

  @override
  void initState() {
    super.initState();
    if (widget.prescriptionId != null) {
      _prescriptionFuture = _loadPrescription();
    }
  }

  Future<PrescriptionModel> _loadPrescription() {
    return context.read<AppRepository>().getPrescription(widget.prescriptionId!);
  }

  @override
  Widget build(BuildContext context) {
    return HbScaffold(
      title: 'تفاصيل الوصفة للصيدلي',
      actions: _commonActions(context),
      body: widget.prescriptionId == null
          ? const HbEmptyState(
              title: 'لا توجد وصفة محددة',
              message: 'يرجى اختيار وصفة أولًا.',
            )
          : FutureBuilder<PrescriptionModel>(
              future: _prescriptionFuture!,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
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
                final canDispense = prescription.status == 'Approved';

                return ListView(
                  children: [
                    HbSectionCard(
                      title: 'ملخص الطلب',
                      child: Column(
                        children: [
                          HbInfoRow(label: 'رقم الوصفة', value: prescription.prescriptionNumber),
                          HbInfoRow(label: 'اسم الموظف الجامعي', value: prescription.employeeName),
                          HbInfoRow(
                            label: 'اسم المستفيد',
                            value: prescription.beneficiaryName ?? prescription.employeeName,
                          ),
                          HbInfoRow(label: 'اسم الطبيب', value: prescription.doctorName),
                          HbInfoRow(label: 'نوع الطلب', value: prescription.serviceType),
                          HbInfoRow(
                            label: 'الجهة المختارة',
                            value: prescription.providerName.isEmpty ? 'غير محدد' : prescription.providerName,
                          ),
                          HbInfoRow(
                            label: 'حالة التأمين',
                            value: prescription.requiresInsuranceApproval
                                ? 'يتطلب موافقة تأمينية'
                                : 'لا يتطلب موافقة مسبقة',
                          ),
                          HbInfoRow(label: 'حالة الوصفة', value: _statusLabel(prescription.status)),
                          HbInfoRow(label: 'نسبة التغطية', value: '${prescription.coveragePercentage.toStringAsFixed(0)}%'),
                          HbInfoRow(label: 'إجمالي السعر', value: prescription.finalPrice.toStringAsFixed(2)),
                          HbInfoRow(label: 'المبلغ المغطى', value: prescription.coveredAmount.toStringAsFixed(2)),
                          HbInfoRow(label: 'حصة الموظف', value: prescription.employeeShare.toStringAsFixed(2)),
                          HbInfoRow(label: 'ملاحظات الطبيب', value: prescription.notes.isEmpty ? 'لا توجد ملاحظات' : prescription.notes),
                          HbInfoRow(
                            label: 'ملاحظات الجهة الطبية',
                            value: prescription.providerNotes.isEmpty ? 'لا توجد ملاحظات' : prescription.providerNotes,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    HbSectionCard(
                      title: prescription.serviceType == 'Medication' ? 'الأدوية' : 'تفاصيل الخدمة',
                      child: prescription.items.isEmpty
                          ? Column(
                              children: [
                                HbInfoRow(
                                  label: 'التفاصيل',
                                  value: prescription.serviceName.isEmpty ? 'لا توجد عناصر تفصيلية' : prescription.serviceName,
                                ),
                              ],
                            )
                          : Column(
                              children: prescription.items.map((item) {
                                return ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(item.medicationName),
                                  subtitle: Text('${item.quantity} • ${item.duration}\n${item.dosageInstructions}'),
                                  isThreeLine: true,
                                );
                              }).toList(),
                            ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: !canDispense
                          ? null
                          : () async {
                              await context.push(
                                '${PharmacistDispenseConfirmScreen.routePath}?id=${prescription.id}',
                              );
                              if (!context.mounted) return;
                              setState(() {
                                _prescriptionFuture = _loadPrescription();
                              });
                            },
                      child: Text(canDispense ? 'تأكيد صرف الدواء' : 'الصرف متاح فقط للوصفات المعتمدة'),
                    ),
                    const SizedBox(height: 12),
                    HbCustomButton(
                      label: 'العودة إلى البحث',
                      onPressed: () => context.pop(),
                      variant: HbButtonVariant.outline,
                    ),
                  ],
                );
              },
            ),
    );
  }
}

class PharmacistDispenseConfirmScreen extends StatefulWidget {
  const PharmacistDispenseConfirmScreen({
    super.key,
    this.prescriptionId,
  });

  static const routeName = 'pharmacist-dispense-confirm';
  static const routePath = '/pharmacist/dispense/confirm';

  final int? prescriptionId;

  @override
  State<PharmacistDispenseConfirmScreen> createState() => _PharmacistDispenseConfirmScreenState();
}

class _PharmacistDispenseConfirmScreenState extends State<PharmacistDispenseConfirmScreen> {
  final _notesController = TextEditingController();
  bool _isSubmitting = false;
  Future<PrescriptionModel>? _prescriptionFuture;

  @override
  void initState() {
    super.initState();
    if (widget.prescriptionId != null) {
      _prescriptionFuture = _loadPrescription();
    }
  }

  Future<PrescriptionModel> _loadPrescription() {
    return context.read<AppRepository>().getPrescription(widget.prescriptionId!);
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit(BuildContext context, PrescriptionModel prescription) async {
    if (prescription.status != 'Approved') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يمكن صرف الوصفات المعتمدة فقط.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final messenger = ScaffoldMessenger.of(context);
      await context.read<AppRepository>().createDispense(
            prescriptionId: prescription.id,
            dispenseNumber: 'DSP-${prescription.id}-${DateTime.now().millisecondsSinceEpoch}',
            status: 'Completed',
            notes: _notesController.text.trim(),
          );
      if (!context.mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('تم تأكيد صرف الدواء بنجاح')),
      );
      context.pop(true);
    } on AppException catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.prescriptionId == null) {
      return const HbScaffold(
        title: 'تأكيد صرف الدواء',
        body: HbEmptyState(
          title: 'لا توجد وصفة محددة',
          message: 'يرجى اختيار وصفة أولًا.',
        ),
      );
    }

    return HbScaffold(
      title: 'تأكيد صرف الدواء',
      body: FutureBuilder<PrescriptionModel>(
        future: _prescriptionFuture!,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return HbEmptyState(
              title: 'تعذر تحميل ملخص الوصفة',
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
          if (prescription.status != 'Approved') {
            return HbEmptyState(
              title: 'الصرف غير متاح',
              message: 'يمكن صرف الوصفات المعتمدة فقط. الحالة الحالية: ${_statusLabel(prescription.status)}',
              icon: Icons.lock_outline_rounded,
            );
          }

          return ListView(
            children: [
              HbSectionCard(
                title: 'ملخص الوصفة',
                child: Column(
                  children: [
                    HbInfoRow(label: 'اسم الموظف الجامعي', value: prescription.employeeName),
                    HbInfoRow(label: 'رقم الوصفة', value: prescription.prescriptionNumber),
                    HbInfoRow(label: 'حالة الصرف', value: 'مكتمل'),
                    ...prescription.items.map(
                      (item) => HbInfoRow(label: item.medicationName, value: item.quantity),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: TextField(
                    controller: _notesController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'ملاحظات',
                      hintText: 'أضف أي ملاحظات متعلقة بعملية الصرف',
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              HbPrimaryButtonRow(
                primaryLabel: _isSubmitting ? 'جاري التأكيد...' : 'تأكيد الصرف',
                onPrimaryPressed: _isSubmitting ? null : () => _submit(context, prescription),
                secondaryLabel: 'إلغاء',
                onSecondaryPressed: () => context.pop(),
              ),
            ],
          );
        },
      ),
    );
  }
}

class PharmacistDispenseHistoryScreen extends StatefulWidget {
  const PharmacistDispenseHistoryScreen({super.key});

  static const routeName = 'pharmacist-dispense-history';
  static const routePath = '/pharmacist/dispense/history';

  @override
  State<PharmacistDispenseHistoryScreen> createState() => _PharmacistDispenseHistoryScreenState();
}

class _PharmacistDispenseHistoryScreenState extends State<PharmacistDispenseHistoryScreen> {
  late Future<List<DispenseModel>> _dispensesFuture;

  @override
  void initState() {
    super.initState();
    _dispensesFuture = _loadDispenses();
  }

  Future<List<DispenseModel>> _loadDispenses() {
    return context.read<AppRepository>().getDispenses();
  }

  void _refresh() {
    setState(() {
      _dispensesFuture = _loadDispenses();
    });
  }

  @override
  Widget build(BuildContext context) {
    return HbScaffold(
      title: 'سجل الصرف',
      actions: _commonActions(context),
      body: FutureBuilder<List<DispenseModel>>(
        future: _dispensesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return HbEmptyState(
              title: 'تعذر تحميل سجل الصرف',
              message: snapshot.error.toString(),
              icon: Icons.cloud_off_rounded,
            );
          }

          final items = snapshot.data ?? const [];
          return ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = items[index];
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(item.employeeName, style: Theme.of(context).textTheme.titleMedium),
                          ),
                          HbStatusChip(_statusLabel(item.status)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      HbInfoRow(label: 'تاريخ الصرف', value: _formatDate(item.dispensedAt)),
                      HbInfoRow(label: 'اسم الصيدلي', value: item.pharmacistName),
                      HbInfoRow(label: 'الملاحظات', value: item.notes.isEmpty ? 'لا توجد ملاحظات' : item.notes),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _refresh,
        child: const Icon(Icons.refresh_rounded),
      ),
    );
  }
}

String _formatDate(DateTime? value, {String fallback = 'غير محدد'}) {
  if (value == null) return fallback;
  return DateFormat('yyyy/MM/dd').format(value.toLocal());
}

String _statusLabel(String status) {
  switch (status) {
    case 'Approved':
      return 'معتمدة';
    case 'Completed':
      return 'مكتمل';
    case 'Partial':
      return 'جزئي';
    case 'Dispensed':
      return 'تم الصرف';
    case 'Cancelled':
      return 'ملغاة';
    default:
      return status;
  }
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
