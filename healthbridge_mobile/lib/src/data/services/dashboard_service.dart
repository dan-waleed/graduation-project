import '../../core/config/app_config.dart';
import '../../core/network/api_client.dart';
import '../models/dashboard_summary_model.dart';

class DashboardService {
  DashboardService({
    required ApiClient apiClient,
    bool enableLocalDemoMode = AppConfig.enableLocalDemoMode,
  })  : _apiClient = apiClient,
        _enableLocalDemoMode = enableLocalDemoMode;

  ApiClient _apiClient;
  final bool _enableLocalDemoMode;

  void rebind(ApiClient apiClient) {
    _apiClient = apiClient;
  }

  Future<DashboardSummaryModel> fetchSummary() async {
    if (_enableLocalDemoMode && _apiClient.isDemoToken) {
      return _buildDemoSummary();
    }

    final response = await _apiClient.get('dashboard/summary/');
    return DashboardSummaryModel.fromJson(response);
  }

  DashboardSummaryModel _buildDemoSummary() {
    final roleKey = _extractDemoRole();
    switch (roleKey) {
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
