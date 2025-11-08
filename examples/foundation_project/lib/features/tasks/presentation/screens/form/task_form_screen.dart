import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:foundation_project/core/foundation/base_screen.dart';
import 'package:foundation_project/features/home/domain/models/task.dart';
import 'package:foundation_project/features/tasks/presentation/screens/form/task_form_view_model.dart';
import 'package:foundation_project/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

class TaskFormScreen
    extends BaseScreen<TaskFormViewModel, TaskFormViewModelState> {
  const TaskFormScreen({super.key, this.initialTask});

  final Task? initialTask;

  @override
  void onInitialize(WidgetRef ref) {
    super.onInitialize(ref);
    ref.read(getViewModelProvider().notifier).initialize(initialTask);
  }

  @override
  NotifierProvider<TaskFormViewModel, TaskFormViewModelState>
      getViewModelProvider() {
    return taskFormViewModelProvider;
  }

  @override
  Future<void> onRefresh(TaskFormViewModel viewModel) async {
    // No refresh behavior for form screen
  }

  @override
  Widget buildContent(
    BuildContext context,
    TaskFormViewModel viewModel,
    TaskFormViewModelState viewModelState,
    WidgetRef ref,
  ) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          viewModelState.isEditMode ? l10n.editTask : l10n.addTask,
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: TaskFormBody(
            state: viewModelState,
            onTitleChanged: viewModel.updateTitle,
            onDescriptionChanged: viewModel.updateDescription,
            onPriorityChanged: viewModel.updatePriority,
            onStatusChanged: viewModel.updateStatus,
            onDueDateChanged: viewModel.updateDueDate,
            onSubmit: () async {
              final task = await viewModel.submit();
              if (task != null && context.mounted) {
                Navigator.of(context).pop(task);
              }
            },
          ),
        ),
      ),
    );
  }
}

class TaskFormBody extends StatefulWidget {
  const TaskFormBody({
    super.key,
    required this.state,
    required this.onTitleChanged,
    required this.onDescriptionChanged,
    required this.onPriorityChanged,
    required this.onStatusChanged,
    required this.onDueDateChanged,
    required this.onSubmit,
  });

  final TaskFormViewModelState state;
  final ValueChanged<String> onTitleChanged;
  final ValueChanged<String> onDescriptionChanged;
  final ValueChanged<TaskPriority> onPriorityChanged;
  final ValueChanged<TaskStatus> onStatusChanged;
  final ValueChanged<DateTime?> onDueDateChanged;
  final Future<void> Function() onSubmit;

  @override
  State<TaskFormBody> createState() => _TaskFormBodyState();
}

class _TaskFormBodyState extends State<TaskFormBody> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.state.title);
    _descriptionController =
        TextEditingController(text: widget.state.description);
  }

  @override
  void didUpdateWidget(covariant TaskFormBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.state.title != _titleController.text) {
      _titleController
        ..text = widget.state.title
        ..selection = TextSelection.fromPosition(
          TextPosition(offset: widget.state.title.length),
        );
    }
    if (widget.state.description != _descriptionController.text) {
      _descriptionController
        ..text = widget.state.description
        ..selection = TextSelection.fromPosition(
          TextPosition(offset: widget.state.description.length),
        );
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final titleError = widget.state.fieldErrors[TaskFormField.title];
    final dueDateError = widget.state.fieldErrors[TaskFormField.dueDate];

    return Form(
      child: ListView(
        children: [
          TextFormField(
            controller: _titleController,
            onChanged: widget.onTitleChanged,
            decoration: InputDecoration(
              labelText: l10n.taskTitleLabel,
              hintText: l10n.taskTitleHint,
              errorText: titleError != null
                  ? _mapFieldErrorToMessage(titleError, l10n)
                  : null,
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _descriptionController,
            minLines: 3,
            maxLines: 6,
            onChanged: widget.onDescriptionChanged,
            decoration: InputDecoration(
              labelText: l10n.taskDescriptionLabel,
              hintText: l10n.taskDescriptionHint,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            l10n.taskPriorityLabel,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: TaskPriority.values.map((priority) {
              final selected = widget.state.priority == priority;
              return ChoiceChip(
                label: Text(_mapPriorityToLabel(priority, l10n)),
                selected: selected,
                onSelected: (_) => widget.onPriorityChanged(priority),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          Text(
            l10n.taskStatusLabel,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: TaskStatus.values.map((status) {
              final selected = widget.state.status == status;
              return ChoiceChip(
                label: Text(_mapStatusToLabel(status, l10n)),
                selected: selected,
                onSelected: (_) => widget.onStatusChanged(status),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          InputDecorator(
            decoration: InputDecoration(
              labelText: l10n.taskDueDate,
              errorText: dueDateError != null
                  ? _mapFieldErrorToMessage(dueDateError, l10n)
                  : null,
              helperText: widget.state.dueDate != null
                  ? l10n.taskDueDateHelper(
                      DateFormat.yMMMMd().format(widget.state.dueDate!),
                    )
                  : l10n.noDueDate,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.state.dueDate != null
                        ? DateFormat.yMMMMd().format(widget.state.dueDate!)
                        : l10n.noDueDate,
                  ),
                ),
                IconButton(
                  tooltip: l10n.selectDueDate,
                  onPressed: () async {
                    final now = DateTime.now();
                    final selectedDate = await showDatePicker(
                      context: context,
                      initialDate: widget.state.dueDate ?? now,
                      firstDate: DateTime(now.year - 5),
                      lastDate: DateTime(now.year + 5),
                    );
                    if (selectedDate != null) {
                      widget.onDueDateChanged(selectedDate);
                    }
                  },
                  icon: const Icon(Icons.event),
                ),
                if (widget.state.dueDate != null)
                  IconButton(
                    tooltip: l10n.clearDueDate,
                    onPressed: () => widget.onDueDateChanged(null),
                    icon: const Icon(Icons.close),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          FilledButton.icon(
            onPressed: widget.state.isSaving ? null : widget.onSubmit,
            icon: const Icon(Icons.save),
            label: Text(l10n.save),
          ),
        ],
      ),
    );
  }

  String _mapPriorityToLabel(TaskPriority priority, AppLocalizations l10n) {
    switch (priority) {
      case TaskPriority.low:
        return l10n.taskPriorityLow;
      case TaskPriority.medium:
        return l10n.taskPriorityMedium;
      case TaskPriority.high:
        return l10n.taskPriorityHigh;
    }
  }

  String _mapStatusToLabel(TaskStatus status, AppLocalizations l10n) {
    switch (status) {
      case TaskStatus.active:
        return l10n.taskStatusActive;
      case TaskStatus.completed:
        return l10n.taskStatusCompleted;
      case TaskStatus.overdue:
        return l10n.taskStatusOverdue;
    }
  }

  String _mapFieldErrorToMessage(
    TaskFormFieldError error,
    AppLocalizations l10n,
  ) {
    switch (error) {
      case TaskFormFieldError.emptyTitle:
        return l10n.taskTitleRequired;
      case TaskFormFieldError.dueDateInPast:
        return l10n.taskDueDateInPast;
    }
  }
}
