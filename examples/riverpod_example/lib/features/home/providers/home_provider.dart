import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'home_provider.g.dart';

// Counter Provider using Riverpod v3 syntax
@riverpod
int counter(Ref ref) => 0;

// Counter Notifier with additional methods using Riverpod v3 syntax
@riverpod
class CounterNotifier extends _$CounterNotifier {
  @override
  int build() => 0;

  void increment() => state++;
  void decrement() => state--;
  void reset() => state = 0;
}

// Todo Model
class Todo {

  Todo({
    required this.id,
    required this.title,
    required this.description,
    required this.createdAt,
  });
  final String id;
  final String title;
  final String description;
  final DateTime createdAt;

  Todo copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? createdAt,
  }) => Todo(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
    );
}

// Todos Provider using Riverpod v3 syntax
@riverpod
class TodosNotifier extends _$TodosNotifier {
  @override
  AsyncValue<List<Todo>> build() => const AsyncValue.data([]);

  void addTodo(String title, String description) {
    final todo = Todo(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      description: description,
      createdAt: DateTime.now(),
    );
    
    state.whenData((todos) {
      state = AsyncValue.data([...todos, todo]);
    });
  }

  void removeTodo(String id) {
    state.whenData((todos) {
      state = AsyncValue.data(todos.where((todo) => todo.id != id).toList());
    });
  }

  void updateTodo(String id, String title, String description) {
    state.whenData((todos) {
      state = AsyncValue.data(todos.map((todo) {
        if (todo.id == id) {
          return todo.copyWith(title: title, description: description);
        }
        return todo;
      }).toList(),
    );
    });
  }
}
