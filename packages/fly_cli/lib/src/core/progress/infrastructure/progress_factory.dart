import 'package:fly_cli/src/core/command/foundation/domain/command_context.dart';
import 'package:fly_cli/src/core/progress/domain/progress_indicator.dart';
import 'package:fly_cli/src/core/progress/infrastructure/bar_progress_indicator.dart';
import 'package:fly_cli/src/core/progress/infrastructure/silent_progress_indicator.dart';
import 'package:fly_cli/src/core/progress/infrastructure/spinner_progress_indicator.dart';
import 'package:mason_logger/mason_logger.dart';

/// Factory for creating appropriate progress indicators based on context
class ProgressFactory {
  /// Create a progress indicator based on command context
  ///
  /// - JSON/AI output mode or quiet mode: [SilentProgressIndicator]
  /// - Otherwise: [SpinnerProgressIndicator] or [BarProgressIndicator]
  static ProgressIndicator create(CommandContext context, {bool useBar = false}) {
    // Silent mode for JSON/AI output or quiet mode
    if (context.jsonOutput || context.aiOutput || context.quiet) {
      return SilentProgressIndicator();
    }

    // Use bar indicator if requested, otherwise spinner
    if (useBar) {
      return BarProgressIndicator(logger: context.logger);
    } else {
      return SpinnerProgressIndicator(logger: context.logger);
    }
  }

  /// Create a silent progress indicator (for programmatic use)
  static ProgressIndicator createSilent() => SilentProgressIndicator();

  /// Create a spinner progress indicator (for human-readable output)
  static ProgressIndicator createSpinner({Logger? logger}) =>
      SpinnerProgressIndicator(logger: logger);

  /// Create a bar progress indicator (for operations with known totals)
  static ProgressIndicator createBar({Logger? logger}) =>
      BarProgressIndicator(logger: logger);
}

