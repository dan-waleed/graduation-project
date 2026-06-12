import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

import 'package:healthbridge_mobile/model/models/app_models.dart';
import 'package:healthbridge_mobile/model/repositories/app_repository.dart';
import 'package:healthbridge_mobile/model/core/errors/app_exception.dart';
import 'package:healthbridge_mobile/modelView/features/pharmacist/pharmacist_dispense_confirm_view_model.dart';
import 'package:healthbridge_mobile/modelView/features/pharmacist/pharmacist_dispense_history_view_model.dart';
import 'package:healthbridge_mobile/modelView/features/pharmacist/pharmacist_prescription_detail_view_model.dart';
import 'package:healthbridge_mobile/modelView/features/pharmacist/pharmacist_qr_lookup_view_model.dart';
import 'package:healthbridge_mobile/modelView/features/pharmacist/pharmacist_search_prescription_view_model.dart';
import 'package:healthbridge_mobile/view/features/common/notifications_screen.dart';
import 'package:healthbridge_mobile/view/features/common/profile_screen.dart';
import 'package:healthbridge_mobile/view/widgets/hb_custom_button.dart';
import 'package:healthbridge_mobile/view/widgets/hb_custom_card.dart';
import 'package:healthbridge_mobile/view/widgets/hb_dashboard_overview.dart';
import 'package:healthbridge_mobile/view/widgets/hb_empty_state.dart';
import 'package:healthbridge_mobile/view/widgets/hb_info_row.dart';
import 'package:healthbridge_mobile/view/widgets/hb_notification_action.dart';
import 'package:healthbridge_mobile/view/widgets/hb_primary_button_row.dart';
import 'package:healthbridge_mobile/view/widgets/hb_quick_action_card.dart';
import 'package:healthbridge_mobile/view/widgets/hb_scaffold.dart';
import 'package:healthbridge_mobile/view/widgets/hb_section_card.dart';
import 'package:healthbridge_mobile/view/widgets/hb_status_chip.dart';

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
                emptyMessage:
                    'ستظهر هنا أحدث العمليات التي قمت بصرفها أو مراجعتها.',
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
                      onTap: () => context.push(
                        PharmacistSearchPrescriptionScreen.routePath,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: actionWidth,
                    child: HbQuickActionCard(
                      title: 'سجل الصرف',
                      subtitle: 'عرض الوصفات التي تم صرفها',
                      icon: Icons.receipt_long_rounded,
                      onTap: () => context.push(
                        PharmacistDispenseHistoryScreen.routePath,
                      ),
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
                      onTap: () =>
                          context.push(PharmacistQrLookupScreen.routePath),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              HbCustomButton(
                label: 'مسح رمز QR',
                icon: Icons.qr_code_scanner_rounded,
                onPressed: () =>
                    context.push(PharmacistQrLookupScreen.routePath),
              ),
            ],
          );
        },
      ),
    );
  }
}

class PharmacistSearchPrescriptionScreen extends StatelessWidget {
  const PharmacistSearchPrescriptionScreen({super.key});

  static const routeName = 'pharmacist-search-prescription';
  static const routePath = '/pharmacist/search';

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => PharmacistSearchPrescriptionViewModel(
        appRepository: context.read<AppRepository>(),
      ),
      child: const _PharmacistSearchPrescriptionView(),
    );
  }
}

class _PharmacistSearchPrescriptionView extends StatelessWidget {
  const _PharmacistSearchPrescriptionView();

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<PharmacistSearchPrescriptionViewModel>();

