import 'package:fly_mcp/fly_mcp.dart';

/// Typed result for fly.context.export tool
class ContextExportResult extends ToolResult {
  ContextExportResult({
    required this.success,
    required this.message,
    this.outputFile,
    this.fileSizeBytes,
    this.sectionsIncluded,
  });

  /// Create from JSON Map
  factory ContextExportResult.fromJson(Map<String, Object?> json) {
    return ContextExportResult(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      outputFile: json['outputFile'] as String?,
      fileSizeBytes: json['fileSizeBytes'] as int?,
      sectionsIncluded: (json['sectionsIncluded'] as List?)?.cast<String>(),
    );
  }

  /// Whether the operation was successful
  final bool success;

  /// Status message
  final String message;

  /// Output file path
  final String? outputFile;

  /// File size in bytes
  final int? fileSizeBytes;

  /// List of included sections
  final List<String>? sectionsIncluded;

  @override
  Map<String, Object?> toJson() => {
        'success': success,
        'message': message,
        if (outputFile != null) 'outputFile': outputFile,
        if (fileSizeBytes != null) 'fileSizeBytes': fileSizeBytes,
        if (sectionsIncluded != null) 'sectionsIncluded': sectionsIncluded,
      };
}
