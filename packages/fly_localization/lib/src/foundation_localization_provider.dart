import 'package:fly_localization/fly_localization.dart';

/// Abstract interface for localization strings used by foundation components
///
/// This interface provides a clean abstraction over localization, allowing
/// foundation components to work with any localization system without
/// hardcoded dependencies.
///
/// **Default Implementation:**
/// - [DefaultFoundationLocalizationProvider] - Provides default English messages
///   that can be used as a fallback when no application-specific provider is available
///
/// **Application Implementation:**
/// Applications should implement this interface to bridge their localization
/// system (e.g., Flutter gen-l10n, i18n, etc.) with foundation components.
///
/// Example implementation:
/// ```dart
/// class AppLocalizationProvider implements FoundationLocalizationProvider {
///   final AppLocalizations _localizations;
///
///   AppLocalizationProvider(this._localizations);
///
///   @override
///   String get networkErrorConnectionRecovery =>
///       _localizations.networkErrorConnectionRecovery;
///
///   // ... implement all other getters
/// }
/// ```
///
/// **Usage with Default:**
/// ```dart
/// // Use default as fallback
/// final provider = appLocalizationProvider ?? DefaultFoundationLocalizationProvider();
///
/// // Use in foundation components
/// final guard = FlowGuard(
///   logger: logger,
///   localizations: provider,
/// );
/// ```
abstract class FoundationLocalizationProvider {
  // ============================================================================
  // Network Error Messages
  // ============================================================================

  /// Message for connection failure recovery
  String get networkErrorConnectionRecovery;

  /// Message for timeout recovery
  String get networkErrorTimeoutRecovery;

  /// Message for DNS failure recovery
  String get networkErrorDnsRecovery;

  /// Message for no internet recovery
  String get networkErrorNoInternetRecovery;

  /// Message for authentication error recovery
  String get networkErrorAuthRecovery;

  /// Message for not found error recovery
  String get networkErrorNotFoundRecovery;

  /// Message for rate limit error recovery
  String get networkErrorRateLimitRecovery;

  /// Message for server error recovery
  String get networkErrorServerRecovery;

  /// Message for certificate error recovery
  String get networkErrorCertificateRecovery;

  /// Message for unknown network error recovery
  String get networkErrorUnknownRecovery;

  /// Message for HTTP error recovery
  String get networkErrorHttpRecovery;

  // ============================================================================
  // Network Error Base Messages
  // ============================================================================

  /// Message for network connection failure
  String get networkConnectionFailed;

  /// Message for no internet connection
  String get networkNoInternet;

  /// Message for network timeout
  String get networkTimeout;

  /// Message for DNS failure
  String get networkDnsFailed;

  /// Message for captive portal detection
  String get networkCaptivePortal;

  /// Message for certificate error
  String get networkCertificateError;

  /// Message for unknown network error
  String get networkUnknownError;

  /// Message for HTTP client error
  String get networkHttpClientError;

  /// Message for HTTP server error
  String get networkHttpServerError;

  /// Message for operation timeout
  String get operationTimedOut;

  /// Message for invalid response format
  String get invalidResponseFormat;

  // ============================================================================
  // Database Error Messages
  // ============================================================================

  /// Message for database error with retry suggestion
  String get databaseErrorPleaseTryAgain;

  // ============================================================================
  // Permission Error Messages
  // ============================================================================

  /// Message for permission denied
  String get permissionDenied;

  // ============================================================================
  // Operation Messages
  // ============================================================================

  /// Short message for no internet connection with queued operation
  String get noInternetConnectionQueuedShort;

  /// Long message for no internet connection with queued operation
  String get noInternetConnectionQueuedLong;

  /// Message for network operation failed after retries
  String get networkOperationFailedAfterRetries;

  /// Default message for network operation
  String get networkOperationDefault;

  // ============================================================================
  // Generic Error Messages
  // ============================================================================

  /// Message for unexpected error
  String get unexpectedErrorOccurred;
}

