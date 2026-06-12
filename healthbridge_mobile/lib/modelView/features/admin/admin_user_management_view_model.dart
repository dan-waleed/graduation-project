import 'package:flutter/material.dart';

import 'package:healthbridge_mobile/model/models/user_model.dart';
import 'package:healthbridge_mobile/model/repositories/app_repository.dart';
import 'package:healthbridge_mobile/model/utils/app_roles.dart';
import 'package:healthbridge_mobile/model/utils/role_label.dart';

class AdminUserManagementViewModel extends ChangeNotifier {
  AdminUserManagementViewModel({required AppRepository appRepository})
    : _appRepository = appRepository;

  final AppRepository _appRepository;
  final searchController = TextEditingController();

  List<UserModel> _users = const [];
  bool _isLoading = true;
  bool _isBusy = false;
  String? _errorMessage;
  String _searchQuery = '';

  List<UserModel> get users => _users;
  bool get isLoading => _isLoading;
  bool get isBusy => _isBusy;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;

  List<UserModel> get filteredUsers {
    final normalizedQuery = _searchQuery.trim().toLowerCase();
    return _users.where((user) {
      if (normalizedQuery.isEmpty) return true;
      return user.displayName.toLowerCase().contains(normalizedQuery) ||
          user.username.toLowerCase().contains(normalizedQuery) ||
          user.email.toLowerCase().contains(normalizedQuery) ||
          roleLabel(user.role).toLowerCase().contains(normalizedQuery);
    }).toList();
  }

  void updateSearchQuery(String value) {
    _searchQuery = value;
    notifyListeners();
  }

  Future<void> loadUsers({bool showLoader = true}) async {
    if (showLoader) {
      _isLoading = true;
    }
    _errorMessage = null;
    notifyListeners();

    try {
      _users = await _appRepository.getUsers();
    } catch (error) {
      _errorMessage = error.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String> toggleUserStatus(UserModel user) async {
    if (user.role == AppRoles.admin) {
      throw Exception('لا يمكن تعطيل مدير النظام الأساسي.');
    }

    _isBusy = true;
    notifyListeners();
    try {
      await _appRepository.updateUser(user.id, {'is_active': !user.isActive});
      await loadUsers(showLoader: false);
      return user.isActive ? 'تم تعطيل المستخدم' : 'تم تفعيل المستخدم';
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  Future<String> deleteUser(UserModel user) async {
    if (user.role == AppRoles.admin) {
      throw Exception('لا يمكن حذف مدير النظام الأساسي.');
    }

    _isBusy = true;
    notifyListeners();
    try {
      await _appRepository.deleteUser(user.id);
      await loadUsers(showLoader: false);
      return 'تم حذف المستخدم';
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }
}
