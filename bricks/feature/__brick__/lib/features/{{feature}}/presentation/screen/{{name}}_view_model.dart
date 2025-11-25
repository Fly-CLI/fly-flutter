{{#with_viewmodel}}
{{#use_riverpod}}
import 'package:flutter_riverpod/flutter_riverpod.dart';
{{/use_riverpod}}
import 'package:fly_mvvm/fly_mvvm.dart';

import '../../../../../core/foundation/screen/base_view_model.dart';

class {{name.pascalCase()}}ViewModelState implements FlyViewModelState<{{name.pascalCase()}}ViewModelState> {
  const {{name.pascalCase()}}ViewModelState({
    this.isLoading = false,
    this.error,
    this.message = 'You are ready to build with Fly.',
  });

  @override
  final bool isLoading;

  @override
  final String? error;

  final String message;

  @override
  bool get hasError => error != null;

  @override
  {{name.pascalCase()}}ViewModelState copyWith({
    bool? isLoading,
    String? error,
    bool updateError = false,
    String? message,
  }) {
    return {{name.pascalCase()}}ViewModelState(
      isLoading: isLoading ?? this.isLoading,
      error: updateError ? error : this.error,
      message: message ?? this.message,
    );
  }

  @override
  {{name.pascalCase()}}ViewModelState withError(String? error) => copyWith(error: error, updateError: true);

  @override
  {{name.pascalCase()}}ViewModelState withLoading(bool isLoading) => copyWith(isLoading: isLoading);

  @override
  {{name.pascalCase()}}ViewModelState clearError() => copyWith(error: null, updateError: true);

  factory {{name.pascalCase()}}ViewModelState.initial() => const {{name.pascalCase()}}ViewModelState();
}

class {{name.pascalCase()}}ViewModel extends BaseViewModel<{{name.pascalCase()}}ViewModelState> {
  @override
  {{name.pascalCase()}}ViewModelState build() => {{name.pascalCase()}}ViewModelState.initial();

  Future<void> refresh() async {
    await runAsyncOperation(() async {
      state = state.copyWith(message: 'Refreshed at ${DateTime.now().toIso8601String()}');
    });
  }
}

{{#use_riverpod}}
final {{name}}ViewModelProvider = NotifierProvider<{{name.pascalCase()}}ViewModel, {{name.pascalCase()}}ViewModelState>(
  {{name.pascalCase()}}ViewModel.new,
);
{{/use_riverpod}}
{{/with_viewmodel}}

