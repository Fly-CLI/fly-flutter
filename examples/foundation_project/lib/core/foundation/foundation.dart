// Barrel file for foundation

// Offline module (includes queue manager and all offline functionality)
export '../offline/offline.dart';
// Error exports
export 'error/app_exception.dart';
export 'error/custom_error_handler.dart';
export 'error/error_handler.dart';
export 'error/network_errors.dart';
// Feedback exports (from fly_feedback package)
export 'package:fly_feedback/fly_feedback.dart';
// MVVM exports
export 'mvvm/screen/fly_screen.dart';
export 'mvvm/view_model/fly_view_model.dart';
// Navigation service exports
export '../navigation/navigation_service.dart';
export '../navigation/default_navigation_service.dart';
export '../navigation/navigation_service_provider.dart';
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
// Event system integration exports
export '../event_system/events.dart';
export '../event_system/event_emitter_mixin.dart';
