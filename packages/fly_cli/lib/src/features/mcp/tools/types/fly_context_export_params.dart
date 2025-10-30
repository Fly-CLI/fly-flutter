import 'package:fly_mcp_server/fly_mcp_server.dart';

/// Typed parameters for fly.context.export tool
class FlyContextExportParams extends ToolParameter {
  FlyContextExportParams({
    this.outputFile,
    this.includeCode,
    this.includeDependencies,
    this.includeArchitecture,
    this.includeSuggestions,
    this.maxFiles,
    this.maxFileSize,
  });

  /// Create from JSON Map
  factory FlyContextExportParams.fromJson(Map<String, Object?> json) {
    return FlyContextExportParams(
      outputFile: json['outputFile'] as String?,
      includeCode: json['includeCode'] as bool?,
      includeDependencies: json['includeDependencies'] as bool?,
      includeArchitecture: json['includeArchitecture'] as bool?,
      includeSuggestions: json['includeSuggestions'] as bool?,
      maxFiles: json['maxFiles'] as int?,
      maxFileSize: json['maxFileSize'] as int?,
    );
  }

  /// Output file path (optional, defaults to stdout)
  final String? outputFile;

  /// Whether to include source code in export
  final bool? includeCode;

  /// Whether to include dependency analysis
  final bool? includeDependencies;

  /// Whether to include architecture analysis
  final bool? includeArchitecture;

  /// Whether to include AI suggestions
  final bool? includeSuggestions;

  /// Maximum number of files to analyze
  final int? maxFiles;

  /// Maximum file size to include (in bytes)
  final int? maxFileSize;

  @override
  Map<String, Object?> toJson() => {
        if (outputFile != null) 'outputFile': outputFile,
        if (includeCode != null) 'includeCode': includeCode,
        if (includeDependencies != null) 'includeDependencies': includeDependencies,
        if (includeArchitecture != null) 'includeArchitecture': includeArchitecture,
        if (includeSuggestions != null) 'includeSuggestions': includeSuggestions,
        if (maxFiles != null) 'maxFiles': maxFiles,
        if (maxFileSize != null) 'maxFileSize': maxFileSize,
      };
}

