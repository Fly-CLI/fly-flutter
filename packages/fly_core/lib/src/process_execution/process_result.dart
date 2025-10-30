/// Result of a process execution
///
/// Provides a standardized wrapper for process execution results
/// with structured information about the execution.
class ProcessExecutionResult {
  const ProcessExecutionResult({
    required this.exitCode,
    required this.stdout,
    required this.stderr,
    this.command,
    this.duration,
  });

  /// Create a success result
  factory ProcessExecutionResult.success({
    String stdout = '',
    String stderr = '',
    String? command,
    Duration? duration,
  }) {
    return ProcessExecutionResult(
      exitCode: 0,
      stdout: stdout,
      stderr: stderr,
      command: command,
      duration: duration,
    );
  }

  /// Create a failure result
  factory ProcessExecutionResult.failure({
    int exitCode = 1,
    String stdout = '',
    String stderr = '',
    String? command,
    Duration? duration,
  }) {
    return ProcessExecutionResult(
      exitCode: exitCode,
      stdout: stdout,
      stderr: stderr,
      command: command,
      duration: duration,
    );
  }

  /// Create from raw ProcessResult
  factory ProcessExecutionResult.fromProcessResult({
    String? command,
    Duration? duration,
  }) {
    // This would need to be adapted based on actual ProcessResult type
    // For now, we'll provide a basic implementation
    return ProcessExecutionResult(
      exitCode: 0,
      stdout: '',
      stderr: '',
      command: command,
      duration: duration,
    );
  }

  /// Exit code of the process
  final int exitCode;

  /// Standard output
  final String stdout;

  /// Standard error output
  final String stderr;

  /// Command that was executed (optional)
  final String? command;

  /// Duration of execution (optional)
  final Duration? duration;

  /// Whether the process succeeded (exit code 0)
  bool get success => exitCode == 0;

  /// Whether the process failed (exit code != 0)
  bool get failed => exitCode != 0;

  /// Get combined output (stdout + stderr)
  String get combinedOutput => stdout + stderr;

  /// Get all output lines from stdout
  List<String> get stdoutLines =>
      stdout.split('\n').where((line) => line.isNotEmpty).toList();

  /// Get all output lines from stderr
  List<String> get stderrLines =>
      stderr.split('\n').where((line) => line.isNotEmpty).toList();

  /// Get a summary of the result
  Map<String, dynamic> toMap() {
    return {
      'exit_code': exitCode,
      'success': success,
      'stdout': stdout,
      'stderr': stderr,
      'command': command,
      'duration_ms': duration?.inMilliseconds,
    };
  }

  @override
  String toString() {
    return 'ProcessExecutionResult(exitCode: $exitCode, success: $success)';
  }
}
