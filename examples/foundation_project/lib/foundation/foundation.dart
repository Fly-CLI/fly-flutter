// Barrel file for foundation

// Error exports
export 'error/app_exception.dart';
export 'error/custom_error_handler.dart';
export 'error/error_handler.dart';
export 'error/network_errors.dart';
// Feedback exports (from fly_feedback package)
export 'package:fly_feedback/fly_feedback.dart';
// Localization exports
export 'localization/foundation_localization_provider.dart';
export 'localization/default_foundation_localization_provider.dart';
// MVVM exports
export 'mvvm/screen/fly_screen.dart';
export 'mvvm/view_model/fly_view_model.dart';
// Navigation service exports
export '../foundation/navigation/navigation_service.dart';
export '../foundation/navigation/default_navigation_service.dart';
// Operations exports
export 'operations/async_operation_handler.dart';
export 'operations/async_operation_config.dart';
export 'connectivity/connectivity_service.dart';
export 'operations/result.dart';
export 'operations/retry_config.dart';
// Utils exports
export 'logger/fly_logger.dart';
// Dependency Injection exports
export 'di/global_container.dart';
// Storage interface exports
export 'storage/interfaces/i_storage_service.dart';
export 'storage/interfaces/i_secure_storage_service.dart';
// Event system exports
export 'events/app_event.dart';
export 'events/event_emitter.dart';
export 'events/event_emitter_mixin.dart';
export 'events/event_providers.dart';
export 'events/managers/event_stream_manager.dart';
export 'events/plugins/analytics_event_plugin.dart';
export 'events/plugins/logging_event_plugin.dart';
export 'events/plugins/performance_event_plugin.dart';
