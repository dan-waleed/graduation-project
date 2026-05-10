import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../app/theme/app_theme.dart';
import '../../data/models/dashboard_summary_model.dart';
import '../../data/services/dashboard_service.dart';
import 'hb_empty_state.dart';
import 'hb_section_card.dart';
import 'hb_stat_card.dart';
import 'hb_status_chip.dart';

class HbDashboardOverview extends StatefulWidget {
  const HbDashboardOverview({
    super.key,
    this.recentTitle = 'النشاط الأخير',
    this.emptyMessage = 'لا توجد بيانات حديثة لعرضها الآن.',
  });

  final String recentTitle;
  final String emptyMessage;

  @override
  State<HbDashboardOverview> createState() => _HbDashboardOverviewState();
}

class _HbDashboardOverviewState extends State<HbDashboardOverview> {
  late Future<DashboardSummaryModel> _summaryFuture;

  @override
  void initState() {
    super.initState();
    _summaryFuture = context.read<DashboardService>().fetchSummary();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DashboardSummaryModel>(
      future: _summaryFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return const _DashboardLoading();
        }

        if (snapshot.hasError) {
          return HbSectionCard(
            title: 'تعذر تحميل الملخص',
            subtitle: 'تحقق من اتصال التطبيق بالخادم ثم أعد المحاولة.',
            child: HbEmptyState(
              title: 'لا يمكن تحميل البيانات',
              message: snapshot.error.toString(),
              icon: Icons.cloud_off_rounded,
            ),
          );
        }

        final summary = snapshot.data;
        if (summary == null) {
          return HbSectionCard(
            title: 'الملخص العام',
            child: HbEmptyState(
              title: 'لا توجد بيانات',
              message: widget.emptyMessage,
            ),
          );
        }

        return Column(
          children: [
            HbSectionCard(
              title: summary.title,
              subtitle: summary.subtitle,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final itemWidth = constraints.maxWidth > 720
                      ? (constraints.maxWidth - 12) / 2
                      : constraints.maxWidth;

                  return Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: summary.metrics.map((metric) {
                      return SizedBox(
                        width: itemWidth,
                        child: HbStatCard(
                          label: metric.label,
                          value: metric.value.toString(),
                          icon: _iconFor(metric.icon),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            HbSectionCard(
              title: widget.recentTitle,
              subtitle: 'آخر العناصر المهمة المرتبطة بدورك في النظام.',
              child: summary.recentActivity.isEmpty
                  ? HbEmptyState(
                      title: 'لا يوجد نشاط حديث',
                      message: widget.emptyMessage,
                      icon: Icons.history_toggle_off_rounded,
                    )
                  : Column(
                      children: summary.recentActivity.map((activity) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _ActivityTile(activity: activity),
                        );
                      }).toList(),
                    ),
            ),
          ],
        );
      },
    );
  }

  IconData _iconFor(String iconKey) {
    switch (iconKey) {
      case 'people':
      case 'users':
      case 'family':
        return Icons.groups_rounded;
      case 'prescriptions':
        return Icons.receipt_long_rounded;
      case 'today':
        return Icons.today_rounded;
      case 'pending':
        return Icons.pending_actions_rounded;
      case 'notifications':
        return Icons.notifications_active_outlined;
      case 'dispense':
        return Icons.local_pharmacy_outlined;
      case 'done':
        return Icons.task_alt_rounded;
      case 'partial':
        return Icons.more_time_rounded;
      case 'approved':
        return Icons.verified_rounded;
      case 'insurance':
        return Icons.health_and_safety_outlined;
      case 'update':
        return Icons.update_rounded;
      case 'doctor':
        return Icons.medical_services_outlined;
      case 'pharmacy':
        return Icons.local_pharmacy_outlined;
      case 'lab':
        return Icons.science_outlined;
      case 'imaging':
        return Icons.perm_media_outlined;
      case 'medical_center':
        return Icons.local_hospital_outlined;
      case 'payments':
        return Icons.payments_outlined;
      case 'rejected':
        return Icons.cancel_outlined;
      case 'patient':
      case 'employee':
        return Icons.personal_injury_outlined;
      case 'active':
        return Icons.check_circle_outline_rounded;
      default:
        return Icons.dashboard_outlined;
    }
  }
}

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({
    required this.activity,
  });

  final DashboardActivityModel activity;

  @override
  Widget build(BuildContext context) {
    final formattedDate = activity.createdAt == null
        ? 'الآن'
        : DateFormat('yyyy/MM/dd - HH:mm').format(activity.createdAt!.toLocal());

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.history_rounded,
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(activity.title, style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 4),
                Text(activity.subtitle, style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (activity.status.isNotEmpty) HbStatusChip(activity.status),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        formattedDate,
                        style: Theme.of(context).textTheme.bodySmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardLoading extends StatelessWidget {
  const _DashboardLoading();

  @override
  Widget build(BuildContext context) {
    return HbSectionCard(
      title: 'جاري تحميل الملخص',
      subtitle: 'نقوم بجلب أحدث البيانات من النظام.',
      child: const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }
}
