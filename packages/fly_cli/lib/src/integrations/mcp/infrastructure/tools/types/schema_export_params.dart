import 'package:fly_mcp/fly_mcp.dart';

/// Typed parameters for fly.schema.export tool
class SchemaExportParams extends ToolParameter {
  SchemaExportParams({
    this.format,
    this.command,
    this.outputFile,
    this.includeExamples,
    this.includeValidation,
    this.includeGlobalOptions,
    this.prettyPrint,
  });

  /// Create from JSON Map
  factory SchemaExportParams.fromJson(Map<String, Object?> json) {
    return SchemaExportParams(
      format: json['format'] as String?,
      command: json['command'] as String?,
      outputFile: json['outputFile'] as String?,
      includeExamples: json['includeExamples'] as bool?,
      includeValidation: json['includeValidation'] as bool?,
      includeGlobalOptions: json['includeGlobalOptions'] as bool?,
      prettyPrint: json['prettyPrint'] as bool?,
    );
  }

  /// Export format: json-schema, openapi, or cli-spec
  final String? format;

  /// Export schema for specific command only
  final String? command;

  /// Output file path (optional, defaults to stdout)
  final String? outputFile;

  /// Whether to include command examples
  final bool? includeExamples;

  /// Whether to include validation rules
  final bool? includeValidation;

  /// Whether to include global options
  final bool? includeGlobalOptions;

  /// Whether to pretty print the output
  final bool? prettyPrint;

  @override
  Map<String, Object?> toJson() => {
    if (format != null) 'format': format,
    if (command != null) 'command': command,
    if (outputFile != null) 'outputFile': outputFile,
    if (includeExamples != null) 'includeExamples': includeExamples,
    if (includeValidation != null) 'includeValidation': includeValidation,
    if (includeGlobalOptions != null)
      'includeGlobalOptions': includeGlobalOptions,
    if (prettyPrint != null) 'prettyPrint': prettyPrint,
  };
}
