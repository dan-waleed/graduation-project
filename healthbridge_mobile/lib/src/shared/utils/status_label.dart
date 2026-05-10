String statusLabel(String value) {
  switch (value) {
    case 'الكل':
      return 'الكل';
    case 'Approved':
      return 'معتمدة';
    case 'Sent':
      return 'مرسل';
    case 'Submitted':
      return 'مرسلة';
    case 'UnderReview':
    case 'PendingInsuranceApproval':
      return 'قيد المراجعة';
    case 'PendingEmployeeSelection':
      return 'بانتظار اختيار الجهة';
    case 'Dispensed':
      return 'تم الصرف';
    case 'Performed':
      return 'تم التنفيذ';
    case 'Rejected':
      return 'مرفوضة';
    case 'Cancelled':
      return 'ملغاة';
    case 'Draft':
      return 'مسودة';
    case 'Expired':
      return 'منتهية';
    case 'Pending':
      return 'معلّقة';
    case 'NeedsUpdate':
      return 'تحتاج تعديل';
    case 'Completed':
      return 'مكتمل';
    case 'Partial':
      return 'جزئي';
    case 'فعّال':
      return 'فعّال';
    case 'لديه تأمين':
      return 'لديه تأمين';
    case 'بدون تأمين':
      return 'بدون تأمين';
    default:
      return value;
  }
}
