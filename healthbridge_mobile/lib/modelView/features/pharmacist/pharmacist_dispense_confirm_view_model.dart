import 'package:flutter/material.dart';

import 'package:healthbridge_mobile/model/core/errors/app_exception.dart';
import 'package:healthbridge_mobile/model/models/app_models.dart';
import 'package:healthbridge_mobile/model/repositories/app_repository.dart';

class PharmacistDispenseConfirmViewModel extends ChangeNotifier {
  PharmacistDispenseConfirmViewModel({
    required AppRepository appRepository,
    required this.prescriptionId,
  }) : _appRepository = appRepository {
    if (prescriptionId != null) {
      _prescriptionFuture = _loadPrescription();
    }
  }

  final AppRepository _appRepository;
  final int? prescriptionId;
  final notesController = TextEditingController();

  bool _isSubmitting = false;
  Future<PrescriptionModel>? _prescriptionFuture;

  bool get isSubmitting => _isSubmitting;
  Future<PrescriptionModel>? get prescriptionFuture => _prescriptionFuture;

  Future<PrescriptionModel> _loadPrescription() {
    return _appRepository.getPrescription(prescriptionId!);
  }

  Future<String> submit(PrescriptionModel prescription) async {
    if (prescription.status != 'Approved') {
      throw Exception('يمكن صرف الوصفات المعتمدة فقط.');
    }

    _isSubmitting = true;
    notifyListeners();
    try {
      await _appRepository.createDispense(
        prescriptionId: prescription.id,
        dispenseNumber:
            'DSP-${prescription.id}-${DateTime.now().millisecondsSinceEpoch}',
        status: 'Completed',
        notes: notesController.text.trim(),
      );
      return 'تم تأكيد صرف الدواء بنجاح';
    } on AppException {
      rethrow;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    notesController.dispose();
    super.dispose();
  }
}
