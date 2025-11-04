/// Statistics model for home screen
class Statistics {
  final int totalTasks;
  final int completedTasks;
  final int overdueTasks;
  final int todayTasks;

  const Statistics({
    required this.totalTasks,
    required this.completedTasks,
    required this.overdueTasks,
    required this.todayTasks,
  });

  /// Create empty statistics
  factory Statistics.empty() {
    return const Statistics(
      totalTasks: 0,
      completedTasks: 0,
      overdueTasks: 0,
      todayTasks: 0,
    );
  }

  /// Copy with new values
  Statistics copyWith({
    int? totalTasks,
    int? completedTasks,
    int? overdueTasks,
    int? todayTasks,
  }) {
    return Statistics(
      totalTasks: totalTasks ?? this.totalTasks,
      completedTasks: completedTasks ?? this.completedTasks,
      overdueTasks: overdueTasks ?? this.overdueTasks,
      todayTasks: todayTasks ?? this.todayTasks,
    );
  }

  @override
  String toString() {
    return 'Statistics(totalTasks: $totalTasks, completedTasks: $completedTasks, overdueTasks: $overdueTasks, todayTasks: $todayTasks)';
  }
}

