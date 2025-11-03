/// Fly Core - Foundation package for Fly CLI applications
///
/// This package provides the core building blocks for Flutter applications
/// created with Fly CLI, including BaseScreen, BaseViewModel, state management,
/// and common utilities.
library fly_core;

// Environment
export 'src/environment/env_var.dart';
export 'src/environment/environment_manager.dart';
// File Operations Infrastructure
export 'src/file_operations/file_operations.dart';
export 'src/models/result.dart';
// Models
export 'src/models/view_state.dart';
// Process Execution Infrastructure
export 'src/process_execution/process_execution.dart';
// Retry Infrastructure
export 'src/retry/retry.dart';
// Cancellation Infrastructure
export 'src/cancellation/cancellation.dart';
// Concurrency Infrastructure
export 'src/concurrency/concurrency_limiter.dart';
// Timeout Infrastructure
export 'src/timeout/timeout_manager.dart';
// Platform Utilities
export 'src/platform/platform_utils.dart';
// Screens
export 'src/screens/base_screen.dart';
// Utilities
export 'src/utils/extensions.dart';
// Validation Infrastructure
export 'src/validation/validation.dart';
// ViewModels
export 'src/viewmodels/base_viewmodel.dart';
export 'src/widgets/error_widget.dart';
// Widgets
export 'src/widgets/loading_widget.dart';
