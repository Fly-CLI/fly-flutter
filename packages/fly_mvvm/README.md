# fly_mvvm

MVVM base classes for ViewModels and Screens for Flutter applications.

## Features

- Base ViewModel class with Riverpod integration
- Base Screen class with lifecycle management
- ViewModel state management
- Async operation coordination
- Feedback coordination

## Usage

```dart
import 'package:fly_mvvm/fly_mvvm.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Define state
class MyState extends BaseViewModelState {
  final String? data;
  
  MyState({super.isLoading, super.error, this.data});
  
  @override
  MyState copyWith({
    bool? isLoading,
    String? error,
    bool updateError = false,
    String? data,
  }) {
    return MyState(
      isLoading: isLoading ?? this.isLoading,
      error: updateError ? error : this.error,
      data: data ?? this.data,
    );
  }
}

// Define ViewModel
class MyViewModel extends FlyViewModel<MyState> {
  @override
  MyState build() => MyState();
  
  Future<void> loadData() async {
    final result = await runAsyncOperation(() => repository.fetchData());
    if (result.isSuccess) {
      state = state.copyWith(data: result.data);
    }
  }
}

// Define Screen
class MyScreen extends FlyScreen<MyViewModel, MyState> {
  static final _provider = NotifierProvider<MyViewModel, MyState>(
    () => MyViewModel(),
  );
  
  @override
  NotifierProvider<MyViewModel, MyState> getViewModelProvider() => _provider;
  
  @override
  Future<void> onRefresh(MyViewModel viewModel) async {
    await viewModel.loadData();
  }
  
  @override
  Widget buildContent(
    BuildContext context,
    MyViewModel viewModel,
    MyState state,
    WidgetRef ref,
  ) {
    if (state.isLoading) {
      return const CircularProgressIndicator();
    }
    return Text(state.data ?? 'No data');
  }
}
```

