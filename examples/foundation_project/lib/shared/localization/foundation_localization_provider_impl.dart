import 'package:foundation_project/foundation/localization/foundation_localization_provider.dart';
import 'package:foundation_project/l10n/app_localizations.dart';

/// Implementation of FoundationLocalizationProvider that wraps AppLocalizations
///
/// This bridges the foundation's localization interface with the application's
/// Flutter gen-l10n localization system.
class FoundationLocalizationProviderImpl
    implements FoundationLocalizationProvider {
  final AppLocalizations _localizations;

  FoundationLocalizationProviderImpl(this._localizations);

  // ============================================================================
  // Network Error Messages
  // ============================================================================

  @override
  String get networkErrorConnectionRecovery =>
      _localizations.networkErrorConnectionRecovery;

  @override
  String get networkErrorTimeoutRecovery =>
      _localizations.networkErrorTimeoutRecovery;

  @override
  String get networkErrorDnsRecovery => _localizations.networkErrorDnsRecovery;

  @override
  String get networkErrorNoInternetRecovery =>
      _localizations.networkErrorNoInternetRecovery;

  @override
  String get networkErrorAuthRecovery =>
      _localizations.networkErrorAuthRecovery;

  @override
  String get networkErrorNotFoundRecovery =>
      _localizations.networkErrorNotFoundRecovery;

  @override
  String get networkErrorRateLimitRecovery =>
      _localizations.networkErrorRateLimitRecovery;

  @override
  String get networkErrorServerRecovery =>
      _localizations.networkErrorServerRecovery;

  @override
  String get networkErrorCertificateRecovery =>
      _localizations.networkErrorCertificateRecovery;

  @override
  String get networkErrorUnknownRecovery =>
      _localizations.networkErrorUnknownRecovery;

  @override
  String get networkErrorHttpRecovery =>
      _localizations.networkErrorHttpRecovery;

  // ============================================================================
  // Network Error Base Messages
  // ============================================================================

  @override
  String get networkConnectionFailed => _localizations.networkConnectionFailed;

  @override
  String get networkNoInternet => _localizations.networkNoInternet;

  @override
  String get networkTimeout => _localizations.networkTimeout;

  @override
  String get networkDnsFailed => _localizations.networkDnsFailed;

  @override
  String get networkCaptivePortal => _localizations.networkCaptivePortal;

  @override
  String get networkCertificateError =>
      _localizations.networkCertificateError;

  @override
  String get networkUnknownError => _localizations.networkUnknownError;

  @override
  String get networkHttpClientError => _localizations.networkHttpClientError;

  @override
  String get networkHttpServerError => _localizations.networkHttpServerError;

  @override
  String get operationTimedOut => _localizations.operationTimedOut;

  @override
  String get invalidResponseFormat => _localizations.invalidResponseFormat;

  // ============================================================================
  // Database Error Messages
  // ============================================================================

  @override
  String get databaseErrorPleaseTryAgain =>
      _localizations.databaseErrorPleaseTryAgain;

  // ============================================================================
  // Permission Error Messages
  // ============================================================================

  @override
  String get permissionDenied => _localizations.permissionDenied;

  // ============================================================================
  // Operation Messages
  // ============================================================================

  @override
  String get noInternetConnectionQueuedShort =>
      _localizations.noInternetConnectionQueuedShort;

  @override
  String get noInternetConnectionQueuedLong =>
      _localizations.noInternetConnectionQueuedLong;

  @override
  String get networkOperationFailedAfterRetries =>
      _localizations.networkOperationFailedAfterRetries;

  @override
  String get networkOperationDefault =>
      _localizations.networkOperationDefault;

  // ============================================================================
  // Generic Error Messages
  // ============================================================================

  @override
  String get unexpectedErrorOccurred =>
      _localizations.unexpectedErrorOccurred;
}

