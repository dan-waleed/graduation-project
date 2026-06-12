import 'package:flutter/foundation.dart';

import 'package:healthbridge_mobile/model/models/admin_dashboard_stats_model.dart';
import 'package:healthbridge_mobile/model/models/app_models.dart';
import 'package:healthbridge_mobile/model/models/user_model.dart';
import 'package:healthbridge_mobile/model/repositories/app_repository.dart';
import 'package:healthbridge_mobile/model/utils/app_roles.dart';

class AdminHomeViewModel extends ChangeNotifier {
  AdminHomeViewModel({required AppRepository appRepository})
    : _appRepository = appRepository;

  final AppRepository _appRepository;

  bool _isLoading = true;
  Object? _error;
  AdminDashboardStatsModel? _stats;

  bool get isLoading => _isLoading;
  Object? get error => _error;
  AdminDashboardStatsModel? get stats => _stats;

  Future<void> load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await Future.wait([
        _appRepository.getUsers(),
        _appRepository.getPrescriptions(),
        _appRepository.getInsuranceRequests(),
        _appRepository.getDispenses(),
      ]);
      final users = data[0] as List<UserModel>;
      final prescriptions = data[1] as List<PrescriptionModel>;
      final insuranceRequests = data[2] as List<InsuranceRequestModel>;
      final dispenses = data[3] as List<DispenseModel>;

      final totalUsers = users.length;
      final activeUsersCount = users.where((user) => user.isActive).length;
      _stats = AdminDashboardStatsModel(
        totalUsers: totalUsers,
        activeUsersCount: activeUsersCount,
        inactiveUsersCount: totalUsers - activeUsersCount,
        doctorsCount: users
            .where((user) => user.role == AppRoles.doctor)
            .length,
        employeesCount: users
            .where((user) => user.role == AppRoles.employee)
            .length,
        prescriptionsCount: prescriptions.length,
        pendingRequestsCount: insuranceRequests
            .where((request) => request.status == 'Pending')
            .length,
        dispensesCount: dispenses.length,
      );
    } catch (error) {
      _error = error;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
