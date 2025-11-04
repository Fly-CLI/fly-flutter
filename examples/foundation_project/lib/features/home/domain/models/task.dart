/// Domain model for Task - pure business entity without persistence concerns
/// 
/// This is the core business model that represents a task in the domain.
/// It contains only business logic properties and has no knowledge of
/// databases, serialization, or UI concerns.
class Task {
  final String id;
  final String title;
  final String? description;
  final TaskStatus status;
  final TaskPriority priority;
  final DateTime? dueDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Task({
    required this.id,
    required this.title,
    this.description,
    required this.status,
    required this.priority,
    this.dueDate,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create a copy of this task with updated fields
  Task copyWith({
    String? id,
    String? title,
    String? description,
    TaskStatus? status,
    TaskPriority? priority,
    DateTime? dueDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      dueDate: dueDate ?? this.dueDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Check if task is overdue
  bool get isOverdue {
    if (dueDate == null) return false;
    if (status == TaskStatus.completed) return false;
    return DateTime.now().isAfter(dueDate!);
  }

  /// Check if task is due today
  bool get isDueToday {
    if (dueDate == null) return false;
    final now = DateTime.now();
    final due = dueDate!;
    return now.year == due.year &&
        now.month == due.month &&
        now.day == due.day;
  }

  /// Check if task is completed
  bool get isCompleted => status == TaskStatus.completed;

  /// Check if task is active
  bool get isActive => status == TaskStatus.active;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Task &&
        other.id == id &&
        other.title == title &&
        other.description == description &&
        other.status == status &&
        other.priority == priority &&
        other.dueDate == dueDate &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      title,
      description,
      status,
      priority,
      dueDate,
      createdAt,
      updatedAt,
    );
  }

  @override
  String toString() {
    return 'Task(id: $id, title: $title, status: $status, priority: $priority, dueDate: $dueDate)';
  }
}

/// Task status enum
enum TaskStatus {
  active,
  completed,
  overdue,
}

/// Extension methods for TaskStatus enum
extension TaskStatusExtension on TaskStatus {
  /// Convert enum to string (lowercase)
  /// 
  /// Example: TaskStatus.active -> "active"
  String toValue() {
    return name.toLowerCase();
  }
}

/// Convert string to TaskStatus enum
/// 
/// [value] - String value to convert
/// Returns the matching TaskStatus or TaskStatus.active as default
TaskStatus taskStatusFromString(String value) {
  try {
    return TaskStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => TaskStatus.active,
    );
  } catch (e) {
    return TaskStatus.active;
  }
}

/// Task priority enum
enum TaskPriority {
  low,
  medium,
  high,
}

/// Extension methods for TaskPriority enum
extension TaskPriorityExtension on TaskPriority {
  /// Convert enum to string (lowercase)
  /// 
  /// Example: TaskPriority.low -> "low"
  String toValue() {
    return name.toLowerCase();
  }
}

/// Convert string to TaskPriority enum
/// 
/// [value] - String value to convert
/// Returns the matching TaskPriority or TaskPriority.medium as default
TaskPriority taskPriorityFromString(String value) {
  try {
    return TaskPriority.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => TaskPriority.medium,
    );
  } catch (e) {
    return TaskPriority.medium;
  }
}

