import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:healthbridge_mobile/model/models/app_models.dart';
import 'package:healthbridge_mobile/model/repositories/app_repository.dart';
import 'package:healthbridge_mobile/modelView/features/insurance_officer/insurance_coverage_catalog_view_model.dart';
import 'package:healthbridge_mobile/modelView/features/insurance_officer/insurance_requests_view_model.dart';
import 'package:healthbridge_mobile/modelView/features/insurance_officer/insurance_review_view_model.dart';
import 'package:healthbridge_mobile/view/features/common/notifications_screen.dart';
import 'package:healthbridge_mobile/view/features/common/profile_screen.dart';
import 'package:healthbridge_mobile/model/utils/status_label.dart';
import 'package:healthbridge_mobile/view/widgets/hb_custom_card.dart';
import 'package:healthbridge_mobile/view/widgets/hb_dashboard_overview.dart';
import 'package:healthbridge_mobile/view/widgets/hb_empty_state.dart';
import 'package:healthbridge_mobile/view/widgets/hb_filter_bar.dart';
import 'package:healthbridge_mobile/view/widgets/hb_info_row.dart';
import 'package:healthbridge_mobile/view/widgets/hb_notification_action.dart';
import 'package:healthbridge_mobile/view/widgets/hb_primary_button_row.dart';
import 'package:healthbridge_mobile/view/widgets/hb_quick_action_card.dart';
import 'package:healthbridge_mobile/view/widgets/hb_scaffold.dart';
import 'package:healthbridge_mobile/view/widgets/hb_section_card.dart';
import 'package:healthbridge_mobile/view/widgets/hb_status_chip.dart';

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
                      onTap: () =>
                          context.push(InsuranceRequestsScreen.routePath),
                    ),
                  ),
                  SizedBox(
                    width: actionWidth,
                    child: HbQuickActionCard(
                      title: 'الطلبات الحديثة',
                      subtitle: 'عرض أحدث الطلبات التي وصلت من الأطباء',
                      icon: Icons.history_toggle_off_rounded,
                      onTap: () =>
                          context.push(InsuranceRequestsScreen.routePath),
                    ),
                  ),
                  SizedBox(
                    width: actionWidth,
                    child: HbQuickActionCard(
                      title: 'الطلبات المعتمدة',
                      subtitle:
                          'الطلبات التي تم اعتمادها تلقائيًا ويمكن مراجعتها',
                      icon: Icons.task_alt_rounded,
                      onTap: () =>
                          context.push(InsuranceRequestsScreen.routePath),
                    ),
                  ),
                  SizedBox(
                    width: actionWidth,
                    child: HbQuickActionCard(
                      title: 'كتالوج التغطية',
                      subtitle: 'إدارة عناصر التغطية والأسعار ونسب التحمل',
                      icon: Icons.inventory_2_outlined,
                      onTap: () => context.push(
                        InsuranceCoverageCatalogScreen.routePath,
                      ),
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

class InsuranceRequestsScreen extends StatelessWidget {
  const InsuranceRequestsScreen({super.key});

  static const routeName = 'insurance-requests';
  static const routePath = '/insurance/requests';

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => InsuranceRequestsViewModel(
        appRepository: context.read<AppRepository>(),
      ),
      child: const _InsuranceRequestsScreenView(),
    );
  }
}

class _InsuranceRequestsScreenView extends StatelessWidget {
  const _InsuranceRequestsScreenView();

  static const _filterOptions = [
    HbFilterOption(value: 'الكل', label: 'الكل'),
    HbFilterOption(value: 'Approved', label: 'مقبولة'),
    HbFilterOption(value: 'Pending', label: 'معلّقة قديمة'),
    HbFilterOption(value: 'Rejected', label: 'مرفوضة'),
    HbFilterOption(value: 'NeedsUpdate', label: 'تحتاج تعديل'),
  ];

