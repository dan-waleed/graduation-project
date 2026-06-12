import 'package:flutter/material.dart';

import 'package:healthbridge_mobile/view/theme/app_theme.dart';

class HbStatusChip extends StatelessWidget {
  const HbStatusChip(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    final color = switch (label) {
      'معتمدة' ||
      'موافقة' ||
      'مقبول' ||
      'مكتمل' ||
      'تم الصرف' ||
      'تم التنفيذ' ||
      'فعّال' ||
      'Approved' ||
      'Completed' ||
      'Dispensed' ||
      'Performed' => AppTheme.success,
      'قيد المراجعة' ||
      'معلقة' ||
      'معلّقة' ||
      'مرسلة' ||
      'مرسل' ||
      'بانتظار اختيار الجهة' ||
      'طلب تعديل' ||
      'جزئي' ||
      'Pending' ||
      'Submitted' ||
      'Sent' ||
      'UnderReview' ||
      'PendingEmployeeSelection' ||
      'PendingInsuranceApproval' ||
      'Partial' ||
      'NeedsUpdate' => AppTheme.warning,
      'مرفوضة' ||
      'مرفوض' ||
      'ملغاة' ||
      'غير فعّال' ||
      'Rejected' ||
      'Cancelled' => AppTheme.error,
      'Expired' || 'منتهية' || 'مسودة' || 'Draft' => AppTheme.neutral,
      _ => AppTheme.primaryDark,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}
