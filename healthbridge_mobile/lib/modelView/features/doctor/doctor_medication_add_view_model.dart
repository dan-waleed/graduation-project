import 'dart:async';

import 'package:flutter/material.dart';

import 'package:healthbridge_mobile/model/models/app_models.dart';
import 'package:healthbridge_mobile/model/repositories/app_repository.dart';

class DoctorMedicationAddViewModel extends ChangeNotifier {
  DoctorMedicationAddViewModel({required AppRepository appRepository})
    : _appRepository = appRepository;

  final AppRepository _appRepository;

  final searchController = TextEditingController();
  final searchFocusNode = FocusNode();
  final durationController = TextEditingController();

  int? _selectedMedicationId;
  String _searchQuery = '';
  Timer? _searchDebounce;
  bool _isLoading = true;
  Object? _error;
  List<MedicationModel> _availableMedications = const [];
  List<CoverageCatalogItemModel> _coverageCatalog = const [];
  bool _initialized = false;

  bool get isLoading => _isLoading;
  Object? get error => _error;
  int? get selectedMedicationId => _selectedMedicationId;
  List<MedicationModel> get availableMedications => _availableMedications;

  List<MedicationModel> get filteredMedications {
    final normalizedQuery = _searchQuery.trim().toLowerCase();
    final filtered = _availableMedications.where((item) {
      if (normalizedQuery.isEmpty) return true;
      return item.name.toLowerCase().contains(normalizedQuery) ||
          item.genericName.toLowerCase().contains(normalizedQuery) ||
          item.strength.toLowerCase().contains(normalizedQuery) ||
          item.manufacturer.toLowerCase().contains(normalizedQuery);
    }).toList();

    if (filtered.isNotEmpty &&
        (_selectedMedicationId == null ||
            !filtered.any((item) => item.id == _selectedMedicationId))) {
      _selectedMedicationId = filtered.first.id;
    }
    return filtered;
  }

  MedicationModel? get selectedMedication {
    final filtered = filteredMedications;
    if (filtered.isEmpty) return null;
    return filtered.cast<MedicationModel?>().firstWhere(
      (item) => item?.id == _selectedMedicationId,
      orElse: () => filtered.first,
    );
  }

  CoverageCatalogItemModel? get selectedCoverageItem {
    final medication = selectedMedication;
    if (medication == null) return null;
    return _findCoverageItemForMedication(_coverageCatalog, medication) ??
        _appRepository.findCoverageForMedication(medication);
  }

  String get fixedUsageCount => _fixedUsageCount(selectedMedication);
  String get fixedQuantity => _fixedQuantity(selectedMedication);
  String get fixedInstructions => _fixedInstructions(selectedMedication);

  void initialize() {
    if (_initialized) return;
    _initialized = true;
    unawaited(load());
  }

  Future<void> load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await Future.wait([
        _appRepository.getMedications(serverOnly: true),
        _appRepository.getCoverageCatalog(category: 'Medication'),
      ]);
      final medications = data[0] as List<MedicationModel>;
      _coverageCatalog = data[1] as List<CoverageCatalogItemModel>;
      _availableMedications = _buildAvailableMedications(
        medications,
        _coverageCatalog,
      );
      if (_availableMedications.isNotEmpty) {
        _selectedMedicationId ??= _availableMedications.first.id;
      }
    } catch (error) {
      _error = error;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void selectMedication(int? value) {
    if (value == null) return;
    _selectedMedicationId = value;
    notifyListeners();
  }

  void scheduleMedicationSearch(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(
      const Duration(milliseconds: 450),
      () => applyMedicationSearch(value),
    );
  }

  void applyMedicationSearch([String? value]) {
    _searchQuery = (value ?? searchController.text).trim();
    notifyListeners();
  }

  void submitMedicationSearch([String? value]) {
    _searchDebounce?.cancel();
    applyMedicationSearch(value);
    searchFocusNode.unfocus();
  }

  void clearDuration() {
    durationController.clear();
  }

  Future<MedicationModel> ensureSelectedMedicationExists() async {
    final medication = selectedMedication;
    if (medication == null) {
      throw StateError('يرجى اختيار دواء أولًا.');
    }
    if (medication.id > 0) return medication;
    return _appRepository.ensureMedicationExists(medication);
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    searchController.dispose();
    searchFocusNode.dispose();
    durationController.dispose();
    super.dispose();
  }
}

String _fixedUsageCount(MedicationModel? medication) {
  if (medication == null) return 'مرتان يوميًا';
  switch (medication.dosageForm.trim()) {
    case 'Injection':
    case 'حقن':
      return 'مرة واحدة يوميًا';
    case 'Syrup':
    case 'شراب':
      return 'ثلاث مرات يوميًا';
    default:
      return 'مرتان يوميًا';
  }
}

String _fixedQuantity(MedicationModel? medication) {
  if (medication == null) return '1';
  switch (medication.dosageForm.trim()) {
    case 'Syrup':
    case 'شراب':
      return '1';
    default:
      return '1';
  }
}

String _fixedInstructions(MedicationModel? medication) {
  if (medication == null) return 'حسب الإرشادات الطبية المعتمدة.';
  switch (medication.dosageForm.trim()) {
    case 'Injection':
    case 'حقن':
      return 'يستخدم تحت إشراف طبي.';
    case 'Tablet':
    case 'Capsule':
    case 'أقراص':
    case 'كبسولات':
      return 'يؤخذ بعد الطعام مع كمية كافية من الماء.';
    default:
      return 'حسب الإرشادات الطبية المعتمدة.';
  }
}

List<MedicationModel> _buildAvailableMedications(
  List<MedicationModel> medications,
  List<CoverageCatalogItemModel> coverageCatalog,
) {
  final available = <MedicationModel>[...medications];

  for (final item in coverageCatalog) {
    if (item.category != 'Medication') {
      continue;
    }
    final hasMatch = medications.any(
      (medication) => _matchesMedicationToCoverageItem(medication, item),
    );
    if (hasMatch) {
      continue;
    }

    available.add(
      MedicationModel(
        id: -item.id,
        name: item.title,
        genericName: item.genericName,
        strength: item.strength,
        dosageForm: '',
        manufacturer: '',
      ),
    );
  }

  available.sort((left, right) => left.name.compareTo(right.name));
  return available;
}

bool _matchesMedicationToCoverageItem(
  MedicationModel medication,
  CoverageCatalogItemModel item,
) {
  if (item.category != 'Medication') {
    return false;
  }

  final medicationName = medication.name.trim().toLowerCase();
  final itemTitle = item.title.trim().toLowerCase();
  if (medicationName.isNotEmpty && medicationName == itemTitle) {
    return true;
  }

  final genericName = medication.genericName.trim().toLowerCase();
  final itemGenericName = item.genericName.trim().toLowerCase();
  final strength = medication.strength.trim().toLowerCase();
  final itemStrength = item.strength.trim().toLowerCase();
  return genericName.isNotEmpty &&
      genericName == itemGenericName &&
      strength.isNotEmpty &&
      strength == itemStrength;
}

CoverageCatalogItemModel? _findCoverageItemForMedication(
  List<CoverageCatalogItemModel> coverageCatalog,
  MedicationModel medication,
) {
  for (final item in coverageCatalog) {
    if (_matchesMedicationToCoverageItem(medication, item)) {
      return item;
    }
  }
  return null;
}
