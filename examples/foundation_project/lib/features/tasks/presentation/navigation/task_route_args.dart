import 'package:foundation_project/features/home/domain/models/task.dart';

class TaskDetailScreenArgs {
  const TaskDetailScreenArgs({
    required this.taskId,
    this.initialTask,
  });

  final String taskId;
  final Task? initialTask;
}

class TaskFormScreenArgs {
  const TaskFormScreenArgs({this.initialTask});

  final Task? initialTask;

  bool get isEditMode => initialTask != null;
}
