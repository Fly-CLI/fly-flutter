import 'package:fly_localization/fly_localization.dart';

/// Default implementation of FoundationLocalizationProvider with English messages
///
/// This class provides default English localizations that can be used as a fallback
/// when no application-specific localization provider is available. Foundation
/// components will use these defaults when a localization provider is not provided.
///
/// **Usage:**
/// ```dart
/// // Use as fallback
/// final provider = appLocalizationProvider ?? DefaultFoundationLocalizationProvider();
///
/// // Use in tests
/// final handler = AsyncOperationHandler(
///   logger: logger,
///   localizations: DefaultFoundationLocalizationProvider(),
/// );
/// ```
class DefaultFoundationLocalizationProvider
    implements FoundationLocalizationProvider {
  /// Singleton instance for reuse
  static final DefaultFoundationLocalizationProvider _instance =
      DefaultFoundationLocalizationProvider._internal();

  /// Get the singleton instance
  factory DefaultFoundationLocalizationProvider() => _instance;

  /// Private constructor for singleton
  DefaultFoundationLocalizationProvider._internal();

  // ============================================================================
  // Network Error Messages
  // ============================================================================

  @override
  String get networkErrorConnectionRecovery =>
      'Connection failed. Please check your connection and try again.';

  @override
  String get networkErrorTimeoutRecovery =>
      'Request timed out. Please try again.';

  @override
  String get networkErrorDnsRecovery =>
      'Failed to resolve hostname. Please check your connection and try again.';

  @override
  String get networkErrorNoInternetRecovery =>
      'No internet connection. Please check your connection and try again.';

  @override
  String get networkErrorAuthRecovery =>
      'Authentication error. Please log in again.';

  @override
  String get networkErrorNotFoundRecovery =>
      'Resource not found. Please check your request and try again.';

  @override
  String get networkErrorRateLimitRecovery =>
      'Too many requests. Please wait a moment and try again.';

  @override
  String get networkErrorServerRecovery =>
      'Server error. Please try again later.';

  @override
  String get networkErrorCertificateRecovery =>
      'Certificate error. Please check your connection and try again.';

  @override
  String get networkErrorUnknownRecovery =>
      'Unknown network error. Please try again.';

  @override
  String get networkErrorHttpRecovery => 'HTTP error. Please try again.';

  // ============================================================================
  // Network Error Base Messages
  // ============================================================================

  @override
  String get networkConnectionFailed =>
      'Network connection failed. Please check your connection and try again.';

  @override
  String get networkNoInternet =>
      'No internet connection. Please check your connection and try again.';

  @override
  String get networkTimeout => 'Request timed out. Please try again.';

  @override
  String get networkDnsFailed =>
      'Failed to resolve hostname. Please check your connection and try again.';

  @override
  String get networkCaptivePortal =>
      'Captive portal detected. Please connect to the network and try again.';

  @override
  String get networkCertificateError =>
      'Certificate error. Please check your connection and try again.';

  @override
  String get networkUnknownError =>
      'Unknown network error occurred. Please try again.';

  @override
  String get networkHttpClientError =>
      'Client error occurred. Please check your request and try again.';

  @override
  String get networkHttpServerError =>
      'Server error occurred. Please try again later.';

  @override
  String get operationTimedOut => 'Operation timed out. Please try again.';

  @override
  String get invalidResponseFormat =>
      'Invalid response format. Please try again.';

  // ============================================================================
  // Database Error Messages
  // ============================================================================

  @override
  String get databaseErrorPleaseTryAgain =>
      'Database error. Please try again or contact support.';

  // ============================================================================
  // Permission Error Messages
  // ============================================================================

  @override
  String get permissionDenied =>
      'You don\'t have permission to perform this action.';

  // ============================================================================
  // Operation Messages
  // ============================================================================

  @override
  String get noInternetConnectionQueuedShort =>
      'No internet connection. Operation queued.';

  @override
  String get noInternetConnectionQueuedLong =>
      'No internet connection. Operation will be executed when connection is available.';

  @override
  String get networkOperationFailedAfterRetries =>
      'Network operation failed after multiple retries. Please try again.';

  @override
  String get networkOperationDefault => 'Network operation';

  // ============================================================================
  // Generic Error Messages
  // ============================================================================

  @override
  String get unexpectedErrorOccurred =>
      'An unexpected error occurred. Please try again.';
}

