import 'dart:async';
import 'dart:io';

import 'package:foundation_project/foundation/error/app_exception.dart';
import 'package:foundation_project/foundation/localization/default_foundation_localization_provider.dart';
import 'package:foundation_project/foundation/localization/foundation_localization_provider.dart';

/// Base class for all network-related errors
/// Extends AppException to integrate with existing error handling infrastructure
abstract class NetworkError extends AppException {
  /// HTTP status code if applicable
  final int? statusCode;

  /// Whether this error is retryable
  final bool isRetryable;

  /// Error code for localization lookup
  final String errorCode;

  NetworkError(
    super.message, {
    this.statusCode,
    required this.isRetryable,
    required this.errorCode,
  });

  /// Get user-friendly recovery suggestion key for localization
  String get recoverySuggestionKey;

  @override
  String toString() => 'NetworkError: $message (code: $errorCode, '
      'retryable: $isRetryable, status: $statusCode)';
}

/// Error when operation times out
class TimeoutError extends NetworkError {
  final Duration timeout;

  TimeoutError({
    required this.timeout,
    String? customMessage,
    FoundationLocalizationProvider? localizations,
  }) : super(
          customMessage ??
              (localizations ?? DefaultFoundationLocalizationProvider())
                  .operationTimedOut,
          isRetryable: true,
          errorCode: 'network_timeout',
        );

  @override
  String get recoverySuggestionKey => 'networkErrorTimeoutRecovery';

  @override
  String toString() => 'TimeoutError: Operation timed out after '
      '${timeout.inSeconds}s';
}

/// Error when connection fails (no route to host, connection refused, etc.)
class ConnectionError extends NetworkError {
  ConnectionError({
    String? customMessage,
    FoundationLocalizationProvider? localizations,
  }) : super(
          customMessage ??
              (localizations ?? DefaultFoundationLocalizationProvider())
                  .networkConnectionFailed,
          isRetryable: true,
          errorCode: 'network_connection_failed',
        );

  @override
  String get recoverySuggestionKey => 'networkErrorConnectionRecovery';
}

/// Error when no internet connection is available
class NoInternetError extends NetworkError {
  NoInternetError({
    String? customMessage,
    FoundationLocalizationProvider? localizations,
  }) : super(
          customMessage ??
              (localizations ?? DefaultFoundationLocalizationProvider())
                  .networkNoInternet,
          isRetryable: false, // Don't retry if offline
          errorCode: 'network_no_internet',
        );

  @override
  String get recoverySuggestionKey => 'networkErrorNoInternetRecovery';
}

/// Error for HTTP-specific errors with status codes
class HttpError extends NetworkError {
  /// Response body if available
  final String? responseBody;

  HttpError({
    required int statusCode,
    this.responseBody,
    String? customMessage,
    FoundationLocalizationProvider? localizations,
  }) : super(
          customMessage ??
              _getDefaultMessage(
                statusCode,
                localizations ?? DefaultFoundationLocalizationProvider(),
              ),
          statusCode: statusCode,
          isRetryable: _isRetryableStatusCode(statusCode),
          errorCode: _errorCodeForStatus(statusCode),
        );

  /// Get default localized message based on status code
  static String _getDefaultMessage(
    int statusCode,
    FoundationLocalizationProvider localizations,
  ) {
    if (statusCode >= 400 && statusCode < 500) {
      return localizations.networkHttpClientError;
    } else if (statusCode >= 500 && statusCode < 600) {
      return localizations.networkHttpServerError;
    }
    return '${localizations.networkUnknownError} ($statusCode)';
  }

  /// Check if the status code indicates a retryable error
  static bool _isRetryableStatusCode(int statusCode) {
    // 5xx server errors are retryable
    if (statusCode >= 500 && statusCode < 600) return true;

    // 408 Request Timeout is retryable
    if (statusCode == 408) return true;

    // 429 Too Many Requests is retryable (after backoff)
    if (statusCode == 429) return true;

    // 4xx client errors are not retryable (except those above)
    return false;
  }

  /// Get error code for localization based on status code
  static String _errorCodeForStatus(int statusCode) {
    if (statusCode >= 400 && statusCode < 500) {
      return 'network_http_client_error';
    } else if (statusCode >= 500 && statusCode < 600) {
      return 'network_http_server_error';
    }
    return 'network_http_error';
  }

