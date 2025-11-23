import 'dart:convert';
import 'dart:io';

import 'package:fly_cli/src/core/command/foundation/domain/command_context.dart';
import 'package:fly_cli/src/features/context/context_generator.dart';
import 'package:fly_cli/src/features/context/models.dart';
import 'package:fly_cli/src/integrations/mcp/mcp_tool_strategy.dart';
import 'package:fly_cli/src/integrations/mcp/tools/types/context_export_params.dart';
import 'package:fly_cli/src/integrations/mcp/tools/types/context_export_result.dart';
import 'package:fly_mcp/fly_mcp.dart';

/// Strategy for fly.context.export tool
class ProjectContextExportStrategy
    extends McpToolStrategy<ContextExportParams, ContextExportResult> {
  @override
  String get name => 'fly.context.export';

  @override
  String get description => 'Export project context for AI integration';

  @override
  ObjectSchema get paramsSchema => ObjectSchema(
        properties: {
          'outputFile': Schema.string(),
          'includeCode': Schema.bool(),
          'includeDependencies': Schema.bool(),
          'includeArchitecture': Schema.bool(),
          'includeSuggestions': Schema.bool(),
          'maxFiles': Schema.int(),
          'maxFileSize': Schema.int(),
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
          'sectionsIncluded': Schema.list(items: Schema.string()),
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
  Duration? get timeout => const Duration(minutes: 2);

  @override
  ContextExportParams paramsFromJson(Map<String, Object?> json) {
    return ContextExportParams.fromJson(json);
  }

  @override
  TypedToolHandler<ContextExportParams, ContextExportResult>
      createTypedHandler(
    CommandContext context,
    ResourceRegistry resourceRegistry,
  ) {
    return (params, {cancelToken, progressNotifier}) async {
      cancelToken?.throwIfCancelled();

      final includeCode = params.includeCode ?? false;
      final includeDependencies = params.includeDependencies ?? false;
      final includeArchitecture = params.includeArchitecture ?? true;
      final includeSuggestions = params.includeSuggestions ?? true;
      final maxFiles = params.maxFiles ?? 50;
      final maxFileSize = params.maxFileSize ?? 10000;

      await progressNotifier?.notify(
          message: 'Analyzing project context...', percent: 10);

      // Create context generator configuration
      final config = ContextGeneratorConfig(
        includeCode: includeCode,
        includeDependencies: includeDependencies,
        includeArchitecture: includeArchitecture,
        includeSuggestions: includeSuggestions,
        maxFiles: maxFiles,
        maxFileSize: maxFileSize,
        includeTests: false,
        includeGenerated: false,
      );

      // Generate context using the enhanced context generator
      final contextGenerator = ContextGenerator(logger: context.logger);
      final projectDir = Directory(context.workingDirectory);

      await progressNotifier?.notify(
          message: 'Generating context data...', percent: 50);

      final contextData = await contextGenerator.generate(projectDir, config);

      cancelToken?.throwIfCancelled();

      // Write to file if specified
      if (params.outputFile != null) {
        final file = File(params.outputFile!);
        await file.writeAsString(
            _formatOutput(contextData));

        final fileSize = await file.length();
        final sectionsIncluded = contextData.keys
            .where((key) => !['export_config', 'export_metadata'].contains(key))
            .toList();

        return ContextExportResult(
          success: true,
          message: 'Context exported to ${params.outputFile}',
          outputFile: params.outputFile,
          fileSizeBytes: fileSize,
          sectionsIncluded: sectionsIncluded,
        );
      }

      final sectionsIncluded = contextData.keys
          .where((key) => !['export_config', 'export_metadata'].contains(key))
          .toList();

      return ContextExportResult(
        success: true,
        message: 'Context exported successfully',
        sectionsIncluded: sectionsIncluded,
      );
    };
  }

  /// Format output as properly indented JSON
  String _formatOutput(Map<String, dynamic> data) {
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(data);
  }
}

