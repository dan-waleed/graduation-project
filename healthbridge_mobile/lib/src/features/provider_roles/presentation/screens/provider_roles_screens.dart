import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../data/models/app_models.dart';
import '../../../../data/services/app_data_service.dart';
import '../../../../features/common/presentation/screens/notifications_screen.dart';
import '../../../../features/common/presentation/screens/profile_screen.dart';
import '../../../../shared/utils/status_label.dart';
import '../../../../shared/widgets/hb_custom_button.dart';
import '../../../../shared/widgets/hb_custom_card.dart';
import '../../../../shared/widgets/hb_dashboard_overview.dart';
import '../../../../shared/widgets/hb_empty_state.dart';
import '../../../../shared/widgets/hb_info_row.dart';
import '../../../../shared/widgets/hb_notification_action.dart';
import '../../../../shared/widgets/hb_quick_action_card.dart';
import '../../../../shared/widgets/hb_scaffold.dart';
import '../../../../shared/widgets/hb_section_card.dart';
import '../../../../shared/widgets/hb_status_chip.dart';

class LaboratoryHomeScreen extends StatelessWidget {
  const LaboratoryHomeScreen({super.key});

  static const routeName = 'laboratory-home';
  static const routePath = '/laboratory';

  @override
  Widget build(BuildContext context) {
    return const _ProviderHomeTemplate(
      config: _laboratoryConfig,
    );
  }
}

class MedicalImagingCenterHomeScreen extends StatelessWidget {
  const MedicalImagingCenterHomeScreen({super.key});

  static const routeName = 'imaging-center-home';
  static const routePath = '/imaging-center';

  @override
  Widget build(BuildContext context) {
    return const _ProviderHomeTemplate(
      config: _imagingConfig,
    );
  }
}

class MedicalCenterHomeScreen extends StatelessWidget {
  const MedicalCenterHomeScreen({super.key});

  static const routeName = 'medical-center-home';
  static const routePath = '/medical-center';

  @override
  Widget build(BuildContext context) {
    return const _ProviderHomeTemplate(
      config: _medicalCenterConfig,
    );
  }
}

class _ProviderHomeTemplate extends StatelessWidget {
  const _ProviderHomeTemplate({
    required this.config,
  });

  final _ProviderDashboardConfig config;