  @override
  String get recoverySuggestionKey {
    if (statusCode != null) {
      if (statusCode! >= 500) {
        return 'networkErrorServerRecovery';
      } else if (statusCode! == 401 || statusCode! == 403) {
        return 'networkErrorAuthRecovery';
      } else if (statusCode! == 404) {
        return 'networkErrorNotFoundRecovery';
      } else if (statusCode! == 429) {
        return 'networkErrorRateLimitRecovery';
      }
    }
    return 'networkErrorHttpRecovery';
  }

  @override
  String toString() => 'HttpError: $message (status: $statusCode)';
}

/// Error for DNS resolution failures
class DnsError extends NetworkError {
  final String? hostname;

  DnsError({
    this.hostname,
    String? customMessage,
    FoundationLocalizationProvider? localizations,
  }) : super(
          customMessage ??
              (localizations ?? DefaultFoundationLocalizationProvider())
                  .networkDnsFailed,
          isRetryable: true,
          errorCode: 'network_dns_failed',
        );

  @override
  String get recoverySuggestionKey => 'networkErrorDnsRecovery';

  @override
  String toString() => 'DnsError: Failed to resolve ${hostname ?? "hostname"}';
}

/// Error when connected to network but no actual internet (captive portal)
class CaptivePortalError extends NetworkError {
  CaptivePortalError({
    String? customMessage,
    FoundationLocalizationProvider? localizations,
  }) : super(
          customMessage ??
              (localizations ?? DefaultFoundationLocalizationProvider())
                  .networkCaptivePortal,
          isRetryable: false,
          errorCode: 'network_captive_portal',
        );

  @override
  String get recoverySuggestionKey => 'networkErrorCaptivePortalRecovery';
}

/// Error when SSL/TLS certificate validation fails
class CertificateError extends NetworkError {
  CertificateError({
    String? customMessage,
    FoundationLocalizationProvider? localizations,
  }) : super(
          customMessage ??
              (localizations ?? DefaultFoundationLocalizationProvider())
                  .networkCertificateError,
          isRetryable: false, // Don't retry certificate errors
          errorCode: 'network_certificate_error',
        );

  @override
  String get recoverySuggestionKey => 'networkErrorCertificateRecovery';
}

/// Error for unknown network issues
class UnknownNetworkError extends NetworkError {
  final Object? originalError;

  UnknownNetworkError({
    this.originalError,
    String? customMessage,
    FoundationLocalizationProvider? localizations,
  }) : super(
          customMessage ??
              (localizations ?? DefaultFoundationLocalizationProvider())
                  .networkUnknownError,
          isRetryable: true, // Conservative: try to retry
          errorCode: 'network_unknown_error',
        );

  @override
  String get recoverySuggestionKey => 'networkErrorUnknownRecovery';

  @override
  String toString() => 'UnknownNetworkError: $message '
      '(original: ${originalError?.toString()})';
}

/// Utility class for classifying exceptions as network errors
class NetworkErrorClassifier {
  /// Classify a generic exception into a specific NetworkError
  static NetworkError classifyError(
    Object error, {
    StackTrace? stackTrace,
    Duration? timeout,
    FoundationLocalizationProvider? localizations,
  }) {
    final loc = localizations ?? DefaultFoundationLocalizationProvider();
    // Handle already classified network errors
    if (error is NetworkError) {
      return error;
    }

    // Handle timeout exceptions
    if (error is TimeoutException) {
      return TimeoutError(
        timeout: timeout ?? const Duration(seconds: 30),
        localizations: loc,
      );
    }

    // Handle socket exceptions
    if (error is SocketException) {
      final message = error.message.toLowerCase();
      if (message.contains('failed host lookup') ||
          message.contains('no address associated')) {
        return DnsError(
          hostname: error.address?.host,
          localizations: loc,
        );
      }
      return ConnectionError(localizations: loc);
    }

    // Handle HTTP exceptions (if using http package)
    if (error.toString().contains('ClientException')) {
      return ConnectionError(
        localizations: loc,
      );
    }

    // Handle format exceptions (often from malformed responses)
    if (error is FormatException) {
      return HttpError(
        statusCode: 502, // Bad Gateway for malformed responses
        localizations: loc,
      );
    }

    // Handle certificate exceptions
    if (error.toString().toLowerCase().contains('certificate') ||
        error.toString().toLowerCase().contains('handshake')) {
      return CertificateError(localizations: loc);
    }

    // Default to unknown network error
    return UnknownNetworkError(
      originalError: error,
      customMessage: error.toString(),
      localizations: loc,
    );
  }

  /// Check if an error is retryable
  static bool isRetryable(Object error) {
    if (error is NetworkError) {
      return error.isRetryable;
    }
    // Conservative: assume retryable for unknown errors
    return true;
  }
}


