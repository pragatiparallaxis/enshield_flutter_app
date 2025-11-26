class DashboardModel {
  final int totalWorkOrders;
  final int activeWorkOrders;
  final int completedWorkOrders;
  final int totalBatches;
  final int activeBatches;
  final int completedBatches;
  final double efficiencyRate;
  final double averageCompletionTime;
  final double materialUtilization;

  DashboardModel({
    required this.totalWorkOrders,
    required this.activeWorkOrders,
    required this.completedWorkOrders,
    required this.totalBatches,
    required this.activeBatches,
    required this.completedBatches,
    required this.efficiencyRate,
    required this.averageCompletionTime,
    required this.materialUtilization,
  });

  factory DashboardModel.fromJson(Map<String, dynamic> json) {
    return DashboardModel(
      totalWorkOrders: json['total_work_orders'] ?? 0,
      activeWorkOrders: json['active_work_orders'] ?? 0,
      completedWorkOrders: json['completed_work_orders'] ?? 0,
      totalBatches: json['total_batches'] ?? 0,
      activeBatches: json['active_batches'] ?? 0,
      completedBatches: json['completed_batches'] ?? 0,
      efficiencyRate: (json['efficiency_rate'] ?? 0).toDouble(),
      averageCompletionTime: (json['average_completion_time'] ?? 0).toDouble(),
      materialUtilization: (json['material_utilization'] ?? 0).toDouble(),
    );
  }
}
