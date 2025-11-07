import 'package:flutter_test/flutter_test.dart';
import 'package:foundation_project/foundation/mvvm/view_model/view_model_state.dart';

void main() {
  group('FlyViewModelState', () {
    group('BaseViewModelState', () {
      test('should create state with default values', () {
        final state = BaseViewModelState();
        expect(state.isLoading, isFalse);
        expect(state.error, isNull);
        expect(state.hasError, isFalse);
      });

      test('should create state with custom values', () {
        final state = BaseViewModelState(
          isLoading: true,
          error: 'Test error',
        );
        expect(state.isLoading, isTrue);
        expect(state.error, equals('Test error'));
        expect(state.hasError, isTrue);
      });

      test('withLoading should create new state with loading flag', () {
        final state = BaseViewModelState();
        final newState = state.withLoading(true);
        expect(newState.isLoading, isTrue);
        expect(state.isLoading, isFalse); // Original unchanged
      });

      test('withError should create new state with error', () {
        final state = BaseViewModelState();
        final newState = state.withError('Error message');
        expect(newState.error, equals('Error message'));
        expect(newState.hasError, isTrue);
        expect(state.error, isNull); // Original unchanged
      });

      test('clearError should create new state without error', () {
        final state = BaseViewModelState(error: 'Error');
        final newState = state.clearError();
        expect(newState.error, isNull);
        expect(newState.hasError, isFalse);
        expect(state.error, equals('Error')); // Original unchanged
      });

      test('copyWith should create new state with modified values', () {
        final state = BaseViewModelState();
        final newState = state.copyWith(isLoading: true);
        expect(newState.isLoading, isTrue);
        expect(state.isLoading, isFalse);
      });

      test('should be equal when properties match', () {
        final state1 = BaseViewModelState(isLoading: true, error: 'error');
        final state2 = BaseViewModelState(isLoading: true, error: 'error');
        expect(state1, equals(state2));
      });

      test('should not be equal when properties differ', () {
        final state1 = BaseViewModelState(isLoading: true);
        final state2 = BaseViewModelState(isLoading: false);
        expect(state1, isNot(equals(state2)));
      });
    });

    group('ViewModelStateExtensions', () {
      test('hasError should return true when error exists', () {
        final state = BaseViewModelState(error: 'error');
        expect(state.hasError, isTrue);
      });

      test('errorMessage should return error or empty string', () {
        final stateWithError = BaseViewModelState(error: 'error');
        final stateWithoutError = BaseViewModelState();
        expect(stateWithError.errorMessage, equals('error'));
        expect(stateWithoutError.errorMessage, equals(''));
      });

      test('isBusy should return isLoading value', () {
        final busyState = BaseViewModelState(isLoading: true);
        final idleState = BaseViewModelState(isLoading: false);
        expect(busyState.isBusy, isTrue);
        expect(idleState.isBusy, isFalse);
      });

      test('isReady should return true when not loading and no error', () {
        final readyState = BaseViewModelState(isLoading: false, error: null);
        final loadingState = BaseViewModelState(isLoading: true);
        final errorState = BaseViewModelState(error: 'error');
        expect(readyState.isReady, isTrue);
        expect(loadingState.isReady, isFalse);
        expect(errorState.isReady, isFalse);
      });
    });
  });
}

