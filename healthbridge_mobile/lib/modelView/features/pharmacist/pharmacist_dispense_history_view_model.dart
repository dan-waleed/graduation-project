import 'package:flutter/foundation.dart';

import 'package:healthbridge_mobile/model/models/app_models.dart';
import 'package:healthbridge_mobile/model/repositories/app_repository.dart';

class PharmacistDispenseHistoryViewModel extends ChangeNotifier {
  PharmacistDispenseHistoryViewModel({required AppRepository appRepository})
    : _appRepository = appRepository {
    _dispensesFuture = _loadDispenses();
  }

  final AppRepository _appRepository;

  late Future<List<DispenseModel>> _dispensesFuture;

  Future<List<DispenseModel>> get dispensesFuture => _dispensesFuture;

  Future<List<DispenseModel>> _loadDispenses() {
    return _appRepository.getDispenses();
  }

  void refresh() {
    _dispensesFuture = _loadDispenses();
    notifyListeners();
  }

  List<DispenseModel> visibleDispenses(List<DispenseModel> dispenses) {
    return dispenses.where((item) => item.status != 'Partial').toList();
  }
}
