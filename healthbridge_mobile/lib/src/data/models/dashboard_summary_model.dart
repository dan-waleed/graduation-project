class DashboardMetricModel {
  const DashboardMetricModel({
    required this.key,
    required this.label,
    required this.value,
    required this.icon,
  });

  final String key;
  final String label;
  final int value;
  final String icon;

  factory DashboardMetricModel.fromJson(Map<String, dynamic> json) {
    return DashboardMetricModel(
      key: json['key'] as String? ?? '',
      label: json['label'] as String? ?? '',
      value: json['value'] as int? ?? 0,
      icon: json['icon'] as String? ?? '',
    );
  }
}

class DashboardActivityModel {
  const DashboardActivityModel({
    required this.title,
    required this.subtitle,
    required this.status,
    this.createdAt,
  });

  final String title;
  final String subtitle;
  final String status;
  final DateTime? createdAt;

  factory DashboardActivityModel.fromJson(Map<String, dynamic> json) {
    return DashboardActivityModel(
      title: json['title'] as String? ?? '',
      subtitle: json['subtitle'] as String? ?? '',
      status: json['status'] as String? ?? '',
      createdAt: json['created_at'] == null
          ? null
          : DateTime.tryParse(json['created_at'] as String),
    );
  }
}

class DashboardSummaryModel {
  const DashboardSummaryModel({
    required this.role,
    required this.title,
    required this.subtitle,
    required this.metrics,
    required this.recentActivity,
  });

  final String role;
  final String title;
  final String subtitle;
  final List<DashboardMetricModel> metrics;
  final List<DashboardActivityModel> recentActivity;

  factory DashboardSummaryModel.fromJson(Map<String, dynamic> json) {
    return DashboardSummaryModel(
      role: json['role'] as String? ?? '',
      title: json['title'] as String? ?? '',
      subtitle: json['subtitle'] as String? ?? '',
      metrics: ((json['metrics'] as List?) ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(DashboardMetricModel.fromJson)
          .toList(),
      recentActivity: ((json['recent_activity'] as List?) ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(DashboardActivityModel.fromJson)
          .toList(),
    );
  }
}
