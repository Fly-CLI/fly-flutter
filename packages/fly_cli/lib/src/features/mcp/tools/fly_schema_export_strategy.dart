import 'dart:io';

import 'package:fly_cli/src/core/command_metadata/command_metadata.dart';
import 'package:fly_cli/src/features/mcp/mcp_tool_strategy.dart';
import 'package:fly_cli/src/features/mcp/tools/types/fly_schema_export_params.dart';
import 'package:fly_cli/src/features/mcp/tools/types/fly_schema_export_result.dart';
import 'package:fly_cli/src/features/schema/export_format.dart';
import 'package:fly_cli/src/features/schema/exporters/schema_exporter.dart';
import 'package:fly_cli/src/features/schema/exporters/schema_exporter_factory.dart';
import 'package:fly_cli/src/core/command_foundation/command_context.dart';
import 'package:fly_mcp_server/fly_mcp_server.dart';

/// Strategy for fly.schema.export tool
class FlySchemaExportStrategy
    extends McpToolStrategy<FlySchemaExportParams, FlySchemaExportResult> {
  @override
  String get name => 'fly.schema.export';

  @override
  String get description => 'Export command schema in various formats';

  @override
  ObjectSchema get paramsSchema => ObjectSchema(
        properties: {
          'format': Schema.string(enumValues: ['json-schema', 'openapi', 'cli-spec']),
          'command': Schema.string(),
          'outputFile': Schema.string(),
          'includeExamples': Schema.bool(),
          'includeValidation': Schema.bool(),
          'includeGlobalOptions': Schema.bool(),
          'prettyPrint': Schema.bool(),
        },
        additionalProperties: false,
      );

  @override
  ObjectSchema get resultSchema => ObjectSchema(
        properties: {
          'success': Schema.bool(),
          'message': Schema.string(),
          'outputFile': Schema.string(),
          'fileSizeBytes': Schema.int(),
          'format': Schema.string(),
          'contentType': Schema.string(),
        },
        required: ['success', 'message'],
      );

  @override
  bool get readOnly => true;

  @override
  bool get writesToDisk => true;

  @override
  bool get requiresConfirmation => false;

  @override
  bool get idempotent => true;

  @override
  Duration? get timeout => const Duration(seconds: 30);

  @override
  FlySchemaExportParams paramsFromJson(Map<String, Object?> json) {
    return FlySchemaExportParams.fromJson(json);
  }

  @override
  TypedToolHandler<FlySchemaExportParams, FlySchemaExportResult> createTypedHandler(
    CommandContext context,
    ResourceRegistry resourceRegistry,
  ) {
    return (params, {cancelToken, progressNotifier}) async {
      cancelToken?.throwIfCancelled();

      final formatStr = params.format ?? 'json-schema';
      final commandFilter = params.command;
      final outputFile = params.outputFile;
      final includeExamples = params.includeExamples ?? true;
      final includeValidation = params.includeValidation ?? true;
      final includeGlobalOptions = params.includeGlobalOptions ?? true;
      final prettyPrint = params.prettyPrint ?? true;

      await progressNotifier?.notify(
          message: 'Exporting command schema...', percent: 10);

      // Parse format
      final format = _parseFormat(formatStr);
      
      await progressNotifier?.notify(
          message: 'Generating schema...', percent: 50);

      // Get command registry
      final registry = CommandMetadataRegistry.instance;

      // Get exporter
      final exporter = SchemaExporterFactory.getExporter(format);
      
      // Export schema
      final schemaContent = exporter.export(registry, _createExportConfig(
        format: format,
        commandFilter: commandFilter,
        includeExamples: includeExamples,
        includeValidation: includeValidation,
        includeGlobalOptions: includeGlobalOptions,
        prettyPrint: prettyPrint,
      ));

      cancelToken?.throwIfCancelled();

      // Write to file if specified
      if (outputFile != null) {
        final file = File(outputFile);
        await file.writeAsString(schemaContent);
        
        final fileSize = await file.length();

        return FlySchemaExportResult(
          success: true,
          message: 'Schema exported to $outputFile',
          outputFile: outputFile,
          fileSizeBytes: fileSize,
          format: format.displayName,
          contentType: exporter.contentType,
        );
      }

      return FlySchemaExportResult(
        success: true,
        message: 'Schema exported successfully',
        format: format.displayName,
        contentType: exporter.contentType,
      );
    };
  }

  ExportFormat _parseFormat(String formatStr) {
    switch (formatStr) {
      case 'json-schema':
        return ExportFormat.jsonSchema;
      case 'openapi':
        return ExportFormat.openApi;
      case 'cli-spec':
        return ExportFormat.cliSpec;
      default:
        throw ArgumentError('Unsupported format: $formatStr');
    }
  }

  ExportConfig _createExportConfig({
    required ExportFormat format,
    String? commandFilter,
    required bool includeExamples,
    required bool includeValidation,
    required bool includeGlobalOptions,
    required bool prettyPrint,
  }) {
    return ExportConfig(
      format: format,
      commandFilter: commandFilter,
      includeExamples: includeExamples,
      includeValidation: includeValidation,
      includeGlobalOptions: includeGlobalOptions,
      prettyPrint: prettyPrint,
    );
  }
}
