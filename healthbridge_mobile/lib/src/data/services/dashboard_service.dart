import '../../core/network/api_client.dart';
import '../models/dashboard_summary_model.dart';

class DashboardService {
  DashboardService({required ApiClient apiClient}) : _apiClient = apiClient;

  ApiClient _apiClient;

  void rebind(ApiClient apiClient) {
    _apiClient = apiClient;
  }

  Future<DashboardSummaryModel> fetchSummary() async {
    final response = await _apiClient.get('dashboard/summary/');
    return DashboardSummaryModel.fromJson(response);
  }
}
