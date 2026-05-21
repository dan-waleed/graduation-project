import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../data/models/app_models.dart';
import '../../../../data/services/app_data_service.dart';
import '../../../../features/auth/presentation/controller/auth_controller.dart';
import '../../../../features/common/presentation/controller/notification_center_controller.dart';
import '../../../../features/doctor/presentation/screens/doctor_home_screen.dart';
import '../../../../features/insurance_officer/presentation/screens/insurance_officer_home_screen.dart';
import '../../../../features/patient/presentation/screens/patient_home_screen.dart';
import '../../../../features/pharmacist/presentation/screens/pharmacist_home_screen.dart';
import '../../../../features/provider_roles/presentation/screens/provider_roles_screens.dart';
import '../../../../shared/widgets/hb_custom_card.dart';
import '../../../../shared/widgets/hb_empty_state.dart';
import '../../../../shared/widgets/hb_scaffold.dart';
import '../../../../shared/widgets/hb_status_chip.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  static const routeName = 'notifications';
  static const routePath = '/notifications';

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _showUnreadOnly = false;
  bool _isLoading = true;
  bool _isRefreshing = false;
  bool _isBulkUpdating = false;
  final Set<int> _optimisticReadIds = <int>{};
  List<NotificationModel> _notifications = const [];
  Object? _loadError;
  int _loadRequestId = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    unawaited(_refreshNotifications(showLoader: true));
    _timer = Timer.periodic(
      const Duration(seconds: 20),
      (_) => unawaited(_refreshNotifications()),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<List<NotificationModel>> _loadNotifications() {
    return _showUnreadOnly
        ? context.read<AppDataService>().getUnreadNotifications()
        : context.read<AppDataService>().getNotifications();
  }

  Future<void> _refreshNotifications({bool showLoader = false}) async {
    final requestId = ++_loadRequestId;
    if (mounted) {
      setState(() {
        _loadError = null;
        if (showLoader) {
          _isLoading = true;
        } else {
          _isRefreshing = true;
        }
      });
    }

    try {
      final items = await _loadNotifications();
      if (!mounted || requestId != _loadRequestId) return;
      setState(() {
        _notifications = items;
        _optimisticReadIds.removeWhere(
          (id) => !items.any((item) => item.id == id),
        );
        _isLoading = false;
        _isRefreshing = false;
      });
    } catch (error) {
      if (!mounted || requestId != _loadRequestId) return;
      setState(() {
        _loadError = error;
        _isLoading = false;
        _isRefreshing = false;
      });
    }
  }

  Future<void> _markAllRead() async {
    final appDataService = context.read<AppDataService>();
    final notificationCenter = context.read<NotificationCenterController>();
    if (mounted) {
      setState(() {
        _optimisticReadIds.addAll(_notifications.map((item) => item.id));
        _isBulkUpdating = true;
      });
    }
    notificationCenter.markAllReadLocally();

    try {
      await appDataService.markAllNotificationsRead();
      if (!mounted) return;
      await notificationCenter.refreshUnreadCount();
      await _refreshNotifications();
    } finally {
      if (mounted) {
        setState(() => _isBulkUpdating = false);
      }
    }
  }

  Future<void> _openNotification(NotificationModel item) async {
    final notificationCenter = context.read<NotificationCenterController>();
    Future<void>? markReadFuture;

    if (!item.isRead) {
      setState(() {
        _optimisticReadIds.add(item.id);
      });
      notificationCenter.markOneReadLocally(item.id);
      markReadFuture = _markNotificationRead(item.id);
    }

    if (!mounted) return;
    await _navigateToRelatedEntity(item);
    if (markReadFuture != null) {
      try {
        await markReadFuture;
      } catch (_) {
        if (!mounted) return;
        await _refreshNotifications();
      }
    }
    if (!mounted) return;
    await notificationCenter.refreshUnreadCount(silent: true);
    await _refreshNotifications();
  }

  Future<void> _markNotificationRead(int notificationId) async {
    final appDataService = context.read<AppDataService>();
    try {
      await appDataService.markNotificationRead(notificationId);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _optimisticReadIds.remove(notificationId);
      });
      await context.read<NotificationCenterController>().refreshUnreadCount();
      rethrow;
    }
  }

  Future<void> _navigateToRelatedEntity(NotificationModel item) async {
    final appDataService = context.read<AppDataService>();
    final authController = context.read<AuthController>();
    final relatedId = int.tryParse(item.relatedEntityId);
    final currentRole = authController.currentUser?.role ?? '';
    if (item.relatedEntityType == 'Prescription' && relatedId != null) {
      switch (currentRole) {
        case 'Doctor':
          context.push('${DoctorPrescriptionDetailScreen.routePath}?id=$relatedId');
        case 'Pharmacist':
          context.push('${PharmacistPrescriptionDetailScreen.routePath}?id=$relatedId');
        default:
          context.push('${PatientPrescriptionDetailScreen.routePath}?id=$relatedId');
      }
      return;
    }
    if (item.relatedEntityType == 'InsuranceRequest' && relatedId != null) {
      if (currentRole == 'InsuranceOfficer') {
        context.push('${InsuranceReviewScreen.routePath}?id=$relatedId');
        return;
      }
      final requests = await appDataService.getInsuranceRequests();
      final matchingRequests = requests.where((item) => item.id == relatedId).toList();
      final match = matchingRequests.isEmpty ? null : matchingRequests.first;
      if (!mounted) return;
      if (match != null) {
        switch (currentRole) {
          case 'Doctor':
            context.push('${DoctorPrescriptionDetailScreen.routePath}?id=${match.prescriptionId}');
          default:
            context.push('${PatientPrescriptionDetailScreen.routePath}?id=${match.prescriptionId}');
        }
        return;
      }
    }
    if (item.relatedEntityType == 'Dispense' && relatedId != null) {
      final dispenses = await appDataService.getDispenses();
      final matchingDispenses = dispenses.where((item) => item.id == relatedId).toList();
      final match = matchingDispenses.isEmpty ? null : matchingDispenses.first;
      if (!mounted) return;
      if (match != null) {
        switch (currentRole) {
          case 'Pharmacist':
            context.push('${PharmacistPrescriptionDetailScreen.routePath}?id=${match.prescriptionId}');
          default:
            context.push('${PatientPrescriptionDetailScreen.routePath}?id=${match.prescriptionId}');
        }
        return;
      }
    }
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('تفاصيل الإشعار'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              Text(item.message),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('إغلاق'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return HbScaffold(
      title: 'الإشعارات',
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _loadError != null
              ? HbEmptyState(
                  title: 'تعذر تحميل الإشعارات',
                  message: _loadError.toString(),
                  icon: Icons.cloud_off_rounded,
                )
              : ListView(
                  children: [
                    HbCustomCard(
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'مركز الإشعارات',
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  _showUnreadOnly
                                      ? 'يتم الآن عرض الإشعارات غير المقروءة فقط.'
                                      : 'يمكنك مراجعة جميع الإشعارات أو فتح غير المقروء فقط.',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          Switch.adaptive(
                            value: _showUnreadOnly,
                            onChanged: (value) {
                              setState(() => _showUnreadOnly = value);
                              unawaited(_refreshNotifications());
                            },
                          ),
                        ],
                      ),
                    ),
                    if (_isRefreshing) ...const [
                      SizedBox(height: 12),
                      LinearProgressIndicator(),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _refreshNotifications,
                            icon: const Icon(Icons.refresh_rounded),
                            label: const Text('تحديث'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isBulkUpdating ? null : _markAllRead,
                            icon: const Icon(Icons.done_all_rounded),
                            label: Text(_isBulkUpdating ? 'جارٍ التحديث...' : 'تحديد الكل كمقروء'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (_notifications.isEmpty)
                      const HbEmptyState(
                        title: 'لا توجد إشعارات حاليًا',
                        message: 'ستظهر هنا إشعارات الطلبات الطبية والتأمين والصرف والتحديثات العامة.',
                        icon: Icons.notifications_none_rounded,
                      )
                    else
                      ..._notifications.map((item) {
                        final isSeen = item.isRead || _optimisticReadIds.contains(item.id);
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: InkWell(
                            onTap: () => _openNotification(item),
                            borderRadius: BorderRadius.circular(20),
                            child: Card(
                              color: isSeen ? null : AppTheme.primary.withValues(alpha: 0.04),
                              child: Padding(
                                padding: const EdgeInsets.all(18),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            color: isSeen
                                                ? AppTheme.border
                                                : AppTheme.primary.withValues(alpha: 0.12),
                                            borderRadius: BorderRadius.circular(14),
                                          ),
                                          child: Icon(
                                            isSeen
                                                ? Icons.notifications_none_rounded
                                                : Icons.notifications_active_rounded,
                                            color: isSeen ? AppTheme.muted : AppTheme.primary,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                item.title,
                                                style: Theme.of(context).textTheme.titleMedium,
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                item.message,
                                                style: Theme.of(context).textTheme.bodyMedium,
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        HbStatusChip(isSeen ? 'مقروء' : 'غير مقروء'),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: [
                                        HbStatusChip(item.notificationType),
                                        if (item.relatedEntityType.isNotEmpty)
                                          HbStatusChip(item.relatedEntityType),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      item.createdAt == null
                                          ? 'غير محدد'
                                          : DateFormat('yyyy/MM/dd - HH:mm')
                                              .format(item.createdAt!.toLocal()),
                                      style: Theme.of(context).textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                  ],
                ),
    );
  }
}
