import 'package:flutter/foundation.dart';

import 'package:healthbridge_mobile/model/models/app_models.dart';
import 'package:healthbridge_mobile/model/repositories/app_repository.dart';

class EmployeePrescriptionsViewModel extends ChangeNotifier {
  EmployeePrescriptionsViewModel({required AppRepository appRepository})
    : _appRepository = appRepository {
    _prescriptionsFuture = _loadPrescriptions();
  }

  final AppRepository _appRepository;

  String _selectedFilter = 'الكل';
  late Future<List<PrescriptionModel>> _prescriptionsFuture;

  String get selectedFilter => _selectedFilter;
  Future<List<PrescriptionModel>> get prescriptionsFuture =>
      _prescriptionsFuture;

  Future<List<PrescriptionModel>> _loadPrescriptions() {
    return _appRepository.getPrescriptions();
  }

  void updateFilter(String value) {
    if (_selectedFilter == value) return;
    _selectedFilter = value;
    notifyListeners();
  }

  void refresh() {
    _prescriptionsFuture = _loadPrescriptions();
    notifyListeners();
  }

  List<PrescriptionModel> filteredPrescriptions(
    List<PrescriptionModel> prescriptions,
  ) {
    if (_selectedFilter == 'الكل') {
      return prescriptions;
    }

    return prescriptions
        .where((item) => item.status == _selectedFilter)
        .toList();
  }
}
