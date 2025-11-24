/// Value object for compatibility checking results.
///
/// This re-exports and extends the existing CompatibilityResult
/// to serve as a domain value object.
library;

import 'package:fly_cli/src/generation/versioning/compatibility_result.dart';

export 'package:fly_cli/src/generation/versioning/compatibility_result.dart';

/// Extension methods for CompatibilityResult value object.
extension CompatibilityResultExtension on CompatibilityResult {
  /// Check if result has any warnings.
  bool get hasWarnings => warnings.isNotEmpty;

  /// Check if result has any errors.
  bool get hasErrors => errors.isNotEmpty;

  /// Get a summary message.
  String get summary {
    if (isCompatible) {
      return hasWarnings
          ? 'Compatible with ${warnings.length} warning(s)'
          : 'Compatible';
    } else {
      return 'Incompatible: ${errors.join('; ')}';
    }
  }
}

