import 'package:flutter/foundation.dart';

import 'package:healthbridge_mobile/model/models/app_models.dart';
import 'package:healthbridge_mobile/model/repositories/app_repository.dart';

class InsuranceReviewData {
  const InsuranceReviewData({
    required this.request,
    required this.prescription,
  });

  final InsuranceRequestModel? request;
  final PrescriptionModel? prescription;
}

class InsuranceReviewViewModel extends ChangeNotifier {
  InsuranceReviewViewModel({
    required AppRepository appRepository,
    required this.requestId,
  }) : _appRepository = appRepository {
    _reviewFuture = _loadReviewData();
  }

  final AppRepository _appRepository;
  final int? requestId;

  late Future<InsuranceReviewData> _reviewFuture;

  Future<InsuranceReviewData> get reviewFuture => _reviewFuture;

  Future<InsuranceReviewData> _loadReviewData() async {
    final data = await Future.wait([
      _appRepository.getInsuranceRequests(),
      _appRepository.getPrescriptions(),
    ]);

    final requests = data[0] as List<InsuranceRequestModel>;
    final prescriptions = data[1] as List<PrescriptionModel>;
    final matchingRequests = requests
        .where((item) => item.id == requestId)
        .toList();
    final request = matchingRequests.isEmpty ? null : matchingRequests.first;
    if (request == null) {
      return const InsuranceReviewData(request: null, prescription: null);
    }

    final matchingPrescriptions = prescriptions
        .where((item) => item.id == request.prescriptionId)
        .toList();
    final prescription = matchingPrescriptions.isEmpty
        ? null
        : matchingPrescriptions.first;

    return InsuranceReviewData(request: request, prescription: prescription);
  }

  void refresh() {
    _reviewFuture = _loadReviewData();
    notifyListeners();
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
