import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:healthbridge_mobile/model/models/app_models.dart';
import 'package:healthbridge_mobile/model/repositories/app_repository.dart';
import 'package:healthbridge_mobile/modelView/features/auth/auth_view_model.dart';
import 'package:healthbridge_mobile/modelView/features/common/notification_center_view_model.dart';
import 'package:healthbridge_mobile/modelView/features/common/notifications_view_model.dart';
import 'package:healthbridge_mobile/view/theme/app_theme.dart';
import 'package:healthbridge_mobile/view/widgets/hb_custom_card.dart';
import 'package:healthbridge_mobile/view/widgets/hb_empty_state.dart';
import 'package:healthbridge_mobile/view/widgets/hb_scaffold.dart';
import 'package:healthbridge_mobile/view/widgets/hb_status_chip.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  static const routeName = 'notifications';
  static const routePath = '/notifications';

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => NotificationsViewModel(
        appRepository: context.read<AppRepository>(),
        notificationCenterViewModel: context
            .read<NotificationCenterViewModel>(),
      )..initialize(),
      child: const _NotificationsScreenView(),
    );
  }
}

class _NotificationsScreenView extends StatelessWidget {
  const _NotificationsScreenView();

  Future<void> _openNotification(
    BuildContext context,
    NotificationModel item,
  ) async {
    final viewModel = context.read<NotificationsViewModel>();
    final currentRole = context.read<AuthViewModel>().currentUser?.role ?? '';
    final markReadFuture = viewModel.beginOpenNotification(item);
    final target = await viewModel.resolveNavigationTarget(item, currentRole);

    if (!context.mounted) return;
    if (target.hasRoute) {
      await context.push(target.routePath!);
    } else {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('تفاصيل الإشعار'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  target.dialogTitle ?? item.title,
                  style: Theme.of(dialogContext).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                Text(target.dialogMessage ?? item.message),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('إغلاق'),
              ),
            ],
          );
        },
      );
    }

    if (markReadFuture != null) {
      try {
        await markReadFuture;
      } catch (_) {
        if (!context.mounted) return;
        await viewModel.refreshNotifications();
      }
    }

    if (!context.mounted) return;
    await viewModel.completeNotificationOpen();
  }

  Future<void> _markAllRead(BuildContext context) async {
    try {
      await context.read<NotificationsViewModel>().markAllRead();
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<NotificationsViewModel>();

    return HbScaffold(
      title: 'الإشعارات',
      body: viewModel.isLoading
          ? const Center(child: CircularProgressIndicator())
          : viewModel.loadError != null
          ? HbEmptyState(
              title: 'تعذر تحميل الإشعارات',
              message: viewModel.loadError.toString(),
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
                              viewModel.showUnreadOnly
                                  ? 'يتم الآن عرض الإشعارات غير المقروءة فقط.'
                                  : 'يمكنك مراجعة جميع الإشعارات أو فتح غير المقروء فقط.',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      Switch.adaptive(
                        value: viewModel.showUnreadOnly,
                        onChanged: viewModel.toggleUnreadOnly,
                      ),
                    ],
                  ),
                ),
                if (viewModel.isRefreshing) ...const [
                  SizedBox(height: 12),
                  LinearProgressIndicator(),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => viewModel.refreshNotifications(),
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('تحديث'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: viewModel.isBulkUpdating
                            ? null
                            : () => _markAllRead(context),
                        icon: const Icon(Icons.done_all_rounded),
                        label: Text(
                          viewModel.isBulkUpdating
                              ? 'جارٍ التحديث...'
                              : 'تحديد الكل كمقروء',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (viewModel.notifications.isEmpty)
                  const HbEmptyState(
                    title: 'لا توجد إشعارات حاليًا',
                    message:
                        'ستظهر هنا إشعارات الطلبات الطبية والتأمين والصرف والتحديثات العامة.',
                    icon: Icons.notifications_none_rounded,
                  )
                else
                  ...viewModel.notifications.map((item) {
                    final isSeen = viewModel.isSeen(item);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: InkWell(
                        onTap: () => _openNotification(context, item),
                        borderRadius: BorderRadius.circular(20),
                        child: Card(
                          color: isSeen
                              ? null
                              : AppTheme.primary.withValues(alpha: 0.04),
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
                                            : AppTheme.primary.withValues(
                                                alpha: 0.12,
                                              ),
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: Icon(
                                        isSeen
                                            ? Icons.notifications_none_rounded
                                            : Icons
                                                  .notifications_active_rounded,
                                        color: isSeen
                                            ? AppTheme.muted
                                            : AppTheme.primary,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.title,
                                            style: Theme.of(
                                              context,
                                            ).textTheme.titleMedium,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            item.message,
                                            style: Theme.of(
                                              context,
                                            ).textTheme.bodyMedium,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    HbStatusChip(
                                      isSeen ? 'مقروء' : 'غير مقروء',
                                    ),
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
                                      : DateFormat(
                                          'yyyy/MM/dd - HH:mm',
                                        ).format(item.createdAt!.toLocal()),
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
