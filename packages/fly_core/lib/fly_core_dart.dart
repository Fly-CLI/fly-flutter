/// Fly Core (Dart-only subset)
///
/// This library exports the platform-agnostic pieces of `fly_core` so that
/// packages which do not depend on Flutter (e.g. the Fly CLI and backend
/// services) can reuse the common infrastructure without pulling in Flutter
/// bindings such as `dart:ui`.
///
/// Only modules that rely exclusively on `dart:*` and other pure Dart
/// dependencies are exported here. Flutter-specific exports remain available
/// via `package:fly_core/fly_core.dart`.
library fly_core_dart;

export 'src/cancellation/cancellation.dart';
export 'src/concurrency/concurrency_limiter.dart';
export 'src/environment/env_var.dart';
export 'src/environment/environment_manager.dart';
export 'src/file_operations/file_operations.dart';
export 'src/models/result.dart';
export 'src/platform/platform_utils.dart';
export 'src/process_execution/process_execution.dart';
export 'src/retry/retry.dart';
export 'src/timeout/timeout_manager.dart';
export 'src/validation/validation.dart';

