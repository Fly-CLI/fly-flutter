import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:foundation_project/core/foundation/base_screen.dart';
import 'package:foundation_project/features/home/domain/models/task.dart';
import 'package:foundation_project/features/tasks/presentation/navigation/task_route_args.dart';
import 'package:foundation_project/features/tasks/presentation/screens/detail/task_detail_view_model.dart';
import 'package:foundation_project/l10n/app_localizations.dart';
import 'package:foundation_project/shared/navigation/app_navigator.dart';
import 'package:foundation_project/shared/navigation/feature_screen_type.dart';
import 'package:intl/intl.dart';

class TaskDetailScreen
    extends BaseScreen<TaskDetailViewModel, TaskDetailViewModelState> {
  const TaskDetailScreen({
    super.key,
    required this.taskId,
    this.initialTask,
  });

  final String taskId;
  final Task? initialTask;

  @override
  void onInitialize(WidgetRef ref) {
    super.onInitialize(ref);
    final viewModel = ref.read(getViewModelProvider().notifier);
    if (initialTask != null) {
      viewModel.updateWith(initialTask!);
    }
    viewModel.loadTask(taskId);
  }

  @override
  NotifierProvider<TaskDetailViewModel, TaskDetailViewModelState>
      getViewModelProvider() {
    return taskDetailViewModelProvider;
  }

  @override
  Future<void> onRefresh(TaskDetailViewModel viewModel) async {
    await viewModel.refresh();
  }

  @override
  Widget buildContent(
    BuildContext context,
    TaskDetailViewModel viewModel,
    TaskDetailViewModelState viewModelState,
    WidgetRef ref,
  ) {
    final l10n = AppLocalizations.of(context);
    final task = viewModelState.task;

    if (!viewModelState.isLoading &&
        task == null &&
        viewModelState.hasInitialized) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted && Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.taskDetailTitle(taskId)),
        actions: [
          IconButton(
            tooltip: l10n.refresh,
            onPressed: () {
              viewModel.refresh();
            },
            icon: const Icon(Icons.refresh),
          ),
          if (task != null)
            IconButton(
              tooltip: l10n.editTask,
              onPressed: () async {
                final args = TaskFormScreenArgs(initialTask: task);
                await AppNavigator.instance.navigateTo(
                  FeatureScreen.taskForm,
                  arguments: args,
                );
              },
              icon: const Icon(Icons.edit),
            ),
          IconButton(
            tooltip: l10n.deleteTask,
            onPressed: task == null
                ? null
                : () => _confirmDelete(
                      context,
                      viewModel,
                      l10n,
                      task: task,
                    ),
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: task == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => onRefresh(viewModel),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(context, task, viewModelState),
                    const SizedBox(height: 16),
                    if (task.description != null &&
                        task.description!.isNotEmpty)
                      _buildDescriptionCard(context, task.description!),
                    const SizedBox(height: 16),
                    _buildMetadataCard(context, task),
                    const SizedBox(height: 24),
                    _buildActions(context, viewModel, viewModelState, task),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    Task task,
    TaskDetailViewModelState viewModelState,
  ) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          task.title.isEmpty ? l10n.untitledTask : task.title,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _statusChip(context, task.status),
            _priorityChip(context, task.priority),
            if (task.isOverdue)
              Chip(
                avatar: const Icon(Icons.warning_amber_rounded, size: 16),
                label: Text(l10n.taskStatusOverdue),
                backgroundColor:
                    theme.colorScheme.error.withValues(alpha: 0.12),
                labelStyle: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildDescriptionCard(BuildContext context, String description) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.taskDescriptionLabel,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: theme.textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetadataCard(BuildContext context, Task task) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final dateFormat = DateFormat.yMMMMd().add_Hm();
    final metadata = [
      _MetadataRow(
        icon: Icons.event,
        label: l10n.taskDueDate,
        value: task.dueDate != null
            ? dateFormat.format(task.dueDate!)
            : l10n.noDueDate,
      ),
      _MetadataRow(
        icon: Icons.calendar_today,
        label: l10n.createdAt,
        value: dateFormat.format(task.createdAt),
      ),
      _MetadataRow(
        icon: Icons.update,
        label: l10n.updatedAt,
        value: dateFormat.format(task.updatedAt),
      ),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.taskMetadataLabel,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            ...metadata.map(
              (row) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: row,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActions(
    BuildContext context,
    TaskDetailViewModel viewModel,
    TaskDetailViewModelState viewModelState,
    Task task,
  ) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton.icon(
          onPressed: viewModelState.isPerformingAction
              ? null
              : () => viewModel.toggleCompletion(),
          icon:
              Icon(task.isCompleted ? Icons.undo : Icons.check_circle_outline),
          label: Text(
            task.isCompleted ? l10n.markTaskActive : l10n.markTaskCompleted,
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: viewModelState.isPerformingAction
              ? null
              : () async {
                  final args = TaskFormScreenArgs(initialTask: task);
                  await AppNavigator.instance.navigateTo(
                    FeatureScreen.taskForm,
                    arguments: args,
                  );
                },
          icon: const Icon(Icons.edit_outlined),
          label: Text(l10n.editTask),
        ),
        const SizedBox(height: 12),
        TextButton.icon(
          onPressed: viewModelState.isPerformingAction
              ? null
              : () => _confirmDelete(
                    context,
                    viewModel,
                    l10n,
                    task: task,
                  ),
          icon: const Icon(Icons.delete_outline),
          label: Text(l10n.deleteTask),
        ),
      ],
    );
  }

  void _confirmDelete(
    BuildContext context,
    TaskDetailViewModel viewModel,
    AppLocalizations l10n, {
    Task? task,
  }) {
    final displayValue =
        (task == null || task.title.isEmpty) ? l10n.untitledTask : task.title;
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n.deleteTaskTitle),
          content: Text(l10n.deleteTaskConfirmation(displayValue)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop();
                viewModel.deleteTask();
              },
              child: Text(l10n.delete),
            ),
          ],
        );
      },
    );
  }

  Widget _statusChip(BuildContext context, TaskStatus status) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final label = () {
      switch (status) {
        case TaskStatus.active:
          return l10n.taskStatusActive;
        case TaskStatus.completed:
          return l10n.taskStatusCompleted;
        case TaskStatus.overdue:
          return l10n.taskStatusOverdue;
      }
    }();

    final color = () {
      switch (status) {
        case TaskStatus.active:
          return theme.colorScheme.primary;
        case TaskStatus.completed:
          return Colors.green.shade600;
        case TaskStatus.overdue:
          return theme.colorScheme.error;
      }
    }();

    return Chip(
      avatar: Icon(
        status == TaskStatus.completed ? Icons.check_circle : Icons.flag,
        size: 16,
        color: color,
      ),
      label: Text(label),
      backgroundColor: color.withValues(alpha: 0.12),
      labelStyle: theme.textTheme.bodySmall?.copyWith(
        color: color,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _priorityChip(BuildContext context, TaskPriority priority) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final label = () {
      switch (priority) {
        case TaskPriority.low:
          return l10n.taskPriorityLow;
        case TaskPriority.medium:
          return l10n.taskPriorityMedium;
        case TaskPriority.high:
          return l10n.taskPriorityHigh;
      }
    }();

    final color = () {
      switch (priority) {
        case TaskPriority.low:
          return Colors.green.shade600;
        case TaskPriority.medium:
          return Colors.orange.shade600;
        case TaskPriority.high:
          return Colors.red.shade600;
      }
    }();

    return Chip(
      avatar: Icon(Icons.flag, size: 16, color: color),
      label: Text(label),
      backgroundColor: color.withValues(alpha: 0.12),
      labelStyle: theme.textTheme.bodySmall?.copyWith(
        color: color,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _MetadataRow extends StatelessWidget {
  const _MetadataRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
