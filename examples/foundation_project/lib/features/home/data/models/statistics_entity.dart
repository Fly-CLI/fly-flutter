/// Statistics entity for home screen
class StatisticsEntity {
  final int totalTasks;
  final int completedTasks;
  final int overdueTasks;
  final int todayTasks;

  const StatisticsEntity({
    required this.totalTasks,
    required this.completedTasks,
    required this.overdueTasks,
    required this.todayTasks,
  });

  /// Create empty statistics
  factory StatisticsEntity.empty() {
    return const StatisticsEntity(
      totalTasks: 0,
      completedTasks: 0,
      overdueTasks: 0,
      todayTasks: 0,
    );
  }

  /// Copy with new values
  StatisticsEntity copyWith({
    int? totalTasks,
    int? completedTasks,
    int? overdueTasks,
    int? todayTasks,
  }) {
    return StatisticsEntity(
      totalTasks: totalTasks ?? this.totalTasks,
      completedTasks: completedTasks ?? this.completedTasks,
      overdueTasks: overdueTasks ?? this.overdueTasks,
      todayTasks: todayTasks ?? this.todayTasks,
    );
  }

  @override
  String toString() {
    return 'StatisticsEntity(totalTasks: $totalTasks, completedTasks: $completedTasks, overdueTasks: $overdueTasks, todayTasks: $todayTasks)';
  }
}

