import 'package:fly_brick_composer/src/exceptions/composer_exception.dart';

/// Generation mode enum representing the three main workflows.
///
/// This enum is used across the CLI generation system to represent the
/// different types of generation operations: project, feature, and service.
enum GenerationMode {
  project,
  feature,
  service;

  /// Returns the canonical string key used in Mason variables.
  String get key {
    switch (this) {
      case GenerationMode.project:
        return 'project';
      case GenerationMode.feature:
        return 'feature';
      case GenerationMode.service:
        return 'service';
    }
  }

  /// Parses generation_mode from a string value.
  static GenerationMode fromKey(String key) {
    final normalized = key.toLowerCase().trim();
    switch (normalized) {
      case 'project':
        return GenerationMode.project;
      case 'feature':
        return GenerationMode.feature;
      case 'service':
        return GenerationMode.service;
      default:
        throw ComposerException(
          'Invalid generation_mode: "$key". '
          'Must be one of: project, feature, service.',
        );
    }
  }

  /// Parses generation_mode from vars and returns the corresponding enum.
  ///
  /// This method reads from a generic map. For domain-specific parsing that
  /// uses typed MasonVarKey, use domain-specific helpers (e.g., in fly_cli).
  static GenerationMode fromVars(Map<String, dynamic> vars) {
    final modeStr = (vars['generation_mode'] as String?)?.toLowerCase();
    if (modeStr == null || modeStr.isEmpty) {
      return GenerationMode.project; // Default
    }
    return fromKey(modeStr);
  }
}
