/// Abstract interface for error reporting services.
/// 
/// This interface allows the foundation to report errors to external services
/// (like Firebase Crashlytics, Sentry, etc.) without creating hard dependencies
/// on specific implementations.
/// 
/// Applications should implement this interface to integrate their preferred
/// error reporting service.
/// 
/// **Example:**
/// ```dart
/// class CrashlyticsErrorReporter implements ErrorReporter {
///   @override
///   void recordError(
///     Object error,
///     StackTrace? stackTrace, {
///     String? reason,
///     Map<String, String>? customKeys,
///   }) {
///     CrashlyticsManager.instance.recordErrorWithCustomKeys(
///       error,
///       stackTrace,
///       reason: reason,
///       customKeys: customKeys,
///     );
///   }
/// }
/// ```
abstract class ErrorReporter {
  /// Records an error to the error reporting service.
  /// 
  /// [error] - The error object to report
  /// [stackTrace] - Optional stack trace associated with the error
  /// [reason] - Optional reason or context for the error
  /// [customKeys] - Optional custom key-value pairs to include with the error
  void recordError(
    Object error,
    StackTrace? stackTrace, {
    String? reason,
    Map<String, String>? customKeys,
  });
}