  @override
  Widget build(BuildContext context) {
    return HbScaffold(
      title: config.title,
      actions: _commonActions(context),
      body: FutureBuilder<List<PrescriptionModel>>(
        future: context.read<AppDataService>().getPrescriptions(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return HbEmptyState(
              title: 'تعذر تحميل لوحة التحكم',
              message: snapshot.error.toString(),
              icon: Icons.cloud_off_rounded,
            );
          }

          final allOrders = snapshot.data ?? const [];
          final orders = config.filterOrders(allOrders);
          final pendingOrders = orders.where((item) => _isPendingStatus(item.status)).toList();
          final completedOrders = orders.where((item) => item.status == 'Performed').toList();
          final rejectedOrders = orders.where((item) => item.status == 'Rejected').toList();
          final approvalOrders =
              orders.where((item) => item.requiresInsuranceApproval).toList();
          final recentOrders = [...orders]
            ..sort((a, b) => (b.issuedAt ?? DateTime(1970)).compareTo(a.issuedAt ?? DateTime(1970)));

          return ListView(
            children: [
              HbDashboardOverview(
                recentTitle: config.recentTitle,
                emptyMessage: 'ستظهر هنا أحدث الطلبات والتنبيهات المرتبطة بجهتك الطبية.',
              ),
              const SizedBox(height: 16),
              HbSectionCard(
                title: 'ملخص تشغيلي',
                subtitle: config.summarySubtitle,
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _ProviderSummaryTile(
                      label: 'إجمالي الطلبات',
                      value: orders.length.toString(),
                      icon: Icons.assignment_rounded,
                    ),
                    _ProviderSummaryTile(
                      label: 'بانتظار التنفيذ',
                      value: pendingOrders.length.toString(),
                      icon: Icons.pending_actions_rounded,
                    ),
                    _ProviderSummaryTile(
                      label: 'تم التنفيذ',
                      value: completedOrders.length.toString(),
                      icon: Icons.task_alt_rounded,
                    ),
                    _ProviderSummaryTile(
                      label: 'تحتاج تأمين',
                      value: approvalOrders.length.toString(),
                      icon: Icons.health_and_safety_outlined,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              HbSectionCard(
                title: 'إجراءات سريعة',
                subtitle: 'أكثر الإجراءات استخدامًا داخل ${config.title}.',
                child: Column(
                  children: [
                    HbQuickActionCard(
                      title: config.requestLabel,
                      subtitle: config.requestSubtitle,
                      icon: config.primaryIcon,
                      onTap: () => context.push(config.detailRoute),
                    ),
                    const SizedBox(height: 12),
                    HbQuickActionCard(
                      title: config.extraActionTitle,
                      subtitle: config.extraActionSubtitle,
                      icon: config.secondaryIcon,
                      onTap: () => context.push(NotificationsScreen.routePath),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              HbSectionCard(
                title: 'قائمة الأولويات',
                subtitle: 'طلبات تتطلب انتباهًا سريعًا من الفريق.',
                child: pendingOrders.isEmpty
                    ? const HbEmptyState(
                        title: 'لا توجد أولويات عاجلة',
                        message: 'جميع الطلبات الحالية إما منفذة أو لا تحتاج إجراء فوري.',
                        icon: Icons.check_circle_outline_rounded,
                      )
                    : Column(
                        children: pendingOrders.take(3).map((order) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _PriorityRequestTile(
                              order: order,
                              ctaLabel: 'فتح الطلب',
                              onTap: () => context.push('${config.detailRoutePath}?id=${order.id}'),
                            ),
                          );
                        }).toList(),
                      ),
              ),
              const SizedBox(height: 16),
              HbSectionCard(
                title: 'جاهزية التشغيل',
                subtitle: 'مؤشرات تشغيلية مساعدة لتسيير العمل اليومي.',
                child: Column(
                  children: [
                    _OperationalInfoRow(
                      label: 'الخدمات النشطة',
                      value: () {
                        final services = _uniqueServiceNames(orders).join('، ');
                        return services.isEmpty ? config.requestLabel : services;
                      }(),
                    ),
                    _OperationalInfoRow(
                      label: 'الطلبات المرفوضة',
                      value: '${rejectedOrders.length} طلب',
                    ),
                    _OperationalInfoRow(
                      label: 'آخر تنفيذ',
                      value: recentOrders
                          .where((item) => item.performedAt != null)
                          .map((item) => item.prescriptionNumber)
                          .cast<String?>()
                          .firstWhere((item) => item != null, orElse: () => 'لا يوجد')
                          .toString(),
                    ),
                    _OperationalInfoRow(
                      label: 'توصية اليوم',
                      value: config.dailyAdvice,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              HbSectionCard(
                title: 'آخر الطلبات',
                subtitle: 'آخر المعاملات المرتبطة بدورك داخل النظام.',
                child: recentOrders.isEmpty
                    ? const HbEmptyState(
                        title: 'لا توجد طلبات حديثة',
                        message: 'ستظهر هنا آخر الطلبات بمجرد توفرها.',
                        icon: Icons.assignment_late_outlined,
                      )
                    : Column(
                        children: recentOrders.take(4).map((order) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _RecentRequestTile(
                              order: order,
                              accentColor: config.accentColor,
                              onTap: () => context.push('${config.detailRoutePath}?id=${order.id}'),
                            ),
                          );
                        }).toList(),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class LaboratoryRequestsScreen extends StatelessWidget {
  const LaboratoryRequestsScreen({super.key});

  static const routeName = 'laboratory-requests';
  static const routePath = '/laboratory/requests';

  @override
  Widget build(BuildContext context) {
    return const _ProviderRequestsScreen(
      title: 'طلبات المختبر',
      detailRoutePath: LaboratoryRequestDetailScreen.routePath,
    );
  }
}

class ImagingRequestsScreen extends StatelessWidget {
  const ImagingRequestsScreen({super.key});

  static const routeName = 'imaging-requests';
  static const routePath = '/imaging-center/requests';

  @override
  Widget build(BuildContext context) {
    return const _ProviderRequestsScreen(
      title: 'طلبات التصوير الطبي',
      detailRoutePath: ImagingRequestDetailScreen.routePath,
    );
  }
}

class MedicalCenterRequestsScreen extends StatelessWidget {
  const MedicalCenterRequestsScreen({super.key});

  static const routeName = 'medical-center-requests';
  static const routePath = '/medical-center/requests';

  @override
  Widget build(BuildContext context) {
    return const _ProviderRequestsScreen(
      title: 'طلبات المركز الطبي',
      detailRoutePath: MedicalCenterRequestDetailScreen.routePath,
    );
  }
}

class _ProviderRequestsScreen extends StatefulWidget {
  const _ProviderRequestsScreen({
    required this.title,
    required this.detailRoutePath,
  });

  final String title;
  final String detailRoutePath;

  @override
  State<_ProviderRequestsScreen> createState() => _ProviderRequestsScreenState();
}

class _ProviderRequestsScreenState extends State<_ProviderRequestsScreen> {
  late Future<List<PrescriptionModel>> _ordersFuture;

  @override
  void initState() {
    super.initState();
    _ordersFuture = _loadOrders();
  }

  Future<List<PrescriptionModel>> _loadOrders() {
    return context.read<AppDataService>().getPrescriptions();
  }

  void _refresh() {
    setState(() {
      _ordersFuture = _loadOrders();
    });
  }

  @override
  Widget build(BuildContext context) {
    return HbScaffold(
      title: widget.title,
      actions: _commonActions(context),
      body: FutureBuilder<List<PrescriptionModel>>(
        future: _ordersFuture,
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
          final orders = snapshot.data ?? const [];
          if (orders.isEmpty) {
            return const HbEmptyState(
              title: 'لا توجد طلبات حاليًا',
              message: 'ستظهر هنا الطلبات الطبية المرسلة إلى جهتك.',
              icon: Icons.assignment_late_outlined,
            );
          }
          return ListView.separated(
            itemCount: orders.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final order = orders[index];
              return HbCustomCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(order.prescriptionNumber, style: Theme.of(context).textTheme.titleMedium),
                        ),
                        HbStatusChip(statusLabel(order.status)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    HbInfoRow(label: 'اسم الموظف الجامعي', value: order.employeeName),
                    HbInfoRow(label: 'اسم المستفيد', value: order.beneficiaryName ?? order.employeeName),
                    HbInfoRow(label: 'اسم الطبيب', value: order.doctorName),
                    HbInfoRow(label: 'نوع الخدمة', value: order.serviceType),
                    HbInfoRow(label: 'السعر الأصلي', value: order.finalPrice.toStringAsFixed(2)),
                    HbInfoRow(label: 'نسبة التغطية', value: '${order.coveragePercentage.toStringAsFixed(0)}%'),
                    HbInfoRow(label: 'المبلغ المغطى', value: order.coveredAmount.toStringAsFixed(2)),
                    HbInfoRow(label: 'حصة الموظف', value: order.employeeShare.toStringAsFixed(2)),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        onPressed: () async {
                          await context.push('${widget.detailRoutePath}?id=${order.id}');
                          if (!context.mounted) return;
                          unawaited(Future<void>.microtask(_refresh));
                        },
                        child: const Text('عرض التفاصيل'),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class LaboratoryRequestDetailScreen extends StatelessWidget {
  const LaboratoryRequestDetailScreen({super.key, this.orderId});

  static const routeName = 'laboratory-request-detail';
  static const routePath = '/laboratory/requests/detail';

  final int? orderId;

  @override
  Widget build(BuildContext context) {
    return _ProviderRequestDetailScreen(
      orderId: orderId,
      title: 'تفاصيل طلب المختبر',
      completeStatus: 'Performed',
      completeLabel: 'تأكيد تنفيذ الفحص',
      rejectLabel: 'رفض الطلب',
    );
  }
}

class ImagingRequestDetailScreen extends StatelessWidget {
  const ImagingRequestDetailScreen({super.key, this.orderId});

  static const routeName = 'imaging-request-detail';
  static const routePath = '/imaging-center/requests/detail';

  final int? orderId;

  @override
  Widget build(BuildContext context) {
    return _ProviderRequestDetailScreen(
      orderId: orderId,
      title: 'تفاصيل طلب التصوير الطبي',
      completeStatus: 'Performed',
      completeLabel: 'تأكيد تنفيذ الخدمة',
      rejectLabel: 'رفض الطلب',
    );
  }
}

class MedicalCenterRequestDetailScreen extends StatelessWidget {
  const MedicalCenterRequestDetailScreen({super.key, this.orderId});

  static const routeName = 'medical-center-request-detail';
  static const routePath = '/medical-center/requests/detail';

  final int? orderId;

  @override
  Widget build(BuildContext context) {
    return _ProviderRequestDetailScreen(
      orderId: orderId,
      title: 'تفاصيل الطلب الطبي',
      completeStatus: 'Performed',
      completeLabel: 'تأكيد التنفيذ',
      rejectLabel: 'رفض الطلب',
    );
  }
}

class _ProviderRequestDetailScreen extends StatefulWidget {
  const _ProviderRequestDetailScreen({
    required this.orderId,
    required this.title,
    required this.completeStatus,
    required this.completeLabel,
    required this.rejectLabel,
  });

  final int? orderId;
  final String title;
  final String completeStatus;
  final String completeLabel;
  final String rejectLabel;

  @override
  State<_ProviderRequestDetailScreen> createState() => _ProviderRequestDetailScreenState();
}

class _ProviderRequestDetailScreenState extends State<_ProviderRequestDetailScreen> {
  final _notesController = TextEditingController();
  bool _isSubmitting = false;
  late Future<PrescriptionModel> _orderFuture;

  @override
  void initState() {
    super.initState();
    _orderFuture = _loadOrder();
  }

  Future<PrescriptionModel> _loadOrder() {
    return context.read<AppDataService>().getPrescription(widget.orderId!);
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _updateStatus(BuildContext context, int id, String status) async {
    setState(() => _isSubmitting = true);
    try {
      await context.read<AppDataService>().updatePrescriptionStatus(
        id: id,
        status: status,
        providerNotes: _notesController.text.trim(),
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(status == 'Performed' ? 'تم تحديث الحالة إلى تم التنفيذ' : 'تم رفض الطلب')),
      );
      context.pop(true);
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.orderId == null) {
      return HbScaffold(
        title: widget.title,
        body: const HbEmptyState(
          title: 'لا يوجد طلب محدد',
          message: 'يرجى اختيار طلب أولًا.',
        ),
      );
    }

    return HbScaffold(
      title: widget.title,
      actions: _commonActions(context),
      body: FutureBuilder<PrescriptionModel>(
        future: _orderFuture,
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
          final order = snapshot.data;
          if (order == null) {
            return const HbEmptyState(
              title: 'الطلب غير متوفر',
              message: 'تعذر العثور على بيانات الطلب المطلوبة.',
            );
          }
          return ListView(
            children: [
              HbSectionCard(
                title: 'معلومات الطلب',
                child: Column(
                  children: [
                    HbInfoRow(label: 'رقم الطلب', value: order.prescriptionNumber),
                    HbInfoRow(label: 'اسم الموظف الجامعي', value: order.employeeName),
                    HbInfoRow(label: 'اسم المستفيد', value: order.beneficiaryName ?? order.employeeName),
                    HbInfoRow(label: 'اسم الطبيب', value: order.doctorName),
                    HbInfoRow(label: 'نوع الخدمة', value: order.serviceType),
                    HbInfoRow(label: 'حالة التأمين', value: order.requiresInsuranceApproval ? 'تحتاج مراجعة تأمينية' : 'لا تحتاج موافقة مسبقة'),
                    HbInfoRow(label: 'الحالة الحالية', value: statusLabel(order.status)),
                    HbInfoRow(label: 'السعر الأصلي', value: order.finalPrice.toStringAsFixed(2)),
                    HbInfoRow(label: 'نسبة التغطية', value: '${order.coveragePercentage.toStringAsFixed(0)}%'),
                    HbInfoRow(label: 'المبلغ المغطى', value: order.coveredAmount.toStringAsFixed(2)),
                    HbInfoRow(label: 'حصة الموظف', value: order.employeeShare.toStringAsFixed(2)),
                    HbInfoRow(label: 'ملاحظات الطبيب', value: order.notes.isEmpty ? 'لا توجد ملاحظات' : order.notes),
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
                      labelText: 'ملاحظات الجهة الطبية',
                      hintText: 'أضف أي ملاحظات مرتبطة بتنفيذ الطلب أو رفضه',
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              HbCustomButton(
                label: _isSubmitting ? 'جارٍ التحديث...' : widget.completeLabel,
                icon: Icons.check_circle_outline_rounded,
                onPressed: _isSubmitting ? null : () => _updateStatus(context, order.id, widget.completeStatus),
              ),
              const SizedBox(height: 12),
              HbCustomButton(
                label: widget.rejectLabel,
                icon: Icons.cancel_outlined,
                onPressed: _isSubmitting ? null : () => _updateStatus(context, order.id, 'Rejected'),
                variant: HbButtonVariant.outline,
              ),
            ],
          );
        },
      ),
    );
  }
}

const _laboratoryConfig = _ProviderDashboardConfig(
  title: 'لوحة المختبر',
  recentTitle: 'آخر طلبات المختبر',
  requestLabel: 'طلبات المختبر',
  requestSubtitle: 'استعراض الطلبات الطبية المخبرية المرسلة إليك.',
  detailRoute: LaboratoryRequestsScreen.routePath,
  detailRoutePath: LaboratoryRequestDetailScreen.routePath,
  primaryIcon: Icons.science_outlined,
  secondaryIcon: Icons.fact_check_outlined,
  summarySubtitle: 'متابعة الفحوصات، الأولويات، وحالة تنفيذ العينات في مكان واحد.',
  extraActionTitle: 'مراجعة الإشعارات',
  extraActionSubtitle: 'متابعة التنبيهات الجديدة المرتبطة بالعينات والتقارير.',
  dailyAdvice: 'رتّب العينات حسب الوقت والحالة لتقليل زمن الانتظار.',
  accentColor: Color(0xFF0E8A72),
  filterOrders: _filterLaboratoryOrders,
);

const _imagingConfig = _ProviderDashboardConfig(
  title: 'لوحة مركز التصوير الطبي',
  recentTitle: 'آخر طلبات التصوير الطبي',
  requestLabel: 'طلبات التصوير',
  requestSubtitle: 'استعراض طلبات الأشعة والتصوير الطبي المرسلة إليك.',
  detailRoute: ImagingRequestsScreen.routePath,
  detailRoutePath: ImagingRequestDetailScreen.routePath,
  primaryIcon: Icons.perm_media_outlined,
  secondaryIcon: Icons.calendar_month_rounded,
  summarySubtitle: 'تنظيم المواعيد، متابعة الطلبات، ومراجعة ضغط العمل اليومي.',
  extraActionTitle: 'متابعة الحالات العاجلة',
  extraActionSubtitle: 'استخدم الإشعارات لمراجعة الطلبات التي تحتاج استجابة أسرع.',
  dailyAdvice: 'أكّد المواعيد المبكرة أولًا ثم راجع الطلبات التي تتطلب موافقة تأمينية.',
  accentColor: Color(0xFF2E6FBE),
  filterOrders: _filterImagingOrders,
);

const _medicalCenterConfig = _ProviderDashboardConfig(
  title: 'لوحة المركز الطبي',
  recentTitle: 'آخر الطلبات الطبية',
  requestLabel: 'الطلبات الطبية',
  requestSubtitle: 'استعراض طلبات الإجراءات والاستشارات المرسلة إليك.',
  detailRoute: MedicalCenterRequestsScreen.routePath,
  detailRoutePath: MedicalCenterRequestDetailScreen.routePath,
  primaryIcon: Icons.local_hospital_outlined,
  secondaryIcon: Icons.medical_information_outlined,
  summarySubtitle: 'عرض شامل للإجراءات، المتابعة السريرية، وحالة التشغيل داخل المركز.',
  extraActionTitle: 'سجل التنبيهات الطبية',
  extraActionSubtitle: 'مراجعة التنبيهات والتحديثات المرتبطة بإجراءات المركز الطبي.',
  dailyAdvice: 'ثبّت الملاحظات السريرية على كل طلب منفذ لضمان تتبع أفضل.',
  accentColor: Color(0xFFB76A1B),
  filterOrders: _filterMedicalCenterOrders,
);

class _ProviderDashboardConfig {
  const _ProviderDashboardConfig({
    required this.title,
    required this.recentTitle,
    required this.requestLabel,
    required this.requestSubtitle,
    required this.detailRoute,
    required this.detailRoutePath,
    required this.primaryIcon,
    required this.secondaryIcon,
    required this.summarySubtitle,
    required this.extraActionTitle,
    required this.extraActionSubtitle,
    required this.dailyAdvice,
    required this.accentColor,
    required this.filterOrders,
  });

  final String title;
  final String recentTitle;
  final String requestLabel;
  final String requestSubtitle;
  final String detailRoute;
  final String detailRoutePath;
  final IconData primaryIcon;
  final IconData secondaryIcon;
  final String summarySubtitle;
  final String extraActionTitle;
  final String extraActionSubtitle;
  final String dailyAdvice;
  final Color accentColor;
  final List<PrescriptionModel> Function(List<PrescriptionModel>) filterOrders;
}

List<PrescriptionModel> _filterLaboratoryOrders(List<PrescriptionModel> orders) {
  return orders.where((order) {
    final combined = '${order.serviceType} ${order.providerName} ${order.serviceName}'.toLowerCase();
    return combined.contains('laboratory') ||
        combined.contains('مختبر') ||
        combined.contains('lab') ||
        combined.contains('cbc') ||
        combined.contains('culture');
  }).toList();
}

List<PrescriptionModel> _filterImagingOrders(List<PrescriptionModel> orders) {
  return orders.where((order) {
    final combined = '${order.serviceType} ${order.providerName} ${order.serviceName}'.toLowerCase();
    return combined.contains('imaging') ||
        combined.contains('تصوير') ||
        combined.contains('x-ray') ||
        combined.contains('mri') ||
        combined.contains('ray');
  }).toList();
}

List<PrescriptionModel> _filterMedicalCenterOrders(List<PrescriptionModel> orders) {
  return orders.where((order) {
    final combined = '${order.serviceType} ${order.providerName} ${order.serviceName}'.toLowerCase();
    return combined.contains('medicalcenter') ||
        combined.contains('medical center') ||
        combined.contains('المركز الطبي') ||
        combined.contains('therapy') ||
        combined.contains('procedure');
  }).toList();
}

bool _isPendingStatus(String status) {
  return status == 'Approved' || status == 'PendingInsuranceApproval' || status == 'Submitted';
}

List<String> _uniqueServiceNames(List<PrescriptionModel> orders) {
  final names = <String>{};
  for (final order in orders) {
    final serviceName = order.serviceName.trim().isEmpty ? order.serviceType.trim() : order.serviceName.trim();
    if (serviceName.isNotEmpty) {
      names.add(serviceName);
    }
  }
  return names.toList();
}

class _ProviderSummaryTile extends StatelessWidget {
  const _ProviderSummaryTile({
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
      width: 160,
      child: HbCustomCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 10),
            Text(value, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 4),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _PriorityRequestTile extends StatelessWidget {
  const _PriorityRequestTile({
    required this.order,
    required this.ctaLabel,
    required this.onTap,
  });

  final PrescriptionModel order;
  final String ctaLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return HbCustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(order.prescriptionNumber, style: Theme.of(context).textTheme.titleMedium),
              ),
              HbStatusChip(statusLabel(order.status)),
            ],
          ),
          const SizedBox(height: 8),
          Text(order.employeeName, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 4),
          Text(
            order.serviceName.isEmpty ? order.serviceType : order.serviceName,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  order.requiresInsuranceApproval ? 'يتطلب موافقة تأمينية' : 'جاهز للمعالجة',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              TextButton(
                onPressed: onTap,
                child: Text(ctaLabel),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OperationalInfoRow extends StatelessWidget {
  const _OperationalInfoRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: HbInfoRow(label: label, value: value),
    );
  }
}

class _RecentRequestTile extends StatelessWidget {
  const _RecentRequestTile({
    required this.order,
    required this.accentColor,
    required this.onTap,
  });

  final PrescriptionModel order;
  final Color accentColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: accentColor.withValues(alpha: 0.22)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 12,
              height: 56,
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(order.prescriptionNumber, style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 4),
                  Text(order.employeeName, style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 4),
                  Text(
                    order.serviceName.isEmpty ? order.serviceType : order.serviceName,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            HbStatusChip(statusLabel(order.status)),
          ],
        ),
      ),
    );
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