    return HbScaffold(
      title: 'البحث عن وصفة',
      actions: _commonActions(context),
      body: FutureBuilder<List<PrescriptionModel>>(
        future: viewModel.prescriptionsFuture,
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

          final prescriptions = viewModel.visiblePrescriptions(
            snapshot.data ?? const [],
          );
          return ListView(
            children: [
              HbCustomCard(
                child: Column(
                  children: [
                    TextField(
                      controller: viewModel.searchController,
                      decoration: const InputDecoration(
                        labelText: 'رقم الوصفة أو رمزها',
                        hintText: 'مثال: RX-2026-014',
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              HbCustomButton(
                label: 'بحث',
                onPressed: viewModel.search,
                icon: Icons.search_rounded,
              ),
              const SizedBox(height: 12),
              const Text(
                'ملاحظة: يمكنك أيضًا استخدام رمز QR للوصول السريع إلى الوصفة.',
              ),
              const SizedBox(height: 12),
              HbCustomButton(
                label: 'عرض وصفة عبر QR',
                onPressed: () =>
                    context.push(PharmacistQrLookupScreen.routePath),
                icon: Icons.qr_code_scanner_rounded,
                variant: HbButtonVariant.outline,
              ),
              const SizedBox(height: 16),
              if (prescriptions.isEmpty)
                HbEmptyState(
                  title: 'لا توجد نتائج',
                  message: viewModel.query.trim().isEmpty
                      ? 'تظهر هنا فقط الوصفات المعتمدة التي لم يتم صرفها بعد.'
                      : 'لم يتم العثور على وصفة مطابقة لرقم البحث.',
                  icon: Icons.search_off_rounded,
                )
              else
                ...prescriptions.take(5).map((prescription) {
                  return Card(
                    child: ListTile(
                      title: Text(prescription.prescriptionNumber),
                      subtitle: Text(
                        '${prescription.employeeName} • ${_statusLabel(prescription.status)}',
                      ),
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
                              unawaited(
                                Future<void>.microtask(viewModel.refresh),
                              );
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

class PharmacistQrLookupScreen extends StatelessWidget {
  const PharmacistQrLookupScreen({super.key});

  static const routeName = 'pharmacist-qr-lookup';
  static const routePath = '/pharmacist/qr';

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => PharmacistQrLookupViewModel(
        appRepository: context.read<AppRepository>(),
      ),
      child: const _PharmacistQrLookupView(),
    );
  }
}

class _PharmacistQrLookupView extends StatelessWidget {
  const _PharmacistQrLookupView();

  Future<void> _showLookupAlert(
    BuildContext context, {
    required String title,
    required String message,
  }) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('حسنًا'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _processLookup(
    BuildContext context,
    String rawValue, {
    bool restartScannerAfter = false,
  }) async {
    final viewModel = context.read<PharmacistQrLookupViewModel>();
    final normalizedQuery = viewModel.extractPrescriptionNumber(rawValue);
    if (normalizedQuery.isEmpty) {
      await _showLookupAlert(
        context,
        title: 'تعذر قراءة الرمز',
        message: 'لم نتمكن من استخراج رقم وصفة صالح من رمز QR.',
      );
      if (restartScannerAfter && context.mounted) {
        await viewModel.restartScanner();
      }
      return;
    }

    viewModel.setLookupCode(normalizedQuery);

    try {
      final result = await viewModel.findPrescriptionLookupResult(
        normalizedQuery,
      );
      if (!context.mounted) {
        return;
      }

      switch (result.state) {
        case PharmacistPrescriptionLookupState.approved:
          await context.push(
            '${PharmacistPrescriptionDetailScreen.routePath}?id=${result.prescription!.id}',
          );
          if (!context.mounted) {
            return;
          }
          viewModel.refreshApprovedPrescriptions();
          break;
        case PharmacistPrescriptionLookupState.dispensed:
          await _showLookupAlert(
            context,
            title: 'تم صرف الوصفة',
            message:
                'الوصفة ${result.query} تم صرفها مسبقًا، لذلك لا يمكن متابعتها من جديد.',
          );
          break;
        case PharmacistPrescriptionLookupState.unavailable:
          await _showLookupAlert(
            context,
            title: 'الوصفة غير جاهزة للصرف',
            message:
                'تم العثور على الوصفة ${result.query} لكن حالتها الحالية هي ${_statusLabel(result.prescription!.status)}.',
          );
          break;
        case PharmacistPrescriptionLookupState.notFound:
          await _showLookupAlert(
            context,
            title: 'الوصفة غير موجودة',
            message: 'تعذر العثور على وصفة مطابقة للرمز أو الرقم المدخل.',
          );
          break;
      }
    } on AppException catch (error) {
      if (!context.mounted) {
        return;
      }
      await _showLookupAlert(
        context,
        title: 'تعذر التحقق من الوصفة',
        message: error.message,
      );
    } finally {
      if (restartScannerAfter && context.mounted) {
        await viewModel.restartScanner();
      }
    }
  }

  Future<void> _handleBarcodeCapture(
    BuildContext context,
    BarcodeCapture capture,
  ) async {
    final viewModel = context.read<PharmacistQrLookupViewModel>();
    if (viewModel.isHandlingScan) {
      return;
    }

    final scannedValue = capture.barcodes
        .map((barcode) => barcode.rawValue?.trim() ?? '')
        .firstWhere((value) => value.isNotEmpty, orElse: () => '');
    if (scannedValue.isEmpty) {
      return;
    }

    await viewModel.stopScannerForHandling();
    if (!context.mounted) {
      return;
    }

    await _processLookup(context, scannedValue, restartScannerAfter: true);
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<PharmacistQrLookupViewModel>();

    return HbScaffold(
      title: 'عرض الوصفة عبر QR',
      body: FutureBuilder<List<PrescriptionModel>>(
        future: viewModel.prescriptionsFuture,
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

          final prescriptions = viewModel.approvedMedicationPrescriptions(
            snapshot.data ?? const [],
          );

          return ListView(
            children: [
              HbCustomCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'امسح رمز QR بالكاميرا',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'على iPhone ستظهر الكاميرا مباشرة. وجّهها إلى رمز الوصفة ليتم إدخال الرقم تلقائيًا.',
                    ),
                    const SizedBox(height: 14),
                    if (kIsWeb ||
                        defaultTargetPlatform == TargetPlatform.iOS ||
                        defaultTargetPlatform == TargetPlatform.android)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: SizedBox(
                          height: 260,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              MobileScanner(
                                controller: viewModel.scannerController,
                                onDetect: (capture) =>
                                    _handleBarcodeCapture(context, capture),
                              ),
                              IgnorePointer(
                                child: Container(
                                  margin: const EdgeInsets.all(36),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: Colors.white.withValues(
                                        alpha: 0.9,
                                      ),
                                      width: 2,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      const HbEmptyState(
                        title: 'الكاميرا غير مدعومة هنا',
                        message:
                            'افتح هذه الشاشة من iPhone أو Android لاستخدام المسح بالكاميرا.',
                        icon: Icons.qr_code_scanner_rounded,
                      ),
                    const SizedBox(height: 12),
                    HbPrimaryButtonRow(
                      primaryLabel: 'إعادة المسح',
                      onPrimaryPressed: viewModel.restartScanner,
                      secondaryLabel: 'فتح البحث المتقدم',
                      onSecondaryPressed: () => context.push(
                        PharmacistSearchPrescriptionScreen.routePath,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
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
                      controller: viewModel.codeController,
                      decoration: const InputDecoration(
                        labelText: 'رقم الوصفة',
                        hintText: 'مثال: RX-DEMO-001',
                      ),
                    ),
                    const SizedBox(height: 12),
                    HbPrimaryButtonRow(
                      primaryLabel: 'التحقق',
                      onPrimaryPressed: () => _processLookup(
                        context,
                        viewModel.codeController.text,
                      ),
                      secondaryLabel: 'فتح البحث المتقدم',
                      onSecondaryPressed: () => context.push(
                        PharmacistSearchPrescriptionScreen.routePath,
                      ),
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
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                              ),
                              HbStatusChip(_statusLabel(prescription.status)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${prescription.employeeName} • ${prescription.doctorName}',
                          ),
                          const SizedBox(height: 10),
                          HbCustomButton(
                            label: 'فتح الوصفة',
                            icon: Icons.open_in_new_rounded,
                            onPressed: () async {
                              await context.push(
                                '${PharmacistPrescriptionDetailScreen.routePath}?id=${prescription.id}',
                              );
                              if (!context.mounted) return;
                              viewModel.refreshApprovedPrescriptions();
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

class PharmacistPrescriptionDetailScreen extends StatelessWidget {
  const PharmacistPrescriptionDetailScreen({super.key, this.prescriptionId});

  static const routeName = 'pharmacist-prescription-detail';
  static const routePath = '/pharmacist/prescriptions/detail';

  final int? prescriptionId;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => PharmacistPrescriptionDetailViewModel(
        appRepository: context.read<AppRepository>(),
        prescriptionId: prescriptionId,
      ),
      child: const _PharmacistPrescriptionDetailView(),
    );
  }
}

class _PharmacistPrescriptionDetailView extends StatelessWidget {
  const _PharmacistPrescriptionDetailView();

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<PharmacistPrescriptionDetailViewModel>();

    return HbScaffold(
      title: 'تفاصيل الوصفة للصيدلي',
      actions: _commonActions(context),
      body: viewModel.prescriptionId == null
          ? const HbEmptyState(
              title: 'لا توجد وصفة محددة',
              message: 'يرجى اختيار وصفة أولًا.',
            )
          : FutureBuilder<PrescriptionModel>(
              future: viewModel.prescriptionFuture!,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData) {
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
                          HbInfoRow(
                            label: 'رقم الوصفة',
                            value: prescription.prescriptionNumber,
                          ),
                          HbInfoRow(
                            label: 'اسم الموظف الجامعي',
                            value: prescription.employeeName,
                          ),
                          HbInfoRow(
                            label: 'اسم المستفيد',
                            value:
                                prescription.beneficiaryName ??
                                prescription.employeeName,
                          ),
                          HbInfoRow(
                            label: 'اسم الطبيب',
                            value: prescription.doctorName,
                          ),
                          if (prescription.serviceType != 'Medication')
                            HbInfoRow(
                              label: 'نوع الطلب',
                              value: prescription.serviceType,
                            ),
                          HbInfoRow(
                            label: 'الجهة المختارة',
                            value: prescription.providerName.isEmpty
                                ? 'غير محدد'
                                : prescription.providerName,
                          ),
                          HbInfoRow(
                            label: 'حالة التأمين',
                            value: prescription.requiresInsuranceApproval
                                ? 'يتطلب موافقة تأمينية'
                                : 'لا يتطلب موافقة مسبقة',
                          ),
                          HbInfoRow(
                            label: 'حالة الوصفة',
                            value: _statusLabel(prescription.status),
                          ),
                          HbInfoRow(
                            label: 'نسبة التغطية',
                            value:
                                '${prescription.coveragePercentage.toStringAsFixed(0)}%',
                          ),
                          HbInfoRow(
                            label: 'إجمالي السعر',
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
                            label: 'ملاحظات الطبيب',
                            value: prescription.notes.isEmpty
                                ? 'لا توجد ملاحظات'
                                : prescription.notes,
                          ),
                          HbInfoRow(
                            label: 'ملاحظات الجهة الطبية',
                            value: prescription.providerNotes.isEmpty
                                ? 'لا توجد ملاحظات'
                                : prescription.providerNotes,
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
                                  label: 'التفاصيل',
                                  value: prescription.serviceName.isEmpty
                                      ? 'لا توجد عناصر تفصيلية'
                                      : prescription.serviceName,
                                ),
                              ],
                            )
                          : Column(
                              children: prescription.items.map((item) {
                                return ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(item.medicationName),
                                  subtitle: Text(
                                    '${item.quantity} • ${item.duration}\n${item.dosageInstructions}',
                                  ),
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
                              viewModel.refresh();
                            },
                      child: Text(
                        canDispense
                            ? 'تأكيد صرف الدواء'
                            : 'الصرف متاح فقط للوصفات المعتمدة',
                      ),
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

class PharmacistDispenseConfirmScreen extends StatelessWidget {
  const PharmacistDispenseConfirmScreen({super.key, this.prescriptionId});

  static const routeName = 'pharmacist-dispense-confirm';
  static const routePath = '/pharmacist/dispense/confirm';

  final int? prescriptionId;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => PharmacistDispenseConfirmViewModel(
        appRepository: context.read<AppRepository>(),
        prescriptionId: prescriptionId,
      ),
      child: const _PharmacistDispenseConfirmView(),
    );
  }
}

class _PharmacistDispenseConfirmView extends StatelessWidget {
  const _PharmacistDispenseConfirmView();

  Future<void> _submit(
    BuildContext context,
    PrescriptionModel prescription,
  ) async {
    try {
      final message = await context
          .read<PharmacistDispenseConfirmViewModel>()
          .submit(prescription);
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
      context.pop(true);
    } on AppException catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<PharmacistDispenseConfirmViewModel>();

    if (viewModel.prescriptionId == null) {
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
        future: viewModel.prescriptionFuture!,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
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
              message:
                  'يمكن صرف الوصفات المعتمدة فقط. الحالة الحالية: ${_statusLabel(prescription.status)}',
              icon: Icons.lock_outline_rounded,
            );
          }

          return ListView(
            children: [
              HbSectionCard(
                title: 'ملخص الوصفة',
                child: Column(
                  children: [
                    HbInfoRow(
                      label: 'اسم الموظف الجامعي',
                      value: prescription.employeeName,
                    ),
                    HbInfoRow(
                      label: 'رقم الوصفة',
                      value: prescription.prescriptionNumber,
                    ),
                    const HbInfoRow(label: 'حالة الصرف', value: 'مكتمل'),
                    ...prescription.items.map(
                      (item) => HbInfoRow(
                        label: item.medicationName,
                        value: item.quantity,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: TextField(
                    controller: viewModel.notesController,
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
                primaryLabel: viewModel.isSubmitting
                    ? 'جاري التأكيد...'
                    : 'تأكيد الصرف',
                onPrimaryPressed: viewModel.isSubmitting
                    ? null
                    : () => _submit(context, prescription),
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

class PharmacistDispenseHistoryScreen extends StatelessWidget {
  const PharmacistDispenseHistoryScreen({super.key});

  static const routeName = 'pharmacist-dispense-history';
  static const routePath = '/pharmacist/dispense/history';

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => PharmacistDispenseHistoryViewModel(
        appRepository: context.read<AppRepository>(),
      ),
      child: const _PharmacistDispenseHistoryView(),
    );
  }
}

class _PharmacistDispenseHistoryView extends StatelessWidget {
  const _PharmacistDispenseHistoryView();

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<PharmacistDispenseHistoryViewModel>();

    return HbScaffold(
      title: 'سجل الصرف',
      actions: _commonActions(context),
      body: FutureBuilder<List<DispenseModel>>(
        future: viewModel.dispensesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return HbEmptyState(
              title: 'تعذر تحميل سجل الصرف',
              message: snapshot.error.toString(),
              icon: Icons.cloud_off_rounded,
            );
          }

          final items = viewModel.visibleDispenses(snapshot.data ?? const []);
          if (items.isEmpty) {
            return const HbEmptyState(
              title: 'لا توجد عمليات صرف',
              message: 'ستظهر هنا الوصفات التي تم صرفها بالكامل.',
              icon: Icons.receipt_long_rounded,
            );
          }

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
                            child: Text(
                              item.employeeName,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          HbStatusChip(_statusLabel(item.status)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      HbInfoRow(
                        label: 'تاريخ الصرف',
                        value: _formatDate(item.dispensedAt),
                      ),
                      HbInfoRow(
                        label: 'اسم الصيدلي',
                        value: item.pharmacistName,
                      ),
                      HbInfoRow(
                        label: 'الملاحظات',
                        value: item.notes.isEmpty
                            ? 'لا توجد ملاحظات'
                            : item.notes,
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: viewModel.refresh,
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
