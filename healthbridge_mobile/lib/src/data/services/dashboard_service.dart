import '../../core/network/api_client.dart';
import '../models/dashboard_summary_model.dart';

class DashboardService {
  DashboardService({
    required ApiClient apiClient,
  }) : _apiClient = apiClient;

  ApiClient _apiClient;

  void rebind(ApiClient apiClient) {
    _apiClient = apiClient;
  }

  Future<DashboardSummaryModel> fetchSummary() async {
    if (_apiClient.isDemoToken) {
      return _buildDemoSummary();
    }

    final response = await _apiClient.get('dashboard/summary/');
    return DashboardSummaryModel.fromJson(response);
  }

  DashboardSummaryModel _buildDemoSummary() {
    final roleKey = _extractDemoRole();
    switch (roleKey) {
      case 'laboratory':
        return _providerSummary(
          role: 'Laboratory',
          title: 'ملخص المختبر',
          subtitle: 'بيانات تجريبية لاختبار لوحة المختبر بدون الاعتماد على الخادم.',
          metrics: const [
            DashboardMetricModel(key: 'lab_requests', label: 'طلبات جديدة', value: 12, icon: 'lab'),
            DashboardMetricModel(key: 'lab_today', label: 'فحوصات اليوم', value: 7, icon: 'today'),
            DashboardMetricModel(key: 'lab_done', label: 'تم التنفيذ', value: 19, icon: 'done'),
            DashboardMetricModel(key: 'lab_pending', label: 'بانتظار الإرسال', value: 4, icon: 'pending'),
          ],
          recentActivity: [
            _activity('CBC - أحمد خليل', 'تم استلام طلب فحص الدم من العيادة العامة.', 'Pending', 18),
            _activity('تحاليل سكر - منى صالح', 'تم تنفيذ الفحص وإرسال النتيجة للطبيب.', 'Completed', 42),
            _activity('وظائف كبد - باسل الجعبري', 'العينة قيد المعالجة داخل المختبر.', 'UnderReview', 95),
          ],
        );
      case 'imagingcenter':
        return _providerSummary(
          role: 'ImagingCenter',
          title: 'ملخص مركز التصوير',
          subtitle: 'بيانات تجريبية لاختبار لوحة مركز التصوير الطبي.',
          metrics: const [
            DashboardMetricModel(key: 'imaging_requests', label: 'طلبات تصوير', value: 9, icon: 'imaging'),
            DashboardMetricModel(key: 'today_scans', label: 'فحوصات اليوم', value: 5, icon: 'today'),
            DashboardMetricModel(key: 'completed', label: 'منجزة', value: 14, icon: 'done'),
            DashboardMetricModel(key: 'pending', label: 'قيد الجدولة', value: 3, icon: 'pending'),
          ],
          recentActivity: [
            _activity('أشعة سينية للصدر', 'تمت إضافة طلب جديد من الطبيب المعالج.', 'Pending', 20),
            _activity('تصوير رنين مغناطيسي', 'الموعد مؤكد غدًا الساعة 10:00.', 'Approved', 60),
            _activity('ألتراساوند للبطن', 'أُرسل التقرير النهائي إلى السجل الطبي.', 'Completed', 120),
          ],
        );
      case 'medicalcenter':
        return _providerSummary(
          role: 'MedicalCenter',
          title: 'ملخص المركز الطبي',
          subtitle: 'بيانات تجريبية لاختبار لوحة المركز الطبي.',
          metrics: const [
            DashboardMetricModel(key: 'medical_orders', label: 'طلبات طبية', value: 11, icon: 'medical_center'),
            DashboardMetricModel(key: 'today_cases', label: 'حالات اليوم', value: 6, icon: 'today'),
            DashboardMetricModel(key: 'completed', label: 'مكتملة', value: 17, icon: 'done'),
            DashboardMetricModel(key: 'pending', label: 'قيد المتابعة', value: 5, icon: 'pending'),
          ],
          recentActivity: [
            _activity('جلسة علاج طبيعي', 'طلب جديد بانتظار تحديد الموعد المناسب.', 'Pending', 22),
            _activity('استشارة باطنية', 'تم إنهاء الخدمة وإغلاق الطلب.', 'Completed', 75),
            _activity('إجراء بسيط', 'الطلب تحت المراجعة من الفريق الطبي.', 'UnderReview', 130),
          ],
        );
      case 'doctor':
        return _providerSummary(
          role: 'Doctor',
          title: 'ملخص الطبيب',
          subtitle: 'بيانات تجريبية للطبيب في وضع الاختبار المحلي.',
          metrics: const [
            DashboardMetricModel(key: 'prescriptions', label: 'وصفات اليوم', value: 8, icon: 'prescriptions'),
            DashboardMetricModel(key: 'patients', label: 'مرضى نشطون', value: 24, icon: 'patient'),
            DashboardMetricModel(key: 'pending', label: 'بانتظار المتابعة', value: 5, icon: 'pending'),
            DashboardMetricModel(key: 'approved', label: 'معتمدة', value: 13, icon: 'approved'),
          ],
          recentActivity: [
            _activity('وصفة RX-2026-1001', 'تم إرسال وصفة جديدة إلى الصيدلية.', 'Submitted', 12),
            _activity('طلب تصوير', 'تمت الموافقة على طلب الأشعة للمريض.', 'Approved', 48),
            _activity('مراجعة مريض', 'أضيفت ملاحظات جديدة إلى السجل الطبي.', 'Completed', 90),
          ],
        );
      default:
        return _providerSummary(
          role: 'Demo',
          title: 'ملخص تجريبي',
          subtitle: 'الوضع الحالي يستخدم بيانات محلية للاختبار النهائي.',
          metrics: const [
            DashboardMetricModel(key: 'active', label: 'عناصر نشطة', value: 10, icon: 'active'),
            DashboardMetricModel(key: 'notifications', label: 'إشعارات', value: 3, icon: 'notifications'),
            DashboardMetricModel(key: 'today', label: 'اليوم', value: 5, icon: 'today'),
            DashboardMetricModel(key: 'pending', label: 'معلقة', value: 2, icon: 'pending'),
          ],
          recentActivity: [
            _activity('جلسة اختبار', 'تم تحميل بيانات العرض المحلية بنجاح.', 'Completed', 10),
            _activity('إشعارات', 'تم تفعيل الإشعارات التجريبية لهذا الدور.', 'Approved', 35),
          ],
        );
    }
  }

  DashboardSummaryModel _providerSummary({
    required String role,
    required String title,
    required String subtitle,
    required List<DashboardMetricModel> metrics,
    required List<DashboardActivityModel> recentActivity,
  }) {
    return DashboardSummaryModel(
      role: role,
      title: title,
      subtitle: subtitle,
      metrics: metrics,
      recentActivity: recentActivity,
    );
  }

  DashboardActivityModel _activity(
    String title,
    String subtitle,
    String status,
    int minutesAgo,
  ) {
    return DashboardActivityModel(
      title: title,
      subtitle: subtitle,
      status: status,
      createdAt: DateTime.now().subtract(Duration(minutes: minutesAgo)),
    );
  }

  String _extractDemoRole() {
    if (!_apiClient.isDemoToken) {
      return '';
    }

    final token = _apiClient.token ?? '';
    final prefixStripped = token.substring('demo-token-'.length);
    final parts = prefixStripped.split('-');
    if (parts.length <= 1) {
      return prefixStripped.toLowerCase();
    }
    return parts.sublist(0, parts.length - 1).join('-').replaceAll('-', '').toLowerCase();
  }
}
