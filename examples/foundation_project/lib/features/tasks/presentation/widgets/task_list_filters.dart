import 'package:flutter/material.dart';
import 'package:foundation_project/features/home/domain/models/task.dart';
import 'package:foundation_project/l10n/app_localizations.dart';

class TaskListFilters extends StatefulWidget {
  const TaskListFilters({
    super.key,
    required this.searchQuery,
    required this.statusFilter,
    required this.onSearchChanged,
    required this.onClearSearch,
    required this.onStatusChanged,
  });

  final String searchQuery;
  final TaskStatus? statusFilter;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearSearch;
  final ValueChanged<TaskStatus?> onStatusChanged;

  @override
  State<TaskListFilters> createState() => _TaskListFiltersState();
}

class _TaskListFiltersState extends State<TaskListFilters> {
  late final TextEditingController _searchController =
      TextEditingController(text: widget.searchQuery);

  @override
  void didUpdateWidget(covariant TaskListFilters oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.searchQuery != _searchController.text) {
      _searchController
        ..text = widget.searchQuery
        ..selection = TextSelection.fromPosition(
          TextPosition(offset: widget.searchQuery.length),
        );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.taskListFiltersTitle,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _searchController,
                onChanged: widget.onSearchChanged,
                decoration: InputDecoration(
                  labelText: l10n.searchTasks,
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: widget.searchQuery.isNotEmpty
                      ? IconButton(
                          onPressed: () {
                            widget.onClearSearch();
                          },
                          tooltip: l10n.clearSearch,
                          icon: const Icon(Icons.clear),
                        )
                      : null,
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 180,
              child: DropdownButtonFormField<TaskStatus?>(
                initialValue: widget.statusFilter,
                onChanged: widget.onStatusChanged,
                decoration: InputDecoration(
                  labelText: l10n.filterByStatus,
                  border: const OutlineInputBorder(),
                ),
                items: [
                  null,
                  ...TaskStatus.values,
                ]
                    .map(
                      (status) => DropdownMenuItem<TaskStatus?>(
                        value: status,
                        child: Text(
                          status == null
                              ? l10n.filterAllStatuses
                              : _statusLabel(l10n, status),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ),
      ],
    );
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
}
