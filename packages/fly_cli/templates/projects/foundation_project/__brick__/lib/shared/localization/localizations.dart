/// Simple localization helper for foundation project
/// In production, this would be replaced with proper localization
class Localizations {
  static const Localizations instance = Localizations._();
  const Localizations._();

  // Network error messages
  String get networkConnectionFailed => 'Network connection failed. Please check your connection and try again.';
  String get networkNoInternet => 'No internet connection. Please check your connection and try again.';
  String get networkTimeout => 'Request timed out. Please try again.';
  String get networkDnsFailed => 'Failed to resolve hostname. Please check your connection and try again.';
  String get networkCaptivePortal => 'Captive portal detected. Please connect to the network and try again.';
  String get networkCertificateError => 'Certificate error. Please check your connection and try again.';
  String get networkUnknownError => 'Unknown network error occurred. Please try again.';
  String get networkHttpClientError => 'Client error occurred. Please check your request and try again.';
  String get networkHttpServerError => 'Server error occurred. Please try again later.';
  String get operationTimedOut => 'Operation timed out. Please try again.';
  String get invalidResponseFormat => 'Invalid response format. Please try again.';

  // General messages
  String get errorOccurred => 'An error occurred. Please try again.';
  String get actionRetry => 'Retry';
  String get actionCancel => 'Cancel';
  String get actionOk => 'OK';
  String get actionSave => 'Save';
  String get actionSubmit => 'Submit';
  String get actionDelete => 'Delete';
  String get actionEdit => 'Edit';
  String get actionAdd => 'Add';
  String get actionClose => 'Close';
  String get actionConfirm => 'Confirm';
  String get actionYes => 'Yes';
  String get actionNo => 'No';
  
  // Offline queue messages
  String get noInternetConnectionQueuedShort => 'No internet connection. Operation queued.';
  String get noInternetConnectionQueuedLong => 'No internet connection. Operation will be executed when connection is available.';
  String get networkOperationFailedAfterRetries => 'Network operation failed after multiple retries. Please try again.';
  String get networkOperationDefault => 'Network operation';
}

const localizations = Localizations.instance;

