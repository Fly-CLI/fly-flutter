/// Result of orchestrating foundation generation.
///
/// This is a generic result type that aggregates the results of multiple
/// brick executions. The type parameter `TFile` allows different hosts
/// (CLI, test harnesses, etc.) to use their own file representations.
class OrchestrationResult<TFile> {
  const OrchestrationResult._({
    required this.success,
    this.files,
    this.targetDirectory,
    this.error,
  });

  /// Creates a successful result with generated files.
  factory OrchestrationResult.success({
    required List<TFile> files,
    required String targetDirectory,
  }) {
    return OrchestrationResult._(
      success: true,
      files: files,
      targetDirectory: targetDirectory,
    );
  }

  /// Creates a failed result with an error message.
  factory OrchestrationResult.failure({required String error}) {
    return OrchestrationResult._(
      success: false,
      error: error,
    );
  }

  /// Whether the orchestration succeeded.
  final bool success;

  /// List of all files generated across all brick invocations (if successful).
  final List<TFile>? files;

  /// Target directory where files were generated (if successful).
  final String? targetDirectory;

  /// Error message (if failed).
  final String? error;
}

