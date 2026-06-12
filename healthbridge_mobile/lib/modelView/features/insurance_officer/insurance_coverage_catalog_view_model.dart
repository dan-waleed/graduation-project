import 'package:flutter/foundation.dart';

import 'package:healthbridge_mobile/model/models/app_models.dart';
import 'package:healthbridge_mobile/model/repositories/app_repository.dart';

class InsuranceCoverageCatalogViewModel extends ChangeNotifier {
  InsuranceCoverageCatalogViewModel({required AppRepository appRepository})
    : _appRepository = appRepository {
    _coverageFuture = _loadCoverage();
  }

  final AppRepository _appRepository;

  late Future<List<CoverageCatalogItemModel>> _coverageFuture;

  Future<List<CoverageCatalogItemModel>> get coverageFuture => _coverageFuture;

  Future<List<CoverageCatalogItemModel>> _loadCoverage() {
    return _appRepository.getCoverageCatalog(
      category: 'Medication',
      activeOnly: false,
    );
  }

  void refresh() {
    _coverageFuture = _loadCoverage();
    notifyListeners();
  }

  Future<String> saveCoverageItem(
    CoverageCatalogItemModel savedItem, {
    CoverageCatalogItemModel? originalItem,
  }) async {
    if (originalItem == null) {
      await _appRepository.createCoverageCatalogItem(item: savedItem);
      refresh();
      return 'تمت إضافة دواء جديد';
    }

    await _appRepository.updateCoverageCatalogItem(item: savedItem);
    refresh();
    return 'تم تحديث بيانات الدواء';
  }
}
