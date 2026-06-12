import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:healthbridge_mobile/model/models/app_models.dart';
import 'package:healthbridge_mobile/model/repositories/app_repository.dart';
import 'package:healthbridge_mobile/modelView/features/common/notification_center_view_model.dart';
import 'package:healthbridge_mobile/view/features/doctor/doctor_views.dart';
import 'package:healthbridge_mobile/view/features/employee/employee_views.dart';
import 'package:healthbridge_mobile/view/features/insurance_officer/insurance_officer_views.dart';

class NotificationNavigationTarget {
  const NotificationNavigationTarget.route(this.routePath)
    : dialogTitle = null,
      dialogMessage = null;

  const NotificationNavigationTarget.dialog({
    required this.dialogTitle,
    required this.dialogMessage,
  }) : routePath = null;

  final String? routePath;
  final String? dialogTitle;
  final String? dialogMessage;

  bool get hasRoute => routePath != null;
}

class NotificationsViewModel extends ChangeNotifier {
  NotificationsViewModel({
    required AppRepository appRepository,
    required NotificationCenterViewModel notificationCenterViewModel,
  }) : _appRepository = appRepository,
       _notificationCenterViewModel = notificationCenterViewModel;

  final AppRepository _appRepository;
  final NotificationCenterViewModel _notificationCenterViewModel;

  bool _showUnreadOnly = false;
  bool _isLoading = true;
  bool _isRefreshing = false;
  bool _isBulkUpdating = false;
  final Set<int> _optimisticReadIds = <int>{};
  List<NotificationModel> _notifications = const [];
  Object? _loadError;
  int _loadRequestId = 0;
  Timer? _timer;
  bool _isInitialized = false;

  bool get showUnreadOnly => _showUnreadOnly;
  bool get isLoading => _isLoading;
  bool get isRefreshing => _isRefreshing;
  bool get isBulkUpdating => _isBulkUpdating;
  List<NotificationModel> get notifications => _notifications;
  Object? get loadError => _loadError;

  void initialize() {
    if (_isInitialized) return;
    _isInitialized = true;
    unawaited(refreshNotifications(showLoader: true));
    _timer?.cancel();
    _timer = Timer.periodic(
      const Duration(seconds: 20),
      (_) => unawaited(refreshNotifications()),
    );
  }

  void toggleUnreadOnly(bool value) {
    if (_showUnreadOnly == value) return;
    _showUnreadOnly = value;
    notifyListeners();
    unawaited(refreshNotifications());
  }

  bool isSeen(NotificationModel item) {
    return item.isRead || _optimisticReadIds.contains(item.id);
  }

  Future<List<NotificationModel>> _loadNotifications() {
    return _showUnreadOnly
        ? _appRepository.getUnreadNotifications()
        : _appRepository.getNotifications();
  }

  Future<void> refreshNotifications({bool showLoader = false}) async {
    final requestId = ++_loadRequestId;
    _loadError = null;
    if (showLoader) {
      _isLoading = true;
    } else {
      _isRefreshing = true;
    }
    notifyListeners();

    try {
      final items = await _loadNotifications();
      if (requestId != _loadRequestId) return;
      _notifications = items;
      _optimisticReadIds.removeWhere(
        (id) => !items.any((item) => item.id == id),
      );
      _isLoading = false;
      _isRefreshing = false;
      notifyListeners();
    } catch (error) {
      if (requestId != _loadRequestId) return;
      _loadError = error;
      _isLoading = false;
      _isRefreshing = false;
      notifyListeners();
    }
  }

  Future<void> markAllRead() async {
    _optimisticReadIds.addAll(_notifications.map((item) => item.id));
    _isBulkUpdating = true;
    notifyListeners();
    _notificationCenterViewModel.markAllReadLocally();

    try {
      await _appRepository.markAllNotificationsRead();
      await _notificationCenterViewModel.refreshUnreadCount();
      await refreshNotifications();
    } finally {
      _isBulkUpdating = false;
      notifyListeners();
    }
  }

  Future<void>? beginOpenNotification(NotificationModel item) {
    if (item.isRead || _optimisticReadIds.contains(item.id)) {
      return null;
    }

    _optimisticReadIds.add(item.id);
    notifyListeners();
    _notificationCenterViewModel.markOneReadLocally(item.id);
    return _markNotificationRead(item.id);
  }

  Future<void> _markNotificationRead(int notificationId) async {
    try {
      await _appRepository.markNotificationRead(notificationId);
    } catch (_) {
      _optimisticReadIds.remove(notificationId);
      notifyListeners();
      await _notificationCenterViewModel.refreshUnreadCount();
      rethrow;
    }
  }

  Future<void> completeNotificationOpen() async {
    await _notificationCenterViewModel.refreshUnreadCount(silent: true);
    await refreshNotifications();
  }

  Future<NotificationNavigationTarget> resolveNavigationTarget(
    NotificationModel item,
    String currentRole,
  ) async {
    final relatedId = int.tryParse(item.relatedEntityId);
    if (item.relatedEntityType == 'Prescription' && relatedId != null) {
      switch (currentRole) {
        case 'Doctor':
          return NotificationNavigationTarget.route(
            '${DoctorPrescriptionDetailScreen.routePath}?id=$relatedId',
          );
        default:
          return NotificationNavigationTarget.route(
            '${EmployeePrescriptionDetailView.routePath}?id=$relatedId',
          );
      }
    }

    if (item.relatedEntityType == 'InsuranceRequest' && relatedId != null) {
      if (currentRole == 'InsuranceOfficer') {
        return NotificationNavigationTarget.route(
          '${InsuranceReviewScreen.routePath}?id=$relatedId',
        );
      }

      final requests = await _appRepository.getInsuranceRequests();
      final matchingRequests = requests
          .where((request) => request.id == relatedId)
          .toList();
      final match = matchingRequests.isEmpty ? null : matchingRequests.first;
      if (match != null) {
        switch (currentRole) {
          case 'Doctor':
            return NotificationNavigationTarget.route(
              '${DoctorPrescriptionDetailScreen.routePath}?id=${match.prescriptionId}',
            );
          default:
            return NotificationNavigationTarget.route(
              '${EmployeePrescriptionDetailView.routePath}?id=${match.prescriptionId}',
            );
        }
      }
    }

    if (item.relatedEntityType == 'Dispense' && relatedId != null) {
      final dispenses = await _appRepository.getDispenses();
      final matchingDispenses = dispenses
          .where((dispense) => dispense.id == relatedId)
          .toList();
      final match = matchingDispenses.isEmpty ? null : matchingDispenses.first;
      if (match != null) {
        return NotificationNavigationTarget.route(
          '${EmployeePrescriptionDetailView.routePath}?id=${match.prescriptionId}',
        );
      }
    }

    return NotificationNavigationTarget.dialog(
      dialogTitle: item.title,
      dialogMessage: item.message,
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
