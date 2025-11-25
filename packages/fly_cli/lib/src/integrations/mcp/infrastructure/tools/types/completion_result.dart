import 'package:fly_mcp/fly_mcp.dart';

/// Typed result for fly.completion tool
class CompletionResult extends ToolResult {
  CompletionResult({
    required this.success,
    required this.message,
    this.shell,
    this.outputFile,
    this.installPath,
  });

  /// Create from JSON Map
  factory CompletionResult.fromJson(Map<String, Object?> json) {
    return CompletionResult(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      shell: json['shell'] as String?,
      outputFile: json['outputFile'] as String?,
      installPath: json['installPath'] as String?,
    );
  }

  /// Whether the operation was successful
  final bool success;

  /// Status message
  final String message;

  /// Target shell
  final String? shell;

  /// Output file path
  final String? outputFile;

  /// Installation path
  final String? installPath;

  @override
  Map<String, Object?> toJson() => {
    'success': success,
    'message': message,
    if (shell != null) 'shell': shell,
    if (outputFile != null) 'outputFile': outputFile,
    if (installPath != null) 'installPath': installPath,
  };
}
