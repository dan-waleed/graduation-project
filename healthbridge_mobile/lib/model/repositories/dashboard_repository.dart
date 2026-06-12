import 'package:healthbridge_mobile/model/models/dashboard_summary_model.dart';
import 'package:healthbridge_mobile/model/services/dashboard_service.dart';

class DashboardRepository {
  DashboardRepository({required DashboardService dashboardService})
    : _dashboardService = dashboardService;

  DashboardService _dashboardService;

  void rebind(DashboardService dashboardService) {
    _dashboardService = dashboardService;
  }

  Future<DashboardSummaryModel> fetchSummary() {
    return _dashboardService.fetchSummary();
  }
}
