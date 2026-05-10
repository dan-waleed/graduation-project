String roleLabel(String role) {
  switch (role) {
    case 'Admin':
      return 'مدير النظام';
    case 'Doctor':
      return 'الطبيب';
    case 'Employee':
      return 'الموظف الجامعي';
    case 'Patient':
      return 'الموظف الجامعي';
    case 'Pharmacist':
      return 'الصيدلي';
    case 'Laboratory':
      return 'المختبر';
    case 'ImagingCenter':
      return 'مركز التصوير الطبي';
    case 'MedicalCenter':
      return 'المركز الطبي';
    case 'InsuranceOfficer':
      return 'موظف التأمين';
    default:
      return role;
  }
}
