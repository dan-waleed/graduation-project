import 'package:flutter/foundation.dart';

import 'package:healthbridge_mobile/model/models/app_models.dart';
import 'package:healthbridge_mobile/model/repositories/app_repository.dart';

class PharmacistPrescriptionDetailViewModel extends ChangeNotifier {
  PharmacistPrescriptionDetailViewModel({
    required AppRepository appRepository,
    required this.prescriptionId,
  }) : _appRepository = appRepository {
    if (prescriptionId != null) {
      _prescriptionFuture = _loadPrescription();
    }
  }

  final AppRepository _appRepository;
  final int? prescriptionId;

  Future<PrescriptionModel>? _prescriptionFuture;

  Future<PrescriptionModel>? get prescriptionFuture => _prescriptionFuture;

  Future<PrescriptionModel> _loadPrescription() {
    return _appRepository.getPrescription(prescriptionId!);
  }

  void refresh() {
    if (prescriptionId == null) return;
    _prescriptionFuture = _loadPrescription();
    notifyListeners();
  }
}
