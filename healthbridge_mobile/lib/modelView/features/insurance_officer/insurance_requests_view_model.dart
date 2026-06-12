import 'package:flutter/foundation.dart';

import 'package:healthbridge_mobile/model/models/app_models.dart';
import 'package:healthbridge_mobile/model/repositories/app_repository.dart';

class InsuranceRequestsViewModel extends ChangeNotifier {
  InsuranceRequestsViewModel({required AppRepository appRepository})
    : _appRepository = appRepository {
    _requestsFuture = _loadRequests();
  }

  final AppRepository _appRepository;

  String _selectedFilter = 'الكل';
  late Future<List<InsuranceRequestModel>> _requestsFuture;

  String get selectedFilter => _selectedFilter;
  Future<List<InsuranceRequestModel>> get requestsFuture => _requestsFuture;

  Future<List<InsuranceRequestModel>> _loadRequests() {
    return _appRepository.getInsuranceRequests();
  }

  void updateFilter(String value) {
    if (_selectedFilter == value) return;
    _selectedFilter = value;
    notifyListeners();
  }

  void refresh() {
    _requestsFuture = _loadRequests();
    notifyListeners();
  }

  List<InsuranceRequestModel> filteredRequests(
    List<InsuranceRequestModel> requests,
  ) {
    if (_selectedFilter == 'الكل') {
      return requests;
    }

    return requests.where((item) => item.status == _selectedFilter).toList();
  }

  Future<String> updateRequestStatus(
    InsuranceRequestModel request,
    String status,
    String actionLabel,
    String notes,
  ) async {
    if (request.status == 'Approved' && status == 'Rejected') {
      throw Exception('لا يمكن رفض الطلب بعد الموافقة عليه.');
    }

    await _appRepository.updateInsuranceRequest(
      id: request.id,
      status: status,
      notes: notes,
    );
    refresh();
    return 'تم $actionLabel الطلب بنجاح';
  }
}
