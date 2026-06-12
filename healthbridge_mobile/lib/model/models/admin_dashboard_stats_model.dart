class AdminDashboardStatsModel {
  const AdminDashboardStatsModel({
    required this.totalUsers,
    required this.activeUsersCount,
    required this.inactiveUsersCount,
    required this.doctorsCount,
    required this.employeesCount,
    required this.prescriptionsCount,
    required this.pendingRequestsCount,
    required this.dispensesCount,
  });

  final int totalUsers;
  final int activeUsersCount;
  final int inactiveUsersCount;
  final int doctorsCount;
  final int employeesCount;
  final int prescriptionsCount;
  final int pendingRequestsCount;
  final int dispensesCount;
}
