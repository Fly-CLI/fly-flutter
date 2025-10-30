import 'package:fly_cli/src/features/schema/export_format.dart';
import 'schema_exporter.dart';
import 'json_schema_exporter.dart';
import 'openapi_exporter.dart';
import 'cli_spec_exporter.dart';

/// Factory for creating schema exporters
class SchemaExporterFactory {
  static final Map<ExportFormat, SchemaExporter> _exporters = {
      ExportFormat.jsonSchema: JsonSchemaExporter(),
      ExportFormat.openApi: OpenApiExporter(),
      ExportFormat.cliSpec: CliSpecExporter(),
  };

  /// Get exporter for the specified format
  static SchemaExporter getExporter(ExportFormat format) {
    final exporter = _exporters[format];
    if (exporter == null) {
      throw ArgumentError('No exporter found for format: $format');
    }
    return exporter;
  }

  /// Get all available exporters
  static Map<ExportFormat, SchemaExporter> getAllExporters() => Map.unmodifiable(_exporters);

  /// Get all supported formats
  static List<ExportFormat> getSupportedFormats() => _exporters.keys.toList();

  /// Check if a format is supported
  static bool isFormatSupported(ExportFormat format) => _exporters.containsKey(format);
}
