import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fly_mvvm/fly_mvvm.dart';

import '../../../core/foundation/screen/base_view_model.dart';

class HomeViewModelState implements FlyViewModelState<HomeViewModelState> {
  const HomeViewModelState({
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
  HomeViewModelState copyWith({
    bool? isLoading,
    String? error,
    bool updateError = false,
    String? message,
  }) {
    return HomeViewModelState(
      isLoading: isLoading ?? this.isLoading,
      error: updateError ? error : this.error,
      message: message ?? this.message,
    );
  }

  @override
  HomeViewModelState withError(String? error) => copyWith(error: error, updateError: true);

  @override
  HomeViewModelState withLoading(bool isLoading) => copyWith(isLoading: isLoading);

  @override
  HomeViewModelState clearError() => copyWith(error: null, updateError: true);

  factory HomeViewModelState.initial() => const HomeViewModelState();
}

class HomeViewModel extends BaseViewModel<HomeViewModelState> {
  @override
  HomeViewModelState build() => HomeViewModelState.initial();

  Future<void> refresh() async {
    await runAsyncOperation(() async {
      state = state.copyWith(message: 'Refreshed at ${DateTime.now().toIso8601String()}');
    });
  }
}

final homeViewModelProvider = NotifierProvider<HomeViewModel, HomeViewModelState>(
  HomeViewModel.new,
);
