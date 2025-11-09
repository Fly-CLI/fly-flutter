import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:foundation_project/core/foundation/base_screen.dart';
import 'package:foundation_project/features/home/domain/models/task.dart';
import 'package:foundation_project/features/tasks/presentation/screens/list/tasks_view_model.dart';
import 'package:foundation_project/features/tasks/presentation/navigation/task_route_args.dart';
import 'package:foundation_project/features/tasks/presentation/widgets/task_list_filters.dart';
import 'package:foundation_project/features/tasks/presentation/widgets/task_list_item.dart';
import 'package:foundation_project/l10n/app_localizations.dart';
import 'package:foundation_project/shared/navigation/app_navigator.dart';
import 'package:foundation_project/shared/navigation/feature_screen_type.dart';

class TasksScreen extends BaseScreen<TasksViewModel, TasksViewModelState> {
  const TasksScreen({super.key});

  @override
  NotifierProvider<TasksViewModel, TasksViewModelState> getViewModelProvider() {
    return tasksViewModelProvider;
  }

  @override
  Future<void> onRefresh(TasksViewModel viewModel) {
    return viewModel.refresh();
  }

  @override
  Widget buildContent(
    BuildContext context,
    TasksViewModel viewModel,
    TasksViewModelState viewModelState,
    WidgetRef ref,
  ) {
    final l10n = AppLocalizations.of(context);
    final tasks = viewModelState.pagination.items;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.tasks),
        actions: [
          IconButton(
            tooltip: l10n.addTask,
            onPressed: () {
              AppNavigator.instance.navigateTo(FeatureScreen.taskForm);
            },
            icon: const Icon(Icons.add_task),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TaskListFilters(
              searchQuery: viewModelState.searchQuery,
              statusFilter: viewModelState.statusFilter,
              onSearchChanged: viewModel.applySearch,
              onClearSearch: viewModel.clearSearch,
              onStatusChanged: viewModel.applyStatusFilter,
            ),
            if (viewModelState.hasSelection) ...[
              const SizedBox(height: 12),
              _SelectedTasksToolbar(
                selectedCount: viewModelState.selectedTaskIds.length,
                onClearSelection: viewModel.clearSelection,
                onDeleteSelected: viewModel.deleteSelectedTasks,
              ),
            ],
            const SizedBox(height: 16),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => onRefresh(viewModel),
                child: _TaskListView(
                  tasks: tasks,
                  isLoading: viewModelState.isLoading,
                  isLoadingMore: viewModelState.isLoadingMore,
                  hasMore: viewModelState.pagination.hasMore,
                  onLoadMore: viewModel.loadMore,
                  onOpenTask: (task) {
                    AppNavigator.instance.navigateTo(
                      FeatureScreen.taskDetail,
                      arguments: TaskDetailScreenArgs(
                        taskId: task.id,
                        initialTask: task,
                      ),
                    );
                  },
                  onToggleCompletion: viewModel.toggleComplete,
                  onDeleteTask: viewModel.deleteTask,
                  onToggleSelection: viewModel.toggleTaskSelection,
                  isTaskSelected: viewModelState.isTaskSelected,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TaskListView extends StatelessWidget {
  const _TaskListView({
    required this.tasks,
    required this.isLoading,
    required this.isLoadingMore,
    required this.hasMore,
    required this.onLoadMore,
    required this.onOpenTask,
    required this.onToggleCompletion,
    required this.onDeleteTask,
    required this.onToggleSelection,
    required this.isTaskSelected,
  });

  final List<Task> tasks;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final VoidCallback onLoadMore;
  final ValueChanged<Task> onOpenTask;
  final ValueChanged<String> onToggleCompletion;
  final ValueChanged<String> onDeleteTask;
  final ValueChanged<String> onToggleSelection;
  final bool Function(String taskId) isTaskSelected;

  @override
  Widget build(BuildContext context) {
    if (isLoading && tasks.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (tasks.isEmpty) {
      return _EmptyState(
        onCreateTask: () {
          AppNavigator.instance.navigateTo(FeatureScreen.taskForm);
        },
      );
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification.metrics.pixels >=
                notification.metrics.maxScrollExtent - 200 &&
            hasMore &&
            !isLoadingMore) {
          onLoadMore();
        }
        return false;
      },
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: tasks.length + (isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= tasks.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final task = tasks[index];
          return TaskListItem(
            task: task,
            isSelected: isTaskSelected(task.id),
            onTap: () => onOpenTask(task),
            onLongPress: () => onToggleSelection(task.id),
            onSelectChanged: (_) => onToggleSelection(task.id),
            onToggleCompletion: () => onToggleCompletion(task.id),
            onDelete: () => _confirmDelete(context, task, onDeleteTask),
          );
        },
      ),
    );
  }

  void _confirmDelete(
    BuildContext context,
    Task task,
    ValueChanged<String> onDelete,
  ) {
    final l10n = AppLocalizations.of(context);
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n.deleteTaskTitle),
          content: Text(
            l10n.deleteTaskConfirmation(
              task.title.isEmpty ? l10n.untitledTask : task.title,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop();
                onDelete(task.id);
              },
              child: Text(l10n.delete),
            ),
          ],
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onCreateTask});

  final VoidCallback onCreateTask;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.task_alt,
            size: 72,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            l10n.noTasksTitle,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.noTasksDescription,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: onCreateTask,
            icon: const Icon(Icons.add),
            label: Text(l10n.createFirstTask),
          ),
        ],
      ),
    );
  }
}

class _SelectedTasksToolbar extends StatelessWidget {
  const _SelectedTasksToolbar({
    required this.selectedCount,
    required this.onClearSelection,
    required this.onDeleteSelected,
  });

  final int selectedCount;
  final VoidCallback onClearSelection;
  final VoidCallback onDeleteSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Card(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Text(
              l10n.selectedTaskCount(selectedCount),
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: onClearSelection,
              child: Text(l10n.clearSelection),
            ),
            const SizedBox(width: 8),
            FilledButton.icon(
              onPressed: onDeleteSelected,
              icon: const Icon(Icons.delete),
              label: Text(l10n.deleteSelected),
            ),
          ],
        ),
      ),
    );
  }
}
