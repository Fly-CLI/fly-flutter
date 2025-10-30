/// Supported schema export formats
enum ExportFormat {
  /// JSON Schema Draft 7 format
  jsonSchema,
  
  /// OpenAPI 3.0 inspired format
  openApi,
  
  /// Custom CLI specification format
  cliSpec,
}

/// Extension methods for ExportFormat
extension ExportFormatExtension on ExportFormat {
  /// Get the display name for the format
  String get displayName {
    switch (this) {
      case ExportFormat.jsonSchema:
        return 'JSON Schema';
      case ExportFormat.openApi:
        return 'OpenAPI';
      case ExportFormat.cliSpec:
        return 'CLI Spec';
    }
  }

  /// Get the file extension for the format
  String get fileExtension {
    switch (this) {
      case ExportFormat.jsonSchema:
        return 'json';
      case ExportFormat.openApi:
        return 'yaml';
      case ExportFormat.cliSpec:
        return 'json';
    }
  }

  /// Get the MIME type for the format
  String get mimeType {
    switch (this) {
      case ExportFormat.jsonSchema:
        return 'application/schema+json';
      case ExportFormat.openApi:
        return 'application/vnd.oai.openapi';
      case ExportFormat.cliSpec:
        return 'application/json';
    }
  }
}
