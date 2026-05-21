import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../data/models/app_models.dart';
import '../../../../data/services/app_data_service.dart';
import '../../../../features/common/presentation/screens/notifications_screen.dart';
import '../../../../features/common/presentation/screens/profile_screen.dart';
import '../../../../shared/utils/status_label.dart';
import '../../../../shared/widgets/hb_custom_card.dart';
import '../../../../shared/widgets/hb_dashboard_overview.dart';
import '../../../../shared/widgets/hb_empty_state.dart';
import '../../../../shared/widgets/hb_filter_bar.dart';
import '../../../../shared/widgets/hb_info_row.dart';
import '../../../../shared/widgets/hb_notification_action.dart';
import '../../../../shared/widgets/hb_primary_button_row.dart';
import '../../../../shared/widgets/hb_quick_action_card.dart';
import '../../../../shared/widgets/hb_scaffold.dart';
import '../../../../shared/widgets/hb_section_card.dart';
import '../../../../shared/widgets/hb_status_chip.dart';

class InsuranceOfficerHomeScreen extends StatelessWidget {
  const InsuranceOfficerHomeScreen({super.key});

  static const routeName = 'insurance-home';
  static const routePath = '/insurance';

  @override
  Widget build(BuildContext context) {
    return HbScaffold(
      title: 'الصفحة الرئيسية لموظف التأمين',
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
                recentTitle: 'آخر طلبات التغطية',
                emptyMessage: 'ستظهر هنا أحدث طلبات التغطية وحالة مراجعتها.',
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
                      title: 'طلبات التغطية',
                      subtitle: 'جميع طلبات التغطية الواردة للمراجعة والمتابعة',
                      icon: Icons.fact_check_outlined,
                      onTap: () => context.push(InsuranceRequestsScreen.routePath),
                    ),
                  ),
                  SizedBox(
                    width: actionWidth,
                    child: HbQuickActionCard(
                      title: 'الطلبات الحديثة',
                      subtitle: 'عرض أحدث الطلبات التي وصلت من الأطباء',
                      icon: Icons.history_toggle_off_rounded,
                      onTap: () => context.push(InsuranceRequestsScreen.routePath),
                    ),
                  ),
                  SizedBox(
                    width: actionWidth,
                    child: HbQuickActionCard(
                      title: 'الطلبات المعتمدة',
                      subtitle: 'الطلبات التي تم اعتمادها تلقائيًا ويمكن مراجعتها',
                      icon: Icons.task_alt_rounded,
                      onTap: () => context.push(InsuranceRequestsScreen.routePath),
                    ),
                  ),
                  SizedBox(
                    width: actionWidth,
                    child: HbQuickActionCard(
                      title: 'كتالوج التغطية',
                      subtitle: 'إدارة الأدوية والخدمات والأسعار ونسب التغطية',
                      icon: Icons.medical_information_outlined,
                      onTap: () => context.push(InsuranceCoverageCatalogScreen.routePath),
                    ),
                  ),
                  SizedBox(
                    width: actionWidth,
                    child: HbQuickActionCard(
                      title: 'الإشعارات',
                      subtitle: 'تنبيهات تخص التغطية والوصفات',
                      icon: Icons.notifications_none_rounded,
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

class InsuranceRequestsScreen extends StatefulWidget {
  const InsuranceRequestsScreen({super.key});

  static const routeName = 'insurance-requests';
  static const routePath = '/insurance/requests';

  @override
  State<InsuranceRequestsScreen> createState() => _InsuranceRequestsScreenState();
}

class _InsuranceRequestsScreenState extends State<InsuranceRequestsScreen> {
  static const _filterOptions = [
    HbFilterOption(value: 'الكل', label: 'الكل'),
    HbFilterOption(value: 'Approved', label: 'مقبولة'),
    HbFilterOption(value: 'Pending', label: 'معلّقة قديمة'),
    HbFilterOption(value: 'Rejected', label: 'مرفوضة'),
    HbFilterOption(value: 'NeedsUpdate', label: 'تحتاج تعديل'),
  ];
  String _selectedFilter = 'الكل';
  late Future<List<InsuranceRequestModel>> _requestsFuture;

  @override
  void initState() {
    super.initState();
    _requestsFuture = _loadRequests();
  }

  Future<List<InsuranceRequestModel>> _loadRequests() {
    return context.read<AppDataService>().getInsuranceRequests();
  }

  void _refresh() {
    setState(() {
      _requestsFuture = _loadRequests();
    });
  }

  @override
  Widget build(BuildContext context) {
    return HbScaffold(
      title: 'طلبات التغطية',
      actions: _commonActions(context),
      body: FutureBuilder<List<InsuranceRequestModel>>(
        future: _requestsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return HbEmptyState(
              title: 'تعذر تحميل الطلبات',
              message: snapshot.error.toString(),
              icon: Icons.cloud_off_rounded,
            );
          }

          final requests = snapshot.data ?? const [];
          final filteredRequests = _selectedFilter == 'الكل'
              ? requests
              : requests.where((item) => item.status == _selectedFilter).toList();
          return ListView(
            children: [
              HbFilterBar(
                options: _filterOptions,
                selectedValue: _selectedFilter,
                onChanged: (value) => setState(() => _selectedFilter = value),
              ),
              const SizedBox(height: 16),
              if (filteredRequests.isEmpty)
                const HbEmptyState(
                  title: 'لا توجد طلبات ضمن هذا الفلتر',
                  message: 'جرّب اختيار حالة أخرى.',
                  icon: Icons.filter_alt_off_rounded,
                )
              else
                ...filteredRequests.map((request) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Card(
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
                                        request.employeeName,
                                        style: Theme.of(context).textTheme.titleMedium,
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        '${request.doctorName} • ${request.serviceName.isEmpty ? "خدمة غير محددة" : request.serviceName}',
                                        style: Theme.of(context).textTheme.bodyMedium,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${request.providerName.isEmpty ? "بدون جهة محددة" : request.providerName} • ${_formatDate(request.submittedAt)}',
                                        style: Theme.of(context).textTheme.bodySmall,
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'التغطية ${request.coveragePercentage.toStringAsFixed(0)}% • المغطى ${request.coveredAmount.toStringAsFixed(2)} • حصة الموظف ${request.employeeShare.toStringAsFixed(2)}',
                                        style: Theme.of(context).textTheme.bodySmall,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                HbStatusChip(statusLabel(request.status)),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: TextButton(
                                onPressed: () async {
                                  await context.push(
                                    '${InsuranceReviewScreen.routePath}?id=${request.id}',
                                  );
                                  if (!context.mounted) return;
                                  unawaited(Future<void>.microtask(_refresh));
                                },
                                child: const Text('مراجعة'),
                              ),
                            ),
                          ],
                        ),
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

class InsuranceReviewScreen extends StatefulWidget {
  const InsuranceReviewScreen({
    super.key,
    this.requestId,
  });

  static const routeName = 'insurance-review';
  static const routePath = '/insurance/requests/review';

  final int? requestId;

  @override
  State<InsuranceReviewScreen> createState() => _InsuranceReviewScreenState();
}

class _InsuranceReviewScreenState extends State<InsuranceReviewScreen> {
  late Future<List<dynamic>> _reviewFuture;

  @override
  void initState() {
    super.initState();
    _reviewFuture = _loadReviewData();
  }

  Future<List<dynamic>> _loadReviewData() {
    return Future.wait([
      context.read<AppDataService>().getInsuranceRequests(),
      context.read<AppDataService>().getPrescriptions(),
    ]);
  }

  void _refresh() {
    setState(() {
      _reviewFuture = _loadReviewData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return HbScaffold(
      title: 'مراجعة تفاصيل الطلب',
      actions: _commonActions(context),
      body: widget.requestId == null
          ? const HbEmptyState(
              title: 'لا يوجد طلب محدد',
              message: 'يرجى اختيار طلب أولًا.',
            )
          : FutureBuilder<List<dynamic>>(
              future: _reviewFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return HbEmptyState(
                    title: 'تعذر تحميل تفاصيل الطلب',
                    message: snapshot.error.toString(),
                    icon: Icons.cloud_off_rounded,
                  );
                }

                final requests = snapshot.data![0] as List<InsuranceRequestModel>;
                final prescriptions = snapshot.data![1] as List<PrescriptionModel>;
                final matchingRequests = requests.where((item) => item.id == widget.requestId).toList();
                final request = matchingRequests.isEmpty ? null : matchingRequests.first;
                if (request == null) {
                  return const HbEmptyState(
                    title: 'الطلب غير متوفر',
                    message: 'تعذر العثور على الطلب المطلوب.',
                  );
                }
                final matchingPrescriptions = prescriptions
                    .where((item) => item.id == request.prescriptionId)
                    .toList();
                final prescription =
                    matchingPrescriptions.isEmpty ? null : matchingPrescriptions.first;
                if (prescription == null) {
                  return const HbEmptyState(
                    title: 'الوصفة غير متوفرة',
                    message: 'تعذر العثور على الوصفة المرتبطة بهذا الطلب.',
                  );
                }

                return ListView(
                  children: [
                    HbSectionCard(
                      title: 'بيانات الطلب',
                      child: Column(
                        children: [
                          HbInfoRow(label: 'رقم طلب التغطية', value: request.requestNumber),
                          HbInfoRow(label: 'اسم الموظف الجامعي', value: request.employeeName),
                          HbInfoRow(
                            label: 'اسم المستفيد',
                            value: request.beneficiaryName ?? request.employeeName,
                          ),
                          HbInfoRow(label: 'الجهة المقدمة', value: request.providerName.isEmpty ? 'غير محدد' : request.providerName),
                          HbInfoRow(label: 'الخدمة', value: request.serviceName.isEmpty ? 'غير محدد' : request.serviceName),
                          HbInfoRow(label: 'اسم الطبيب', value: request.doctorName),
                          HbInfoRow(label: 'نوع الطلب', value: prescription.serviceType),
                          HbInfoRow(label: 'نسبة التغطية', value: '${prescription.coveragePercentage.toStringAsFixed(0)}%'),
                          HbInfoRow(label: 'السعر الأصلي', value: prescription.finalPrice.toStringAsFixed(2)),
                          HbInfoRow(label: 'المبلغ المغطى', value: prescription.coveredAmount.toStringAsFixed(2)),
                          HbInfoRow(label: 'حصة الموظف', value: prescription.employeeShare.toStringAsFixed(2)),
                          HbInfoRow(label: 'التشخيص', value: prescription.diagnosis.isEmpty ? 'غير محدد' : prescription.diagnosis),
                          HbInfoRow(label: 'الملاحظات', value: prescription.notes.isEmpty ? 'لا توجد ملاحظات' : prescription.notes),
                          HbInfoRow(label: 'حالة الطلب الحالية', value: statusLabel(request.status)),
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
                                  label: 'ملاحظات التنفيذ',
                                  value: prescription.providerNotes.isEmpty ? 'لا توجد ملاحظات من الجهة الطبية' : prescription.providerNotes,
                                ),
                              ],
                            )
                          : Column(
                              children: prescription.items.map((item) {
                                return ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(item.medicationName),
                                  subtitle: Text('${item.quantity} • ${item.dosageInstructions}'),
                                );
                              }).toList(),
                            ),
                    ),
                    const SizedBox(height: 16),
                    HbSectionCard(
                      title: 'حالة المراجعة',
                      subtitle: 'طلبات التأمين أصبحت تعتمد تلقائيًا، ودور موظف التأمين الآن للمراجعة والمتابعة فقط.',
                      child: Column(
                        children: [
                          HbInfoRow(label: 'الحالة الحالية', value: statusLabel(request.status)),
                          HbInfoRow(
                            label: 'ملاحظات المراجعة',
                            value: request.responseNotes.isEmpty ? 'لا توجد ملاحظات إضافية.' : request.responseNotes,
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }
}

class InsuranceDecisionScreen extends StatefulWidget {
  const InsuranceDecisionScreen({
    super.key,
    this.decision = 'موافقة',
    this.requestId,
  });

  static const routeName = 'insurance-decision';
  static const routePath = '/insurance/requests/decision';

  final String decision;
  final int? requestId;

  @override
  State<InsuranceDecisionScreen> createState() => _InsuranceDecisionScreenState();
}

class _InsuranceDecisionScreenState extends State<InsuranceDecisionScreen> {
  late final TextEditingController _decisionController;
  final TextEditingController _notesController = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _decisionController = TextEditingController(text: widget.decision);
  }

  @override
  void dispose() {
    _decisionController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveDecision() async {
    if (widget.requestId == null) return;

    setState(() => _isSaving = true);
    try {
      final status = switch (widget.decision) {
        'approve' => 'Approved',
        'reject' => 'Rejected',
        'update' => 'NeedsUpdate',
        _ => 'Approved',
      };

      await context.read<AppDataService>().updateInsuranceRequest(
            id: widget.requestId!,
            status: status,
            notes: _notesController.text.trim(),
          );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حفظ ملاحظات المراجعة بنجاح')),
      );
      context.pop();
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return HbScaffold(
      title: 'ملاحظات المراجعة',
      body: ListView(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  TextField(
                    controller: _decisionController,
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: 'حالة الطلب',
                      hintText: 'الحالة الحالية للطلب',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _notesController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'ملاحظات المراجعة',
                      hintText: 'أدخل ملاحظات المتابعة أو التوضيح هنا',
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          HbPrimaryButtonRow(
            primaryLabel: _isSaving ? 'جاري الحفظ...' : 'حفظ الملاحظات',
            onPrimaryPressed: _isSaving ? () {} : () => _saveDecision(),
          ),
        ],
      ),
    );
  }
}

class InsuranceCoverageCatalogScreen extends StatefulWidget {
  const InsuranceCoverageCatalogScreen({super.key});

  static const routeName = 'insurance-coverage-catalog';
  static const routePath = '/insurance/coverage-catalog';

  @override
  State<InsuranceCoverageCatalogScreen> createState() => _InsuranceCoverageCatalogScreenState();
}

class _InsuranceCoverageCatalogScreenState extends State<InsuranceCoverageCatalogScreen> {
  static const _filterOptions = [
    HbFilterOption(value: 'الكل', label: 'الكل'),
    HbFilterOption(value: 'Medication', label: 'أدوية'),
    HbFilterOption(value: 'Laboratory', label: 'مختبر'),
    HbFilterOption(value: 'Imaging', label: 'تصوير'),
    HbFilterOption(value: 'MedicalCenter', label: 'مركز طبي'),
  ];

  String _selectedFilter = 'الكل';
  late Future<List<CoverageCatalogItemModel>> _coverageFuture;

  @override
  void initState() {
    super.initState();
    _coverageFuture = _loadCoverage();
  }

  Future<List<CoverageCatalogItemModel>> _loadCoverage() {
    return context.read<AppDataService>().getCoverageCatalog(activeOnly: false);
  }

  void _refresh() {
    setState(() {
      _coverageFuture = _loadCoverage();
    });
  }

  Future<void> _openCoverageEditor({CoverageCatalogItemModel? item}) async {
    final savedItem = await showDialog<CoverageCatalogItemModel>(
      context: context,
      builder: (context) => _CoverageCatalogEditorDialog(initialItem: item),
    );
    if (savedItem == null || !mounted) return;

    final service = context.read<AppDataService>();
    if (item == null) {
      await service.createCoverageCatalogItem(item: savedItem);
    } else {
      await service.updateCoverageCatalogItem(item: savedItem);
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(item == null ? 'تمت إضافة عنصر التغطية' : 'تم تحديث عنصر التغطية')),
    );
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return HbScaffold(
      title: 'كتالوج التغطية التأمينية',
      actions: _commonActions(context),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openCoverageEditor(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('إضافة عنصر'),
      ),
      body: FutureBuilder<List<CoverageCatalogItemModel>>(
        future: _coverageFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return HbEmptyState(
              title: 'تعذر تحميل كتالوج التغطية',
              message: snapshot.error.toString(),
              icon: Icons.cloud_off_rounded,
            );
          }

          final items = snapshot.data ?? const <CoverageCatalogItemModel>[];
          final filteredItems = _selectedFilter == 'الكل'
              ? items
              : items.where((item) => item.category == _selectedFilter).toList();

          return ListView(
            children: [
              HbSectionCard(
                title: 'نظرة عامة',
                subtitle: 'إدارة التغطية حسب نوع الطلب والسعر ونسبة التغطية.',
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _CoverageStatCard(label: 'إجمالي العناصر', value: '${items.length}', icon: Icons.dataset_outlined),
                    _CoverageStatCard(
                      label: 'أدوية مغطاة',
                      value: '${items.where((item) => item.category == "Medication").length}',
                      icon: Icons.medication_outlined,
                    ),
                    _CoverageStatCard(
                      label: 'فحوصات مختبر',
                      value: '${items.where((item) => item.category == "Laboratory").length}',
                      icon: Icons.science_outlined,
                    ),
                    _CoverageStatCard(
                      label: 'تصوير طبي',
                      value: '${items.where((item) => item.category == "Imaging").length}',
                      icon: Icons.perm_media_outlined,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              HbFilterBar(
                options: _filterOptions,
                selectedValue: _selectedFilter,
                onChanged: (value) => setState(() => _selectedFilter = value),
              ),
              const SizedBox(height: 16),
              if (filteredItems.isEmpty)
                const HbEmptyState(
                  title: 'لا توجد عناصر ضمن هذا الفلتر',
                  message: 'أضف عناصر تغطية جديدة أو غيّر نوع الفلترة.',
                  icon: Icons.inventory_2_outlined,
                )
              else
                ...filteredItems.map((item) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: HbCustomCard(
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
                                    Text(item.title, style: Theme.of(context).textTheme.titleMedium),
                                    const SizedBox(height: 6),
                                    Text(
                                      '${_coverageCategoryLabel(item.category)} • ${item.providerName}',
                                      style: Theme.of(context).textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              HbStatusChip(item.isActive ? 'فعّال' : 'غير فعّال'),
                            ],
                          ),
                          const SizedBox(height: 12),
                          HbInfoRow(label: 'الكود', value: item.code),
                          HbInfoRow(label: 'نوع الجهة', value: _providerTypeLabel(item.providerType)),
                          HbInfoRow(label: 'السعر المعتمد', value: item.unitPrice.toStringAsFixed(2)),
                          HbInfoRow(label: 'نسبة التغطية', value: '${item.coveragePercentage.toStringAsFixed(0)}%'),
                          HbInfoRow(
                            label: 'حصة الموظف',
                            value: '${item.employeeSharePercentage.toStringAsFixed(0)}% (${item.employeeShareFor(item.unitPrice).toStringAsFixed(2)})',
                          ),
                          HbInfoRow(label: 'الحد الأعلى للكمية', value: '${item.maxQuantity}'),
                          HbInfoRow(
                            label: 'الموافقة المسبقة',
                            value: item.requiresInsuranceApproval ? 'مطلوبة' : 'غير مطلوبة',
                          ),
                          HbInfoRow(
                            label: 'الوصف',
                            value: item.description.isEmpty ? 'لا يوجد وصف إضافي' : item.description,
                          ),
                          HbInfoRow(
                            label: 'ملاحظات',
                            value: item.notes.isEmpty ? 'لا توجد ملاحظات' : item.notes,
                          ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton.icon(
                              onPressed: () => _openCoverageEditor(item: item),
                              icon: const Icon(Icons.edit_outlined),
                              label: const Text('تعديل العنصر'),
                            ),
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

class _CoverageStatCard extends StatelessWidget {
  const _CoverageStatCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 165,
      child: HbSectionCard(
        title: value,
        subtitle: label,
        child: Align(
          alignment: Alignment.centerLeft,
          child: Icon(icon, color: Theme.of(context).colorScheme.primary),
        ),
      ),
    );
  }
}

class _CoverageCatalogEditorDialog extends StatefulWidget {
  const _CoverageCatalogEditorDialog({
    this.initialItem,
  });

  final CoverageCatalogItemModel? initialItem;

  @override
  State<_CoverageCatalogEditorDialog> createState() => _CoverageCatalogEditorDialogState();
}

class _CoverageCatalogEditorDialogState extends State<_CoverageCatalogEditorDialog> {
  late final TextEditingController _codeController;
  late final TextEditingController _titleController;
  late final TextEditingController _providerNameController;
  late final TextEditingController _unitPriceController;
  late final TextEditingController _coverageController;
  late final TextEditingController _maxQuantityController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _notesController;

  String _category = 'Medication';
  String _providerType = 'Pharmacy';
  bool _requiresInsuranceApproval = false;
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    final item = widget.initialItem;
    _codeController = TextEditingController(text: item?.code ?? '');
    _titleController = TextEditingController(text: item?.title ?? '');
    _providerNameController = TextEditingController(text: item?.providerName ?? '');
    _unitPriceController = TextEditingController(
      text: item == null ? '' : item.unitPrice.toStringAsFixed(2),
    );
    _coverageController = TextEditingController(
      text: item == null ? '' : item.coveragePercentage.toStringAsFixed(0),
    );
    _maxQuantityController = TextEditingController(text: item == null ? '1' : '${item.maxQuantity}');
    _descriptionController = TextEditingController(text: item?.description ?? '');
    _notesController = TextEditingController(text: item?.notes ?? '');
    _category = item?.category ?? 'Medication';
    _providerType = item?.providerType ?? 'Pharmacy';
    _requiresInsuranceApproval = item?.requiresInsuranceApproval ?? false;
    _isActive = item?.isActive ?? true;
  }

  @override
  void dispose() {
    _codeController.dispose();
    _titleController.dispose();
    _providerNameController.dispose();
    _unitPriceController.dispose();
    _coverageController.dispose();
    _maxQuantityController.dispose();
    _descriptionController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _save() {
    final unitPrice = double.tryParse(_unitPriceController.text.trim()) ?? 0;
    final coverage = double.tryParse(_coverageController.text.trim()) ?? 0;
    final maxQuantity = int.tryParse(_maxQuantityController.text.trim()) ?? 1;

    final item = CoverageCatalogItemModel(
      id: widget.initialItem?.id ?? DateTime.now().millisecondsSinceEpoch,
      code: _codeController.text.trim().isEmpty
          ? 'AUTO-${DateTime.now().millisecondsSinceEpoch}'
          : _codeController.text.trim(),
      title: _titleController.text.trim(),
      category: _category,
      providerType: _providerType,
      providerName: _providerNameController.text.trim().isEmpty
          ? _defaultProviderName(_providerType)
          : _providerNameController.text.trim(),
      unitPrice: unitPrice,
      coveragePercentage: coverage.clamp(0, 100),
      maxQuantity: maxQuantity <= 0 ? 1 : maxQuantity,
      requiresInsuranceApproval: _requiresInsuranceApproval,
      isActive: _isActive,
      description: _descriptionController.text.trim(),
      notes: _notesController.text.trim(),
    );

    Navigator.of(context).pop(item);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.initialItem == null ? 'إضافة عنصر تغطية' : 'تعديل عنصر تغطية'),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _codeController,
                decoration: const InputDecoration(labelText: 'الكود'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'اسم الدواء / الخدمة'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: const InputDecoration(labelText: 'الفئة'),
                items: const [
                  DropdownMenuItem(value: 'Medication', child: Text('دواء')),
                  DropdownMenuItem(value: 'Laboratory', child: Text('مختبر')),
                  DropdownMenuItem(value: 'Imaging', child: Text('تصوير طبي')),
                  DropdownMenuItem(value: 'MedicalCenter', child: Text('مركز طبي')),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    _category = value;
                    _providerType = _providerTypeForCategory(value);
                  });
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _providerType,
                decoration: const InputDecoration(labelText: 'نوع الجهة'),
                items: const [
                  DropdownMenuItem(value: 'Pharmacy', child: Text('صيدلية')),
                  DropdownMenuItem(value: 'Laboratory', child: Text('مختبر')),
                  DropdownMenuItem(value: 'ImagingCenter', child: Text('تصوير طبي')),
                  DropdownMenuItem(value: 'MedicalCenter', child: Text('مركز طبي')),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _providerType = value);
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _providerNameController,
                decoration: const InputDecoration(labelText: 'اسم الجهة المقدمة'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _unitPriceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'السعر المعتمد'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _coverageController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'نسبة التغطية %'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _maxQuantityController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'الحد الأعلى للكمية'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _descriptionController,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'وصف مختصر'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _notesController,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'ملاحظات التغطية'),
              ),
              const SizedBox(height: 12),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                value: _requiresInsuranceApproval,
                title: const Text('يتطلب موافقة مسبقة'),
                onChanged: (value) => setState(() => _requiresInsuranceApproval = value),
              ),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                value: _isActive,
                title: const Text('العنصر فعّال'),
                onChanged: (value) => setState(() => _isActive = value),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('إلغاء'),
        ),
        FilledButton(
          onPressed: _save,
          child: const Text('حفظ'),
        ),
      ],
    );
  }
}

String _coverageCategoryLabel(String category) {
  switch (category) {
    case 'Medication':
      return 'دواء';
    case 'Laboratory':
      return 'فحص مختبر';
    case 'Imaging':
      return 'تصوير طبي';
    case 'MedicalCenter':
      return 'خدمة مركز طبي';
    default:
      return category;
  }
}

String _providerTypeLabel(String providerType) {
  switch (providerType) {
    case 'Pharmacy':
      return 'صيدلية';
    case 'Laboratory':
      return 'مختبر';
    case 'ImagingCenter':
      return 'تصوير طبي';
    case 'MedicalCenter':
      return 'مركز طبي';
    default:
      return providerType;
  }
}

String _providerTypeForCategory(String category) {
  switch (category) {
    case 'Medication':
      return 'Pharmacy';
    case 'Laboratory':
      return 'Laboratory';
    case 'Imaging':
      return 'ImagingCenter';
    case 'MedicalCenter':
      return 'MedicalCenter';
    default:
      return 'Pharmacy';
  }
}

String _defaultProviderName(String providerType) {
  switch (providerType) {
    case 'Pharmacy':
      return 'شبكة الصيدليات المتعاقدة';
    case 'Laboratory':
      return 'مختبر الجامعة';
    case 'ImagingCenter':
      return 'مركز التصوير الطبي';
    case 'MedicalCenter':
      return 'المركز الطبي الجامعي';
    default:
      return 'جهة معتمدة';
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
