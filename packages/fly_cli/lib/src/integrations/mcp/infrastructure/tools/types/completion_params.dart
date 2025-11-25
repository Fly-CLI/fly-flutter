import 'package:fly_mcp/fly_mcp.dart';

/// Typed parameters for fly.completion tool
class CompletionParams extends ToolParameter {
  CompletionParams({
    this.shell,
    this.outputFile,
    this.install,
  });

  /// Create from JSON Map
  factory CompletionParams.fromJson(Map<String, Object?> json) {
    return CompletionParams(
      shell: json['shell'] as String?,
      outputFile: json['outputFile'] as String?,
      install: json['install'] as bool?,
    );
  }

  /// Target shell: bash, zsh, fish, or powershell
  final String? shell;

  /// Output file path (optional, defaults to stdout)
  final String? outputFile;

  /// Whether to install completion script
  final bool? install;

  @override
  Map<String, Object?> toJson() => {
    if (shell != null) 'shell': shell,
    if (outputFile != null) 'outputFile': outputFile,
    if (install != null) 'install': install,
  };
}
