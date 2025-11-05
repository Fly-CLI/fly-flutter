// Barrel file for foundation

// Offline module (includes queue manager and all offline functionality)
export '../offline/offline.dart';
// Error exports
export 'error/app_exception.dart';
export 'error/custom_error_handler.dart';
export 'error/error_handler.dart';
export 'error/network_errors.dart';
// Feedback exports
// Note: FeedbackEvent classes are exported from lifecycle/lifecycle_events.dart
export 'feedback/types/feedback_types.dart';
export 'feedback/service/feedback_service.dart';
export 'feedback/service/default_feedback_service.dart';
export 'feedback/service/feedback_service_provider.dart';
export 'feedback/mixins/fly_feedback_emitter_mixin.dart';
export 'feedback/handlers/fly_feedback_handler.dart';
export 'feedback/handlers/snackbar_feedback_handler.dart';
export 'feedback/handlers/dialog_feedback_handler.dart';
export 'feedback/handlers/bottom_sheet_feedback_handler.dart';
export 'feedback/handlers/toast_feedback_handler.dart';
export 'feedback/handlers/banner_feedback_handler.dart';
export 'feedback/handlers/composite_feedback_handler.dart';
export 'feedback/mixins/fly_feedback_listener_mixin.dart';
// MVVM exports
export 'mvvm/fly_screen.dart';
export 'mvvm/fly_view_model.dart';
// Navigation service exports
export 'mvvm/services/navigation_service.dart';
export 'mvvm/services/default_navigation_service.dart';
export 'mvvm/services/navigation_service_provider.dart';
// Operations exports
export 'operations/async_operation_handler.dart';
export 'operations/async_operation_config.dart';
export 'connectivity/connectivity_service.dart';
export 'operations/result.dart';
export 'operations/retry_config.dart';
// State exports
export 'state/state_notifier.dart';
// Utils exports
export 'utils/app_logger.dart';
// Lifecycle integration exports
export '../lifecycle/lifecycle_events.dart';
export '../lifecycle/lifecycle_emitter_mixin.dart';
