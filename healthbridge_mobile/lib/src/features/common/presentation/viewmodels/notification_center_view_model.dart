import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../data/repositories/app_repository.dart';

class NotificationCenterViewModel extends ChangeNotifier {
  NotificationCenterViewModel({
    required AppRepository appRepository,
  }) : _appRepository = appRepository;

  AppRepository _appRepository;
  Timer? _timer;
  int _unreadCount = 0;
  bool _isInitialized = false;
  bool _isRefreshing = false;
  DateTime? _nextSilentRefreshAt;

  int get unreadCount => _unreadCount;

  void rebind(AppRepository appRepository) {
    _appRepository = appRepository;
  }

  Future<void> initialize() async {
    if (_isInitialized) return;
    _isInitialized = true;
    await refreshUnreadCount();
    _timer?.cancel();
    _timer = Timer.periodic(
      const Duration(seconds: 20),
      (_) => refreshUnreadCount(silent: true),
    );
  }

  Future<void> refreshUnreadCount({bool silent = false}) async {
    if (_isRefreshing) return;
    if (silent && _nextSilentRefreshAt != null && DateTime.now().isBefore(_nextSilentRefreshAt!)) {
      return;
    }

    _isRefreshing = true;
    try {
      final count = await _appRepository.getUnreadNotificationCount();
      _nextSilentRefreshAt = null;
      if (_unreadCount != count) {
        _unreadCount = count;
        notifyListeners();
      } else if (!silent) {
        notifyListeners();
      }
    } catch (_) {
      _nextSilentRefreshAt = DateTime.now().add(const Duration(minutes: 1));
      if (!silent && _unreadCount != 0) {
        _unreadCount = 0;
        notifyListeners();
      }
    } finally {
      _isRefreshing = false;
    }
  }

  void markOneReadLocally(int notificationId) {
    if (_unreadCount > 0) {
      _unreadCount -= 1;
      notifyListeners();
    }
  }

  void markAllReadLocally() {
    if (_unreadCount != 0) {
      _unreadCount = 0;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
