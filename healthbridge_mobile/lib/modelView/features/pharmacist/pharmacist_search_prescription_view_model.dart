import 'package:flutter/material.dart';

import 'package:healthbridge_mobile/model/models/app_models.dart';
import 'package:healthbridge_mobile/model/repositories/app_repository.dart';

class PharmacistSearchPrescriptionViewModel extends ChangeNotifier {
  PharmacistSearchPrescriptionViewModel({required AppRepository appRepository})
    : _appRepository = appRepository {
    _prescriptionsFuture = _loadPrescriptions();
  }

  final AppRepository _appRepository;
  final searchController = TextEditingController();

  String _query = '';
  late Future<List<PrescriptionModel>> _prescriptionsFuture;

  String get query => _query;
  Future<List<PrescriptionModel>> get prescriptionsFuture =>
      _prescriptionsFuture;

  Future<List<PrescriptionModel>> _loadPrescriptions() {
    return _appRepository.searchPrescriptions(_query);
  }

  void search() {
    _query = searchController.text.trim();
    refresh();
  }

  void refresh() {
    _prescriptionsFuture = _loadPrescriptions();
    notifyListeners();
  }

  List<PrescriptionModel> visiblePrescriptions(
    List<PrescriptionModel> prescriptions,
  ) {
    return prescriptions.where((item) {
      return item.serviceType == 'Medication' && item.status == 'Approved';
    }).toList();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }
}
