class AppRoles {
  static const admin = 'Admin';
  static const doctor = 'Doctor';
  static const employee = 'Employee';
  static const pharmacist = 'Pharmacist';
  static const insuranceOfficer = 'InsuranceOfficer';

  static const supportedRoles = <String>{
    admin,
    doctor,
    employee,
    pharmacist,
    insuranceOfficer,
  };

  static const assignableRoles = <String>[
    doctor,
    employee,
    pharmacist,
    insuranceOfficer,
  ];
}

class AppRoleOption {
  const AppRoleOption({
    required this.backendValue,
    required this.label,
  });

  final String backendValue;
  final String label;
}

const assignableRoleOptions = <AppRoleOption>[
  AppRoleOption(backendValue: AppRoles.doctor, label: 'الطبيب'),
  AppRoleOption(backendValue: AppRoles.employee, label: 'الموظف الجامعي'),
  AppRoleOption(backendValue: AppRoles.pharmacist, label: 'الصيدلي'),
  AppRoleOption(backendValue: AppRoles.insuranceOfficer, label: 'موظف التأمين'),
];

String arabicRoleLabel(String role) {
  switch (role) {
    case AppRoles.admin:
      return 'مدير النظام';
    case AppRoles.doctor:
      return 'الطبيب';
    case AppRoles.employee:
    case 'Patient':
      return 'الموظف الجامعي';
    case AppRoles.pharmacist:
      return 'الصيدلي';
    case AppRoles.insuranceOfficer:
      return 'موظف التأمين';
    default:
      return role;
  }
}
