import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:foundation_project/foundation/logger/fly_logger.dart';

/// Provider family for creating named logger instances.
/// 
/// Each logger instance is created with a specific name (typically the class name)
/// for better log filtering and debugging. The provider ensures that loggers
/// are properly managed and can be easily mocked in tests.
/// 
/// **Usage:**
/// ```dart
/// // In a provider
/// final logger = ref.watch(loggerProvider('MyService'));
/// 
/// // In a static class
/// final logger = GlobalContainer.instance.read(loggerProvider('MyService'));
/// ```
final loggerProvider = Provider.family<FlyLogger, String>((ref, name) {
  return FlyLoggerImpl(name);
});

