import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:foundation_project/features/home/domain/models/task.dart';
import 'package:foundation_project/l10n/app_localizations.dart';

class TaskListItem extends StatelessWidget {
  const TaskListItem({
    super.key,
    required this.task,
    required this.isSelected,
    required this.onTap,
    required this.onLongPress,
    required this.onSelectChanged,
    required this.onToggleCompletion,
    required this.onDelete,
  });

  final Task task;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final ValueChanged<bool?> onSelectChanged;
  final VoidCallback onToggleCompletion;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final dueDateLabel = _buildDueDateLabel(context, task);
    final statusLabel = _statusLabel(l10n, task.status);
    final priorityLabel = _priorityLabel(l10n, task.priority);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(
                value: isSelected,
                onChanged: onSelectChanged,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            task.title.isEmpty ? l10n.untitledTask : task.title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              decoration: task.isCompleted
                                  ? TextDecoration.lineThrough
                                  : TextDecoration.none,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _buildStatusChip(context, statusLabel, task.status),
                      ],
                    ),
                    if (task.description != null &&
                        task.description!.trim().isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        task.description!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.7),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _buildPriorityChip(
                          context,
                          priorityLabel,
                          task.priority,
                        ),
                        if (dueDateLabel != null)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.event,
                                size: 16,
                                color: _dueDateColor(context, task),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                dueDateLabel,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: _dueDateColor(context, task),
                                ),
                              ),
                            ],
                          ),
                        Text(
                          l10n.updatedAtLabel(
                            DateFormat.yMMMd().format(task.updatedAt),
                          ),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                children: [
                  IconButton(
                    onPressed: onToggleCompletion,
                    tooltip: task.isCompleted
                        ? l10n.markTaskActive
                        : l10n.markTaskCompleted,
                    icon: Icon(
                      task.isCompleted ? Icons.undo : Icons.check_circle,
                      color: task.isCompleted
                          ? theme.colorScheme.tertiary
                          : theme.colorScheme.primary,
                    ),
                  ),
                  IconButton(
                    onPressed: onDelete,
                    tooltip: l10n.deleteTask,
                    icon: Icon(
                      Icons.delete_outline,
                      color: theme.colorScheme.error,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(
    BuildContext context,
    String label,
    TaskStatus status,
  ) {
    final theme = Theme.of(context);
    final statusColor = _statusColor(context, status);
    return Chip(
      label: Text(label),
      backgroundColor: statusColor.withValues(
        alpha: status == TaskStatus.active ? 0.12 : 0.2,
      ),
      labelStyle: theme.textTheme.bodySmall?.copyWith(
        color: statusColor,
        fontWeight: FontWeight.w600,
      ),
      side: BorderSide.none,
    );
  }

  Widget _buildPriorityChip(
    BuildContext context,
    String label,
    TaskPriority priority,
  ) {
    final theme = Theme.of(context);
    final color = _priorityColor(context, priority);
    return Chip(
      avatar: Icon(
        Icons.flag,
        size: 16,
        color: color,
      ),
      label: Text(label),
      backgroundColor: color.withValues(alpha: 0.12),
      labelStyle: theme.textTheme.bodySmall?.copyWith(
        color: color,
        fontWeight: FontWeight.w600,
      ),
      side: BorderSide.none,
    );
  }

  Color _statusColor(BuildContext context, TaskStatus status) {
    final colorScheme = Theme.of(context).colorScheme;
    switch (status) {
      case TaskStatus.active:
        return colorScheme.primary;
      case TaskStatus.completed:
        return Colors.green.shade600;
      case TaskStatus.overdue:
        return colorScheme.error;
    }
  }

  Color _priorityColor(BuildContext context, TaskPriority priority) {
    switch (priority) {
      case TaskPriority.low:
        return Colors.green.shade600;
      case TaskPriority.medium:
        return Colors.orange.shade600;
      case TaskPriority.high:
        return Colors.red.shade600;
    }
  }

  Color _dueDateColor(BuildContext context, Task task) {
    if (task.isOverdue) {
      return Theme.of(context).colorScheme.error;
    }
    if (task.isDueToday) {
      return Theme.of(context).colorScheme.secondary;
    }
    return Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7);
  }

  String? _buildDueDateLabel(BuildContext context, Task task) {
    final dueDate = task.dueDate;
    if (dueDate == null) return null;
    final l10n = AppLocalizations.of(context);
    final formatted = DateFormat.yMMMd().format(dueDate);
    if (task.isOverdue) {
      return l10n.taskDueDateOverdue(formatted);
    }
    if (task.isDueToday) {
      return l10n.taskDueDateToday;
    }
    return l10n.taskDueDateOn(formatted);
  }

  String _statusLabel(AppLocalizations l10n, TaskStatus status) {
    switch (status) {
      case TaskStatus.active:
        return l10n.taskStatusActive;
      case TaskStatus.completed:
        return l10n.taskStatusCompleted;
      case TaskStatus.overdue:
        return l10n.taskStatusOverdue;
    }
  }

  String _priorityLabel(AppLocalizations l10n, TaskPriority priority) {
    switch (priority) {
      case TaskPriority.low:
        return l10n.taskPriorityLow;
      case TaskPriority.medium:
        return l10n.taskPriorityMedium;
      case TaskPriority.high:
        return l10n.taskPriorityHigh;
    }
  }
}
