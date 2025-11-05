// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Task & Notes Manager';

  @override
  String get home => 'Home';

  @override
  String get tasks => 'Tasks';

  @override
  String get notes => 'Notes';

  @override
  String get settings => 'Settings';

  @override
  String get totalTasks => 'Total Tasks';

  @override
  String get completedTasks => 'Completed Tasks';

  @override
  String get overdueTasks => 'Overdue Tasks';

  @override
  String get todayTasks => 'Today\'s Tasks';

  @override
  String get addTask => 'Add Task';

  @override
  String get addNote => 'Add Note';

  @override
  String get syncNow => 'Sync Now';

  @override
  String get syncing => 'Syncing...';

  @override
  String get lastSync => 'Last Sync';

  @override
  String get pendingOperations => 'Pending Operations';

  @override
  String get noInternet => 'No Internet Connection';

  @override
  String get connected => 'Connected';

  @override
  String get retry => 'Retry';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get submit => 'Submit';

  @override
  String get ok => 'OK';

  @override
  String get errorOccurred => 'An error occurred. Please try again.';

  @override
  String get loading => 'Loading...';

  @override
  String get comingSoon => 'Coming Soon';

  @override
  String get tasksComingSoon => 'Tasks feature coming soon';

  @override
  String get notesComingSoon => 'Notes feature coming soon';

  @override
  String get settingsComingSoon => 'Settings feature coming soon';

  @override
  String get noData => 'No data available';

  @override
  String get refresh => 'Refresh';

  @override
  String get networkStatus => 'Network Status';

  @override
  String get activityFeed => 'Activity Feed';

  @override
  String get recentActivity => 'Recent Activity';

  @override
  String get taskCreated => 'Task created';

  @override
  String get taskUpdated => 'Task updated';

  @override
  String get taskCompleted => 'Task completed';

  @override
  String get noteCreated => 'Note created';

  @override
  String get noteUpdated => 'Note updated';

  @override
  String get syncStatus => 'Sync Status';

  @override
  String get syncSuccess => 'Sync successful';

  @override
  String get syncFailed => 'Sync failed';

  @override
  String get noPendingOperations => 'No pending operations';

  @override
  String get statistics => 'Statistics';

  @override
  String get quickActions => 'Quick Actions';

  @override
  String get syncData => 'Sync Data';

  @override
  String get pullToRefresh => 'Pull to refresh';

  @override
  String get syncStatusIdle => 'Idle';

  @override
  String get syncStatusPending => 'Pending';

  @override
  String get syncStatusSynced => 'Synced';

  @override
  String get syncStatusFailed => 'Failed';

  @override
  String get syncStatusConflicted => 'Conflicted';

  @override
  String get syncStatusOffline => 'Offline';

  @override
  String get action => 'Action';

  @override
  String get success => 'Success';

  @override
  String get error => 'Error';

  @override
  String get warning => 'Warning';

  @override
  String get information => 'Information';

  @override
  String get taskDetail => 'Task Detail';

  @override
  String taskDetailTitle(String id) {
    return 'Task Detail: $id';
  }

  @override
  String get taskDetailComingSoon => 'Task Detail - Coming Soon';

  @override
  String get noteDetail => 'Note Detail';

  @override
  String noteDetailTitle(String id) {
    return 'Note Detail: $id';
  }

  @override
  String get noteDetailComingSoon => 'Note Detail - Coming Soon';

  @override
  String get addEditTask => 'Add/Edit Task';

  @override
  String get taskFormComingSoon => 'Task Form - Coming Soon';

  @override
  String get addEditNote => 'Add/Edit Note';

  @override
  String get noteFormComingSoon => 'Note Form - Coming Soon';

  @override
  String get delete => 'Delete';

  @override
  String get edit => 'Edit';

  @override
  String get add => 'Add';

  @override
  String get close => 'Close';

  @override
  String get confirm => 'Confirm';

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String get update => 'Update';

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

  @override
  String get actionRetry => 'Retry';

  @override
  String get actionCancel => 'Cancel';

  @override
  String get actionOk => 'OK';

  @override
  String get actionSave => 'Save';

  @override
  String get actionSubmit => 'Submit';

  @override
  String get actionDelete => 'Delete';

  @override
  String get actionEdit => 'Edit';

  @override
  String get actionAdd => 'Add';

  @override
  String get actionClose => 'Close';

  @override
  String get actionConfirm => 'Confirm';

  @override
  String get actionYes => 'Yes';

  @override
  String get actionNo => 'No';

  @override
  String get databaseErrorPleaseTryAgain =>
      'Database error. Please try again or contact support.';

  @override
  String get permissionDenied =>
      'You don\'t have permission to perform this action.';

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

  @override
  String get unexpectedErrorOccurred =>
      'An unexpected error occurred. Please try again.';

  @override
  String get taskNotFound => 'Task not found';

  @override
  String get noteNotFound => 'Note not found';

  @override
  String get failedToLoadStatistics => 'Failed to load statistics';

  @override
  String get failedToLoadSyncStatus => 'Failed to load sync status';

  @override
  String get failedToRefresh => 'Failed to refresh';

  @override
  String get failedToSync => 'Failed to sync';

  @override
  String get lifecycleEmitterDisposed =>
      'Cannot register controller: emitter is disposed';

  @override
  String lifecycleControllerAlreadyRegistered(String key) {
    return 'Controller with key \"$key\" already registered';
  }

  @override
  String lifecycleNoControllerRegistered(String key) {
    return 'No controller registered with key \"$key\"';
  }

  @override
  String get lifecycleEmitterMixinDisposed =>
      'LifecycleEmitterMixin is disposed';

  @override
  String lifecycleEmitterAccessError(String error) {
    return 'Error accessing lifecycle emitter: $error. Make sure lifecycle_providers.dart is exported and GlobalContainer is initialized.';
  }
}
