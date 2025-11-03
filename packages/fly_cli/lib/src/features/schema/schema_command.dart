import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:fly_cli/src/core/command/foundation/application/command_base.dart';
import 'package:fly_cli/src/core/command/foundation/domain/command_context.dart';
import 'package:fly_cli/src/core/command/foundation/domain/command_result.dart';
import 'package:fly_cli/src/core/command/foundation/domain/command_validator.dart';
import 'package:fly_cli/src/core/command/foundation/flags/cli_flags.dart';
import 'package:fly_cli/src/core/command/foundation/flags/flag_accessor.dart';
import 'package:fly_cli/src/core/command/foundation/flags/flag_factory.dart';
import 'package:fly_cli/src/core/command/metadata/command_metadata.dart';
import 'package:fly_cli/src/core/middleware/domain/command_middleware.dart';
import 'package:fly_cli/src/core/utils/version_utils.dart';
import 'package:fly_cli/src/features/schema/export_format.dart';
import 'package:fly_cli/src/features/schema/exporters/schema_exporter.dart';
import 'package:fly_cli/src/features/schema/exporters/schema_exporter_factory.dart';

/// SchemaCommand using new architecture
class SchemaCommand extends FlyCommand {
  SchemaCommand(CommandContext context) : super(context);

  /// Factory constructor for enum-based command creation
  factory SchemaCommand.create(CommandContext context) =>
      SchemaCommand(context);

  @override
  String get name => 'schema';

  @override
  String get description => 'Export command schema in various formats';

  @override
  ArgParser get argParser {
    final parser = super.argParser;
    FlagFactory.applyFlagsToParser(parser, [
      const SchemaFormatFlag(),
      const SchemaCommandFilterFlag(),
      const OutputFileFlag(),
      const SchemaIncludeExamplesFlag(),
      const SchemaIncludeValidationFlag(),
      const SchemaIncludeGlobalOptionsFlag(),
      const SchemaPrettyPrintFlag(),
    ]);
    return parser;
  }

  @override
  List<CommandValidator> get validators => [
        EnvironmentValidator(),
      ];

  @override
  List<CommandMiddleware> get middleware => [
      ];

  @override
  Future<CommandResult> execute() async {
    try {
      final formatStr = FlagAccessor.getStringOrDefault(
        argResults,
        const SchemaFormatFlag(),
        'json-schema',
      );
      final commandFilter = FlagAccessor.getString(
        argResults,
        const SchemaCommandFilterFlag(),
      );
      final outputFile =
          FlagAccessor.getString(argResults, const OutputFileFlag());
      final includeExamples = FlagAccessor.getBool(
        argResults,
        const SchemaIncludeExamplesFlag(),
      );
      final includeValidation = FlagAccessor.getBool(
        argResults,
        const SchemaIncludeValidationFlag(),
      );
      final includeGlobalOptions = FlagAccessor.getBool(
        argResults,
        const SchemaIncludeGlobalOptionsFlag(),
      );
      final prettyPrint = FlagAccessor.getBool(
        argResults,
        const SchemaPrettyPrintFlag(),
      );

      logger.info('📋 Exporting command schema...');

      // Parse format
      final format = _parseFormat(formatStr);

      // Create export configuration
      final config = ExportConfig(
        format: format,
        commandFilter: commandFilter,
        includeExamples: includeExamples,
        includeValidation: includeValidation,
        includeGlobalOptions: includeGlobalOptions,
        prettyPrint: prettyPrint,
      );

      // Get command registry (lazy initialization happens automatically when metadata is accessed)
      final registry = CommandMetadataRegistry.instance;

      // Get exporter
      final exporter = SchemaExporterFactory.getExporter(format);

      // Export schema
      final schemaContent = exporter.export(registry, config);

      // Parse schema for metadata extraction
      final schemaData = json.decode(schemaContent) as Map<String, dynamic>;

      // Add command-specific metadata
      final enrichedData = {
        'schema': schemaData,
        'export_config': {
          'format': format.displayName,
          'format_type': format.name,
          'command_filter': commandFilter,
          'include_examples': includeExamples,
          'include_validation': includeValidation,
          'include_global_options': includeGlobalOptions,
          'pretty_print': prettyPrint,
        },
        'export_metadata': {
          'exported_at': DateTime.now().toIso8601String(),
          'cli_version': VersionUtils.getCurrentVersion(),
          'content_type': exporter.contentType,
          'file_extension': format.fileExtension,
          'output_file': outputFile,
        },
      };

      // Write to file if specified
      if (outputFile != null) {
        final file = File(outputFile);
        await file.writeAsString(schemaContent);

        return CommandResult.success(
          command: 'schema',
          message: 'Schema exported to $outputFile',
          data: {
            'output_file': outputFile,
            'file_size_bytes': await file.length(),
            'format': format.displayName,
            'commands_included': _getCommandsIncluded(schemaData),
            'content_type': exporter.contentType,
          },
          nextSteps: [
            NextStep(
              command: 'cat $outputFile',
              description: 'View the exported schema file',
            ),
          ],
        );
      }

      return CommandResult.success(
        command: 'schema',
        message: 'Schema exported successfully',
        data: enrichedData,
        nextSteps: [
          const NextStep(
            command: 'fly schema --file=schema.json',
            description: 'Save schema to a file for later use',
          ),
          const NextStep(
            command: 'fly schema --format=openapi',
            description: 'Export schema in OpenAPI format',
          ),
        ],
      );
    } catch (e) {
      return CommandResult.error(
        message: 'Failed to export schema: $e',
        suggestion: 'Check your command syntax and try again',
      );
    }
  }

  /// Parse format string to ExportFormat enum
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

  /// Get list of commands included in schema
  List<String> _getCommandsIncluded(Map<String, dynamic> schemaData) {
    if (schemaData.containsKey('properties')) {
      return (schemaData['properties'] as Map<String, dynamic>).keys.toList();
    }
    return [];
  }
}