  Future<void> _updateRequestStatus(
    BuildContext context,
    InsuranceRequestModel request,
    String status,
    String actionLabel,
  ) async {
    final notes = await _showInsuranceDecisionDialog(
      context,
      actionLabel: actionLabel,
      initialNotes: request.responseNotes,
    );
    if (notes == null || !context.mounted) return;

    try {
      final message = await context
          .read<InsuranceRequestsViewModel>()
          .updateRequestStatus(request, status, actionLabel, notes);
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<InsuranceRequestsViewModel>();

    return HbScaffold(
      title: 'طلبات التغطية',
      actions: _commonActions(context),
      body: FutureBuilder<List<InsuranceRequestModel>>(
        future: viewModel.requestsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
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
          final filteredRequests = viewModel.filteredRequests(requests);
          return ListView(
            children: [
              HbFilterBar(
                options: _filterOptions,
                selectedValue: viewModel.selectedFilter,
                onChanged: viewModel.updateFilter,
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        request.employeeName,
                                        style: Theme.of(
                                          context,
                                        ).textTheme.titleMedium,
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        '${request.doctorName} • ${request.serviceName.isEmpty ? "خدمة غير محددة" : request.serviceName}',
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodyMedium,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${request.providerName.isEmpty ? "بدون جهة محددة" : request.providerName} • ${_formatDate(request.submittedAt)}',
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodySmall,
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'التغطية ${request.coveragePercentage.toStringAsFixed(0)}% • المغطى ${request.coveredAmount.toStringAsFixed(2)} • حصة الموظف ${request.employeeShare.toStringAsFixed(2)}',
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodySmall,
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
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  TextButton(
                                    onPressed: () async {
                                      await context.push(
                                        '${InsuranceReviewScreen.routePath}?id=${request.id}',
                                      );
                                      if (!context.mounted) return;
                                      viewModel.refresh();
                                    },
                                    child: const Text('عرض التفاصيل'),
                                  ),
                                  FilledButton.tonal(
                                    onPressed: request.status == 'Approved'
                                        ? null
                                        : () => _updateRequestStatus(
                                            context,
                                            request,
                                            'Approved',
                                            'قبول',
                                          ),
                                    child: const Text('قبول'),
                                  ),
                                  OutlinedButton(
                                    onPressed:
                                        request.status == 'Approved' ||
                                            request.status == 'Rejected'
                                        ? null
                                        : () => _updateRequestStatus(
                                            context,
                                            request,
                                            'Rejected',
                                            'رفض',
                                          ),
                                    child: const Text('رفض'),
                                  ),
                                ],
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

class InsuranceReviewScreen extends StatelessWidget {
  const InsuranceReviewScreen({super.key, this.requestId});

  static const routeName = 'insurance-review';
  static const routePath = '/insurance/requests/review';

  final int? requestId;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => InsuranceReviewViewModel(
        appRepository: context.read<AppRepository>(),
        requestId: requestId,
      ),
      child: _InsuranceReviewScreenView(requestId: requestId),
    );
  }
}

class _InsuranceReviewScreenView extends StatelessWidget {
  const _InsuranceReviewScreenView({required this.requestId});

  final int? requestId;

  Future<void> _updateRequestStatus(
    BuildContext context,
    InsuranceRequestModel request,
    String status,
    String actionLabel,
  ) async {
    final notes = await _showInsuranceDecisionDialog(
      context,
      actionLabel: actionLabel,
      initialNotes: request.responseNotes,
    );
    if (notes == null || !context.mounted) return;

    try {
      final message = await context
          .read<InsuranceReviewViewModel>()
          .updateRequestStatus(request, status, actionLabel, notes);
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return HbScaffold(
      title: 'مراجعة تفاصيل الطلب',
      actions: _commonActions(context),
      body: requestId == null
          ? const HbEmptyState(
              title: 'لا يوجد طلب محدد',
              message: 'يرجى اختيار طلب أولًا.',
            )
          : FutureBuilder<InsuranceReviewData>(
              future: context.watch<InsuranceReviewViewModel>().reviewFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return HbEmptyState(
                    title: 'تعذر تحميل تفاصيل الطلب',
                    message: snapshot.error.toString(),
                    icon: Icons.cloud_off_rounded,
                  );
                }

                final reviewData = snapshot.data;
                final request = reviewData?.request;
                if (request == null) {
                  return const HbEmptyState(
                    title: 'الطلب غير متوفر',
                    message: 'تعذر العثور على الطلب المطلوب.',
                  );
                }
                final prescription = reviewData?.prescription;
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
                          HbInfoRow(
                            label: 'رقم طلب التغطية',
                            value: request.requestNumber,
                          ),
                          HbInfoRow(
                            label: 'اسم الموظف الجامعي',
                            value: request.employeeName,
                          ),
                          HbInfoRow(
                            label: 'اسم المستفيد',
                            value:
                                request.beneficiaryName ?? request.employeeName,
                          ),
                          HbInfoRow(
                            label: 'الجهة المقدمة',
                            value: request.providerName.isEmpty
                                ? 'غير محدد'
                                : request.providerName,
                          ),
                          HbInfoRow(
                            label: 'الخدمة',
                            value: request.serviceName.isEmpty
                                ? 'غير محدد'
                                : request.serviceName,
                          ),
                          HbInfoRow(
                            label: 'اسم الطبيب',
                            value: request.doctorName,
                          ),
                          if (prescription.serviceType != 'Medication')
                            HbInfoRow(
                              label: 'نوع الطلب',
                              value: prescription.serviceType,
                            ),
                          HbInfoRow(
                            label: 'نسبة التغطية',
                            value:
                                '${prescription.coveragePercentage.toStringAsFixed(0)}%',
                          ),
                          HbInfoRow(
                            label: 'السعر الأصلي',
                            value: prescription.finalPrice.toStringAsFixed(2),
                          ),
                          HbInfoRow(
                            label: 'المبلغ المغطى',
                            value: prescription.coveredAmount.toStringAsFixed(
                              2,
                            ),
                          ),
                          HbInfoRow(
                            label: 'حصة الموظف',
                            value: prescription.employeeShare.toStringAsFixed(
                              2,
                            ),
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
                            label: 'حالة الطلب الحالية',
                            value: statusLabel(request.status),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    HbSectionCard(
                      title: prescription.serviceType == 'Medication'
                          ? 'الأدوية'
                          : 'تفاصيل الخدمة',
                      child: prescription.items.isEmpty
                          ? Column(
                              children: [
                                HbInfoRow(
                                  label: 'ملاحظات التنفيذ',
                                  value: prescription.providerNotes.isEmpty
                                      ? 'لا توجد ملاحظات من الجهة الطبية'
                                      : prescription.providerNotes,
                                ),
                              ],
                            )
                          : Column(
                              children: prescription.items.map((item) {
                                return ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(item.medicationName),
                                  subtitle: Text(
                                    '${item.quantity} • ${item.dosageInstructions}',
                                  ),
                                );
                              }).toList(),
                            ),
                    ),
                    const SizedBox(height: 16),
                    HbSectionCard(
                      title: 'حالة الطلب',
                      subtitle:
                          'يمكنك الاطلاع على الطلب وتأكيد قبوله أو رفضه مع إضافة ملاحظات عند الحاجة.',
                      child: Column(
                        children: [
                          HbInfoRow(
                            label: 'الحالة الحالية',
                            value: statusLabel(request.status),
                          ),
                          HbInfoRow(
                            label: 'ملاحظات المراجعة',
                            value: request.responseNotes.isEmpty
                                ? 'لا توجد ملاحظات إضافية.'
                                : request.responseNotes,
                          ),
                          const SizedBox(height: 12),
                          HbPrimaryButtonRow(
                            primaryLabel: 'قبول الطلب',
                            onPrimaryPressed: request.status == 'Approved'
                                ? null
                                : () => _updateRequestStatus(
                                    context,
                                    request,
                                    'Approved',
                                    'قبول',
                                  ),
                            secondaryLabel: 'رفض الطلب',
                            onSecondaryPressed:
                                request.status == 'Approved' ||
                                    request.status == 'Rejected'
                                ? null
                                : () => _updateRequestStatus(
                                    context,
                                    request,
                                    'Rejected',
                                    'رفض',
                                  ),
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

Future<String?> _showInsuranceDecisionDialog(
  BuildContext context, {
  required String actionLabel,
  required String initialNotes,
}) async {
  final notesController = TextEditingController(text: initialNotes);
  final result = await showDialog<String>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text('$actionLabel الطلب'),
        content: TextField(
          controller: notesController,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: 'ملاحظات',
            hintText: 'أدخل ملاحظات إضافية إن وجدت',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(notesController.text.trim()),
            child: Text(actionLabel),
          ),
        ],
      );
    },
  );
  notesController.dispose();
  return result;
}

class InsuranceCoverageCatalogScreen extends StatelessWidget {
  const InsuranceCoverageCatalogScreen({super.key});

  static const routeName = 'insurance-coverage-catalog';
  static const routePath = '/insurance/coverage-catalog';

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => InsuranceCoverageCatalogViewModel(
        appRepository: context.read<AppRepository>(),
      ),
      child: const _InsuranceCoverageCatalogScreenView(),
    );
  }
}

class _InsuranceCoverageCatalogScreenView extends StatelessWidget {
  const _InsuranceCoverageCatalogScreenView();

  Future<void> _openCoverageEditor(
    BuildContext context, {
    CoverageCatalogItemModel? item,
  }) async {
    final savedItem = await showDialog<CoverageCatalogItemModel>(
      context: context,
      builder: (context) => _CoverageCatalogEditorDialog(initialItem: item),
    );
    if (savedItem == null || !context.mounted) return;

    try {
      final message = await context
          .read<InsuranceCoverageCatalogViewModel>()
          .saveCoverageItem(savedItem, originalItem: item);
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<InsuranceCoverageCatalogViewModel>();

    return HbScaffold(
      title: 'كتالوج التغطية التأمينية',
      actions: _commonActions(context),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openCoverageEditor(context, item: null),
        icon: const Icon(Icons.add_rounded),
        label: const Text('إضافة دواء'),
      ),
      body: FutureBuilder<List<CoverageCatalogItemModel>>(
        future: viewModel.coverageFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
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

          return ListView(
            children: [
              HbSectionCard(
                title: 'نظرة عامة',
                subtitle: 'إدارة أسعار الأدوية المغطاة ونسب التحمل المعتمدة.',
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _CoverageStatCard(
                      label: 'إجمالي العناصر',
                      value: '${items.length}',
                      icon: Icons.dataset_outlined,
                    ),
                    _CoverageStatCard(
                      label: 'أدوية مغطاة',
                      value:
                          '${items.where((item) => item.category == "Medication").length}',
                      icon: Icons.medication_outlined,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (items.isEmpty)
                const HbEmptyState(
                  title: 'لا توجد أدوية مضافة',
                  message: 'أضف أدوية جديدة إلى كتالوج التغطية.',
                  icon: Icons.inventory_2_outlined,
                )
              else
                ...items.map((item) {
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
                                    Text(
                                      item.title,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleMedium,
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      item.providerName.isEmpty
                                          ? 'شبكة الصيدليات المتعاقدة'
                                          : item.providerName,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              HbStatusChip(
                                item.isActive ? 'فعّال' : 'غير فعّال',
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          HbInfoRow(label: 'الكود', value: item.code),
                          HbInfoRow(
                            label: 'السعر المعتمد',
                            value: item.unitPrice.toStringAsFixed(2),
                          ),
                          HbInfoRow(
                            label: 'نسبة التغطية',
                            value:
                                '${item.coveragePercentage.toStringAsFixed(0)}%',
                          ),
                          HbInfoRow(
                            label: 'حصة الموظف',
                            value:
                                '${item.employeeSharePercentage.toStringAsFixed(0)}% (${item.employeeShareFor(item.unitPrice).toStringAsFixed(2)})',
                          ),
                          HbInfoRow(
                            label: 'الحد الأعلى للكمية',
                            value: '${item.maxQuantity}',
                          ),
                          HbInfoRow(
                            label: 'الموافقة المسبقة',
                            value: item.requiresInsuranceApproval
                                ? 'مطلوبة'
                                : 'غير مطلوبة',
                          ),
                          HbInfoRow(
                            label: 'الوصف',
                            value: item.description.isEmpty
                                ? 'لا يوجد وصف إضافي'
                                : item.description,
                          ),
                          HbInfoRow(
                            label: 'ملاحظات',
                            value: item.notes.isEmpty
                                ? 'لا توجد ملاحظات'
                                : item.notes,
                          ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton.icon(
                              onPressed: () =>
                                  _openCoverageEditor(context, item: item),
                              icon: const Icon(Icons.edit_outlined),
                              label: const Text('تعديل الدواء'),
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
  const _CoverageCatalogEditorDialog({this.initialItem});

  final CoverageCatalogItemModel? initialItem;

  @override
  State<_CoverageCatalogEditorDialog> createState() =>
      _CoverageCatalogEditorDialogState();
}

class _CoverageCatalogEditorDialogState
    extends State<_CoverageCatalogEditorDialog> {
  late final TextEditingController _codeController;
  late final TextEditingController _titleController;
  late final TextEditingController _providerNameController;
  late final TextEditingController _unitPriceController;
  late final TextEditingController _coverageController;
  late final TextEditingController _maxQuantityController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _notesController;

  bool _requiresInsuranceApproval = false;
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    final item = widget.initialItem;
    _codeController = TextEditingController(text: item?.code ?? '');
    _titleController = TextEditingController(text: item?.title ?? '');
    _providerNameController = TextEditingController(
      text: item?.providerName ?? '',
    );
    _unitPriceController = TextEditingController(
      text: item == null ? '' : item.unitPrice.toStringAsFixed(2),
    );
    _coverageController = TextEditingController(
      text: item == null ? '' : item.coveragePercentage.toStringAsFixed(0),
    );
    _maxQuantityController = TextEditingController(
      text: item == null ? '1' : '${item.maxQuantity}',
    );
    _descriptionController = TextEditingController(
      text: item?.description ?? '',
    );
    _notesController = TextEditingController(text: item?.notes ?? '');
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
      category: 'Medication',
      providerType: 'Pharmacy',
      providerName: _providerNameController.text.trim().isEmpty
          ? _defaultProviderName()
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
      title: Text(widget.initialItem == null ? 'إضافة دواء' : 'تعديل دواء'),
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
                decoration: const InputDecoration(labelText: 'اسم الدواء'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _providerNameController,
                decoration: const InputDecoration(
                  labelText: 'اسم الجهة المقدمة',
                ),
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
                decoration: const InputDecoration(
                  labelText: 'الحد الأعلى للكمية',
                ),
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
                onChanged: (value) =>
                    setState(() => _requiresInsuranceApproval = value),
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
        FilledButton(onPressed: _save, child: const Text('حفظ')),
      ],
    );
  }
}

String _defaultProviderName() {
  return 'شبكة الصيدليات المتعاقدة';
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
