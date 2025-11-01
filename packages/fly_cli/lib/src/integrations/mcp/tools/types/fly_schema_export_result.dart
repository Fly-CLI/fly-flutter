import 'package:fly_mcp/fly_mcp.dart';

/// Typed result for fly.schema.export tool
class FlySchemaExportResult extends ToolResult {
  FlySchemaExportResult({
    required this.success,
    required this.message,
    this.outputFile,
    this.fileSizeBytes,
    this.format,
    this.contentType,
  });

  /// Create from JSON Map
  factory FlySchemaExportResult.fromJson(Map<String, Object?> json) {
    return FlySchemaExportResult(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      outputFile: json['outputFile'] as String?,
      fileSizeBytes: json['fileSizeBytes'] as int?,
      format: json['format'] as String?,
      contentType: json['contentType'] as String?,
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

  /// Export format
  final String? format;

  /// Content type
  final String? contentType;

  @override
  Map<String, Object?> toJson() => {
        'success': success,
        'message': message,
        if (outputFile != null) 'outputFile': outputFile,
        if (fileSizeBytes != null) 'fileSizeBytes': fileSizeBytes,
        if (format != null) 'format': format,
        if (contentType != null) 'contentType': contentType,
      };
}
