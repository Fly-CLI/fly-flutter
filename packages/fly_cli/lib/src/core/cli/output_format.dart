/// Output format for CLI command results
///
/// This enum represents the different output formats supported by the Fly CLI.
/// It replaces string-based format checks throughout the codebase for type safety.
enum OutputFormat {
  /// Human-readable output (default)
  human,

  /// Machine-readable JSON format
  json,

  /// AI-optimized JSON format with enhanced structure
  ai;

  /// Parse output format from a string value
  ///
  /// Returns the corresponding [OutputFormat] enum value, or [OutputFormat.human]
  /// as the default if the string is null or doesn't match any format.
  ///
  /// [value] - The string value to parse (e.g., 'human', 'json', 'ai')
  static OutputFormat parse(String? value) {
    if (value == null) return OutputFormat.human;

    switch (value.toLowerCase()) {
      case 'json':
        return OutputFormat.json;
      case 'ai':
        return OutputFormat.ai;
      case 'human':
      default:
        return OutputFormat.human;
    }
  }

  /// Get the string representation of this format
  ///
  /// Returns the string value that can be used in command line arguments
  /// or serialized formats.
  @override
  String toString() {
    switch (this) {
      case OutputFormat.human:
        return 'human';
      case OutputFormat.json:
        return 'json';
      case OutputFormat.ai:
        return 'ai';
    }
  }

  /// Whether this format is machine-readable (JSON or AI)
  bool get isMachineReadable =>
      this == OutputFormat.json || this == OutputFormat.ai;

  /// Whether this format is JSON
  bool get isJson => this == OutputFormat.json;

  /// Whether this format is AI-optimized
  bool get isAi => this == OutputFormat.ai;

  /// Whether this format is human-readable
  bool get isHuman => this == OutputFormat.human;
}
