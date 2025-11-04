// Barrel file for foundation

// Offline module (includes queue manager and all offline functionality)
export '../offline/offline.dart';
// Error exports
export 'error/app_exception.dart';
export 'error/custom_error_handler.dart';
export 'error/error_handler.dart';
export 'error/network_errors.dart';
// Feedback exports
export 'feedback/feedback_emitter_mixin.dart';
export 'feedback/feedback_event.dart';
export 'feedback/feedback_handler.dart';
export 'feedback/feedback_listener_mixin.dart';
export 'feedback/feedback_test_utils.dart';
// Forms exports
export 'forms/form_view_model_interface.dart';
export 'forms/form_view_model_mixin.dart';
// MVVM exports
export 'mvvm/base_form_screen_with_validation.dart';
export 'mvvm/base_screen.dart';
export 'mvvm/view_model.dart';
// Operations exports
export 'operations/async_handler.dart';
export 'operations/async_handler_config.dart';
export 'operations/connectivity_service.dart';
export 'operations/result.dart';
export 'operations/retry_config.dart';
// State exports
export 'state/state_notifier.dart';
// Utils exports
export 'utils/app_logger.dart';
