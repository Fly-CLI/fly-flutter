import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fly_errors/src/error_message_formatter.dart';
import 'package:fly_logger/fly_logger.dart';

/// Provider for ErrorMessageFormatter
///
/// Creates an [ErrorMessageFormatter] instance with a logger and optional
/// default localization provider. The formatter can be injected into services
/// that need to format errors for user display.
///
/// Example usage:
/// ```dart
/// final formatter = ref.read(errorMessageFormatterProvider);
/// final userMessage = formatter.format(error);
/// ```
///
/// To override with custom localizations:
/// ```dart
/// final container = ProviderContainer(
///   overrides: [
///     errorMessageFormatterProvider.overrideWithValue(
///       ErrorMessageFormatter(
///         logger: logger,
///         defaultLocalizations: customLocalizations,
///       ),
///     ),
///   ],
/// );
/// ```
final errorMessageFormatterProvider = Provider<ErrorMessageFormatter>((ref) {
  return ErrorMessageFormatter(
    logger: FlyLoggerImpl('ErrorMessageFormatter'),
  );
});

