import 'package:foundation_project/features/home/domain/models/task.dart';

/// Presentation model for Task - UI-specific model
/// 
/// This model is used in the presentation layer (ViewModels, widgets)
/// and contains UI-specific concerns like formatting, display logic, etc.
class TaskUi {
  final Task task;
  final bool isSelected;
  final String formattedDueDate;
  final String formattedCreatedAt;
  final String formattedUpdatedAt;
  final String displayTitle;
  final String displayDescription;
  final String statusLabel;
  final String priorityLabel;
  final String priorityColor;

  const TaskUi({
    required this.task,
    this.isSelected = false,
    required this.formattedDueDate,
    required this.formattedCreatedAt,
    required this.formattedUpdatedAt,
    required this.displayTitle,
    required this.displayDescription,
    required this.statusLabel,
    required this.priorityLabel,
    required this.priorityColor,
  });

  /// Create TaskUi from domain Task
  factory TaskUi.fromDomain(Task task, {bool isSelected = false}) {
    return TaskUi(
      task: task,
      isSelected: isSelected,
      formattedDueDate: task.dueDate != null ? _formatDate(task.dueDate!) : 'No due date',
      formattedCreatedAt: _formatDate(task.createdAt),
      formattedUpdatedAt: _formatDate(task.updatedAt),
      displayTitle: task.title.isEmpty ? 'Untitled Task' : task.title,
      displayDescription: task.description ?? 'No description',
      statusLabel: _getStatusLabel(task.status),
      priorityLabel: _getPriorityLabel(task.priority),
      priorityColor: _getPriorityColor(task.priority),
    );
  }

  /// Create TaskUi with updated selection state
  TaskUi copyWith({
    Task? task,
    bool? isSelected,
    String? formattedDueDate,
    String? formattedCreatedAt,
    String? formattedUpdatedAt,
    String? displayTitle,
    String? displayDescription,
    String? statusLabel,
    String? priorityLabel,
    String? priorityColor,
  }) {
    return TaskUi(
      task: task ?? this.task,
      isSelected: isSelected ?? this.isSelected,
      formattedDueDate: formattedDueDate ?? this.formattedDueDate,
      formattedCreatedAt: formattedCreatedAt ?? this.formattedCreatedAt,
      formattedUpdatedAt: formattedUpdatedAt ?? this.formattedUpdatedAt,
      displayTitle: displayTitle ?? this.displayTitle,
      displayDescription: displayDescription ?? this.displayDescription,
      statusLabel: statusLabel ?? this.statusLabel,
      priorityLabel: priorityLabel ?? this.priorityLabel,
      priorityColor: priorityColor ?? this.priorityColor,
    );
  }

  /// Format date for display
  static String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  /// Get status label for display
  static String _getStatusLabel(TaskStatus status) {
    switch (status) {
      case TaskStatus.active:
        return 'Active';
      case TaskStatus.completed:
        return 'Completed';
      case TaskStatus.overdue:
        return 'Overdue';
    }
  }

  /// Get priority label for display
  static String _getPriorityLabel(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.low:
        return 'Low';
      case TaskPriority.medium:
        return 'Medium';
      case TaskPriority.high:
        return 'High';
    }
  }

  /// Get priority color for UI
  static String _getPriorityColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.low:
        return 'green';
      case TaskPriority.medium:
        return 'orange';
      case TaskPriority.high:
        return 'red';
    }
  }

  /// Check if task is overdue
  bool get isOverdue => task.isOverdue;

  /// Check if task is due today
  bool get isDueToday => task.isDueToday;

  /// Check if task is completed
  bool get isCompleted => task.isCompleted;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TaskUi &&
        other.task == task &&
        other.isSelected == isSelected;
  }

  @override
  int get hashCode => Object.hash(task, isSelected);

  @override
  String toString() {
    return 'TaskUi(task: ${task.id}, isSelected: $isSelected, title: $displayTitle, status: $statusLabel)';
  }
}

