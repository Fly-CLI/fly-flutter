import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

  /// The title of the application
  ///
  /// In en, this message translates to:
  /// **'Task & Notes Manager'**
  String get appTitle;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @tasks.
  ///
  /// In en, this message translates to:
  /// **'Tasks'**
  String get tasks;

  /// No description provided for @notes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notes;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @totalTasks.
  ///
  /// In en, this message translates to:
  /// **'Total Tasks'**
  String get totalTasks;

  /// No description provided for @completedTasks.
  ///
  /// In en, this message translates to:
  /// **'Completed Tasks'**
  String get completedTasks;

  /// No description provided for @overdueTasks.
  ///
  /// In en, this message translates to:
  /// **'Overdue Tasks'**
  String get overdueTasks;

  /// No description provided for @todayTasks.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Tasks'**
  String get todayTasks;

  /// No description provided for @addTask.
  ///
  /// In en, this message translates to:
  /// **'Add Task'**
  String get addTask;

  /// No description provided for @addNote.
  ///
  /// In en, this message translates to:
  /// **'Add Note'**
  String get addNote;

  /// No description provided for @syncNow.
  ///
  /// In en, this message translates to:
  /// **'Sync Now'**
  String get syncNow;

  /// No description provided for @syncing.
  ///
  /// In en, this message translates to:
  /// **'Syncing...'**
  String get syncing;

  /// No description provided for @lastSync.
  ///
  /// In en, this message translates to:
  /// **'Last Sync'**
  String get lastSync;

  /// No description provided for @pendingOperations.
  ///
  /// In en, this message translates to:
  /// **'Pending Operations'**
  String get pendingOperations;

  /// No description provided for @noInternet.
  ///
  /// In en, this message translates to:
  /// **'No Internet Connection'**
  String get noInternet;

  /// No description provided for @connected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get connected;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @submit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submit;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @errorOccurred.
  ///
  /// In en, this message translates to:
  /// **'An error occurred. Please try again.'**
  String get errorOccurred;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming Soon'**
  String get comingSoon;

  /// No description provided for @tasksComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Tasks feature coming soon'**
  String get tasksComingSoon;

  /// No description provided for @notesComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Notes feature coming soon'**
  String get notesComingSoon;

  /// No description provided for @settingsComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Settings feature coming soon'**
  String get settingsComingSoon;

  /// No description provided for @noData.
  ///
  /// In en, this message translates to:
  /// **'No data available'**
  String get noData;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @networkStatus.
  ///
  /// In en, this message translates to:
  /// **'Network Status'**
  String get networkStatus;

  /// No description provided for @activityFeed.
  ///
  /// In en, this message translates to:
  /// **'Activity Feed'**
  String get activityFeed;

  /// No description provided for @recentActivity.
  ///
  /// In en, this message translates to:
  /// **'Recent Activity'**
  String get recentActivity;

  /// No description provided for @taskCreated.
  ///
  /// In en, this message translates to:
  /// **'Task created'**
  String get taskCreated;

  /// No description provided for @taskUpdated.
  ///
  /// In en, this message translates to:
  /// **'Task updated'**
  String get taskUpdated;

  /// No description provided for @taskCompleted.
  ///
  /// In en, this message translates to:
  /// **'Task completed'**
  String get taskCompleted;

  /// No description provided for @noteCreated.
  ///
  /// In en, this message translates to:
  /// **'Note created'**
  String get noteCreated;

  /// No description provided for @noteUpdated.
  ///
  /// In en, this message translates to:
  /// **'Note updated'**
  String get noteUpdated;

  /// No description provided for @syncStatus.
  ///
  /// In en, this message translates to:
  /// **'Sync Status'**
  String get syncStatus;

  /// No description provided for @syncSuccess.
  ///
  /// In en, this message translates to:
  /// **'Sync successful'**
  String get syncSuccess;

  /// No description provided for @syncFailed.
  ///
  /// In en, this message translates to:
  /// **'Sync failed'**
  String get syncFailed;

  /// No description provided for @noPendingOperations.
  ///
  /// In en, this message translates to:
  /// **'No pending operations'**
  String get noPendingOperations;

  /// No description provided for @statistics.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get statistics;

  /// No description provided for @quickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick Actions'**
  String get quickActions;

  /// No description provided for @syncData.
  ///
  /// In en, this message translates to:
  /// **'Sync Data'**
  String get syncData;

  /// No description provided for @pullToRefresh.
  ///
  /// In en, this message translates to:
  /// **'Pull to refresh'**
  String get pullToRefresh;

  /// No description provided for @syncStatusIdle.
  ///
  /// In en, this message translates to:
  /// **'Idle'**
  String get syncStatusIdle;

  /// No description provided for @syncStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get syncStatusPending;

  /// No description provided for @syncStatusSynced.
  ///
  /// In en, this message translates to:
  /// **'Synced'**
  String get syncStatusSynced;

  /// No description provided for @syncStatusFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get syncStatusFailed;

  /// No description provided for @syncStatusConflicted.
  ///
  /// In en, this message translates to:
  /// **'Conflicted'**
  String get syncStatusConflicted;

  /// No description provided for @syncStatusOffline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get syncStatusOffline;

  /// No description provided for @action.
  ///
  /// In en, this message translates to:
  /// **'Action'**
  String get action;

  /// No description provided for @success.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get success;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @warning.
  ///
  /// In en, this message translates to:
  /// **'Warning'**
  String get warning;

  /// No description provided for @information.
  ///
  /// In en, this message translates to:
  /// **'Information'**
  String get information;

  /// No description provided for @taskDetail.
  ///
  /// In en, this message translates to:
  /// **'Task Detail'**
  String get taskDetail;

  /// No description provided for @taskDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Task Detail: {id}'**
  String taskDetailTitle(String id);

  /// No description provided for @taskDetailComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Task Detail - Coming Soon'**
  String get taskDetailComingSoon;

  /// No description provided for @noteDetail.
  ///
  /// In en, this message translates to:
  /// **'Note Detail'**
  String get noteDetail;

  /// No description provided for @noteDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Note Detail: {id}'**
  String noteDetailTitle(String id);

  /// No description provided for @noteDetailComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Note Detail - Coming Soon'**
  String get noteDetailComingSoon;

  /// No description provided for @addEditTask.
  ///
  /// In en, this message translates to:
  /// **'Add/Edit Task'**
  String get addEditTask;

  /// No description provided for @taskFormComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Task Form - Coming Soon'**
  String get taskFormComingSoon;

  /// No description provided for @addEditNote.
  ///
  /// In en, this message translates to:
  /// **'Add/Edit Note'**
  String get addEditNote;

  /// No description provided for @noteFormComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Note Form - Coming Soon'**
  String get noteFormComingSoon;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @update.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get update;

  /// No description provided for @networkConnectionFailed.
  ///
  /// In en, this message translates to:
  /// **'Network connection failed. Please check your connection and try again.'**
  String get networkConnectionFailed;

  /// No description provided for @networkNoInternet.
  ///
  /// In en, this message translates to:
  /// **'No internet connection. Please check your connection and try again.'**
  String get networkNoInternet;

  /// No description provided for @networkTimeout.
  ///
  /// In en, this message translates to:
  /// **'Request timed out. Please try again.'**
  String get networkTimeout;

  /// No description provided for @networkDnsFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to resolve hostname. Please check your connection and try again.'**
  String get networkDnsFailed;

  /// No description provided for @networkCaptivePortal.
  ///
  /// In en, this message translates to:
  /// **'Captive portal detected. Please connect to the network and try again.'**
  String get networkCaptivePortal;

  /// No description provided for @networkCertificateError.
  ///
  /// In en, this message translates to:
  /// **'Certificate error. Please check your connection and try again.'**
  String get networkCertificateError;

  /// No description provided for @networkUnknownError.
  ///
  /// In en, this message translates to:
  /// **'Unknown network error occurred. Please try again.'**
  String get networkUnknownError;

  /// No description provided for @networkHttpClientError.
  ///
  /// In en, this message translates to:
  /// **'Client error occurred. Please check your request and try again.'**
  String get networkHttpClientError;

  /// No description provided for @networkHttpServerError.
  ///
  /// In en, this message translates to:
  /// **'Server error occurred. Please try again later.'**
  String get networkHttpServerError;

  /// No description provided for @operationTimedOut.
  ///
  /// In en, this message translates to:
  /// **'Operation timed out. Please try again.'**
  String get operationTimedOut;

  /// No description provided for @invalidResponseFormat.
  ///
  /// In en, this message translates to:
  /// **'Invalid response format. Please try again.'**
  String get invalidResponseFormat;

  /// No description provided for @networkErrorConnectionRecovery.
  ///
  /// In en, this message translates to:
  /// **'Connection failed. Please check your connection and try again.'**
  String get networkErrorConnectionRecovery;

  /// No description provided for @networkErrorTimeoutRecovery.
  ///
  /// In en, this message translates to:
  /// **'Request timed out. Please try again.'**
  String get networkErrorTimeoutRecovery;

  /// No description provided for @networkErrorDnsRecovery.
  ///
  /// In en, this message translates to:
  /// **'Failed to resolve hostname. Please check your connection and try again.'**
  String get networkErrorDnsRecovery;

  /// No description provided for @networkErrorNoInternetRecovery.
  ///
  /// In en, this message translates to:
  /// **'No internet connection. Please check your connection and try again.'**
  String get networkErrorNoInternetRecovery;

  /// No description provided for @networkErrorAuthRecovery.
  ///
  /// In en, this message translates to:
  /// **'Authentication error. Please log in again.'**
  String get networkErrorAuthRecovery;

  /// No description provided for @networkErrorNotFoundRecovery.
  ///
  /// In en, this message translates to:
  /// **'Resource not found. Please check your request and try again.'**
  String get networkErrorNotFoundRecovery;

  /// No description provided for @networkErrorRateLimitRecovery.
  ///
  /// In en, this message translates to:
  /// **'Too many requests. Please wait a moment and try again.'**
  String get networkErrorRateLimitRecovery;

  /// No description provided for @networkErrorServerRecovery.
  ///
  /// In en, this message translates to:
  /// **'Server error. Please try again later.'**
  String get networkErrorServerRecovery;

  /// No description provided for @networkErrorCertificateRecovery.
  ///
  /// In en, this message translates to:
  /// **'Certificate error. Please check your connection and try again.'**
  String get networkErrorCertificateRecovery;

  /// No description provided for @networkErrorUnknownRecovery.
  ///
  /// In en, this message translates to:
  /// **'Unknown network error. Please try again.'**
  String get networkErrorUnknownRecovery;

  /// No description provided for @networkErrorHttpRecovery.
  ///
  /// In en, this message translates to:
  /// **'HTTP error. Please try again.'**
  String get networkErrorHttpRecovery;

  /// No description provided for @actionRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get actionRetry;

  /// No description provided for @actionCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get actionCancel;

  /// No description provided for @actionOk.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get actionOk;

  /// No description provided for @actionSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get actionSave;

  /// No description provided for @actionSubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get actionSubmit;

  /// No description provided for @actionDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get actionDelete;

  /// No description provided for @actionEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get actionEdit;

  /// No description provided for @actionAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get actionAdd;

  /// No description provided for @actionClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get actionClose;

  /// No description provided for @actionConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get actionConfirm;

  /// No description provided for @actionYes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get actionYes;

  /// No description provided for @actionNo.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get actionNo;

  /// No description provided for @databaseErrorPleaseTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Database error. Please try again or contact support.'**
  String get databaseErrorPleaseTryAgain;

  /// No description provided for @permissionDenied.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have permission to perform this action.'**
  String get permissionDenied;

  /// No description provided for @noInternetConnectionQueuedShort.
  ///
  /// In en, this message translates to:
  /// **'No internet connection. Operation queued.'**
  String get noInternetConnectionQueuedShort;

  /// No description provided for @noInternetConnectionQueuedLong.
  ///
  /// In en, this message translates to:
  /// **'No internet connection. Operation will be executed when connection is available.'**
  String get noInternetConnectionQueuedLong;

  /// No description provided for @networkOperationFailedAfterRetries.
  ///
  /// In en, this message translates to:
  /// **'Network operation failed after multiple retries. Please try again.'**
  String get networkOperationFailedAfterRetries;

  /// No description provided for @networkOperationDefault.
  ///
  /// In en, this message translates to:
  /// **'Network operation'**
  String get networkOperationDefault;

  /// No description provided for @unexpectedErrorOccurred.
  ///
  /// In en, this message translates to:
  /// **'An unexpected error occurred. Please try again.'**
  String get unexpectedErrorOccurred;

  /// No description provided for @taskNotFound.
  ///
  /// In en, this message translates to:
  /// **'Task not found'**
  String get taskNotFound;

  /// No description provided for @noteNotFound.
  ///
  /// In en, this message translates to:
  /// **'Note not found'**
  String get noteNotFound;

  /// No description provided for @failedToLoadStatistics.
  ///
  /// In en, this message translates to:
  /// **'Failed to load statistics'**
  String get failedToLoadStatistics;

  /// No description provided for @failedToLoadSyncStatus.
  ///
  /// In en, this message translates to:
  /// **'Failed to load sync status'**
  String get failedToLoadSyncStatus;

  /// No description provided for @failedToRefresh.
  ///
  /// In en, this message translates to:
  /// **'Failed to refresh'**
  String get failedToRefresh;

  /// No description provided for @failedToSync.
  ///
  /// In en, this message translates to:
  /// **'Failed to sync'**
  String get failedToSync;

  /// Error message when trying to register a controller on a disposed emitter
  ///
  /// In en, this message translates to:
  /// **'Cannot register controller: emitter is disposed'**
  String get lifecycleEmitterDisposed;

  /// Error message when trying to register a controller with an existing key
  ///
  /// In en, this message translates to:
  /// **'Controller with key \"{key}\" already registered'**
  String lifecycleControllerAlreadyRegistered(String key);

  /// Error message when trying to access a non-existent controller
  ///
  /// In en, this message translates to:
  /// **'No controller registered with key \"{key}\"'**
  String lifecycleNoControllerRegistered(String key);

  /// Error message when trying to use a disposed lifecycle emitter mixin
  ///
  /// In en, this message translates to:
  /// **'LifecycleEmitterMixin is disposed'**
  String get lifecycleEmitterMixinDisposed;

  /// Error message when accessing lifecycle emitter fails
  ///
  /// In en, this message translates to:
  /// **'Error accessing lifecycle emitter: {error}. Make sure lifecycle_providers.dart is exported and GlobalContainer is initialized.'**
  String lifecycleEmitterAccessError(String error);

  /// No description provided for @taskListFiltersTitle.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get taskListFiltersTitle;

  /// No description provided for @searchTasks.
  ///
  /// In en, this message translates to:
  /// **'Search tasks'**
  String get searchTasks;

  /// No description provided for @clearSearch.
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get clearSearch;

  /// No description provided for @filterByStatus.
  ///
  /// In en, this message translates to:
  /// **'Filter by status'**
  String get filterByStatus;

  /// No description provided for @filterAllStatuses.
  ///
  /// In en, this message translates to:
  /// **'All statuses'**
  String get filterAllStatuses;

  /// No description provided for @taskStatusActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get taskStatusActive;

  /// No description provided for @taskStatusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get taskStatusCompleted;

  /// No description provided for @taskStatusOverdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get taskStatusOverdue;

  /// No description provided for @taskPriorityLow.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get taskPriorityLow;

  /// No description provided for @taskPriorityMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get taskPriorityMedium;

  /// No description provided for @taskPriorityHigh.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get taskPriorityHigh;

  /// No description provided for @untitledTask.
  ///
  /// In en, this message translates to:
  /// **'Untitled Task'**
  String get untitledTask;

  /// No description provided for @markTaskActive.
  ///
  /// In en, this message translates to:
  /// **'Mark as active'**
  String get markTaskActive;

  /// No description provided for @markTaskCompleted.
  ///
  /// In en, this message translates to:
  /// **'Mark as completed'**
  String get markTaskCompleted;

  /// No description provided for @deleteTask.
  ///
  /// In en, this message translates to:
  /// **'Delete task'**
  String get deleteTask;

  /// No description provided for @deleteTaskTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Task'**
  String get deleteTaskTitle;

  /// No description provided for @deleteTaskConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{value}\"?'**
  String deleteTaskConfirmation(String value);

  /// No description provided for @noTasksTitle.
  ///
  /// In en, this message translates to:
  /// **'No tasks yet'**
  String get noTasksTitle;

  /// No description provided for @noTasksDescription.
  ///
  /// In en, this message translates to:
  /// **'Create your first task to get started.'**
  String get noTasksDescription;

  /// No description provided for @createFirstTask.
  ///
  /// In en, this message translates to:
  /// **'Create task'**
  String get createFirstTask;

  /// No description provided for @selectedTaskCount.
  ///
  /// In en, this message translates to:
  /// **'{count} selected'**
  String selectedTaskCount(int count);

  /// No description provided for @clearSelection.
  ///
  /// In en, this message translates to:
  /// **'Clear selection'**
  String get clearSelection;

  /// No description provided for @deleteSelected.
  ///
  /// In en, this message translates to:
  /// **'Delete selected'**
  String get deleteSelected;

  /// No description provided for @taskDueDateOverdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue since {date}'**
  String taskDueDateOverdue(String date);

  /// No description provided for @taskDueDateToday.
  ///
  /// In en, this message translates to:
  /// **'Due today'**
  String get taskDueDateToday;

  /// No description provided for @taskDueDateOn.
  ///
  /// In en, this message translates to:
  /// **'Due on {date}'**
  String taskDueDateOn(String date);

  /// No description provided for @updatedAtLabel.
  ///
  /// In en, this message translates to:
  /// **'Updated {date}'**
  String updatedAtLabel(String date);

  /// No description provided for @taskDescriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get taskDescriptionLabel;

  /// No description provided for @taskDescriptionHint.
  ///
  /// In en, this message translates to:
  /// **'Add more details about this task'**
  String get taskDescriptionHint;

  /// No description provided for @taskMetadataLabel.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get taskMetadataLabel;

  /// No description provided for @taskDueDate.
  ///
  /// In en, this message translates to:
  /// **'Due date'**
  String get taskDueDate;

  /// No description provided for @taskDueDateHelper.
  ///
  /// In en, this message translates to:
  /// **'Selected date: {date}'**
  String taskDueDateHelper(String date);

  /// No description provided for @selectDueDate.
  ///
  /// In en, this message translates to:
  /// **'Select due date'**
  String get selectDueDate;

  /// No description provided for @clearDueDate.
  ///
  /// In en, this message translates to:
  /// **'Clear due date'**
  String get clearDueDate;

  /// No description provided for @noDueDate.
  ///
  /// In en, this message translates to:
  /// **'No due date'**
  String get noDueDate;

  /// No description provided for @createdAt.
  ///
  /// In en, this message translates to:
  /// **'Created'**
  String get createdAt;

  /// No description provided for @updatedAt.
  ///
  /// In en, this message translates to:
  /// **'Updated'**
  String get updatedAt;

  /// No description provided for @taskPriorityLabel.
  ///
  /// In en, this message translates to:
  /// **'Priority'**
  String get taskPriorityLabel;

  /// No description provided for @taskStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get taskStatusLabel;

  /// No description provided for @taskTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get taskTitleLabel;

  /// No description provided for @taskTitleHint.
  ///
  /// In en, this message translates to:
  /// **'Enter a task title'**
  String get taskTitleHint;

  /// No description provided for @taskTitleRequired.
  ///
  /// In en, this message translates to:
  /// **'Title is required'**
  String get taskTitleRequired;

  /// No description provided for @taskDueDateInPast.
  ///
  /// In en, this message translates to:
  /// **'Due date cannot be in the past'**
  String get taskDueDateInPast;

  /// No description provided for @editTask.
  ///
  /// In en, this message translates to:
  /// **'Edit task'**
  String get editTask;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
