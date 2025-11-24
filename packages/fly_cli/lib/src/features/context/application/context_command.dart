import 'dart:convert';
import 'dart:io';

import 'package:fly_cli/src/features/commands/application/command_base.dart';
import 'package:fly_cli/src/features/commands/domain/command_context.dart';
import 'package:fly_cli/src/features/commands/domain/command_result.dart';
import 'package:fly_cli/src/features/commands/domain/command_validator.dart';
import 'package:fly_cli/src/features/commands/infrastructure/flags/cli_flags.dart';
import 'package:fly_cli/src/features/commands/infrastructure/flags/flag_accessor.dart';
import 'package:fly_cli/src/cli/infrastructure/middleware/domain/command_middleware.dart';
import 'package:fly_cli/src/shared/utils/version_utils.dart';
import 'package:fly_cli/src/features/context/infrastructure/context_generator.dart';
import 'package:fly_cli/src/features/context/domain/models.dart';

/// ContextCommand using new architecture
class ContextCommand extends FlyCommand {
  ContextCommand(CommandContext context) : super(context);

  /// Factory constructor for enum-based command creation
  factory ContextCommand.create(CommandContext context) =>
      ContextCommand(context);

  @override
  String get name => 'context';

  @override
  String get description => 'Export project context for AI integration';

  @override
  List<CliFlag> get flags => [
        const OutputFileFlag(),
        const ContextIncludeCodeFlag(),
        const ContextIncludeDependenciesFlag(),
        const ContextIncludeArchitectureFlag(),
        const ContextIncludeSuggestionsFlag(),
        const ContextMaxFilesFlag(),
        const ContextMaxFileSizeFlag(),
      ];

  @override
  List<CommandValidator> get validators => [
        FlutterProjectValidator(),
        DirectoryWritableValidator(),
      ];

  @override
  List<CommandMiddleware> get middleware => [
      ];

  @override
  Future<CommandResult> execute() async {
    try {
      final outputFile =
          FlagAccessor.getString(argResults, const OutputFileFlag());
      final includeCode = FlagAccessor.getBool(
        argResults,
        const ContextIncludeCodeFlag(),
      );
      final includeDependencies = FlagAccessor.getBool(
        argResults,
        const ContextIncludeDependenciesFlag(),
      );
      final includeArchitecture = FlagAccessor.getBool(
        argResults,
        const ContextIncludeArchitectureFlag(),
      );
      final includeSuggestions = FlagAccessor.getBool(
        argResults,
        const ContextIncludeSuggestionsFlag(),
      );
      final maxFiles = int.tryParse(
            FlagAccessor.getStringOrDefault(
              argResults,
              const ContextMaxFilesFlag(),
              '50',
            ),
          ) ??
          50;
      final maxFileSize = int.tryParse(
            FlagAccessor.getStringOrDefault(
              argResults,
              const ContextMaxFileSizeFlag(),
              '10000',
            ),
          ) ??
          10000;

      logger.info('🔍 Analyzing project context...');

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
      final contextGenerator = ContextGenerator(logger: logger);
      final projectDir = Directory(context.workingDirectory);

      final contextData = await contextGenerator.generate(projectDir, config);

      // Add command-specific metadata
      final enrichedData = {
        ...contextData,
        'export_config': {
          'include_code': includeCode,
          'include_dependencies': includeDependencies,
          'include_architecture': includeArchitecture,
          'include_suggestions': includeSuggestions,
          'max_files': maxFiles,
          'max_file_size': maxFileSize,
        },
        'export_metadata': {
          'exported_at': DateTime.now().toIso8601String(),
          'cli_version': VersionUtils.getCurrentVersion(),
          'working_directory': context.workingDirectory,
          'output_file': outputFile,
        },
      };

      // Write to file if specified
      if (outputFile != null) {
        final file = File(outputFile);
        await file.writeAsString(isJsonOutputFormat
            ? json.encode(enrichedData)
            : isAiOutputFormat
                ? json.encode(enrichedData)
                : _formatHumanOutput(enrichedData));

        return CommandResult.success(
          command: 'context',
          message: 'Context exported to $outputFile',
          data: {
            'output_file': outputFile,
            'file_size_bytes': await file.length(),
            'sections_included': _getIncludedSections(enrichedData),
          },
          nextSteps: [
            NextStep(
              command: 'cat $outputFile',
              description: 'View the exported context file',
            ),
          ],
        );
      }

      return CommandResult.success(
        command: 'context',
        message: 'Context exported successfully',
        data: enrichedData,
        nextSteps: [
          const NextStep(
            command: 'fly context --output-file=context.json',
            description: 'Save context to a file for later use',
          ),
        ],
      );
    } catch (e) {
      return CommandResult.error(
        message: 'Failed to export context: $e',
        suggestion: 'Check your project structure and try again',
      );
    }
  }

  /// Format context data for human-readable output
  String _formatHumanOutput(Map<String, dynamic> data) {
    final buffer = StringBuffer()
      ..writeln('📋 Project Context Export')
      ..writeln('========================')
      ..writeln();

    if (data.containsKey('project')) {
      final project = data['project'] as Map<String, dynamic>;
      buffer
        ..writeln('📁 Project: ${project['name'] ?? 'Unknown'}')
        ..writeln('📦 Package: ${project['package_name'] ?? 'Unknown'}')
        ..writeln('🏗️  Type: ${project['project_type'] ?? 'Unknown'}')
        ..writeln();
    }

    if (data.containsKey('structure')) {
      final structure = data['structure'] as Map<String, dynamic>;
      buffer
        ..writeln('📂 Structure:')
        ..writeln('  - Directories: ${structure['directory_count'] ?? 0}')
        ..writeln('  - Files: ${structure['file_count'] ?? 0}')
        ..writeln();
    }

    if (data.containsKey('commands')) {
      final commands = data['commands'] as Map<String, dynamic>;
      final available = commands['available'] as List<dynamic>? ?? [];
      buffer
        ..writeln('⚡ Available Commands: ${available.length}')
        ..writeln();
    }

    buffer
      ..writeln('📊 Export Summary:')
      ..writeln('  - Sections: ${data.keys.length}')
      ..writeln(
          '  - Exported: ${data['export_metadata']?['exported_at'] ?? 'Unknown'}')
      ..writeln();

    return buffer.toString();
  }

  /// Get list of included sections for metadata
  List<String> _getIncludedSections(Map<String, dynamic> data) => data.keys
      .where((key) => !['export_config', 'export_metadata'].contains(key))
      .toList();
}
