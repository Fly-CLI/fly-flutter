import 'package:foundation_project/core/mappers/base_mapper.dart';
import 'package:foundation_project/features/home/domain/models/task.dart';
import 'package:foundation_project/features/home/presentation/models/task_ui.dart';

/// Mapper for converting between domain and presentation models for Task
/// 
/// Extends BaseMapper for reusable mapping functionality
class TaskUiMapper extends BaseMapper<Task, TaskUi> {
  /// Singleton instance for instance-based usage
  static final TaskUiMapper instance = TaskUiMapper._();

  TaskUiMapper._();

  @override
  TaskUi toTarget(Task source, {Map<String, dynamic>? options}) {
    final isSelected = options?['isSelected'] as bool? ?? false;
    return TaskUi.fromDomain(source, isSelected: isSelected);
  }

  @override
  Task toSource(TaskUi target, {Map<String, dynamic>? options}) {
    return target.task;
  }
}

