import '../models/dashboard_summary_model.dart';
import '../services/dashboard_service.dart';

class DashboardRepository {
  DashboardRepository({
    required DashboardService dashboardService,
  }) : _dashboardService = dashboardService;

  DashboardService _dashboardService;

  void rebind(DashboardService dashboardService) {
    _dashboardService = dashboardService;
  }

  Future<DashboardSummaryModel> fetchSummary() {
    return _dashboardService.fetchSummary();
  }
}
