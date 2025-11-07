import 'dart:async' show unawaited;

import 'package:flutter/foundation.dart';
import 'package:foundation_project/core/foundation/foundation.dart';
import 'package:foundation_project/core/di/global_container.dart';
import 'package:foundation_project/core/providers/logger_provider.dart';

typedef SuccessFeedbackHandler = void Function(String message);
typedef ErrorFeedbackHandler = void Function(
  String message,
  VoidCallback retryAction,
);

class ViewModelFeedbackHandlers {
  final SuccessFeedbackHandler? showSuccess;
  final ErrorFeedbackHandler? showError;

  const ViewModelFeedbackHandlers({
    this.showSuccess,
    this.showError,
  });

  static const ViewModelFeedbackHandlers none = ViewModelFeedbackHandlers();
}

class ViewModelAsyncCoordinator {
  final AsyncOperationHandler _asyncHandler;

  ViewModelAsyncCoordinator({AsyncOperationHandler? asyncHandler})
      : _asyncHandler = asyncHandler ??
            AsyncOperationHandler(
              logger: GlobalContainer.instance
                  .read(loggerProvider('AsyncOperationHandler')),
            );

  Future<AppResult<R>> execute<R>(
    Future<R> Function() operation, {
    String? errorMessage,
    Duration? timeout,
    bool resetError = true,
    void Function()? onFinally,
    void Function(bool isLoading)? onLoadingChanged,
    void Function(String? errorMessage)? onErrorChanged,
    String? successMessage,
    bool canShowSuccess = true,
    bool canShowError = true,
    ViewModelFeedbackHandlers feedbackHandlers =
        ViewModelFeedbackHandlers.none,
  }) async {
    final result = await _asyncHandler.runAsyncOperation(
      operation,
      errorMessage: errorMessage,
      timeout: timeout ?? AsyncOperationConfig.standardTimeout,
      onLoadingChanged: onLoadingChanged,
      onErrorChanged: onErrorChanged,
      onNotify: () {},
      resetError: resetError,
      notifyChange: false,
      onFinally: onFinally,
    );

    if (result.isSuccess) {
      if (canShowSuccess && successMessage != null) {
        feedbackHandlers.showSuccess?.call(successMessage);
      }
      return result;
    }

    if (canShowError) {
      final resolvedErrorMessage = errorMessage ?? result.error;
      if (resolvedErrorMessage != null) {
        void retryAction() {
          unawaited(execute<R>(
            operation,
            errorMessage: errorMessage,
            timeout: timeout,
            resetError: resetError,
            onFinally: onFinally,
            onLoadingChanged: onLoadingChanged,
            onErrorChanged: onErrorChanged,
            successMessage: successMessage,
            canShowSuccess: canShowSuccess,
            canShowError: canShowError,
            feedbackHandlers: feedbackHandlers,
          ));
        }

        feedbackHandlers.showError?.call(
          resolvedErrorMessage,
          retryAction,
        );
      }
    }

    return result;
  }
}


