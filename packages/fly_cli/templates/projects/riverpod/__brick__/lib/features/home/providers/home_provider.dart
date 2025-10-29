import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:fly_core/fly_core.dart';

part 'home_provider.g.dart';

// Counter Provider using Riverpod v3 syntax
@riverpod
int counter(CounterRef ref) => 0;

// Counter Notifier with additional methods using Riverpod v3 syntax
@riverpod
class CounterNotifier extends _$CounterNotifier {
  @override
  int build() => 0;

  void increment() => state++;
  void decrement() => state--;
  void reset() => state = 0;
}

class HomeViewModel extends BaseViewModel {
  HomeViewModel();

  void incrementCounter() {
    // This would typically update a provider
    // For now, we'll just simulate some work
    runSafe(() async {
      await Future<void>.delayed(const Duration(milliseconds: 100));
      // Counter is managed by the provider, not the view model
    });
  }

  @override
  Future<void> initialize() async {
    // Initialize any data needed for the home screen
    await runSafe(() async {
      await Future<void>.delayed(const Duration(milliseconds: 500));
    });
  }
}

@riverpod
class HomeViewModelNotifier extends _$HomeViewModelNotifier {
  @override
  ViewState build() => const ViewState.idle();

  Future<void> initialize() async {
    final viewModel = HomeViewModel();
    await viewModel.initialize();
    state = const ViewState.success();
  }
}
