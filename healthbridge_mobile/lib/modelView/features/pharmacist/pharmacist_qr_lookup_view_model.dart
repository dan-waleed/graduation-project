import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'package:healthbridge_mobile/model/models/app_models.dart';
import 'package:healthbridge_mobile/model/repositories/app_repository.dart';

enum PharmacistPrescriptionLookupState {
  approved,
  dispensed,
  unavailable,
  notFound,
}

class PharmacistPrescriptionLookupResult {
  const PharmacistPrescriptionLookupResult._({
    required this.state,
    required this.query,
    this.prescription,
  });

  const PharmacistPrescriptionLookupResult.approved({
    required PrescriptionModel prescription,
    required String query,
  }) : this._(
         state: PharmacistPrescriptionLookupState.approved,
         query: query,
         prescription: prescription,
       );

  const PharmacistPrescriptionLookupResult.dispensed({
    required PrescriptionModel prescription,
    required String query,
  }) : this._(
         state: PharmacistPrescriptionLookupState.dispensed,
         query: query,
         prescription: prescription,
       );

  const PharmacistPrescriptionLookupResult.unavailable({
    required PrescriptionModel prescription,
    required String query,
  }) : this._(
         state: PharmacistPrescriptionLookupState.unavailable,
         query: query,
         prescription: prescription,
       );

  const PharmacistPrescriptionLookupResult.notFound({required String query})
    : this._(state: PharmacistPrescriptionLookupState.notFound, query: query);

  final PharmacistPrescriptionLookupState state;
  final String query;
  final PrescriptionModel? prescription;
}

class PharmacistQrLookupViewModel extends ChangeNotifier {
  PharmacistQrLookupViewModel({required AppRepository appRepository})
    : _appRepository = appRepository {
    _prescriptionsFuture = _loadPrescriptions();
  }

  final AppRepository _appRepository;
  final codeController = TextEditingController();
  final MobileScannerController scannerController = MobileScannerController(
    formats: const [BarcodeFormat.qrCode],
  );

  late Future<List<PrescriptionModel>> _prescriptionsFuture;
  bool _isHandlingScan = false;

  Future<List<PrescriptionModel>> get prescriptionsFuture =>
      _prescriptionsFuture;
  bool get isHandlingScan => _isHandlingScan;

  Future<List<PrescriptionModel>> _loadPrescriptions() {
    return _appRepository.getPrescriptions(status: 'Approved');
  }

  void refreshApprovedPrescriptions() {
    _prescriptionsFuture = _loadPrescriptions();
    notifyListeners();
  }

  List<PrescriptionModel> approvedMedicationPrescriptions(
    List<PrescriptionModel> prescriptions,
  ) {
    return prescriptions
        .where(
          (item) =>
              item.serviceType == 'Medication' && item.status == 'Approved',
        )
        .toList();
  }

  String extractPrescriptionNumber(String value) {
    final trimmedValue = value.trim();
    if (trimmedValue.isEmpty) {
      return '';
    }
    final rxMatch = RegExp(
      r'RX-[A-Za-z0-9-]+',
      caseSensitive: false,
    ).firstMatch(trimmedValue);
    return rxMatch?.group(0) ?? trimmedValue;
  }

  Future<PharmacistPrescriptionLookupResult> findPrescriptionLookupResult(
    String rawQuery,
  ) async {
    final normalizedQuery = extractPrescriptionNumber(rawQuery);
    if (normalizedQuery.isEmpty) {
      return const PharmacistPrescriptionLookupResult.notFound(query: '');
    }

    final results = await _appRepository.searchPrescriptions(normalizedQuery);
    final medicationMatches = results
        .where((item) => item.serviceType == 'Medication')
        .toList();
    final exactMatches = medicationMatches.where((item) {
      return item.prescriptionNumber.trim().toLowerCase() ==
          normalizedQuery.toLowerCase();
    }).toList();
    final candidates = exactMatches.isNotEmpty
        ? exactMatches
        : medicationMatches;

    final approvedMatches = candidates
        .where((item) => item.status == 'Approved')
        .toList();
    if (approvedMatches.isNotEmpty) {
      return PharmacistPrescriptionLookupResult.approved(
        prescription: approvedMatches.first,
        query: normalizedQuery,
      );
    }

    final dispensedMatches = candidates
        .where((item) => item.status == 'Dispensed')
        .toList();
    if (dispensedMatches.isNotEmpty) {
      return PharmacistPrescriptionLookupResult.dispensed(
        prescription: dispensedMatches.first,
        query: normalizedQuery,
      );
    }

    if (candidates.isNotEmpty) {
      return PharmacistPrescriptionLookupResult.unavailable(
        prescription: candidates.first,
        query: normalizedQuery,
      );
    }

    return PharmacistPrescriptionLookupResult.notFound(query: normalizedQuery);
  }

  Future<void> stopScannerForHandling() async {
    _isHandlingScan = true;
    notifyListeners();
    await scannerController.stop();
  }

  Future<void> restartScanner() async {
    _isHandlingScan = false;
    await scannerController.start();
    notifyListeners();
  }

  void setLookupCode(String value) {
    codeController.text = value;
    notifyListeners();
  }

  @override
  void dispose() {
    codeController.dispose();
    unawaited(scannerController.dispose());
    super.dispose();
  }
}
