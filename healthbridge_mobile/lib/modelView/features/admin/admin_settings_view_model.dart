import 'package:flutter/material.dart';

import 'package:healthbridge_mobile/model/models/app_models.dart';
import 'package:healthbridge_mobile/model/repositories/app_repository.dart';

class AdminSettingsViewModel extends ChangeNotifier {
  AdminSettingsViewModel({required AppRepository appRepository})
    : _appRepository = appRepository;

  final AppRepository _appRepository;

  final systemNameController = TextEditingController();
  final organizationNameController = TextEditingController();
  final shortDescriptionController = TextEditingController();
  final adminNotesController = TextEditingController();

  bool notificationsEnabled = true;
  bool insuranceWorkflowEnabled = true;
  bool pharmacistNotesRequired = false;
  String selectedLanguage = 'العربية';
  String selectedSessionTimeout = '30 دقيقة';
  bool _isLoading = true;
  bool _isSaving = false;
  Object? _error;

  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  Object? get error => _error;

  Future<void> loadSettings() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final settings = await _appRepository.getSystemSettings();
      systemNameController.text = settings.systemName;
      organizationNameController.text = settings.organizationName;
      shortDescriptionController.text = settings.shortDescription;
      adminNotesController.text = settings.adminNotes;
      notificationsEnabled = settings.notificationsEnabled;
      insuranceWorkflowEnabled = settings.insuranceWorkflowEnabled;
      pharmacistNotesRequired = settings.pharmacistNotesRequired;
      selectedLanguage = settings.interfaceLanguage;
      selectedSessionTimeout = '${settings.sessionTimeoutMinutes} دقيقة';
    } catch (error) {
      _error = error;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setNotificationsEnabled(bool value) {
    notificationsEnabled = value;
    notifyListeners();
  }

  void setInsuranceWorkflowEnabled(bool value) {
    insuranceWorkflowEnabled = value;
    notifyListeners();
  }

  void setPharmacistNotesRequired(bool value) {
    pharmacistNotesRequired = value;
    notifyListeners();
  }

  void setSelectedLanguage(String value) {
    selectedLanguage = value;
    notifyListeners();
  }

  void setSelectedSessionTimeout(String value) {
    selectedSessionTimeout = value;
    notifyListeners();
  }

  int _selectedTimeoutMinutes() {
    return int.tryParse(selectedSessionTimeout.split(' ').first) ?? 30;
  }

  Future<String> saveSettings() async {
    _isSaving = true;
    notifyListeners();
    try {
      final updated = SystemSettingsModel(
        systemName: systemNameController.text.trim(),
        organizationName: organizationNameController.text.trim(),
        shortDescription: shortDescriptionController.text.trim(),
        notificationsEnabled: notificationsEnabled,
        insuranceWorkflowEnabled: insuranceWorkflowEnabled,
        pharmacistNotesRequired: pharmacistNotesRequired,
        interfaceLanguage: selectedLanguage,
        sessionTimeoutMinutes: _selectedTimeoutMinutes(),
        adminNotes: adminNotesController.text.trim(),
      );
      await _appRepository.updateSystemSettings(updated);
      return 'تم حفظ إعدادات النظام وتفعيلها بنجاح';
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    systemNameController.dispose();
    organizationNameController.dispose();
    shortDescriptionController.dispose();
    adminNotesController.dispose();
    super.dispose();
  }
}
