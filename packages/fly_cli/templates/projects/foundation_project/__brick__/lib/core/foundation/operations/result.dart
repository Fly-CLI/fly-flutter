// Robust result pattern with sealed classes
sealed class AppResult<T> {
  const AppResult();

  // Factory constructors
  factory AppResult.success(T data) => Success(data);

  factory AppResult.failure(String message, [Object? error]) =>
      Failure(message, error);

  factory AppResult.loading() => const Loading();

  bool get isSuccess => this is Success<T>;

  bool get isFailure => this is Failure<T>;

  bool get isLoading => this is Loading<T>;

  T? get data => isSuccess ? (this as Success<T>).data : null;

  String? get error => isFailure ? (this as Failure<T>).message : null;

  R when<R>({
    required R Function(T data) success,
    required R Function(String message, Object? error) failure,
    required R Function() loading,
  }) {
    return switch (this) {
      Success<T>(data: final data) => success(data),
      Failure<T>(message: final message, originalError: final error) => failure(
        message,
        error,
      ),
      Loading<T>() => loading(),
    };
  }
}

class Success<T> extends AppResult<T> {
  @override
  final T data;

  const Success(this.data);

  @override
  String toString() => 'Success($data)';
}

class Failure<T> extends AppResult<T> {
  final String message;
  final Object? originalError;

  const Failure(this.message, [this.originalError]);

  @override
  String toString() => 'Failure($message)';
}

class Loading<T> extends AppResult<T> {
  const Loading();

  @override
  String toString() => 'Loading()';
}
